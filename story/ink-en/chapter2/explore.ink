// Chapter 2. Exploration: three side spots and the hunt for "Spear of the Sunken Shrine".
// English parallel of story/ink/chapter2/explore.ink.
// The game calls the inspection knots (see explore_common.ink). Where each object sits is in the comment above its knot.
//
// The hunt: three clues, any two needed. The site is the flooded chapel by the sluice;
// the water is drained from it by the second, small lever of the gate. The drowned man's note lies only in the flooded
// storeroom (side spot 1). The guardian is not a required fight but a test: Father Meren asks whether
// the hero is living or dead, and the candle answers by Darkness. A fight only if you lie to him in the Gloom.

VAR ch2_clue_note = false      // the drowned man's note in the black water
VAR ch2_clue_tale = false      // the fugitives' tale
VAR ch2_clue_boatmen = false   // the boatmen's talk at the landing stage
VAR ch2_hunt_clues = 0
VAR ch2_shrine_drained = false // small lever pulled, chapel open
VAR ch2_hunt_done = false
VAR ch2_hunt_enter_seen = false // the entry into the chapel has been shown
VAR ch2_priest = ""             // "gift" — Meren gave the spear himself, "fought" — fight with the guardian
VAR ch2_nook_cellar_done = false
VAR ch2_nook_ledge_done = false
VAR ch2_nook_stash_done = false

// Side spot 1. Scene 1 map ("Black water"): the flooded storeroom by the stairs, entrance under water.
=== ch2_nook_cellar ===
{ ch2_nook_cellar_done:
    The flooded storeroom. Nothing under the water but empty shelves.
    -> DONE
}
By the wall, just under the water, an opening showed dark. The door of a storeroom, its top edge barely above the surface. Beyond it, judging by the echo, it was dry, or almost.
+ [Dive.]
    -> ch2_nook_cellar_dive
+ [Not now.]
    -> DONE

= ch2_nook_cellar_dive
~ ch2_nook_cellar_done = true
The water closed over your head, black as ink. Three blind strokes, your hand found the edge of the doorway, one more stroke, and you surfaced in the dark, in a pocket of air under the vault.
Once they had kept things here that they were afraid would get wet. The irony was not funny.
On a hook right under the vault, where the water had not reached, hung a bundle in oiled leather. Inside was a cloak: dark, heavy, hooded, soaked in something that made water run off it like off a duck's feather.
By the far wall, where the air ran out, a drowned man sat on a shelf. He had not risen with the others: he just stayed sitting, arms round his knees. Round his neck hung a waxed leather case, the kind couriers wear.
You put the cloak on right over your wet clothes. This time the water seemed warmer. # item:cloak_underwater
"A cloak of the underwater passage," said Velior, when he saw it. "Smugglers trade a boat for one of those. Where did you get it? No, don't tell me. I'll be hurt that I didn't find it myself." # spk:velior # mood:smile
-> DONE

// Clue 1. The flooded storeroom (side spot 1), only after the dive: the drowned man on the shelf by the far wall,
// with a wax case round his neck. This clue is nowhere else.
=== ch2_look_drowned_note ===
{ not ch2_nook_cellar_done:
    -> DONE
}
{ ch2_clue_note:
    The drowned man on the shelf. An empty case on a cord.
    -> DONE
}
~ ch2_clue_note = true
~ ch2_hunt_clues++
You took the case from the drowned man's neck. The wax had kept the water out.
Inside the case was a note, dry.
"If you find me: I went to the chapel by the sluice. The water there stands above the waist, but Father Meren used to say a candle still burns under the water. I want to see. If I don't come back, I saw."
There was no signature.
{ hero_class == "cleric":
    A chapel under water. You had heard of such places: the first settlers built them when the mines were still small, and people asked the water not to come. The water came anyway.
}
A note in the journal: "The chapel by the sluice. Father Meren." # journal:ch2_hunt_note
-> ch2_hunt_progress

// Side spot 2. Scene 2 map ("The fugitives"): the far end of the ledge, where the fugitives don't sit.
=== ch2_nook_ledge ===
{ ch2_nook_ledge_done:
    The end of the ledge. Old bedding, an empty quiver.
    -> DONE
}
~ ch2_nook_ledge_done = true
At the far end of the ledge, behind the rocks, someone had once made a sleeping place: a sackcloth mat, a burnt-out candle, an empty flask. Whoever lived here had left long ago and not come back.
Under the mat lay a bow. A good one, yew, with a leather wrap on the grip. On the limb a mark was burned: an ear of wheat and an arrow.
You knew the mark. Old Hugo from Ashmoor marked his bows like that, the one who lived by the mill and grumbled at everyone who bought their bows in town.
"Someone from home?" asked Garret. # spk:garret
"His bow. Not him, it seems." # spk:hero
Someone from Ashmoor had been here before you. Maybe he went off to work before the dead came. Maybe not. You took the bow. # item:eshmur_hunter_bow
-> DONE

// Clue 2. Scene 2 map: talk to the fugitives' leader (Mab or Tobin) after the main conversation.
=== ch2_talk_fugitive_tale ===
{ ch2_clue_tale:
    { ch2_fugitives_leader == "meb":Mab|Tobin} shrugs: {ch2_fugitives_leader == "meb":she|he} knows nothing more.
    -> DONE
}
~ ch2_clue_tale = true
~ ch2_hunt_clues++
{ ch2_fugitives_leader == "meb":
    "The chapel by the sluice?" Mab smirked. "That's a story for the new ones. That there's a priest down there under the water with his fishing spear, and whoever goes down to him, he blesses. Or runs through. Depends what sort you are." # spk:meb
    "A fishing spear?" # spk:hero
    "For fish. They say the first ones here didn't dig ore, they fished an underground lake. Blind white fish. The priest was their headman. With his spear he pinned the dead down in the water so they wouldn't rise." Mab paused. "An old woman told me that, in the barracks. She's dead now." # spk:meb
- else:
    "The chapel by the sluice?" Tobin rubbed his bandaged arm. "Heard of it. That there's a priest down there under the water with his fishing spear. They say the first ones here didn't dig ore, they fished an underground lake. The priest was their headman, and with his spear he pinned the dead down in the water so they wouldn't rise." # spk:tobin
    "You believe that?" # spk:hero
    "A week ago I didn't believe the dead walked." He shrugged. "Now I believe everything. It's simpler." # spk:tobin
}
A note in the journal: "A priest with a fishing spear. He pinned the dead down in the water." # journal:ch2_hunt_tale
-> ch2_hunt_progress

// Side spot 3. Scene 3 map ("The smugglers"): the store under the platform. Only with a rogue in the party or the foreman's lantern.
=== ch2_nook_stash ===
{ ch2_nook_stash_done:
    The store under the platform. Empty crates.
    -> DONE
}
{ not has_rogue() && not has_lantern():
    Under the platform stand crates with the smugglers' brand. All nailed shut, tightly and properly. Without tools and clever hands there's nothing to be done here.
    -> DONE
}
~ ch2_nook_stash_done = true
Under the platform, in the dark between the piers, stood crates. Most held goods nobody cared about: salt, nails, cloth.
{
- hero_class == "rogue":
    One crate was heavier than a crate of salt ought to be. You prised up a board with your knife.
- not has_rogue():
    You raised the foreman's lantern. In its yellow light the salt in the cracks of the crates glittered, but in one it did not: under the salt there was something else. Garret prised up the board with his cleaver.
- else:
    "This one," Velior whispered, tapping one of the crates. "Too heavy for salt. Renna always keeps a stash where nobody will look: among things nobody wants." # spk:velior
}
Under a layer of salt lay a purse and two flasks of greater potion, packed in straw.
{ ch2_choice == "hand_over":
    Irena looked at the purse, then at you.
    "You've already paid them," she said. "In people. You may as well take the silver too, it's all the same to them now." # spk:irena # mood:tense
}
You took the stash. # silver:25 # item:potion_greater
-> DONE

// Clue 3. Scene 3 map: the boatmen at the landing stage talk among themselves while the party is with Renna.
=== ch2_listen_boatmen ===
{ ch2_clue_boatmen:
    The boatmen are talking about the price of salt.
    -> DONE
}
~ ch2_clue_boatmen = true
~ ch2_hunt_clues++
At the landing stage two boatmen were unloading a flat-bottomed boat and bickering under their breath.
"...and I'm telling you, there are two levers at the sluice. A big one and a small one. The big one lifts the gate, the small one drains the chapel. Dwarves made it, not men." # spk:boatman
"So why didn't you pull it?" # spk:boatman
"One fellow did. The water went, he climbed in. Then the water came back, and he didn't. After that Renna had the small lever wrapped in chain so nobody'd play with it." # spk:boatman
"You're lying." # spk:boatman
"Go and look yourself. The chain's still hanging there." # spk:boatman
A note in the journal: "A small lever at the sluice, wrapped in chain." # journal:ch2_hunt_boatmen
-> ch2_hunt_progress

=== ch2_hunt_progress ===
{ ch2_hunt_clues == 2:
    Now it is clear where to look: the flooded chapel by the sluice. The small lever of the gate drains it. # journal:ch2_hunt_ready
}
-> DONE

// The hunt site. Scene 6 map ("The sluice") after the fight with the warden: the small lever by the gate, wrapped in chain,
// and a grate in the wall with water behind it. Before two clues it is just a rusty lever.
=== ch2_hunt_site ===
{
- ch2_hunt_done:
    The chapel by the sluice. A dry stone floor, an empty altar.
    -> DONE
- ch2_shrine_drained:
    -> ch2_hunt_enter
- ch2_hunt_clues < 2:
    Next to the big gate lever there is a second, smaller one, wrapped in rusty chain. What it is for is unclear. Behind a grate in the wall stands black water.
    -> DONE
}
The small lever was where they said: right by the gate, wrapped three times in chain. The chain had rusted so that the links had grown together.
{ hero_class == "wizard":
    Above the lever a rune was cut, just one. Not "hold", as above the gate. Another one. It took you a moment to make it out: "Release".
}
Garret cut through the chain with his cleaver on the third blow. Irena and Velior threw their weight on the lever together.
Behind the grate something gurgled and hummed, and the water went down: slowly, squelching, baring steps.
~ ch2_shrine_drained = true
The steps led into a small hall with a low vault. # map:ch2_shrine_drained
-> ch2_hunt_enter

= ch2_hunt_enter
{ ch2_hunt_enter_seen:
    The chapel by the sluice. The candle on the altar still burns, the man in vestments still stands with his back to you, the spear in his hands.
- else:
    ~ ch2_hunt_enter_seen = true
    The chapel was tiny: six benches, an altar of rough stone, bands of silt on the walls right up to the vault. On the altar stood a candle.
    The candle was burning.
    By the altar, with his back to you, stood a man in vestments heavy with water. In his hands he held a three-pronged fishing spear, long, taller than himself. He did not move.
    { evening_asked_songs:
        From somewhere under the floor, from the water that had not quite gone, came a barely audible: "The water remembers, the water never sleeps..." {sp()}'s song. Grandmother's song. Here.
        You did not know what it meant. Maybe nothing. Maybe in these mines all the songs about water are the same.
    }
}
+ [Go closer.]
    -> ch2_hunt_meet
+ [Leave before the water comes back.]
    You stepped back to the stairs. The candle on the altar did not waver. Neither did the man by the altar.
    -> DONE

= ch2_hunt_meet
Water squelched underfoot. The man by the altar turned round.
It was Father Meren. You understood that at once, though you had never seen him: this is how someone looks who served thirty years in one chapel and did not leave it even when the water came.
Almost nothing was left of his face. The eyes were left, white as the fish of the underground lake.
He took the candle from the altar and held it out towards you. The spear he held in his other hand, prongs down.
"Who... has come..." he said. His voice was like gurgling in a pipe. "Living or... dead..." # spk:shrine_priest
{ hero_class == "cleric":
    You knew this rite. In the old parishes that was how they met those who came back from the mine after a cave-in: the candle does not go out only for the living.
}
+ ["Living."]
    "Living, Father," you said. # spk:hero
    -> ch2_hunt_alive
+ ["I don't know."]
    "I don't know, Father," you said. And you were surprised yourself that it was true. # spk:hero
    -> ch2_hunt_unsure

= ch2_hunt_alive
{ darkness >= 50:
    The candle flame bent away from you as if in a draught, and shrank to a blue point.
    The dead man looked at it for a long time. Then he raised the spear.
    "They all... say so..." He moved towards you. Slowly, the way one walks along the bottom. "The dead... into the water... I... pin them..." # spk:shrine_priest
    -> ch2_hunt_fight
}
The flame leaned towards you and straightened. Even, yellow, warm.
The dead man looked at it for a long time, as if remembering what it meant.
"Living," he said at last. # spk:shrine_priest
-> ch2_hunt_gift

= ch2_hunt_unsure
{ darkness >= 25:
    The candle flame trembled. It bent away from you, came back, bent away again. But it did not go out.
    "Honest..." said the dead man. "The dead... don't doubt... And you... still..." # spk:shrine_priest
- else:
    The flame leaned towards you and straightened.
    "The living... always... doubt," said the dead man, and in the gurgling there was something like a laugh. # spk:shrine_priest
}
-> ch2_hunt_gift

= ch2_hunt_gift
~ ch2_hunt_done = true
~ ch2_priest = "gift"
He set the candle on the altar and held out the spear to you. Shaft first, the way a post is handed over.
"Pin them... into the water," he said. "So they don't rise." # spk:shrine_priest
{ darkness >= 25:
    "And yourself... test yourself... Every night..." # spk:shrine_priest
}
Then Father Meren lay down on the floor by the altar, the way one lies down to sleep, and moved no more. The candle burned a little longer and went out by itself.
Irena knelt beside him and closed his eyes. What was left of them.
"For thirty years he guarded them from the dead," she said. "And then he became one of the dead and guarded them still. Only he asked first." # spk:irena # mood:sad
You took the spear. The shaft was wet and cold, and the prongs dry and warm, as if just taken out of a fire. # item:sunken_shrine_spear
Somewhere behind the wall the water hummed. It was time to go.
-> DONE

= ch2_hunt_fight
// Optional fight: the chapter 2 hunt guardian, only after lying in the Gloom. Not one of the 19 main battles, not in the level budget.
The candle on the altar flared. # battle:ch2_hunt_priest
~ ch2_hunt_done = true
~ ch2_priest = "fought"
Father Meren fell to his knees by the altar. The spear dropped from his hands and rang on the stone.
"Didn't... pin you..." he said, almost surprised. "So... still... living." # spk:shrine_priest
He lay down on the floor the way one lies down to sleep, and moved no more. The candle on the altar burned down and went out by itself.
Irena did not go to him. She was looking at you.
"He asked," she said. "He only asked." # spk:irena # mood:tense
{ velior_terms != "" && velior_fate != "exiled" && velior_fate != "killed":
    "Many don't notice the difference," said Velior. Quietly, without his usual smirk. # spk:velior
}
You picked up the spear. The shaft was wet and cold, and the prongs were cold too. # item:sunken_shrine_spear
Somewhere behind the wall the water hummed. It was time to go.
-> DONE
