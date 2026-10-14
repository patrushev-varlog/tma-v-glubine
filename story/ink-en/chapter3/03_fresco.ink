// Chapter 3, scene 3. "The fresco". English parallel of story/ink/chapter3/03_fresco.ink.
// About 10 minutes. The fresco and Edric's diary from sixty years ago. The truth about the seal.

VAR ch3_diary_read = false

=== fresco ===
The hall beyond the forge was round and domed, and in its centre the floor went down in steps, like a bowl. At the bottom of the bowl lay a stone circle scored with grooves.
"Something was done here," said Irena. "People prayed here. Or..." # spk:irena
She did not finish.
The walls were covered in dwarven carving, but on one of them, right over the carving, someone had painted a fresco. The colours had faded, but not worn away. People had painted it: dwarves do not paint like that.
A woman in white stood in the stone circle. Around her were people in high-collared robes, all with the same face, as if the painter had not wanted to tell them apart. And at the very edge of the circle stood a mage with his hands raised. Only his face had been painted with care. Young. Wet with tears.
{ hero_class == "wizard":
    Under the fresco ran an inscription in the old tongue of men, in the court style. You read:
    "'In such-and-such a year the Council of Eldmar, mindful of the good of the realm, renewed the seal. Archmage Edric Sayr fulfilled his duty.'" # spk:hero
- else:
    Under the fresco ran an inscription in the old tongue of men. Irena read it slowly, syllable by syllable:
    "'The Council of Eldmar, mindful of the good of the realm, renewed the seal. Archmage Edric Sayr fulfilled his duty.'" # spk:irena
}
"Edric," Velior repeated. "I never heard his name. Only 'the King'." # spk:velior
In a niche under the fresco, as if someone had hidden it in haste, lay a bundle in rotted leather. Inside was a notebook. An even hand, without a single blot. You knew it at once.
* [Read it.]
    ~ ch3_diary_read = true
    -> diary
* [Don't read it. Give the notebook to Irena.]
    You handed the notebook to Irena. You did not want to hold in your hands anything he had written.
    Irena leafed through it for a long time. Then she closed it and pressed it to her chest.
    "He loved her," she said. "Her name was Liara. He loved her, and he... here." # spk:irena # mood:sad
    -> truth

= diary
The entries were short, like a campaign log.
"Third day in the halls. L. laughs that I count the steps. Two hundred and forty-one. She says she will remember, to tell her grandchildren. I did not tell her."
"The Council asked again. They always ask, never order. It is easier afterwards."
"L. knows. She knew before I did. She said: one against thousands, Edric, it is not even a question. I said she was right. I believe it. Then why is it so hard to breathe."
The last entry was written in another hand. No, the same one, but the hand was shaking.
"Tomorrow. They wanted to give it to the priests. I will not allow it. Let her hand be held by one who loves her."
You closed the notebook.
{ hero_class == "wizard":
    At the bottom of the last page, small, was one more line, almost worn away. Only someone who knows how magic leaves its trace on paper could have made it out. "If only it could be undone. If only there were a way." And a formula, a scrap of a formula. You recognised necromancy in it before you understood that you had recognised it.
}
-> truth

= truth
You went down into the bowl and touched the grooves. Dry, clean. Nothing had ever flowed in them.
"This isn't the seal," said Velior. He was looking at the fresco, not at you. "They only practised here. The seal is at the bottom." He broke off, as if he had heard what he said. # spk:velior
"Then what is the seal?" asked Garret. # spk:garret
"Blood," said Velior. "The King told me once, when he was drunk. The blood of an old house can wake the one who sleeps below. Or it can put him back to sleep. And the one whose blood put him to sleep stays there. In the seal. For ever." # spk:velior
You thought of the "list". Of the house of Tal. And of the one on that list whose name was {sp()}.
"So they're not taking {s("him", "her")} to kill {s("him", "her")}," you said. Your voice was a stranger's. "They're taking {s("him", "her")} to make {s("him", "her")} into this." # spk:hero
No one answered.
"He was a righteous man too," Irena said at last. She was looking at the young, wet face in the fresco. "He did what I would have done. What I preached all my life. One life against thousands." She turned away. "I don't know what I should preach now." # spk:irena # mood:sad
"He isn't evil," said Garret. "He's empty. That's worse. An evil man at least wants something for himself." # spk:garret
Velior was silent for a long time. Then he said, still without looking at you:
"The dwarves wrote down everything they knew about him. About the one who sleeps. The King ordered me to find those records." He paused. "I found them. And didn't hand them over. Come. I'll show you." # spk:velior
->->
