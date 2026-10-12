// English parallel of story/ink/common.ink. Logic must stay identical to the Russian
// source: same VARs, functions and their arguments; only the text is translated.
// Parity is checked by prototypes/stack-slice/tools/ink_tool.mjs (command "parity").

VAR hero_f = false          // the hero is a woman
VAR spouse_f = true         // the spouse is a woman (wife)
VAR hero_class = "fighter"  // fighter / rogue / cleric / wizard
VAR darkness = 0            // hidden Darkness scale 0–100

// Line tags are the same as in Russian and must never be translated:
//   # spk:spouse, # spk:hero, # mood:<emotion>, # flag:<name>, # battle:<id>

// Word form by the hero's gender: h("he", "she").
=== function h(m, f)
{ hero_f:
    ~ return f
- else:
    ~ return m
}

// Word form by the spouse's gender: s("his", "her").
=== function s(m, f)
{ spouse_f:
    ~ return f
- else:
    ~ return m
}

VAR spouse_name = "Eila"   // the player types the name; this is the default

// The spouse's name, as typed by the player.
=== function sp()
~ return spouse_name

// Change Darkness, clamped to 0–100.
=== function add_darkness(n)
~ darkness = darkness + n
{ darkness > 100:
    ~ darkness = 100
}
{ darkness < 0:
    ~ darkness = 0
}
