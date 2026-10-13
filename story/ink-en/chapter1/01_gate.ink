// Chapter 1, scene 1. "The gate". English parallel of story/ink/chapter1/01_gate.ink.
// About 10 minutes with chapter battle 1. Garret leads the party past the upper-level post.

VAR ch1_gate_disguise = false   // reached the post posing as an escort: the party moves first

=== gate ===
Past the gates it was dark and close, and it smelled of wet stone. Somewhere ahead the lift's windlass creaked, steady as a sleeper's breathing.
{
- interrogation == "dead":
    You looked back at the entrance. Brandt's body was no longer by the gates. Irena looked back too, and said nothing.
- else:
    You looked back at the entrance. Where they had left Brandt there was only a cut rope.
}
Garret raised a hand, and you stopped.
"There's a post ahead," he said under his breath. "The Upper Windlass. Four on shift, one on the walkway with a bow. Sergeant Holt. We drank from the same flask for three winters." # spk:garret
"And what does that mean?" asked Irena. # spk:irena
"That he'll know me at twenty paces. And that he's a fair shot." # spk:garret
{ garret_hunters_scared:
    He was quiet for a moment.
    "One more thing. That crossbowman you scared off at the stream. He was headed here. If he got here first, Holt's waiting for us." # spk:garret # mood:tense
}
* ["You go first as the escort. We're runaways you've caught."]
    -> disguise
* ["Then we don't give him twenty paces. We hit them at once."]
    -> attack

= disguise
"You go first, as the escort. Irena and I are runaways you've caught." # spk:hero
Garret looked at you, then at his Crown-issue boots.
"The funny thing is, it isn't even a lie. That's how I used to walk. Every day." # spk:garret
He tied your hands with a slipknot that came loose with one tug, and walked ahead, scuffing his feet loudly.
{ garret_hunters_scared:
    -> disguise_fails
- else:
    -> disguise_works
}

= disguise_works
"Halt! Who goes there?" # spk:holt
"One of yours, Holt. Bringing in two runaways from the woods." # spk:garret
The pause was a long one.
"Garret?" The sergeant's voice changed. "Garret, they struck you off. They said you'd..." # spk:holt
"They said," Garret agreed, and came three steps closer. # spk:garret
~ ch1_gate_disguise = true
You tugged the knot. # battle:chapter1_1
-> after_fight

= disguise_fails
"Halt. Not one step more." # spk:holt
A bowstring creaked on the walkway.
"Garret. And with you, I take it, the one who's 'leading a lot of people'. Your friend with the crossbow told us everything. Let go of their hands, don't shame yourself." # spk:holt
"Pity," said Garret. "I really did just want to walk through." # spk:garret
You tugged the knot. # battle:chapter1_1
-> after_fight

= attack
"Then we don't give him twenty paces." # spk:hero
Garret nodded, as if he had been waiting for it.
"Walkway on the left. The archer first, or he'll count every one of us off right here." # spk:garret
You came out of the dark all at once. # battle:chapter1_1
-> after_fight

= after_fight
Holt sat against the wall, clutching a broken arm to his chest. Garret squatted in front of him.
"Say it again. That they struck me off." # spk:garret
"Struck off," Holt breathed. "Like everyone. Everyone gets struck off down here, Garret. First the prisoners. Then us." # spk:holt # mood:tense
{ ch1_gate_disguise:
    "You let me in. Why?" # spk:garret
    "Because I was glad, like a fool. I thought you were alive." # spk:holt
}
Garret stood up without answering.
On the board by the post hung an allocation sheet: which columns went to which barracks. A clerk's hand, uneven, blotted. Not that other one, neat and polite.
{ column_choice == "trail":
    You found the line at once: "Column from Ashmoor, 38 head. Barracks three."
    Thirty-eight. You had not known how many there were when you walked away from the fires. Now you knew.
- else:
    There was no column from Ashmoor on the list. It took you a moment to understand what that meant, and then you understood, and it became a little easier to breathe.
}
"The overseers' camp is further down the tunnel," said Garret. "It's shift change, so it'll be empty. Nearly." # spk:garret
// On the post map the party walks freely: Holt's guardhouse (hunt clue), the side working (nook 1).
+ [Go down the tunnel to the overseers' camp. #obj:drift_on]
-
->->
