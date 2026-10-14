// Chapter 4. Exploration: three side spots and the hunt for the "Chain of the Nameless".
// English parallel of story/ink/chapter4/explore.ink.
// The game calls the inspection knots (see explore_common.ink). Where each object sits is in the comment above its knot.
//
// The hunt: three clues, any two are needed. Gessar's note lies only in the armoury (side spot 2).
// The prisoner's clue exists only if the vats were broken by hand (ch4_vats == "hands"): she is one of the seven saved.
// The site is the old cupola behind the flesh master's hall, a separate small map. Available after battle 2 (scene 3),
// until the party climbs to the hall of executions (scene 4), that is, before the battle in the foundry.

VAR ch4_clue_names = false     // the names on the walls of the works
VAR ch4_clue_iron = false      // Gessar's note about the missing iron
VAR ch4_clue_prisoners = false // the story of the prisoner saved at the vats
VAR ch4_hunt_clues = 0
VAR ch4_chain = ""             // "taken" — took the chain, "left" — left it to the prisoners
VAR ch4_hunt_done = false      // the hunt site has been examined, the decision about the chain is made
VAR ch4_nook_smith_done = false
VAR ch4_nook_armory_done = false
VAR ch4_nook_safe_done = false

// Clue 1. Scene 1 map ("The works") after the battle: the wall by the gates where the prisoners waited their turn for the vats.
=== ch4_look_names ===
{ ch4_clue_names:
    The wall of names. Hundreds of names.
    -> DONE
}
~ ch4_clue_names = true
~ ch4_hunt_clues++
By the gates, where the prisoners had stood in line for the vats, the wall was scratched from top to bottom. Names. Hundreds of names, scratched with fingernails, nails, broken pieces of chain. Some deep, others barely there.
Under many of the names was the same small mark: a single link of chain.
{ ch3_camp_people == "many":
    "A link," said Irena. "The fugitives in the camp had the same one. Scratched on their mugs. I thought it was just a convicts' sign." # spk:irena
- else:
    "A link," said Irena. "It's not just a signature. They were telling each other something with it." # spk:irena
}
{ column_choice == "trail":
    You looked for names you knew. You found one: "Hasker". No first name, only the family name. Under it, a link.
}
A note in the journal: "A chain link under the names on the wall of the works." # journal:ch4_hunt_names
-> ch4_hunt_progress

// Clue 2. Scene 2 map ("The reports"), the armoury behind the office (side spot 2): the storekeeper's book on a shelf.
// Only after the party has entered the armoury.
=== ch4_look_iron_note ===
{ not ch4_nook_armory_done:
    -> DONE
}
{ ch4_clue_iron:
    The storekeeper's book. A note on the missing shackle iron.
    -> DONE
}
~ ch4_clue_iron = true
~ ch4_hunt_clues++
On a shelf in the armoury, among the inventories of straps and buckles, lay the storekeeper's book. Nails, wire, shackles. Figures, figures.
Between the pages was a note in another hand, sprawling and angry:
"Shackle iron short again. One link from every one that goes into a vat. Not a chain, a sieve. Find who is taking them, and into the vat with him. Not yet reported upstairs. G."
"Gessar," said Garret. "The flesh master. He was afraid the King would find out about the shortfall." # spk:garret
"Links," you said. "One from each of them." # spk:hero
{ ch4_clue_names:
    The mark under the names on the wall. A link.
}
A note in the journal: "One link from each. Gessar never found who was taking them." # journal:ch4_hunt_iron
-> ch4_hunt_progress

// Clue 3. Scene 1 map ("The works") after the vats, only when ch4_vats == "hands":
// a grey-haired prisoner, one of the seven saved, sits by a cooled vat.
=== ch4_talk_prisoners ===
{ ch4_vats != "hands":
    -> DONE
}
{ ch4_clue_prisoners:
    The old woman nods to you and glances deeper into the works, towards the master's hall.
    -> DONE
}
~ ch4_clue_prisoners = true
~ ch4_hunt_clues++
One of the saved, grey-haired, her hands covered in burns, sat by a cooled vat. She looked at your palms, torn on the valves, and beckoned you over.
"You're looking for the chain?" she asked, as simply as if she were asking the way. # spk:prisoner
"What chain?" # spk:hero
"Ours. We forged it. At night, in the old cupola behind the master's hall, while the overseers slept. From everyone they led off to the vats, we took a link and forged it in. So that something of a person would be left that wasn't in the ranks." She pointed deeper into the works. "The cupola's cold, nobody goes there. The slab by the hearth." # spk:prisoner
"Why are you telling me?" # spk:hero
"Because you pulled with your hands. You could have done it another way. I heard him whispering to you." She looked straight at you. "So you're allowed." # spk:prisoner
A note in the journal: "The old cupola behind the master's hall. The slab by the hearth." # journal:ch4_hunt_prisoners
-> ch4_hunt_progress

=== ch4_hunt_progress ===
{ ch4_hunt_clues == 2:
    Now it is clear where to look: where the prisoners forged at night, in the old cupola behind the master's hall. Once the party climbs to the hall of executions, there is no coming back. # journal:ch4_hunt_ready
}
-> DONE

// The hunt site. The old cupola: a small map behind the flesh master's hall (scene 3), open after battle 2,
// until the party climbs to the hall of executions (scene 4). With fewer than two clues it is just a cold furnace.
=== ch4_hunt_site ===
{
- ch4_chain != "":
    The slab by the cupola's hearth lies in its place.
    -> DONE
- ch4_hunt_clues < 2:
    The old cupola: a low vault, a cold hearth, floor slabs crusted with scale. Nothing has been melted here for a long time.
    -> DONE
}
The cupola was cold, but the scale on the floor by the hearth was fresh, no older than a month. The slab by the hearth came up easily: it had been lifted many times.
Beneath it, in a niche hollowed out of the stone, lay a chain. Long, heavy, crude. The links were all different: some of shackle iron, dark, others lighter, others quite thin, a child's. On every link something was scratched. A letter. A sign. Sometimes a whole name.
Irena knelt and took one end in her palms.
"How many are there?" # spk:irena
You began to count and gave up in the second hundred.
{ ring_taken:
    The ring on your hand turned cold. It took you a moment to understand that it was drawing away from the chain. As if from fire.
}
* [Take the chain. Let it go with you to the end.]
    -> ch4_hunt_take
* [Leave it here. It is their memory, not yours.]
    -> ch4_hunt_leave

= ch4_hunt_take
~ ch4_chain = "taken"
~ ch4_hunt_done = true
You lifted the chain. It was lighter than it looked. Garret helped you straighten it out: it lay across your jacket crosswise, over the shoulder and around the waist, like a poor man's mail. The links were cold at first, then grew warm.
{ ch4_clue_prisoners:
    You remembered the grey-haired prisoner by the vat. "So you're allowed."
}
"He counts them by heads," said Garret. "Here, each one has a name." He paused. "Wear it. Let him see." # spk:garret # item:nameless_chain
-> DONE

= ch4_hunt_leave
~ ch4_chain = "left"
~ ch4_hunt_done = true
You laid the chain back and lowered the slab.
{ irena_confronted != "left":
    Irena looked at you for a long time. Then she said:
    "You know, this is the first thing we've left behind here not because we couldn't take it." # spk:irena # mood:sad
    She read a prayer over the slab. The one for the living.
}
-> DONE

// Side spot 1. Scene 1 map ("The works"): the smithy at the end of the row of vats, where weapons were forged for the dead.
=== ch4_nook_smith ===
{ ch4_nook_smith_done:
    The smithy. A cold hearth, an empty anvil.
    -> DONE
}
~ ch4_nook_smith_done = true
At the end of the row of vats was a smithy: a hearth, an anvil, racks of identical blades for identical dead men. By the anvil, chained by the leg, lay a smith. For a long time now.
{ column_choice == "neighbors":
    A stranger. For some reason you let out a breath when you realised it. Then you were ashamed of having let it out.
    In a box under the anvil lay his stash: coins he had no use for here, and which he had saved all the same. # silver:20
- else:
    You knew him by his hands. The smith from Ashmoor. The one you took your sickle to for sharpening every autumn. He was led off with the column while you chased the cart.
    They had set him to forge what his neighbours would later be turned into. He forged. The chain on his leg left him no choice.
    But on the wall above the hearth hung no service blade. A cleaver, broad, with a bone handle, with the mark of Ashmoor: an ear of wheat and a hammer. His own. He had forged it here, in secret, from the same iron. For himself. He never got the chance.
    You took the cleaver down from the wall. # item:eshmur_cleaver
    { irena_confronted != "left":
        Irena said nothing. She only put a hand on your shoulder and kept it there until you stepped away from the anvil.
    }
}
-> DONE

// Side spot 2. Scene 2 map ("The reports"): the garrison armoury behind the office. Clue 2 (the storekeeper's book) is here too.
=== ch4_nook_armory ===
{ ch4_nook_armory_done:
    The armoury. Empty racks.
    -> DONE
}
~ ch4_nook_armory_done = true
Behind the office was the garrison armoury. Nearly everything had been taken when the alarm was raised. What remained were racks, straps, and one suit of armour on a dummy in the corner: a founder's heavy plate, coated with grey scale, with pauldrons that iron had once poured over without burning through.
"Founders wear these so they don't burn at the ladle," said Garret, knocking on the breastplate. "Good iron. Better than the guards have. Strange. Someone in these forges did think about the living after all." # spk:garret
You took the plate off the dummy. # item:foundry_plate
Behind the dummy, in a box of straps, lay a bar of dark steel with a dwarven mark. On the tag, in the storekeeper's hand: "Trophy. Do not melt. Master's orders." Even here, it seems, this steel was kept safe.
You took the bar. # item:dwarf_steel
-> DONE

// Side spot 3. Scene 2 map ("The reports"): the clerk's safe under the window. Only with a rogue in the party or the foreman's lantern.
=== ch4_nook_safe ===
{ ch4_nook_safe_done:
    The clerk's safe, open and empty.
    -> DONE
}
{ not has_rogue() && not has_lantern():
    Under the office window stands the clerk's iron safe. A lock of dwarven make; without a key it will not open, and there is no key.
    -> DONE
}
~ ch4_nook_safe_done = true
{
- hero_class == "rogue":
    The lock on the safe was dwarven, fine, with five tumblers. You dealt with it in the time it took Irena to read one report.
- not has_rogue():
    The lock on the safe was dwarven, with five tumblers. In the light of the foreman's lantern, scratches showed on the windowsill above it: five strokes of different lengths. The clerk had not trusted his memory. You turned the tumblers by the scratches, and the lock clicked.
- else:
    "A dwarven lock," said Velior tenderly. "Five tumblers. I opened one like it once, in the capital, at the treasurer's. He was surprised for a long time afterwards." # spk:velior # mood:smile
    He dealt with it in the time it took Irena to read one report.
}
Inside was silver, the garrison's pay for a month, and a scroll in a case with the seal of the works: "Thunderwave. For the suppression of revolt in the works."
"For the suppression of revolt," Irena repeated. "So there were revolts." # spk:irena
You took everything. # silver:30 # item:scroll_thunderwave
-> DONE
