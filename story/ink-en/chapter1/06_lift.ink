// Chapter 1, scene 6. "The lift". English parallel of story/ink/chapter1/06_lift.ink.
// About 12 minutes with chapter battle 3. An ambush at the cage, the descent to the lower levels.

=== lift ===
The lift platform hung over the shaft on thick beams. The cage stood at the edge: an iron basket on chains, big enough to take a cart.
{
- ch1_choice == "riot":
    The alarm had already run through the tunnels. They were waiting at the cage: there were more guards than Velior had said, and one of them held a torch by the signal horn.
    Noise came from the gallery behind you. The prisoners who had not gone up to the surface were following.
    "They're with us," said Garret. "Not all of them. But some." # spk:garret
- else:
    There were six guards, just as Velior had said. They were not expecting you. But there was no help to expect either.
}
"The cage goes as soon as someone pulls the lever," said Velior. "The lever's over there. If they realise up top that we're inside, they'll just drop us." # spk:velior
"Then we pull the lever," you said. # spk:hero
// Battle 3: ambush at the lift. With the riot there are more enemies, but the prisoners draw some off.
// With the quiet passage there are fewer enemies and no help. The game reads ch1_choice.
The guards at the cage raised their weapons. # battle:chapter1_3
-> after_fight

= after_fight
// On the platform map after the fight: the boarded drift at the side (hunt site). The lever is the point
// of no return: the game calls hunt_leave_check(1) first (explore_common.ink).
+ [Pull the cage lever. #obj:lever]
-
The chains creaked. The cage jerked and started down.
The light of the platform drew away upwards, became a square, then a point. Then it was gone. Only Garret's lantern and a cold wind from below, as if down there something very large was breathing.
{ ch1_choice == "riot" && column_choice == "trail":
    The last thing you saw up top was Oldric's boy at the edge of the platform, his hand raised.
}
Velior stood at the bars of the cage, looking down.
"Do you know the difference between the upper levels and the lower ones?" he said without turning round. "Up top they count people by heads. Down below, by names." # spk:velior
* ["How do you know?"]
    "How do you know? You said they wouldn't even let you down there." # spk:hero
    Velior was silent one second longer than he needed to be.
    "I heard," he said. "I've heard a lot of things. It was my job." # spk:velior # mood:smile
* [Say nothing.]
    You said nothing. Neither did Irena, standing beside you. But you noticed that she had remembered those words.
-
->->
