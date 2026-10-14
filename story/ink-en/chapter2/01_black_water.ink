// Chapter 2, scene 1. "Black water". English parallel of story/ink/chapter2/01_black_water.ink.
// About 12 minutes including the chapter's first battle. The voice in the water.

VAR liara_ch2_heard = false

=== black_water ===
The stairs from the watch-hut went down, and after forty steps they ended in water. Black, still water, with a thin film of rust.
"From here we wade," said Velior. "Waist-deep. Sometimes chest-deep. Sometimes... well, we'll see." # spk:velior
Garret stepped into the water first and swore at the cold. Irena tucked up her hem and followed, holding her staff above her head.
The water was so cold that within a minute you stopped feeling your legs. Garret's lantern was reflected in it, trembling.
Then there were more reflections than lanterns.
"Stop," said Irena. # spk:irena # mood:tense
All around you heads were slowly rising out of the water. Wet hair, white eyes. The ones who drowned here when the tunnels flooded, and whom nobody bothered to bring up.
// Chapter battle 1: the drowned in the water. Teaches fighting in water: slow movement, cover.
The drowned came towards you. # battle:chapter2_1
-> after_fight

= after_fight
The last of the drowned sank under the water and did not rise again. It went quiet; only the ceiling dripped.
And in that quiet you heard a voice. Not from above, not from nearby, but from below, from the water itself, as if someone were speaking from the bottom.
"He is coming for her..." A woman's voice, soft, almost without breath. "Don't let him..." # spk:liara
~ liara_ch2_heard = true
* ["Who is coming? For whom?"]
    "Who is coming? For whom?" # spk:hero
    The water was silent. Only rings spread out from the place where you stood.
* [Put your hand in the water.]
    You put your hand in the water. The cold went up to your elbow, to your shoulder, to your heart. For a moment it seemed that someone's fingers touched yours. Then nothing.
-
"You're talking to someone again," said Irena. It was not a question. # spk:irena
"You didn't hear it?" # spk:hero
Garret shook his head. Velior did not answer at all: he was looking at the water, paler than usual.
{ liara_seen_ch1:
    You thought of the woman in white at the end of the tunnel. The voice was hers. You did not know how you knew.
}
"He is coming for her," you repeated aloud. "Who is he?" # spk:hero
"The King, maybe," said Garret. "Or maybe you. You're going after someone too." # spk:garret
{ spouse_f:
    He said "for her", and the first thing that came to your mind was a name: {sp()}. Then you thought the voice might have meant something else entirely.
- else:
    You thought that your own was a "him", not a "her". So the voice was speaking of someone else. Or not of the one you were thinking of.
}
// On the black water map the party moves freely: the flooded storeroom by the stairs (nook 1, clue 1).
+ [Go on down the tunnel. #obj:drift_on]
-
->->
