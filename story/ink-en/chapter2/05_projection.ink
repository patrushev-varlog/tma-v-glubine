// Chapter 2, scene 5. "The projection". English parallel of story/ink/chapter2/05_projection.ink.
// About 5 minutes. Edric's first, courteous projection. No battle.

VAR edric_ch2_reply = ""   // "defy" / "ask" / "silent"

=== projection ===
A narrow gallery above the water led to the sluice. Halfway along, Garret's lantern flickered and went out, though there was plenty of oil.
In the dark above the water, light was gathering. Pale, like the glow of rotten wood. Slowly a figure emerged from it: a tall man in an old high-collared robe. The face could not be seen, only shadow and the glint of eyes.
You knew the voice at once. The one from the dream. The one that kept the books.
"So this is you," he said, studying you. "I have heard you described in different ways." # spk:edric
You did not answer. Behind you the companions froze. Irena raised her staff, and the bell on it trembled without a sound.
"Have no fear, sister. It is only light and water; I am far away." The figure turned its head slightly. "I simply grew curious. It is not every day that someone comes after me of their own accord. Usually I have to send for them." # spk:edric
{ column_choice == "trail":
    "You chose rightly at the column," he told you. "Not everyone can. One's own is dearer than thirty-eight strangers. I understand. I thought so too. Once." # spk:edric
- else:
    "You freed the column and lost the cart," he told you. "Noble. I was noble once too. It passes." # spk:edric
}
{ ch2_choice == "hand_over":
    "And you paid Renna in the right coin. You see, you already know how to count." # spk:edric
}
{ hero_class == "wizard":
    "You hear the whisper, don't you," he said more gently, almost like a teacher. "Do not fear it. It is more honest than people. I could teach you a great deal." # spk:edric
}
"As for Velior..." He looked somewhere past your shoulder. "He searched well. Look after him. He will be useful yet. To us both." # spk:edric
* ["I'm coming for you. And you'll regret it."]
    ~ edric_ch2_reply = "defy"
    "I'm coming for you. And you'll regret not sending anyone to meet me." # spk:hero
    "You will come," he agreed. "You will come exactly where I need you. As for regret... oh, I have been regretting for sixty years. One more or one less." # spk:edric
* ["What do you want with my {spouse_f:wife|husband}?"]
    ~ edric_ch2_reply = "ask"
    "What do you want with my {spouse_f:wife|husband}?" # spk:hero
    The figure was silent for a long time.
    "To take back what was taken from me," he said at last. For the first time the voice was not courteous, only tired. "You will understand. One day you will understand better than anyone." # spk:edric
* [Say nothing.]
    ~ edric_ch2_reply = "silent"
    You said nothing. You simply looked, until he was the first to look away.
    "Silent," he said, with something like respect. "Rightly so. Words are cheaper than water here." # spk:edric
-
"I will not stand in your way," he said. "Go. You will come anyway." # spk:edric
The light above the water broke apart like a reflection hit by a stone. Garret's lantern flared up again.
"Was that him?" Irena whispered. # spk:irena
"That was him," said Velior. His voice was a stranger's. # spk:velior
->->
