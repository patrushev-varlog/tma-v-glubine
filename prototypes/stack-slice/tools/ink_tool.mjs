#!/usr/bin/env node
// Инструменты Ink для среза стека. Нужен Node 18+ и inkjs 2.3.2 (npm install в этой папке).
//
//   node ink_tool.mjs build      — компилирует историю в JSON для Godot (story/*.json)
//   node ink_tool.mjs reference  — эталонные прогоны inkjs для тестов рантаймов (tests/reference.json)
//   node ink_tool.mjs parity     — русский и английский текст ведут себя одинаково (строки, теги, выборы, флаги)
//   node ink_tool.mjs check      — parity + сверка, что JSON сцены в репозитории свежий (вся история — только предупреждение)
//   node ink_tool.mjs transcript <story.json> <class> <hero_f> <spouse_f> <seed>  — прогон для отладки
//
// Прогон («транскрипт») одинаково устроен здесь, в tests/run_tests.gd (GodotInk) и в fallback-inkgd:
// выборы делает детерминированный генератор, раз в три выбора состояние сохраняется и загружается обратно.

import { createRequire } from "node:module";
import { createHash } from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const { Compiler, CompilerOptions, Story } = require("inkjs/full");

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SLICE = path.resolve(HERE, "..");
const REPO = path.resolve(SLICE, "../..");

// Что компилируем: исходник → JSON в проекте Godot.
const TARGETS = [
  { id: "game.ru", src: path.join(REPO, "story/ink/game.ink") },
  { id: "slice.ru", src: path.join(SLICE, "ink/slice.ru.ink") },
  { id: "slice.en", src: path.join(SLICE, "ink/slice.en.ink") },
];

// Только для проверки parity: компилируются в памяти, JSON в проект не пишется.
const PARITY_ONLY = [
  { id: "prologue.ru", src: path.join(SLICE, "ink/prologue.ru.ink") },
  { id: "prologue.en", src: path.join(SLICE, "ink/prologue.en.ink") },
];
const PARITY_PAIRS = [
  ["slice.ru", "slice.en"],
  ["prologue.ru", "prologue.en"],
];

export const CLASSES = ["fighter", "rogue", "cleric", "wizard"];
export const SETUPS = [];
for (const cls of CLASSES)
  for (const hero_f of [false, true])
    for (const spouse_f of [false, true]) SETUPS.push({ cls, hero_f, spouse_f });

const SAVE_EVERY = 3;
// Имя супруга задаёт игра; в прогонах одно и то же для обоих языков.
const SPOUSE_NAME = "Mara";

function compile(src) {
  const dir = path.dirname(src);
  const fileHandler = {
    ResolveInkFilename: (name) => path.resolve(dir, name),
    LoadInkFileContents: (full) => fs.readFileSync(full, "utf8"),
  };
  const errors = [];
  const opts = new CompilerOptions(src, [], false, (msg, type) => {
    if (type >= 1) errors.push(msg);
  }, fileHandler);
  const compiler = new Compiler(fs.readFileSync(src, "utf8"), opts);
  const story = compiler.Compile();
  const real = errors.filter((e) => !/WARNING/.test(e));
  if (!story || real.length) throw new Error(`${src}:\n${errors.join("\n")}`);
  return story.ToJson();
}

// Имена глобальных переменных из скомпилированного JSON (контейнер "global decl").
export function globalNames(json) {
  const root = JSON.parse(json).root;
  const named = root[root.length - 1];
  const decl = named["global decl"] || [];
  return decl.filter((x) => x && typeof x === "object" && "VAR=" in x).map((x) => x["VAR="]).sort();
}

function fmt(v) {
  if (typeof v === "boolean") return v ? "true" : "false";
  return String(v);
}

// Детерминированный выбор: LCG, такой же в GDScript.
function makeRng(seed) {
  let s = BigInt(seed);
  return () => {
    s = (s * 1103515245n + 12345n) % 2147483648n;
    return Number(s);
  };
}

// hi: выбор по старшим битам генератора. У LCG по модулю 2^31 младший бит чередуется, и выбор
// из двух вариантов по «% 2» идёт строго через раз: часть веток не проигрывается никогда.
// Эталонные прогоны (reference) оставлены как были, чтобы не расходиться с тестами в Godot.
export function transcript(json, setup, seed, names, { shape = false, hi = false } = {}) {
  let story = new Story(json);
  const vs = story.variablesState;
  vs.$("hero_class", setup.cls);
  vs.$("hero_f", setup.hero_f);
  vs.$("spouse_f", setup.spouse_f);
  vs.$("spouse_name", SPOUSE_NAME);
  const rng = makeRng(seed);
  const out = [];
  let picks = 0;
  for (;;) {
    while (story.canContinue) {
      // Перевод строки в конце строки Ink экранируем, чтобы одна строка Ink = одна строка прогона.
      const text = story.Continue().replace(/\n/g, "\\n");
      const tags = story.currentTags.join(",");
      out.push(shape ? `L|${tags}` : `L|${text}|${tags}`);
    }
    const choices = story.currentChoices;
    if (choices.length === 0) break;
    const idx = (hi ? rng() >> 16 : rng()) % choices.length;
    out.push(shape ? `C|${choices.length}|>${idx}` : `C|${choices.map((c) => c.text).join("|")}|>${idx}`);
    story.ChooseChoiceIndex(idx);
    picks++;
    if (picks % SAVE_EVERY === 0) {
      const saved = story.state.ToJson();
      story = new Story(json);
      story.state.LoadJson(saved);
    }
  }
  const values = names.map((n) => `${n}=${fmt(story.variablesState.$(n))}`);
  out.push(`V|${values.join(";")}`);
  const text = out.join("\n");
  return { text, hash: createHash("sha256").update(text, "utf8").digest("hex"), lines: out.length, picks };
}

function storyPath(id) {
  return path.join(SLICE, "story", `${id}.json`);
}

function build({ write = true } = {}) {
  const stale = [];
  const jsons = {};
  for (const t of TARGETS) {
    const json = compile(t.src);
    const dest = storyPath(t.id);
    const old = fs.existsSync(dest) ? fs.readFileSync(dest, "utf8") : null;
    if (old !== json) stale.push(t.id);
    jsons[t.id] = json;
    if (write) fs.writeFileSync(dest, json);
    console.log(`${t.id}: ${(json.length / 1024).toFixed(0)} КБ${old !== json ? " (обновлён)" : ""}`);
  }
  return { stale, jsons };
}

// Сиды: на полную игру по 4 прогона на сочетание, на сцену — по 8 (у сцены мало ветвлений).
const RUNS = [
  { story: "game.ru", seeds: [1, 2, 3, 4] },
  { story: "slice.ru", seeds: [1, 2, 3, 4, 5, 6, 7, 8] },
  { story: "slice.en", seeds: [1, 2, 3, 4, 5, 6, 7, 8] },
];

function reference() {
  const out = { generated_by: "inkjs 2.3.2", save_every: SAVE_EVERY, spouse_name: SPOUSE_NAME, stories: {} };
  for (const r of RUNS) {
    const json = fs.readFileSync(storyPath(r.story), "utf8");
    const names = globalNames(json);
    const runs = [];
    const t0 = Date.now();
    for (const setup of SETUPS)
      for (const seed of r.seeds) {
        const t = transcript(json, setup, seed, names);
        runs.push({ ...setup, seed, hash: t.hash, lines: t.lines, picks: t.picks });
      }
    out.stories[r.story] = { vars: names, runs };
    console.log(`${r.story}: ${runs.length} прогонов, ${Date.now() - t0} мс`);
  }
  fs.writeFileSync(path.join(SLICE, "tests/reference.json"), JSON.stringify(out, null, 1));
}

// Русский и английский должны давать одинаковую «форму»: те же строки с теми же тегами,
// то же число вариантов в каждом выборе и одинаковые флаги в конце.
function parity(jsons = null, pairs = PARITY_PAIRS) {
  const extra = Object.fromEntries(PARITY_ONLY.map((t) => [t.id, t.src]));
  const load = (id) => (jsons && jsons[id]) || (extra[id] ? compile(extra[id]) : fs.readFileSync(storyPath(id), "utf8"));
  let bad = 0;
  for (const [a, b] of pairs) {
    const ja = load(a);
    const jb = load(b);
    const na = globalNames(ja);
    const nb = globalNames(jb);
    if (na.join() !== nb.join()) {
      console.log(`${a} / ${b}: разные переменные:\n  ${na.join(" ")}\n  ${nb.join(" ")}`);
      bad++;
      continue;
    }
    const names = na.filter((n) => n !== "spouse_name");
    let runs = 0;
    for (const setup of SETUPS)
      for (const seed of [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
      for (const hi of [false, true]) {
        const ta = transcript(ja, setup, seed, names, { shape: true, hi }).text.split("\n");
        const tb = transcript(jb, setup, seed, names, { shape: true, hi }).text.split("\n");
        runs++;
        const n = Math.max(ta.length, tb.length);
        for (let i = 0; i < n; i++) {
          if (ta[i] !== tb[i]) {
            if (bad < 3) {
              const fa = transcript(ja, setup, seed, names, { hi }).text.split("\n");
              const fb = transcript(jb, setup, seed, names, { hi }).text.split("\n");
              console.log(`${a} / ${b}: расхождение, ${JSON.stringify(setup)} seed ${seed}, шаг ${i + 1}`);
              console.log(`  ${a}: ${(fa[i] ?? "(конец)").trim()}\n  ${b}: ${(fb[i] ?? "(конец)").trim()}`);
            }
            bad++;
            break;
          }
        }
      }
    console.log(`${a} / ${b}: ${runs} прогонов сверено${bad ? `, с расхождениями: ${bad}` : ", расхождений нет"}`);
  }
  return bad;
}

const [cmd, ...args] = process.argv.slice(2);
if (cmd === "build") build();
else if (cmd === "reference") reference();
else if (cmd === "parity") process.exit(parity() ? 1 : 0);
else if (cmd === "check") {
  const { stale, jsons } = build({ write: false });
  const bad = parity(jsons);
  // Сцена среза (slice.*) обязана быть свежей. Вся история (game.ru) меняется в других тредах
  // постоянно: её JSON в репозитории — снимок для сборок, а CI пересобирает его перед тестами.
  const strict = stale.filter((id) => id.startsWith("slice."));
  if (stale.length) console.log(`Устарел JSON: ${stale.join(", ")}. Запустите: node ink_tool.mjs build && node ink_tool.mjs reference`);
  process.exit(strict.length || bad ? 1 : 0);
} else if (cmd === "transcript") {
  const [file, cls, hf, sf, seed] = args;
  const json = fs.readFileSync(file, "utf8");
  const t = transcript(json, { cls, hero_f: hf === "true", spouse_f: sf === "true" }, Number(seed), globalNames(json));
  console.log(t.text);
} else {
  console.log("Команды: build | reference | parity | check | transcript <json> <class> <hero_f> <spouse_f> <seed>");
  process.exit(2);
}
