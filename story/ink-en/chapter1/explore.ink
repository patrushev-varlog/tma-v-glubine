// Chapter 1. Exploration: three side spots and the hunt for "Lantern of the First Foreman".
// English parallel of story/ink/chapter1/explore.ink.
// The game calls the inspection knots (see explore_common.ink). Where each object sits is in the comment above its knot.
//
// The hunt: three clues, any two needed. The old prisoner's clue exists only after the riot,
// so with the quiet passage both others are needed. The rockfall by the shaft can only be cleared once
// the roof is propped with timber from the storeroom (side spot 2): without it the hunt site does not open.

VAR ch1_clue_marks = false     // miners' notches at the old face
VAR ch1_clue_prisoner = false  // the old prisoner's tale (riot only)
VAR ch1_clue_map = false       // the mark on Holt's map
VAR ch1_hunt_clues = 0
VAR ch1_hunt_done = false      // lantern found
VAR ch1_hunt_site_seen = false // the intro at the boarded-up tunnel has been shown
VAR ch1_nook_face_done = false
VAR ch1_nook_timber_done = false // Garret also takes timber for the rockfall by the shaft
VAR ch1_nook_hut_done = false

// Side spot 1. Scene 1 map ("The gate"): a side face before Holt's post.
=== ch1_nook_face ===
{ ch1_nook_face_done:
    The old face. A miner's bones under the fallen props, a pick against the wall. Nothing else here.
    -> DONE
}
~ ch1_nook_face_done = true
A side face sloped down away from the main tunnel. The props here were old and blackened, and half the posts had long since fallen to the floor.
At the very end, under a sagging beam, sat a skeleton. Back to the wall, legs stretched out, a pick across its knees. As if it had sat down for a rest and forgotten to get up.
Round its neck, on a blackened cord, hung a charm: a copper plate stamped with a hammer. Miners wore them for luck.
"Didn't help," said Garret. "Never does. But they all wear them." # spk:garret
You took the charm. The cord crumbled in your fingers. # item:miner_charm
-> ch1_clue_marks_text

// Clue 1 is visible in the same face: notches on the wall above the skeleton.
= ch1_clue_marks_text
Above the skeleton's head someone had cut a row of notches into the wall. Not cracks: even, deep, three in a row, and under them an arrow pointing down.
~ ch1_clue_marks = true
~ ch1_hunt_clues++
Garret held the lantern closer.
"Miners' marks. Old ones, nobody writes like this now." He ran a finger along the arrow. "Three notches mean 'the foreman was here'. The arrow means 'went down, towards the shaft'. They marked where the head man went, so they'd know where to look if he didn't come back." # spk:garret
"The foreman?" # spk:hero
"Head man over the faces. There was one here, back under the old king, before the dead. There's a tale about him: he had a lantern that showed the dead before they rose. He went under in a rockfall, lantern and all." Garret snorted. "Every mine has a tale like that." # spk:garret
{ hero_class == "wizard":
    There was something in the notches. Not magic, but the trace of it, like the smell of smoke in an empty room. Whoever cut them had been holding something warm.
}
"Lantern of the First Foreman" appeared in your journal. # journal:ch1_hunt_marks
-> ch1_hunt_progress

// Side spot 2. Scene 2 map ("The cage"): the timber store behind the overseers' bunks.
=== ch1_nook_timber ===
{ ch1_nook_timber_done:
    The timber store. Logs, wedges, an empty box.
    -> DONE
}
~ ch1_nook_timber_done = true
Behind the overseers' bunks there was a low door to a storeroom. Logs for pit props, stacked crosswise, wedges, a coil of rope. It smelled of resin: the only living smell on the whole level.
On the top shelf, behind the wedges, stood a box. Someone had been hiding things in it that they did not want to hand over to the common pot.
Inside lay a purse and a vial of brown potion, carefully wrapped in a rag.
{ velior_terms != "":
    "Overseers steal from each other too," said Velior with pleasure. "Nice to know some things in this world never change." # spk:velior # mood:smile
- else:
    "A stash," said Garret. "Everyone had one. So did I." He paused. "Had." # spk:garret
}
You took both. # silver:15 # item:potion_heal
Meanwhile Garret picked two sturdy posts and some wedges out of the stack and heaved them onto his shoulder.
"These'll come in handy," he said. "In these tunnels the roof stays up on a promise. And nobody down here keeps a promise." # spk:garret
{ ch1_hunt_clues > 0:
    Journal entry: "Timber from the storeroom. Without it the rockfall can't be cleared." # journal:ch1_hunt_timber
}
-> DONE

// Side spot 3. Scene 4 map ("The barracks"): the ganger's hut at the end of the gallery.
=== ch1_nook_hut ===
{ ch1_nook_hut_done:
    The ganger's hut. A table, a bench, empty shelves.
    -> DONE
}
~ ch1_nook_hut_done = true
At the end of the barracks gallery stood the ganger's hut: a plank booth with a little window onto the bars. From here you could see every prisoner at once.
An open book lay on the table: columns of names, a number beside each. Output per shift. Some of the numbers had a small cross next to them. It took you a moment to understand that the cross meant "works no more".
Under the table was a tin box of silver. A month's pay that no one had ever collected. # silver:20
{ has_rogue():
    -> ch1_nook_hut_rogue
}
-> DONE

= ch1_nook_hut_rogue
{ hero_class == "rogue":
    You rapped your knuckles on the wall behind the bench. It did not sound like the rest.
- else:
    Velior rapped his knuckles on the wall behind the bench and listened.
    "Hollow," he said. "I mean, there's nothing there. There ought to be solid rock." # spk:velior
}
Behind the board was a hiding place. Two vials of the oil the overseers rubbed on their blades before going down to the lower levels, and a scroll in oiled leather.
"Oil against the dead," said Irena, sniffing the stopper. "Blessed. Badly, in a hurry, but blessed. So they were afraid too." # spk:irena
You took the cache. # item:oil_undead # item:scroll_shield_of_faith
-> DONE

// Clue 2. Scene 4 map after the riot: an old prisoner does not leave for the surface, he sits by the bars.
// The game shows this prisoner only when ch1_choice == "riot".
=== ch1_talk_old_prisoner ===
{ ch1_choice != "riot":
    -> DONE
}
{ ch1_clue_prisoner:
    The old man nods to you and looks into the dark again.
    -> DONE
}
~ ch1_clue_prisoner = true
~ ch1_hunt_clues++
An old man sat by the open bars, in no hurry to leave. The others were running for the tunnel, and he sat.
"You go on, go on," he said when you stopped beside him. "I've been here twenty years. Nobody's waiting for me up top now, and down here at least I know the way." # spk:prisoner
"Twenty years?" # spk:hero
"Hard labour, sentenced back under the old king. There was a foreman here then, Alaric. Strict, he was, but he counted people by name, not by head." The old man worked his lips. "When the roof came down under the lift, he went in after two of them, a father and son. Nobody came out. They said his lantern shone from under the rockfall for a week after. Then it went out." # spk:prisoner # mood:sad
"Where was this?" # spk:hero
"Right by the shaft. Below the platform, in the old tunnel. They boarded it up so nobody would go poking in." He looked at you more closely. "Only don't you go in. Nobody under a rockfall lies easy. Not these days, that's for sure." # spk:prisoner # mood:tense
Journal entry: "The old tunnel by the shaft, under the lift platform." # journal:ch1_hunt_prisoner
-> ch1_hunt_progress

// Clue 3. Scene 1 map after the fight: a map of the level on the wall of Holt's guardroom.
=== ch1_look_holt_map ===
{ ch1_clue_map:
    A map of the level. A red mark by the shaft.
    -> DONE
}
~ ch1_clue_map = true
~ ch1_hunt_clues++
On the guardroom wall hung a map of the level, drawn in charcoal on an oxhide. Tunnels, barracks, the lift shaft.
By the shaft, a little to one side, was a fat red cross and the words: "Do not open. By order."
"Holt drew that cross himself," said Garret. "One of the new lads went in there after copper and never came back. Holt said 'someone walks' in there. We laughed." # spk:garret
Journal entry: "A red cross by the shaft on Holt's map." # journal:ch1_hunt_map
-> ch1_hunt_progress

// Two clues out of three: the player knows where to go.
=== ch1_hunt_progress ===
{ ch1_hunt_clues == 2:
    Now it is clear where to look: the old boarded-up tunnel by the lift shaft. The roof there is unsafe after the rockfall; it will need propping. # journal:ch1_hunt_ready
}
-> DONE

// The hunt site. Scene 6 map ("The lift") after the fight at the cage, before the lever is pulled:
// a boarded-up tunnel beside the platform. Behind the boards is a separate small tunnel map, not the cage battle map.
// Before two clues these are just old boards. Without timber from the storeroom (ch1_nook_timber) the roof can't be propped.
=== ch1_hunt_site ===
{
- ch1_hunt_done:
    An empty tunnel. Stone, broken boards, and nothing more.
    -> DONE
- ch1_hunt_clues < 2:
    Beside the platform, a passage boarded up with old planks. Nothing is written on the boards. Cold seeps from the cracks, as from any crack in these mines.
    -> DONE
- not ch1_nook_timber_done:
    Garret pried off one board and shone the lantern inside. Behind it the rockfall began, and over the rockfall the roof, split lengthwise like an old bowl.
    "I'm not going in," he said. "And I won't let you. Touch one stone at the bottom and the whole lot comes down on top. This needs timber, a couple of posts at least." # spk:garret
    There was no timber on the platform. It had all been carried off to the store behind the overseers' bunks, back where you had left long ago.
    -> DONE
}
{ ch1_hunt_site_seen:
    Pried-off boards, and behind them the cleared rockfall and stones stacked along the walls. Deep in the tunnel the yellow light still burns.
- else:
    ~ ch1_hunt_site_seen = true
    The boards across the tunnel had been nailed from the inside. Not the outside: the inside.
    Garret looked at this and said nothing. He only shifted his grip on his cleaver.
    Behind the boards the rockfall began. Not a solid one: someone had been clearing it, stone by stone, for a long time, patiently, and had stacked what they cleared along the walls in neat piles, sorted by size. The roof above it was split lengthwise.
    Without a word Garret took the posts from the storeroom off his shoulder and set them under the crack, driving the wedges home with a hammer, two blows each. The roof creaked and fell silent.
    Deep inside, a light was burning. Faint, yellow, steady. A lantern.
}
+ [Go towards the light.]
    -> ch1_hunt_meet
+ [Not now. Go back to the cage.]
    You stepped back. The light deep inside did not stir. It had waited like this for twenty years; it could wait a little longer.
    -> DONE

= ch1_hunt_meet
He stood at the end of the tunnel, facing the wall, clearing the rockfall. A dead man in a rotted foreman's jacket and a copper helmet. Stone after stone. He picked up a stone, turned, put it on a pile and went back for the next.
The lantern hung at his belt. The glass was whole, and the light inside burned without oil.
{ ch1_clue_prisoner:
    "Alaric," you said. # spk:hero
    The dead man stopped. The stone in his hands went still.
- else:
    You called out to him. The dead man stopped. The stone in his hands went still.
}
"He doesn't know he's dead," Irena said quietly. "He's still digging those two out." # spk:irena # mood:sad
{ hero_class == "wizard":
    It was not the King who had raised him. You understood that at once: there were no threads. The lantern itself held him. A light that would not go out, and a man who would not leave until he had finished.
}
The dead man turned slowly. Under the helmet there was no face, only darkness, and in it two small lights, yellow as the lantern's.
He raised his pick.
// Optional battle: the chapter 1 hunt guardian. Not part of the 19 main battles or the level budget.
He was guarding the rockfall. He did not know there was no one left to guard. # battle:ch1_hunt_foreman
-> ch1_hunt_after

= ch1_hunt_after
~ ch1_hunt_done = true
The foreman sank to his knees by the rockfall. He did not fall: he knelt, the way a man kneels to catch his breath. Then the light in his eyes went out, and there were only bones in a copper helmet.
The lantern was still burning.
You took it from his belt. The copper was warm, as if a living hand had just let go of it.
Behind the last stone of the rockfall, the one the foreman never moved, lay two sets of bones. One of them very small.
Irena said a prayer over them. A short one, the one said over those who have waited a long time.
"I thought it was a tale," said Garret. "Three winters I walked these tunnels. Thought it was a tale." # spk:garret
The lantern burned steadily. In its light the tunnel walls seemed closer and the shadows in the corners deeper, and in one of them, right down by the floor, you made out a crack that had not been visible before. # item:foreman_lantern
-> DONE
