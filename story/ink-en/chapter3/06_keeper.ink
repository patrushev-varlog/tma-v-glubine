// Chapter 3, scene 6. "The keeper of the seal". English parallel of story/ink/chapter3/06_keeper.ink.
// About 10 minutes including the chapter's third battle. Torvin the Voiceless and the dwarves' legacy for the hero.

=== keeper ===
The hall of the seal opened below you, seen from a gallery. Far below lay a slab. Huge, round, smooth as the surface of a lake. Cracks ran across it, and pale light seeped from the cracks.
"Is that it?" asked Garret. "The seal?" # spk:garret
"That's what lies on top," said Velior. "The seal itself is deeper. At the bottom. Where he's taking..." He broke off. "There's no way down from here. Only looking." # spk:velior
// On the gallery map: a collapsed side passage with the fugitives' bones (nook 2, an ingot). The keeper is at the far end.
+ [Walk along the gallery towards the figure at the edge. #obj:torvin]
-
At the edge of the gallery, his back to you, stood a dwarf. Not sitting, like the ones in the archive, but standing, leaning on a long-handled hammer. His armour had gone green with patina, and his beard fell to his belt in plaits bound with iron.
He had no mouth. Where his mouth should have been was an iron muzzle, riveted to the jaw.
{ hero_class == "wizard":
    There were runes on the muzzle. You read: "Torvin. Gave his voice so as not to wake him."
- else:
    Runes were struck into the muzzle. Velior read them in a whisper: "Torvin. Gave his voice... so as not to wake him." # spk:velior
}
The keeper turned. His eyes were empty, like those of the dead in the archive. But he did not move like the dead. He moved like a soldier who has stood at his post so long that he has forgotten he may leave it.
He raised the hammer.
"We haven't come for the seal," you said. "We're only looking." # spk:hero
The keeper could not answer. He only shook his head. Slowly, heavily. No one. To no one. Never.
// Chapter battle 3: Torvin the Voiceless, the last keeper of the seal. His hammer blows shake the gallery.
The hammer came down. # battle:chapter3_3
-> after_fight

= after_fight
Torvin fell to one knee. The hammer slipped from his fingers and rolled to the edge of the gallery, but did not fall: it stuck between the slabs.
The keeper raised his head. For a moment his eyes were different: alive, tired, very old.
He reached to his belt, unfastened something and held it out to you. His hand was shaking.
There were no words, and there could be none. But you understood what he meant. "Take it. We could not hold on."
{
- hero_class == "wizard":
    It was a staff of black stone, without a single rune. The stone was warm and quiet. The whisper that had always been with you fell silent beside it, for the first time in many days. # item:silent_legacy
- hero_class == "fighter":
    It was a blade of dull dwarven steel, shorter than yours, heavier than yours. On the blade, cut deep, a single word: "Hold." # item:silent_legacy
- hero_class == "rogue":
    It was a dagger without a guard, thin as a needle, and so quiet that it did not ring when you took it in your hand. A weapon for one who must come and go without waking anyone. # item:silent_legacy
- else:
    It was a pendant: a stone disc with a hole in the middle. Emptiness at the centre.
    You understood what none of your companions would have understood. The dwarves had not prayed to emptiness. They had prayed for the one who sleeps, that he would go on sleeping. The way people pray at a sickbed: do not wake him. When you put the disc on, it became easier to breathe. # item:silent_legacy
}
Torvin closed his eyes. He did not open them again.
"He was waiting," said Irena. "He stood here for hundreds of years, waiting for someone to give it to." # spk:irena
"Or waiting for someone to stop him," said Garret. "I don't know which is worse." # spk:garret
+ [Go back to the forge. #obj:gallery_out]
-
->->
