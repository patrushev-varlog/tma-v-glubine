// Chapter 2, scene 3. "The smugglers". English parallel of story/ink/chapter2/03_smugglers.ink.
// About 15 minutes including the chapter's second battle. The main choice: hand over the fugitives or fight.

VAR ch2_choice = ""          // "hand_over" — handed over the fugitives, "fight" — refused and fought
VAR ch2_favor_owed = false   // paid the smugglers with a "favour" (+5 Darkness)

=== smugglers ===
The pumping station stood over the water on stone piers: huge wheels, rusty pipes as thick as a man, and light. A lot of light: lanterns, braziers, laughter. After the black water it was almost painful.
Men with crossbows sat on the platforms. Below, by the landing stage, flat-bottomed boats loaded with crates rocked on the water.
"Smugglers," said Velior. "They make a living carrying down what can't be had up there, and up what shouldn't be down here." # spk:velior
// On the pumping station map, before the talk with Renna: the store under the platform (nook 3), the boatmen at the landing stage (clue 3).
+ [Climb up to the desk on the platform. #obj:desk]
-
Renna Sol turned out to be a short woman in a man's doublet, her grey hair neatly cropped. She sat at a writing desk right on the platform, like a merchant at a fair.
"Guests," she said, without surprise. "Armed, wet, and trailing runaways. I like you already. Shall we trade?" # spk:renna # mood:smile
{ hero_class == "rogue":
    Her eyes lingered on your hands.
    "Clever hands," she said. "Ashmoor? The miller there still owes me. Said he once had an apprentice who paid his debt in full. A rarity." # spk:renna
}
// The smugglers' shop: the best stock, dark items. Paying with a "favour" instead of silver gives +5 Darkness.
Her people were already laying out goods on the crates. # shop:smugglers
* [Pay with a "favour" for what the silver won't cover.]
    ~ ch2_favor_owed = true
    ~ add_darkness(5)
    "We haven't enough silver," you said. # spk:hero
    "No matter," Renna smiled. "You'll owe me a favour. Which one, I'll tell you later. I always tell later." # spk:renna # mood:smile
    She lifted the lid of a crate holding the things that are never put out in the light. # shop:smugglers_favor
    Irena silently watched you shake Renna's hand.
* [Buy only what the silver covers.]
    You counted out the silver. Renna counted it twice and nodded.
-
"Now to business," you said. "We need the sluice." # spk:hero
"Everyone needs the sluice." Renna leaned back in her chair. "Through it you reach the old dwarven passages, and from there it's the surface or the very bottom, as you like. I'll let you through. The price is simple." # spk:renna
She nodded at the fugitives huddled by the landing stage.
"Them. The King pays by the head. Your heads I don't need, but theirs I very much do. You go through, they stay, everyone's happy. Almost everyone." # spk:renna
{ ch2_fugitives_leader == "meb":
    Mab said nothing. She was not looking at you, but at Garret.
- else:
    Tobin clenched his good hand into a fist, but said nothing.
}
{ ch1_choice == "slip":
    Velior leaned towards you:
    "You've left prisoners behind for speed before. The only difference is that these ones are looking you in the eye." # spk:velior
- else:
    Velior leaned towards you:
    "Think. The one you came here for is waiting below. And these... these may not make it anyway." # spk:velior
}
"Don't you dare," Irena said quietly. It was not to you, it was to Velior. But she was looking at you. # spk:irena # mood:tense
* [Hand over the fugitives. Go through the sluice.]
    ~ ch2_choice = "hand_over"
    ~ add_darkness(10)
    -> hand_over
* ["No. We'll pay in silver, and if it's not enough, we'll take it."]
    ~ ch2_choice = "fight"
    -> fight

= hand_over
"Agreed," you said. # spk:hero
You did not look at the fugitives while Renna's people tied them up. You looked at the water.
{ ch2_fugitives_leader == "meb":
    As Mab was led past, she stopped for a second in front of Garret.
    "You stood over us with a whip," she said. "Now you stand beside the one who's selling us. You haven't changed, Garret. You've just changed masters." # spk:meb
    Garret did not raise his eyes.
- else:
    Tobin did not resist. He only said, as he passed: "You promised," though you had promised nothing. Or had you.
}
Irena turned to the wall and stood like that until the fugitives were taken away.
"The bypass channel," said Renna, pleased. "My people will see you through. Mind, a few things swim in there. But you know how to deal with those." # spk:renna # mood:smile
// Battle 2 (variant): the drowned in the flooded bypass channel.
The channel met you with cold, and with movement in the water. # battle:chapter2_2_flooded
-> office

= fight
"No." # spk:hero
Renna sighed, the way one sighs over a bad customer.
"Pity. I almost liked you." # spk:renna
The crossbowmen on the platforms raised their weapons. Behind you the fugitives grabbed whatever came to hand: planks, an oar, a length of broken pipe.
{ ch2_fugitives_leader == "meb":
    "At last," said Mab. "For once it's not just us." # spk:meb
}
// Battle 2: the smugglers in the pumping station. The fugitives help (AI allies).
The pumping station erupted in shouting. # battle:chapter2_2_smugglers
-> office

= office
{ ch2_choice == "fight":
    When it was over, Renna sat on the floor by her desk, tied up with her own belt, watching you with polite interest.
    "The office is through there," she said, before you asked. "Take what you like. I won't be trading any more anyway." # spk:renna
- else:
    The bypass channel brought you out at the back door of the pumping station. While Renna was upstairs counting her living goods, the office door stood unlocked.
    "Since we're here," said Velior, and went in first. # spk:velior
}
The office smelled of wax and dry paper. On the desk, under a heavy paperweight, lay a stack of letters.
->->
