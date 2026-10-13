// Prologue, scene 3. "The ashes". English parallel of story/ink/prologue/03_ashes.ink.
// About 5 minutes. Darkness does not change. Clues on the map are separate knots the game calls on inspection.

VAR buried_neighbors = false

=== ashes ===
The cold woke you. A grey dawn stood over Ashmoor, and the smoke rose straight up with no wind, as over a snuffed candle.
Half the houses were gone. Yours still stood. The door still hung by a single nail.
Someone coughed in the cellar by the well, and then a grey head came up out of it.
"Alive," said old Oldric, looking at you. "Well, somebody's alive." # spk:oldrik
He climbed out, holding on to the edge, and sat down right on the ground.
"They took my boy. Into the column, with everyone. I sat in the cellar. Heard it all and sat there." # spk:oldrik # mood:sad
* ["You couldn't have done anything, Oldric."]
    "You couldn't have done anything. There were too many of them." # spk:hero
    "I know," said Oldric. "That's the bad part, that I know." # spk:oldrik # mood:sad
* [Sit down beside him without a word.]
    You sat down beside him. For a while the two of you sat and watched the smoke.
-
In the Haskers' yard lay the ones they had not bothered to take. Five of them. The dead had gone off with the column, and these were left lying where they had been thrown.
"Ought to bury them," said Oldric, without getting up. "But I'll not manage it alone before dark." # spk:oldrik
* [Take the shovel. The dead have earned a grave.]
    ~ buried_neighbors = true
    -> burial
* ["There's no time. They're being taken away right now."]
    -> no_burial

= burial
You dug until noon. The earth was heavy with rain. Oldric worked slowly but did not stop, and he talked as if he could not do otherwise.
"That scribe, last week... He spoke to your {s("husband", "wife")} on {s("his", "her")} own. A long while. I saw them at the well." # spk:oldrik
{ evening_asked_scribe:
    You remembered last night. "He asked where my family comes from. That's true. Almost."
- else:
    It was the first you had heard of it: {sp()} had never told you.
}
"And then the scribe marked something down and watched {s("him", "her")} go for a long time. I thought: looking for kin, is he. Old fool that I am." # spk:oldrik # mood:sad
When the last mound of earth was raised, Oldric straightened up and looked at the road.
"Go. I'll finish here. If you see my boy... Tell him his father isn't sitting in the cellar any more." # spk:oldrik
-> clues

= no_burial
"They're being taken away right now. I can't help the dead any more." # spk:hero
Oldric nodded, but stopped looking at you.
"Right," he said to the ground. "Right, of course. Go." # spk:oldrik # mood:sad
{ not evening_asked_scribe:
    You were already at the fence when he called after you:
    "That scribe! He spoke to your {s("husband", "wife")} on {s("his", "her")} own, a long while. I thought you knew!" # spk:oldrik
}
-> clues

// Clues. In the game these are objects on the map; here they run in order for testing.
= clues
-> clue_crown -> clue_list -> clue_track -> leave

= clue_crown
A cart with a broken axle has been abandoned by the well. On its side is a yellow sign: a crown, and under it three prongs.
{ hero_class == "wizard":
    The sign is not painted. You run a finger over it, and grey dust stays on your skin, cold as ash from a crypt.
- else:
    The paint has peeled, but the sign is still easy to see. It is as if it were drawn on purpose to be seen from far off.
}
->->

= clue_list
In the mud by the wheel lies a scrap of paper, soaked but whole. A column of names. The hand is even, without a single blot, almost polite.
Beside every name stands "column". Except for one, at the very bottom: "{sp()} of the house of Tal. Separately. In person."
->->

= clue_track
The ruts lead north, towards the mountains. To where the Deep Mines begin beyond the forest. The wheel tracks are deep, and beside them are hundreds of feet.
->->

= leave
The road led north. You did not look back.
->->
