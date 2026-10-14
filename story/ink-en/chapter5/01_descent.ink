// Chapter 5, scene 1. "The descent". English parallel of story/ink/chapter5/01_descent.ink.
// ~10 minutes. Velior's secret way, or a fight with the garrison at the main descent.

VAR ch5_secret_path = false

=== descent ===
The stairs from the foundry led down for a long time. The steps grew narrower and steeper, then ended altogether, and after that there was only sloping stone, smooth, as if thousands of feet had polished it. Or thousands of years.
Sounds faded. You could hear your own breathing, and nothing else.
Then a light appeared ahead. Steady, pale. And voices: orders, the clank of chains.
"The main descent," said Garret. "The garrison's there. And the pens." # spk:garret
// On the descent map: the council guardroom by the stairs (side spot, hunt clue). The fork is at the third pillar:
// the crack of the secret way to the left, the main descent with the pens straight ahead.
+ [Go down to the third pillar. #obj:third_pillar]
-
{ velior_fate == "forgiven":
    -> secret_path
- else:
    -> garrison
}

= secret_path
~ ch5_secret_path = true
"Not that way," said Velior. "This way." # spk:velior
He turned into a crack you would have walked past without noticing. Beyond the crack was a crawlway, and beyond the crawlway a narrow ledge over emptiness.
"I used to lead him this way," he said, without turning round. "He liked to come here alone. To sit by the seal. To talk to it." # spk:velior
You walked above the garrison, above the pens where hundreds of people sat. Down below, no one raised their head.
"When this is over," said Velior, "we'll come back for them. I promise. I'm promising you, not him." # spk:velior
{ ch4_debt == "paid":
    You told him a name: Corvin Haas. His grating was not to be opened. Velior looked at you for a long time and nodded. He did not ask.
}
// On the map: the ledge above the hall of the seal, Velior points down (hunt clue).
+ [Climb down from the ledge to the hall of the seal. #obj:ledge_end]
-
->->

= garrison
{ velior_fate == "exiled":
    You found the third pillar of the foundry, as Velior had said. There was no crack behind it. There was stone, fresh, still dusty with mortar.
    { hero_class == "rogue":
        You ran a finger along the joint. Laid in a hurry, with one hand, from the bottom up. That is how you lay stone when you want it to be noticed. Or when you don't know yourself whether you want it to be.
    }
    "Someone told him about the third pillar," said Garret. # spk:garret
}
There was no way round. Only the main descent, wide as a street, and the garrison across it.
On both sides of the descent stretched the pens. The people behind the bars watched you, and there was no hope in their eyes. Only weariness.
{ irena_confronted == "left":
    Irena was not there. But you heard her voice as clearly as if she were standing beside you: "If we start here, they'll get hurt too."
- else:
    "If we start here," Irena said quietly, "they'll get hurt too." # spk:irena # mood:tense
}
"There's no other way," answered Garret. # spk:garret
// Chapter battle 1: the garrison at the main descent. Prisoners in the pens die from stray blows while the fight goes on.
The garrison saw you first. # battle:chapter5_1_garrison
-> after_garrison

= after_garrison
When it was all over, the pens were quieter. Some of the people lay down and did not get up again.
Garret opened the gratings, one after another.
{ ch4_debt == "paid":
    One you told him to leave shut. The man behind it did not ask why. He seemed to know.
}
"Go up," he said. "Through the foundry, to the dwarves. Your own people are there." # spk:garret
The people left slowly. Many looked back. At you, at the dead, at the light below.
+ [Go down, towards the pale light. #obj:hall_gate]
-
->->
