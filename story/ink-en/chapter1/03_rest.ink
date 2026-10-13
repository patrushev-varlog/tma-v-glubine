// Chapter 1, scene 3. "The rest". English parallel of story/ink/chapter1/03_rest.ink.
// About 5 minutes. A party of four at one fire; the first dream with Edric's voice. Darkness does not change.

=== rest ===
In an abandoned working they found a dry corner and an old fire pit. Garret built a fire from broken pit props. Irena bound Velior's ribs, tightly and without wasted pity.
For a while nobody spoke. Then Velior, of course, spoke first.
"So. A priestess, a deserter, a traitor and..." he looked at you, "and what?" # spk:velior
* ["Someone who had the person closest to them taken."]
    "Someone who had the person closest to them taken." # spk:hero
    Velior stopped smiling.
    "Ah. By the list," he said quietly. It was not a question. # spk:velior
* ["None of your business."]
    "None of your business." # spk:hero
    "Fair," Velior agreed easily. "Down here nobody much cares who you are anyway. Only whose." # spk:velior # mood:smile
-
// The companions' lines depend on choices made in the prologue.
{ interrogation == "dead":
    -> irena_whisper ->
}
{ column_choice == "trail":
    Garret was cleaning a captured cleaver, and said without looking at you:
    "At the column you chose your own. Once I chose the service and left my own behind. I don't know which of us was right. I only know it doesn't let go of you for a long time after." # spk:garret
- else:
    Garret was cleaning a captured cleaver, and suddenly said:
    "At the column you chose strangers. So did I, once. Only you did it to set them free, and I did it to guard them." # spk:garret
}
Velior looked at Garret, then at you, and this time said nothing.
-> dream

= dream
You fell asleep without noticing.
In the dream it was dark. Not the dark of a tunnel, but the dark you see when you close your eyes in a room where a single candle burns. Somewhere close by, pages rustled calmly.
"Every life is a line," said a voice. Quiet, tired, polite. # spk:voice
{ column_choice == "trail":
    "I have kept these books for sixty years. This week they gained forty-three lines in one temple and thirty-eight in one column. You would be surprised how quickly one learns not to mix them up." # spk:voice
- else:
    "I have kept these books for sixty years. This week they gained forty-three lines in one temple. And one column struck itself out. Untidily, but I understand." # spk:voice
}
You tried to see who was speaking. There was no face, no outline. Only the even voice and the sound of a pen.
"You will learn to count too," said the voice. "Everyone does. The only question is what you will put on the other side of the scales." # spk:voice
The pen stopped.
-> wake

= wake
You woke from the cold. The fire had burned down to embers.
Velior sat across from you, hugging his knees, watching you. It looked as if he had not slept at all.
"Bad dream?" he asked. "Everyone has bad dreams down here. Pay it no mind." # spk:velior
* ["I dreamed of a voice. It talked about books and lines."]
    "I dreamed of a voice. It said it keeps books. That every life is a line." # spk:hero
    Velior was silent for a very long time.
    "Everyone has bad dreams down here," he said again at last, no longer smiling. "Sleep. I'll keep watch." # spk:velior # mood:tense
* ["Just a dream."]
    "Just a dream." # spk:hero
    "Of course," said Velior. "Just a dream." # spk:velior
-
->->

= irena_whisper
Irena was looking into the fire, and said without raising her eyes:
"That whisper at the gates. Do you still hear it?" # spk:irena # mood:tense
* ["No."]
    "No." # spk:hero
    Irena nodded, but you could see she did not believe it.
* ["Sometimes."]
    "Sometimes." # spk:hero
    "Thank you for not lying," said Irena. "Tell me when it gets more often." # spk:irena
-
->->
