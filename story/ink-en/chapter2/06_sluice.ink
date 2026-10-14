// Chapter 2, scene 6. "The sluice". English parallel of story/ink/chapter2/06_sluice.ink.
// About 10 minutes including the chapter's third battle. The sluice warden, the way into the Dwarven Halls.

=== sluice ===
The sluice turned out to be a huge stone wall across the tunnel, with a gate of black iron. Above the gate runes were cut: angular, deep, plainly not human.
{ hero_class == "wizard":
    You could read one of them: "Hold". Just "hold". With no word on what.
}
At the foot of the gate, waist-deep in water, sat something large. At first you took it for a heap of rags. Then the heap raised its head.
It was people. Several people, sewn into one body with thick wire, with a chain round its neck fixed to the gate. Someone had set it here on guard and forgotten it.
"The dwarves never made that," Garret said quietly. "That's ours. That's from our workshops." # spk:garret
The warden stood up, and water poured off it in streams.
// Chapter battle 3: the sluice warden, a drowned giant sewn together from several bodies.
// If the fugitives were not handed over, they wait behind and do not interfere.
The chain went taut. # battle:chapter2_3
-> after_fight

= after_fight
The warden sank into the water and went still. The chain slackened.
Garret and Velior threw their weight on the gate lever together. The iron groaned, and the water began to drain: first in a thin trickle, then with a roar, into the blackness beyond the wall.
When it was gone, a staircase opened behind the gate. Broad steps, cut for a short stride, went down towards carved arches.
"The Dwarven Halls," said Velior. "I never went further than this. Not even on his orders." # spk:velior
// On the sluice map after the battle: the small lever and the chapel grate (hunt site). The stairs are the point of no return:
// the game first calls hunt_leave_check(2) (explore_common.ink).
+ [Go down the stairs. #obj:stairs]
-
->->
