#!/usr/bin/env node
// Сборка истории для проекта игры. Нужен Node 18+ и inkjs 2.3.2 (npm install в этой папке).
//
//   node ink_tool.mjs build   — story/ink/game.ink и story/ink-en/game.ink → game/story/game.{ru,en}.json
//                              и порядок сцен по главам → game/story/scenes.json (для автосохранений)
//   node ink_tool.mjs check   — JSON в репозитории совпадает с текущими .ink (код 1, если устарел)
//
// JSON лежит в репозитории, чтобы игру можно было открыть без Node. Сюжет правят другие треды,
// поэтому CI пересобирает JSON перед тестами и сборками, а check только предупреждает.
// Проверки рантаймов и совпадения языков — в prototypes/stack-slice/tools/ink_tool.mjs.

import { createRequire } from "node:module";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const { Compiler, CompilerOptions } = require("inkjs/full");

const HERE = path.dirname(fileURLToPath(import.meta.url));
const GAME = path.resolve(HERE, "..");
const REPO = path.resolve(GAME, "..");

// Язык → точка входа истории. В английской переведён пролог, главы 1–5 подключены из story/ink.
const TARGETS = [
  { id: "game.ru", src: path.join(REPO, "story/ink/game.ink") },
  { id: "game.en", src: path.join(REPO, "story/ink-en/game.ink") },
].filter((t) => fs.existsSync(t.src));

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
  const story = new Compiler(fs.readFileSync(src, "utf8"), opts).Compile();
  const real = errors.filter((e) => !/WARNING/.test(e));
  if (!story || real.length) throw new Error(`${src}:\n${errors.join("\n")}`);
  return story.ToJson();
}

// Порядок сцен: узлы глав в game.ink вызывают сцены-туннели строкой «-> a -> b -> c ->».
function scenes() {
  const text = fs.readFileSync(path.join(REPO, "story/ink/game.ink"), "utf8");
  const out = [];
  let chapter = null;
  for (const line of text.split("\n")) {
    const knot = line.match(/^===\s*(\w+)\s*===/);
    if (knot) {
      chapter = knot[1];
      continue;
    }
    if (!chapter || !line.trim().startsWith("->")) continue;
    for (const name of line.split("->").map((x) => x.trim()).filter(Boolean)) {
      if (name !== "END") out.push({ chapter, scene: name });
    }
  }
  return `{"scenes": [\n${out.map((o) => "  " + JSON.stringify(o)).join(",\n")}\n]}\n`;
}

function build({ write = true } = {}) {
  const stale = [];
  const manifest = scenes();
  const mdest = path.join(GAME, "story", "scenes.json");
  const mold = fs.existsSync(mdest) ? fs.readFileSync(mdest, "utf8") : null;
  if (mold !== manifest) stale.push("scenes");
  if (write) fs.writeFileSync(mdest, manifest);
  for (const t of TARGETS) {
    const json = compile(t.src);
    const dest = path.join(GAME, "story", `${t.id}.json`);
    const old = fs.existsSync(dest) ? fs.readFileSync(dest, "utf8") : null;
    if (old !== json) stale.push(t.id);
    if (write) fs.writeFileSync(dest, json);
    console.log(`${t.id}: ${(json.length / 1024).toFixed(0)} КБ${old !== json ? (write ? " (обновлён)" : " (устарел)") : ""}`);
  }
  return stale;
}

const [cmd] = process.argv.slice(2);
if (cmd === "build") build();
else if (cmd === "check") {
  const stale = build({ write: false });
  if (stale.length) console.log(`Устарел JSON: ${stale.join(", ")}. Запустите: node ink_tool.mjs build`);
  process.exit(stale.length ? 1 : 0);
} else {
  console.log("Команды: build | check");
  process.exit(2);
}
