// Chapter 4, scene 4. "Arithmetic". English parallel of story/ink/chapter4/04_arithmetic.ink.
// ~10 minutes. The second talk with Edric's projection. The chapter's main choice.

VAR ch4_arithmetic = ""   // "play" — freed ten, he executed twenty (+5), "pass" — walked past (+10), "refuse" — refused to play

=== arithmetic ===
The hall above the foundry was built like a theatre: rows of stone benches in a half-circle, and below, where the stage should be, cages. People sat in the cages. Some thirty of them. By each cage stood a dead man with an axe.
Above the cages, in the smoke rising from the foundry, a light was gathering. Pale, like the one at the sluice.
"Hello," said Edric. The figure in the old robe stood in the empty air above the stage. "I'm glad you made it. Truly glad." # spk:edric
{
- edric_ch2_reply == "defy":
    "You promised I would regret it. I'm still waiting. But you came, just as I said you would." # spk:edric
- edric_ch2_reply == "ask":
    "You asked what I wanted with your {s("husband", "wife")}. Now you know. You've been in the halls." # spk:edric
- else:
    "At the sluice you said nothing. I liked that. Today, I'm afraid, we'll have to talk." # spk:edric
}
{ ch3_diary_read:
    "You read my diary." He paused. "I left it there on purpose. No. That's not true. I forgot it. I forgot a great deal back then." # spk:edric
}
{
- velior_fate == "forgiven":
    "And you kept Velior. Good. I told you he'd be useful. Hello, Velior." # spk:edric
    Velior did not answer. {velior_dagger == "velior":He only tightened his grip on the dagger's hilt.|He only touched his belt where the dagger used to hang.}
- velior_fate == "killed":
    "And Velior you killed." The voice did not change by a single note. "I understand. I too kill those dear to me when I reckon it must be done. You see? We already have a great deal in common." # spk:edric
- else:
    "And Velior you drove away. He'll come to me. They never have anywhere else to go." # spk:edric
}
"But let's get to business." He nodded at the cages. "There are thirty people here. Tomorrow they'll be put in the vats. You can save them. Some of them." # spk:edric
"The rules are simple. For each one you let out, I execute two. Here, in front of you. Let out ten, and twenty die. Walk past, and no one dies today. Tomorrow, of course, they all go into the vats. But tomorrow is tomorrow." # spk:edric
{
- ch2_choice == "hand_over":
    "You already know how to count. You gave the fugitives to Renna for safe passage. That was a good bargain." # spk:edric
- column_choice == "trail":
    "You already know how to count. At the column you chose one against many. As I once did." # spk:edric
- else:
    "You still count badly. The column, the fugitives... You keep taking on more than you can carry. I want to see what you do when it becomes visible." # spk:edric
}
{ hero_class == "wizard":
    "It will be easier for you than for others," he added, almost tenderly. "You know that numbers don't lie." # spk:edric
}
"Your council killed one woman and called it mercy," he said. "I kill thousands and call it the price. I'm the more honest of us. Decide." # spk:edric
{ velior_fate == "forgiven":
    Velior leaned towards you:
    "It's a projection. It has an anchor, a bone lantern. Somewhere near the stage, in the smoke. Break it, and he can't see us. The dead by the cages will stay, but it won't be him deciding any more." # spk:velior
}
* [Let ten go. Let it be his price.]
    ~ ch4_arithmetic = "play"
    ~ add_darkness(5)
    -> play
* [Walk past. No one dies today.]
    ~ ch4_arithmetic = "pass"
    ~ add_darkness(10)
    -> pass
* ["I won't play with your numbers."]
    ~ ch4_arithmetic = "refuse"
    -> refuse

= play
You opened ten cages. The people came out, not believing it, looking back.
Edric nodded. The dead by the remaining cages raised their axes.
Irena screamed. Garret held her back and turned away himself.
It did not last long. Edric was watching not the cages but you. Closely, like a teacher at an examination.
"Today you cost me twenty," he said. "Every day of delay costs me twenty lives. You do understand that you count too? Only more slowly." # spk:edric
The light above the stage went out. Ten people stood at your feet. Twenty lay in the cages.
->->

= pass
You walked to the way out of the hall, without looking at the cages.
"Sensible," Edric said to your back. "No one died today. Remember that feeling. It's the feeling of a good ruler." # spk:edric
The people in the cages were silent. One, a boy, reached his hand through the bars as you passed. You did not stop.
Irena stopped. She stood by the cage for a while. Then she followed you, and her step was heavy, like an old woman's.
{ velior_fate == "forgiven":
    "He used to walk away like that," Velior said quietly. "In the first years. Without looking back. Then he stopped walking away. He started staying, and watching." # spk:velior
}
->->

= refuse
"I won't play with your numbers," you said. # spk:hero
{ velior_fate == "forgiven":
    Velior was already moving. You saw a pale glow in the smoke at the edge of the stage, and a moment later he smashed it with his elbow.
- else:
    You saw where the light was coming from: out of the smoke at the edge of the stage, where a bone lantern hung on a pole. Garret reached it first and crushed it with one blow.
}
Edric had time to smile. Not cruelly. With interest, rather.
"Then you'll have to count your own," he said, fading. "That costs more." # spk:edric
The light went out. The dead by the cages turned towards you. The axes rose, not over the prisoners. Over you.
->->
