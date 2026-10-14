// Chapter 3, scene 7. "The judgment". English parallel of story/ink/chapter3/07_judgment.ink.
// About 10 minutes. The main choice of the chapter: forgive, banish or kill Velior.

VAR velior_fate = ""     // "forgiven" / "exiled" / "killed"
VAR velior_dagger = ""   // "velior" — kept it himself, "hero" — gave it to the hero, "taken" — the hero took it (dark item)

=== judgment ===
In the evening, in the forge, Velior came and sat down across from you of his own accord. He laid a dagger on the stone between you. The one with the crown on the hilt, the one he never parted with.
"Decide," he said. "Enough putting it off." # spk:velior
{
- velior_confronted == "rage":
    "Last time you nearly strangled me. I don't hold it against you. But let's use words this time." # spk:velior
- velior_confronted == "truth":
    "I've already told you everything I knew. Except one thing." # spk:velior
- else:
    "You said: later. It's later now. I've waited. Now it's my turn to talk, and yours to decide." # spk:velior
}
"I know a secret way to the bottom. The one I used to take him by. Without it you'll have to go through the garrison, and there..." He shrugged. "There are a lot of dead there, and not all of them are enemies. Prisoners too." # spk:velior
"In the cage you said they never let even you go down there," said Irena. "And you asked us to remember it. I remembered." # spk:irena # mood:tense
"I lied." Velior did not even smile. "I took him to the bottom dozens of times. He would sit by the seal, and I would wait outside the door and think that one day he'd leave me down there. If I'd said that in the cage, you'd have left me in it." # spk:velior
"And is this a bargain now?" asked Garret. # spk:garret
"It's the truth. I've nothing to bargain with. I want you to know what you lose if you decide to be rid of me. So you can't say afterwards that I hid it." # spk:velior
{ velior_terms == "conditions":
    "You promised to answer questions," you reminded him. "In the cage." # spk:hero
    "And I did. Every time. I just never once told you anything you didn't ask about." He smiled crookedly. "I'm a thief. It comes with the trade." # spk:velior
}
"You brought us to the archive," said Irena. "You could have kept quiet." # spk:irena
"I could." Velior did not look at her. "I don't expect it to outweigh anything. I found twelve houses. The archive is not twelve houses." # spk:velior
{ ch3_dead_spoke:
    "And you made a dead man talk," he said to you, more quietly. "I saw. I've seen him do it. A thousand times. You're not the first to find the whisper more honest than people." # spk:velior # mood:tense
}
Everyone was looking at you.
{
- hero_class == "wizard":
    The whisper was right there. It said: this man knows where your own one lies. It said: a dead man can show the way too. You drove it off. Not all the way.
- hero_class == "cleric":
    You tried to pray. The words came, but you were not sure anyone heard them.
- hero_class == "rogue":
    You looked at him and thought that in his place you would have done the same. Found the ones you were told to find. Until you saw what for.
- else:
    You looked at his hands. The hands that had written "Tal" in the column. The hands that had led you to the archive today.
}
* ["You stay. But everything you do from now on, you do for {s("him", "her")}."]
    -> forgive
* ["Go. I won't kill you. But I won't have you near me."]
    -> exile
* [Take the dagger from the table.]
    -> kill

= forgive
~ velior_fate = "forgiven"
"You stay," you said. "But everything you do from now on, you do for {s("him", "her")}. Every step." # spk:hero
Velior looked at you for a long time. Then he nodded. Once.
"Fair," he said. His voice broke in the middle of the word. # spk:velior
"I wouldn't have forgiven him," said Irena. "So I suppose it's as well that it isn't my decision." # spk:irena
Garret laid a hand on Velior's shoulder and said nothing.
Velior pushed the dagger towards you.
"His gift. Take it, if you like. I wore it to remember who I was beholden to. Now I remember something else." # spk:velior
* [Take the dagger.]
    ~ velior_dagger = "hero"
    You took the dagger. The crown on the hilt was cold. # item:crown_dagger
    ->->
* ["Keep it. Remember both."]
    ~ velior_dagger = "velior"
    "Keep it," you said. "Remember both." # spk:hero
    Velior slipped the dagger into his belt. # item:crown_dagger # to:velior
    ->->

= exile
~ velior_fate = "exiled"
"Go," you said. "I won't kill you. But I won't have you near me." # spk:hero
Velior stood up. He did not argue. He did not plead.
"The secret way is a crack behind the third pillar of the foundry, counting from the stairs," he said. "Maybe you'll find it yourselves. Unlikely. But you might." # spk:velior
He did not take the dagger. He left it on the stone.
"His gift. I don't need it any more. Maybe it'll be of use to you. It cuts what ordinary steel won't. That's all I know about it." # spk:velior
He walked off into the darkness of the hall without looking back. His footsteps died away almost at once: here footsteps always died away at once.
~ velior_dagger = "taken"
The dagger stayed where it lay. You picked it up, so that it would not just lie there. # item:crown_dagger_taken
"He'll be back," said Garret. "His kind always come back. The question is, for whom." # spk:garret
->->

= kill
~ velior_fate = "killed"
~ add_darkness(10)
You took the dagger from the table.
Velior understood at once. He did not get up, did not reach for his belt. He only straightened.
"All right," he said. "That's fair." # spk:velior
Irena stepped towards you. Garret took her by the arm and held her back. Not hard. She could have pulled free. She did not.
"Don't," she said. Not to you. To God, perhaps. # spk:irena # mood:tense
It was quick. He saw to that himself: at the last moment he leaned forward.
"The house of Tal," he said. His lips would no longer obey him. "They hid well. Sixty years." # spk:velior
He said nothing more.
~ velior_dagger = "taken"
The dagger stayed in your hand. The crown on the hilt was warm. You did not wipe it. # item:crown_dagger_taken
Irena prayed aloud, loudly, so that you would hear every word. Garret turned to the hearth and stood like that for a long time.
"I've seen this before," he said at last, without turning round. "I've done it myself. I thought you were different." He paused. "I'm with you. I just thought." # spk:garret
->->
