// Chapter 4, scene 1. "The works". English parallel of story/ink/chapter4/01_workshops.ink.
// ~12 minutes including the chapter's battle 1. A conveyor of dead soldiers and the chapter's first story temptation.

VAR ch4_vats = ""   // "whisper" — the whisper drained the vats (+5 Darkness, all saved), "hands" — by hand (seven saved)

=== workshops ===
The heat came before the light. First the stone grew warm under your palm, then the air, then it was hard to breathe. A burnt smell seeped from the cracks in the walls.
Then the tunnel led out onto a gallery, and you saw the works.
Below, in a vast working, a conveyor was running. A chain of prisoners, naked, shaven, went from the gates to a long row of vats full of black, thickly smoking slurry. The overseers took the chain off each one and laid them in a vat, the way you lay washing in a tub. From the far end of the row the dead came out of the vats. In armour. In ranks. With the same empty faces.
No one screamed. That was the worst of it.
"So this is where the columns went," said Garret. His voice was dry. "All these years. I thought it was for ore." # spk:garret
{ velior_fate == "forgiven":
    "I knew," said Velior. "I never saw it. But I knew." # spk:velior
}
{ column_choice == "trail":
    You thought of the column at the gates of Ashmoor. Of the neighbours driven into the mine while you chased the cart. You looked at the faces by the vats and were afraid to know even one.
}
Irena gripped her staff in silence, so hard her knuckles went white.
One of the overseers below raised his head. He saw you.
// Chapter battle 1: vat soldiers and workshop overseers. The dead fight in formation, the overseers raise the fallen.
Below, someone struck a gong. # battle:chapter4_1
-> after_fight

= after_fight
The conveyor stopped. In the silence that followed you could hear the vats bubbling.
The last twelve still held people. Alive, sunk to the chest, to the neck, their eyes glazed. The slurry was slowly rising.
The valves were worked by dead operators: chained to the levers, they went on working after the overseers were gone. Slowly. Evenly.
"The valves are rusted," said Garret, already moving. "Breaking them will take a long time." # spk:garret
{
- hero_class == "wizard":
    The whisper was close. It said: they are dead, they will obey you. One word, and every valve opens at once. You knew that word. You had known it since the temple.
- hero_class == "cleric":
    You reached for a prayer, and the prayer answered. Only the voice that answered was not the one you had called on. It said: the dead will obey. Command them.
- else:
    The whisper was close. It said: they are dead, they will obey. You can hear me already. You have always heard me.
}
* [Command the dead to drain the vats.]
    ~ ch4_vats = "whisper"
    ~ add_darkness(5)
    -> whisper
* [Break the valves by hand.]
    ~ ch4_vats = "hands"
    -> hands

= whisper
You said the word. It was short and cold, and for a moment your tongue went numb.
The dead operators turned their heads. All twelve. And pulled the levers down at once.
The slurry drained away with a long sucking sound. Twelve people were left lying at the bottom of the vats, coughing, alive.
Irena rushed to pull them out, without looking at you.
Garret looked. For a long time.
"Quick," he said. "Very quick." # spk:garret
{ velior_fate == "forgiven":
    "That's how he started too," Velior said quietly, to no one. "So I was told. First it was to save people." # spk:velior
}
-> leave

= hands
The {velior_fate == "forgiven":four|three} of you broke the valves. Garret hammered at them with the back of his cleaver, Irena held up the heads of those who were drowning, you hauled on the levers until the skin tore from your palms.
It took a long time. The slurry rose.
When the last valve opened, there was no one left to pull out of five of the vats. In seven, people were still alive.
Irena closed the eyes of each of the five. Herself, one after another, looking at no one.
"Seven," said Garret. "Seven is a lot. You hear me? Seven is a lot." # spk:garret
He was saying it to you. Or to himself.
-> leave

// On the works map after the vats: the wall of names by the gates, the smithy at the end of the row of vats (side spot 1)
// and the grey-haired prisoner by a cooled vat (only if the valves were broken by hand).
= leave
+ [Climb the stairs to the works office. #obj:office_stairs]
-
->->
