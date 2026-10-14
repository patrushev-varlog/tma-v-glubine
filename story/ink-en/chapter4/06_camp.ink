// Chapter 4, scene 6. "The camp". English parallel of story/ink/chapter4/06_camp.ink.
// Long rest, level 5, the ring into the furnace (atonement), Irena's warning or confrontation.

VAR ring_destroyed = false
VAR irena_confronted = ""   // "" — no confrontation, "stayed" — she stayed, "left" — she left
VAR camp4_talk = ""         // "irena" / "garret" / "velior"
VAR ch4_debt = ""           // the debt to Renna: "paid" — leave her debtor in the pens, "refused" — refuse

=== camp4 ===
You settled in the cooled foundry, by the last furnace that still held its heat. The descent to the bottom began twenty paces away, beyond the arch. What came up from it was neither cold nor heat. Nothing. As if the air ran out down there.
{ ch4_arithmetic == "refuse":
    The freed prisoners went up to the dwarves' forge. Garret explained the way to them twice.
}
You slept heavily. # rest:long # levelup:5
{ column_choice == "neighbors":
    In the morning the smith from Ashmoor came down the stairs from the forge of the Silent. He had a sack on his back, and something in it clinked.
    "Made from the iron here," he said, laying out his wares on a cooled slab. "It's not the iron's fault it was cast here." # spk:smith # shop:smith_ch4
- else:
    In the morning a familiar sutler turned up by the furnace. How he had got past the garrison, he did not explain.
    "The founders have no more use for goods," he said. "But you'll still need them." # spk:sutler # shop:sutler_ch4
}
{ ch2_favor_owed:
    -> renna_debt ->
}
{ ring_taken:
    -> ring_choice ->
}
{
- darkness >= 50:
    -> irena_confront ->
- darkness >= 25:
    -> irena_warn ->
}
Before the descent, you could talk to one of them.
* {irena_confronted != "left"} [Sit down by Irena.]
    ~ camp4_talk = "irena"
    -> talk_irena
* [Sit down by Garret.]
    ~ camp4_talk = "garret"
    -> talk_garret
* {velior_fate == "forgiven"} [Sit down by Velior.]
    ~ camp4_talk = "velior"
    -> talk_velior

= renna_debt
Towards morning a stranger was sitting by the furnace: a wet cloak, a boatman's pole across his knees. Garret was already standing over him with his cleaver. The stranger did not look at the cleaver.
"From Renna Sol," he said. "About the favour. She said she'd tell you later. Now it's later." # spk:smuggler
{ ch2_choice == "fight":
    "She's not holding the pumping station against you. That's another account. This one's by agreement." # spk:smuggler
}
"In the pens at the bottom sits Corvin Haas. He sold three of her boatmen to the King. When you open the gratings, leave him. Let him sit where he sent others. Nothing more." # spk:smuggler
* ["Tell Renna: the debt will be paid."]
    ~ ch4_debt = "paid"
    "Tell Renna: the debt will be paid." # spk:hero
    The stranger nodded, as if it could not have been otherwise, and went off into the dark without a sound.
    Irena was looking at you. You pretended not to notice.
* ["Tell Renna I won't pay this debt."]
    ~ ch4_debt = "refused"
    "Tell Renna I won't pay this debt. Not in people." # spk:hero
    "She thought as much," said the stranger. "She'll remember. She remembers everything." # spk:smuggler
    He left. Garret watched him go for a long time.
    "Now you have an enemy up above," he said. "That's better than a debt." # spk:garret
-
->->

= ring_choice
The ring on your finger was warm. Warmer than your hand.
The furnace beside you hummed. It could still melt anything.
{
- hero_class == "wizard":
    The whisper understood what you were thinking before you did. It did not ask. It simply reminded you how many times today the ring had saved your lives.
- hero_class == "fighter":
    The ring sat on your sword hand as if the two were one steel. In battle the blade did not ask, it took. You could not remember when that had begun.
- else:
    You remembered how easy it had been in battle. How the gifts came on their own, without effort, without counting.
}
* [Throw the ring into the furnace.]
    ~ ring_destroyed = true
    ~ ring_taken = false
    ~ add_darkness(-10)
    You took off the ring. It did not want to come off; you had to pull your finger free as if from a trap.
    The ring fell into the fire without a sound. The stone cracked, and for a moment cold breathed out of the furnace, as from a well.
    It grew easier. Not for the body. For something else. # item_remove:pale_ring
    { irena_bell == "blessed":
        The bell at your neck chimed softly on its own.
    }
    Irena was looking at you across the fire. And for the first time in a long while she smiled.
* [Keep the ring.]
    You turned away from the furnace. The ring stayed on your finger. Warm.
-
->->

= irena_warn
Irena came and sat by you herself, when the others were asleep.
"You talk like him," she said quietly. "Not always. Sometimes. When you count. I hear it, and it frightens me." # spk:irena # mood:tense
"I'm not him." # spk:hero
"He thought so too. In the diary." She paused. "I'm only asking: listen to yourself. While there's still someone to listen to." # spk:irena
Garret was not asleep. You could tell by the way he looked into the fire. The way you look at something you have seen once before. In a mirror.
->->

= irena_confront
Irena was waiting for you by the furnace. Staff in hand, pack on her back. Ready to go.
"I have to say this now," she said. "While I can still say it to you, and not to him." # spk:irena # mood:tense
{ irena_bell == "cracked":
    She touched the cracked bell on her staff.
    "It cracked back in the halls. I kept quiet then. I shouldn't have." # spk:irena
}
"I look at you and I see the fresco. The wet face. Only you don't weep. You don't weep any more." # spk:irena
{ hero_class == "cleric":
    "You're of my order. You know the prayer that is read over those who have gone over to him. Don't make me read it over you." # spk:irena # mood:sad
}
"I'll go to the end with you, if you stop. If not, I won't go. I can't stand beside you when you do what he did." # spk:irena
* ["You're right. I'll stop."]
    ~ irena_confronted = "stayed"
    "You're right. I'll stop. No more bargains with the whisper." # spk:hero
    Irena looked into your eyes for a long time. Searching for something. She seemed to find it, but not all of it.
    "I'll believe you," she said. "Once. I have no faith left beyond that." # spk:irena
    She took the pack off her back.
* ["I need this power to get there."]
    ~ irena_confronted = "left"
    "I need this power to get there. Without it, {s("he", "she")} dies." # spk:hero
    "He used to say that too," Irena answered. "I've read it." # spk:irena # mood:sad
    She went over to Garret, put a hand on his shoulder, said something. He shook his head.
    Then she left. Up, to the dwarves' forge, to the prisoners. The bell on her staff did not ring. Not once.
    Garret watched her go until she was out of sight.
    "I'm staying," he said, without turning round. "Not because you're right. Because someone has to." # spk:garret
-
->->

= talk_irena
{ irena_confronted == "stayed":
    "Once," Irena repeated, looking into the fire. "Do you remember?" # spk:irena
    "I remember." # spk:hero
- else:
    "{s("He", "She")} will be down there," said Irena. "And the King. And a choice. I pray you won't make it for {s("him", "her")}." # spk:irena
    "And if {s("he", "she")} makes it {s("himself", "herself")}?" # spk:hero
    "Then I pray you can bear it." # spk:irena # mood:sad
}
-> leave

= talk_garret
"You know what I understood in the foundry?" said Garret. "All my life I thought my guilt was that I stood there with the whip. But it's that I counted. How many days till the shift changed. How many were left. How much I could get away with not noticing." # spk:garret
"Annet died while I was counting." # spk:garret
{ irena_confronted == "left":
    "Irena said you'd become like him." He paused. "Maybe you will. I'll be there. Someone will have to tell you so." # spk:garret
}
-> leave

= talk_velior
"The secret way begins behind the third pillar," said Velior. "We'll get past the garrison. He won't even know until it's too late." # spk:velior
"And if he does know?" # spk:hero
"He will," Velior agreed. "He always knows. But too late. That's all I can give you: too late, for him." # spk:velior
-> leave

= leave
In the morning you stood at the arch. The stairs went down, into a silence where there was no heat, no cold, no sound.
Somewhere there, at the bottom, was {sp()}.
Chapter 5. The Bottom # chapter:5
->->
