// Chapter 2, scene 7. "The camp". English parallel of story/ink/chapter2/07_camp.ink.
// Long rest, level 3, a talk with a companion. Velior sits apart.

VAR camp2_talk = ""   // "irena" / "garret" / "velior"
VAR ch2_fugitives_led = false   // atonement (−10): the party itself took the fugitives to the camp above

=== camp2 ===
Above the sluice there was a dry chamber, once a dwarven guardroom: stone benches, a niche for a fire, a sign cut into the wall: a hammer over a closed eye.
{ ch2_choice == "fight":
    -> fugitives_farewell ->
}
Velior sat in the farthest corner, his back to the wall, and did not light a fire of his own.
For the first time that day it was quiet. # rest:long # levelup:3
Before sleep you could talk to one of them.
* [Sit down by Irena.]
    ~ camp2_talk = "irena"
    -> talk_irena
* [Sit down by Garret.]
    ~ camp2_talk = "garret"
    -> talk_garret
* [Go over to Velior.]
    ~ camp2_talk = "velior"
    -> talk_velior

= fugitives_farewell
The fugitives were getting ready to make for the surface through old passages they knew of only from rumour. No food, two wounded to carry.
"They won't make it on their own," Garret said quietly. "The passages are old, and there are guards up top." # spk:garret
"And {sp()} is waiting below," said Velior. Not to you. To the side. # spk:velior
* [See them to the runaways' camp above. Give them the silver from Renna's office.]
    ~ ch2_fugitives_led = true
    ~ add_darkness(-10)
    -> fugitives_led
* [Say goodbye here.]
    -> fugitives_parted

= fugitives_led
The way up took a day. Two rockfalls had to be cleared by hand, and the wounded were carried in turns. Renna's silver went on bread and blankets in the camp, down to the last coin. # silver:-40
The camp turned out to be three fires in an old working right under the sky. People from the barracks already lived there. They met you as if they had been waiting.
{ ch2_fugitives_leader == "meb":
    "That's for the barracks," said Mab. "And for the pumping station. Now we're even. No. Now I owe you." # spk:meb
    She held out her hand to Garret. He looked at it for a long time before he shook it.
- else:
    "We'll tell everyone who brought us out," said Tobin. "Not 'let us go'. Brought us out." # spk:tobin
}
You went back down in silence. The day you had given away weighed on your shoulders heavier than the pack. Somewhere below, {sp()} had spent that day without you.
But that night the whisper was silent. For the first time in a long while.
->->

= fugitives_parted
The fugitives said goodbye at the stairs.
{ ch2_fugitives_leader == "meb":
    "We'll wait for you up there," said Mab. "Or down here. Wherever it works out." # spk:meb
    She held out her hand to Garret. He looked at it for a long time before he shook it.
- else:
    "If we get out, we'll tell them who brought us out," said Tobin. # spk:tobin
}
->->

= talk_irena
{ ch2_choice == "hand_over":
    "He said you already know how to count," said Irena. "The one above the water." # spk:irena
    She was not looking at you.
    "I prayed for them all the way through the channel. It was all I could do. It's very little." # spk:irena # mood:tense
- else:
    "He spoke to you as one of his own," said Irena. "The one above the water." # spk:irena
    "He was wrong," she said. "Today you didn't count the way he wanted. I saw it." # spk:irena
}
-> leave

= talk_garret
{
- ch2_fugitives_leader == "meb" && ch2_choice == "hand_over":
    "Mab was right," said Garret. "I haven't changed. I've just changed masters." # spk:garret # mood:tense
    For a long time he turned his cleaver over in his fingers.
    "Only now I choose the master myself. Maybe that's the difference. If there is one." # spk:garret
- ch2_fugitives_leader == "meb":
    "She shook my hand," said Garret. "Mab. Mine. I kept her in a cage for two years." # spk:garret
    He threw a broken pit prop on the fire.
    "I don't know what to do with that. Nothing, probably. Just remember it." # spk:garret
- else:
    Garret said nothing. He just threw a broken pit prop on the fire and watched it burn.
}
-> leave

= talk_velior
Velior raised his eyes to you.
"Come to decide?" # spk:velior
"Not tonight." # spk:hero
"In the morning, then. Everything in the morning." He turned to the wall. "You know what's funniest? He's right. I really have nowhere to go. Except with you." # spk:velior # mood:tense
-> leave

= leave
In the morning the stairs led down, towards carved arches and a silence many hundreds of years old.
Chapter 3. The Dwarven Halls # chapter:3
->->
