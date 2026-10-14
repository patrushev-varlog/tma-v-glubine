// Chapter 3, scene 2. "The refuge". English parallel of story/ink/chapter3/02_refuge.ink.
// About 8 minutes. The dwarven forge becomes a permanent camp. Who lives in it depends on earlier choices.

VAR ch3_camp_people = ""   // "many" — the fugitives and the smith, "few" — one of them, "none" — nobody
VAR ch3_fugitives_here = false   // the chapter 2 fugitives live in the forge (for the camp map)
VAR ch3_camp_leader = ""         // their leader at the hearth: "meb" / "tobin" (for the camp map)

=== refuge ===
~ temp fugitives_stay = ch2_choice == "fight" && not ch2_fugitives_led
~ ch3_fugitives_here = fugitives_stay
{
- fugitives_stay && column_choice == "neighbors":
    ~ ch3_camp_people = "many"
- fugitives_stay || column_choice == "neighbors":
    ~ ch3_camp_people = "few"
- else:
    ~ ch3_camp_people = "none"
}
Two halls further on, a light appeared ahead. Not cold, like rotting wood, but alive and red. It smelled of smoke and iron.
It was a forge. A dwarven one, enormous: a hearth the size of a village house, anvils a man could have slept on, channels for molten metal running into the wall.
{ fugitives_stay:
    -> fugitives_here ->
}
{ column_choice == "neighbors":
    -> smith_here ->
}
{ ch3_camp_people == "none":
    -> nobody_here ->
}
"One could live here," said Irena, looking around. "Dry, warm, there's water. And walls that will stand another thousand years." # spk:irena
"One could hold this place," said Garret. He was thinking of something else. # spk:garret
Dwarven steel lay in chests along the wall, dull and heavy. It could be made into things that human iron could not. # shop:dwarf_forge
This place became the camp. You could leave it, and you could come back to it.
// On the forge map: the brewery of the Silent behind the hearth (nook 1, an ingot for the forge).
+ [Go into the round hall beyond the forge. #obj:fresco_door]
-
->->

= fugitives_here
~ ch3_camp_leader = ch2_fugitives_leader
People were sitting by the hearth. You did not know them at first: washed, in borrowed dwarven coats down to their heels.
{ ch2_fugitives_leader == "meb":
    "We told you we'd wait," said Mab. "Rockfall up above. You down below. It was an easy choice." # spk:meb # mood:smile
    She nodded to Garret. He nodded back. Almost as to an equal.
- else:
    "The ways up are blocked," said Tobin. "We came back. We thought it better to be near the ones who fight." # spk:tobin
}
->->

= smith_here
The smith from Ashmoor stood at the anvil with his sleeves rolled up. He had fired the dwarven hearth and was now looking at it the way other men look at a temple.
"Dreamed of this all my life," he said, without turning round. "Thought it was a fairy tale. It's real." # spk:smith
{ ch2_choice == "fight" && not ch2_fugitives_led:
    The fugitives were carrying coal for him. It seemed they had already become friends.
}
->->

= nobody_here
The hearth was cold. The ash in it had lain so long that it had baked into stone. No one.
{ ch2_fugitives_led:
    You thought of the fugitives by the three fires under the sky. They were better off there. It just made it no warmer here.
- else:
    You thought of the column at the gates, of the barracks, of the fugitives on Renna's landing stage. They could have been sitting here.
}
Garret walked to the hearth without a word, found the bellows and began to pump. An hour later the flame was roaring.
"I worked for a smith when I was young," he said, not looking at you. "Before I became an overseer. Worked badly. But I worked." # spk:garret
->->
