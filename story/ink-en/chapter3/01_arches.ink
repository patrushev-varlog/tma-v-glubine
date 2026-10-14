// Chapter 3, scene 1. "The arches". English parallel of story/ink/chapter3/01_arches.ink.
// About 12 minutes including the chapter's first battle. Construct guardians and an optional riddle door.

VAR ch3_riddle_solved = false
VAR ch3_riddle_tried = false   // an answer has been given (right or wrong); the door gives no second try

=== arches ===
The stairs ended in a hall that could have held all of Ashmoor, fields and all. Arches rose into the darkness, beyond the reach of the lantern. Each was carved from a single piece of rock, and on each ran rows of angular runes.
It was dry here. And very quiet: footsteps raised no echo, but seemed to sink into the stone.
{ hero_class == "wizard":
    You stopped at the first arch. The runes were the same as on the sluice, but here there were many of them, and they made words.
    "'Here we keep silent, so that he sleeps,'" you read aloud. # spk:hero
    Velior looked at you in surprise.
    "I could make out three signs in ten. And you read it like a page." # spk:velior
- else:
    "What does it say?" you asked. # spk:hero
    Velior ran his fingers over the runes, his lips moving.
    "I know a few of the signs. 'Keep silent.' 'Sleep.' And this one, 'he', but with a sort of tail, as if 'he' isn't a man." He took his hand away. "Something like: 'Here we keep silent, so that he sleeps.'" # spk:velior
}
"Who is he?" asked Irena. # spk:irena
No one had time to answer. In the niches between the arches something shifted. Stone figures the height of a man, with mouthless faces, slowly turned their heads towards the sound of her voice.
"Keep silent," said Garret, very quietly. "That's what they wrote up there. 'Keep silent.'" # spk:garret
But it was too late. The first figure stepped out of its niche, and the floor shook.
// Chapter battle 1: construct guardians. Teaches fighting armoured enemies: blunt weapons, spells, getting behind them.
The stone came for you. # battle:chapter3_1
-> after_fight

= after_fight
The last guardian crumbled, and the hall was quiet again. Now you all spoke in whispers, without anyone deciding to.
Beyond the arch there was a door. Stone, with no handle and no keyhole. In the middle, a ring of runes, and below it a single line, larger than the rest.
{ hero_class == "wizard":
    "It's a riddle," you said. "'What is kept without being touched, and lost once it is named?'" # spk:hero
- else:
    Velior took a long time over the line.
    "Looks like a riddle. 'What is kept without being touched... and lost once it is named.' The dwarves were fond of those. They say there's only one answer, and they don't give a second try." # spk:velior
}
* [Answer: "A promise."]
    -> wrong("A promise")
* [Answer: "Silence."]
    -> right
* [Answer: "Breath."]
    -> wrong("Breath")
* [Leave the door alone. For now.]
    You stepped back from the door. The dwarves have one answer, and they give no second try. Better first to understand what they are asking.
    A note in the journal: "A riddle door in the hall of arches." # journal:ch3_riddle_door
    -> leave

// On the arches map after the battle: the riddle door (if unanswered, it can be revisited, ch3_riddle_door).
= leave
+ [Go on through the hall, towards the warm light. #obj:hall_on]
-
->->

= right
"Silence," you said. # spk:hero
One by one, the runes in the ring slowly went out. The door sank into the floor without a sound.
~ ch3_riddle_solved = true
~ ch3_riddle_tried = true
Behind it was a tiny room. On a stone stand lay what the dwarves had seen fit to hide from all who do not know how to keep silent. # item:silent_crown
"Good thing it was you who answered, and not me," said Velior. "I'd have said 'money'." # spk:velior # mood:smile
-> leave

= wrong(answer)
~ ch3_riddle_tried = true
"{answer}," you said. # spk:hero
The runes flared red and went out. Something clicked heavily deep in the stone, and the door seemed to sink further into the wall.
"They don't give a second try," Velior repeated. "I told you." # spk:velior
-> leave
