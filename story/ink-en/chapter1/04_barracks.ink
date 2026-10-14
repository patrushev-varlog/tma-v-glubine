// Chapter 1, scene 4. "The barracks". English parallel of story/ink/chapter1/04_barracks.ink.
// About 15 minutes with chapter battle 2. The main choice of the chapter: a riot or a quiet passage.

VAR ch1_choice = ""           // "riot": raised a riot, "slip": slipped quietly to the lift
VAR garret_tag_found = false  // Garret found his wife's tag (legendary amulet "His Wife's Tag")

=== barracks ===
The barracks stood along a long gallery, cut straight into the rock: bars instead of walls, bunks three high, and a smell that made Irena cover her face with her sleeve.
The prisoners lay on the bunks or sat by the bars. Alive. Beside them, behind the same bars, stood the dead: motionless, faces to the wall, like tools put away until morning.
At the bars of the nearest barracks a thin woman with a shaved head got to her feet.
"Garret," she said. Not surprised. Just naming him. # spk:meb
Garret stopped.
"Mab." # spk:garret
"You stood over us with a whip. Two years." She looked at the others. "And whose side are you on now?" # spk:meb # mood:tense
"This was a penal mine under the old king too," Velior told you quietly. "But the lower levels the King took for himself long before the throne. Through men of straw, from the treasury. Up top they thought they were digging for ore down there." # spk:velior
Garret did not answer. You answered for him:
* ["He's with us. And we've come for you."]
    "He's with us. And we haven't only come for our own." # spk:hero
    Mab looked at you for a long time.
    "We'll see," she said. # spk:meb
* ["He's with us. The rest can wait."]
    "He's with us. The rest can wait." # spk:hero
    "Nothing waits down here," said Mab. # spk:meb
-
{ column_choice == "trail":
    Someone cried out from deep in the barracks. A boy pushed his way to the bars, thin, filthy, with Oldric's eyes.
    Behind him came the Haskers. The smith's wife. They looked at you and said nothing.
    The boy asked only one thing:
    "Where's {sp()}?" # spk:boy
    You found no answer. Again.
}
Velior came back out of the dark of the tunnel without a sound, as if he had grown out of the wall.
"The lift's round the next bend," he said. "It goes down once a shift. The next descent is soon. Six guards at the cage." # spk:velior
He paused and added more quietly, just to you:
"Your person went down on it yesterday. Handled gently, like glass. I asked a dead porter. They remember everything they've carried." # spk:velior
{ hero_class == "wizard" || interrogation == "dead":
    You looked at him. Velior shrugged.
    "Not the way you do it. I just know how to listen to what they mutter. It isn't the same thing." # spk:velior
}
"If we raise the barracks," said Irena, "we take everyone out." # spk:irena
"If we raise the barracks," said Velior, "we'll be at it till morning, the guards at the lift will hear, and the cage will go down without us. The dead aren't going anywhere. Nor are the living. But the lift will go." # spk:velior
{ garret_trust_start:
    "I say the barracks," said Garret. "I owe them. You know that." # spk:garret
- else:
    Garret looked at Mab and said nothing.
}
Everyone looked at you. Again.
* [Raise a riot. Get everyone out, however long it takes.]
    ~ ch1_choice = "riot"
    -> riot
* [Slip quietly to the lift. The prisoners stay here.]
    ~ ch1_choice = "slip"
    ~ add_darkness(10)
    -> slip

= riot
"We open them," you said. # spk:hero
Mab smiled for the first time. It was a terrible smile, with half the teeth gone.
"The keys are with the shift boss. He's in the guardroom. And they'll raise the dead in the barracks as soon as the noise starts." # spk:meb
"Then the noise will be short," said Garret, and drew his cleaver. # spk:garret
// Battle 2: riot in the barracks. The prisoners fight beside the party (AI-controlled allies).
The bars began to rattle. # battle:chapter1_2_riot
-> riot_after

= riot_after
The barracks were empty within the hour. The prisoners left by an old tunnel for the surface, for the runaways' camp everyone whispered about and nobody had seen.
{ column_choice == "trail":
    Oldric's boy lingered at the way out.
    "I'll tell my father you came," he said. "That you did come after all." # spk:boy
}
// On the barracks map: the foreman's hut (nook 3), the old prisoner by the bars (hunt clue).
+ [Follow Garret into the guardroom. #obj:guardroom]
-
In the guardroom Garret found a box of tags: copper tokens, one for every prisoner who had died here. He sorted through them for a long time, until he found one. Then he closed his fist on it and said nothing.
~ garret_tag_found = true
"Her name was Annet," he said later, when you were already walking to the lift. That was all he told you. # spk:garret
Somewhere ahead, by the lift, a gong sounded. The alarm.
->->

= slip
"We go to the lift," you said. "Quietly." # spk:hero
Irena looked at you the same way she had at the temple. But this time she said nothing, and that was worse.
Mab stepped back from the bars. She did not spit, did not shout. She simply went back into the barracks, to her own.
{ column_choice == "trail":
    Oldric's boy stayed standing at the bars. He watched your back until you turned the corner.
}
{ garret_trust_start:
    Garret followed you. Only at the bend did he look back at the barracks, once.
- else:
    Garret followed you in silence.
}
// On the barracks map on the way to the lift: the foreman's hut at the end of the gallery (nook 3).
+ [Go on to the lift. #obj:gallery_end]
-
Half the way you went quietly. Then a patrol came out of a side tunnel, and the quiet was over.
// Battle 2: a patrol in the tunnel. The prisoners don't help.
"Stand where you are!" # spk:overseer # battle:chapter1_2_patrol
-> slip_after

= slip_after
The patrol went down in the narrow tunnel. There was not much noise. The lift was still there.
"Quick," said Velior approvingly. "Very quick." # spk:velior
Garret wiped his cleaver and said, looking at no one:
"There's a box of the dead's tags in the guardroom by the barracks. I could have looked there for... one." He paused. "Doesn't matter. I wouldn't have anyway." # spk:garret
->->
