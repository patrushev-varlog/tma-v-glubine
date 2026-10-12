// Prologue, scene 5. "The deserter". English parallel of story/ink/prologue/05_deserter.ink.
// About 15 minutes with battle 3. Meeting Garret, the first fight as a party of three. Darkness does not change.

VAR garret_ambush = false          // attacked from ambush: the party moves first
VAR garret_hunters_scared = false  // the crossbowman left before the fight
VAR garret_trust_start = false     // the hero stood up for Garret against Irena

=== deserter ===
By evening the road ran down to a stream. A fire burned by the ford, and around it sat four men in overseers' leather jackets. A fifth, without a jacket, lay bound on the ground, face down in the wet grass.
"Get up, Garret," said one, and kicked him in the side. "Two days to the mines, and I didn't sign on to carry you." # spk:hunter
"Then untie my legs, Kort," answered the bound man, without lifting his head. "Or go on alone. I'll wait." # spk:garret
Irena touched your sleeve.
"Those are overseers," she whispered. "The same kind that took your people." # spk:irena # mood:tense
"So is the one tied up," you said. # spk:hero
They had taken his jacket, but his boots were Crown issue.
"All the more reason." # spk:irena # mood:tense
* [Ambush them while they sit by the fire.]
    ~ garret_ambush = true
    You nodded Irena towards the bushes on the far side of the ford. Strike now, and they would not even get to their feet.
    -> fight
* [Walk out to the fire and talk.]
    -> talk

= talk
You walked out to the fire with your empty hands in plain sight. The four got up. One of them was suddenly holding a loaded crossbow.
"Who are you?" asked Kort. # spk:hunter
* ["Let him go, and we part in peace."]
    "Let him go, and we part in peace." # spk:hero
    Kort laughed.
    "In peace. Hear that, Garret? They've come for you in peace. What are you to him, kin?" # spk:hunter
    "Nothing," said Garret from the grass. "{h("He", "She")}'s nothing to me. Leave while they're still laughing." # spk:garret
    -> fight
* ["There are more coming behind me. Many. Decide fast."]
    ~ garret_hunters_scared = true
    "There are more coming behind me. Many. If they find you here, you'll envy the ones you drive to the mines. Decide fast." # spk:hero
    The crossbowman looked at the dark forest behind you. Then at Kort. Then he lowered the crossbow without a word and walked off across the ford, not looking back.
    "Coward," Kort threw after him, and turned to you. "Three of us will do." # spk:hunter
    -> fight

= fight
// Battle 3: the hero and Irena against the overseers (three or four). In round 2 Garret breaks his ropes
// (or the hero cuts them by standing next to him) and joins the fight. Tutorial: taunt and "knock down".
// The game reads garret_ambush (the party moves first) and garret_hunters_scared (minus the crossbowman).
{ garret_ambush:
    Irena raised her staff. You picked a target.
- else:
    Kort drew a cleaver from its sheath.
}
The fight began. # battle:prologue_3
-> after_fight

= after_fight
Kort lay by the fire. Garret stood over him with a scrap of rope round his wrist, breathing hard.
{
- garret_ambush:
    "You fight well," he said to you. "From the bushes, no warning. I respect that." # spk:garret
- garret_hunters_scared:
    "'More coming. Many,'" he repeated, and snorted. "Nobody's coming, are they? You lie well." # spk:garret
- else:
    "You fight well," he said to you. "For someone who came 'in peace'." # spk:garret
}
Irena did not lower her staff.
"You're an overseer," she said. # spk:irena # mood:tense
"Was." # spk:garret
"How many people did you drive down there yourself?" # spk:irena # mood:tense
Garret did not answer. He was looking at you, as if it were yours to decide.
* ["He just fought for us. That matters more for now."]
    ~ garret_trust_start = true
    "He just fought beside us. For now that's enough." # spk:hero
    Irena pressed her lips together, but held her tongue. Garret gave you a short nod, the way men nod on parade.
* ["Irena is right. Answer her."]
    "Irena is right. Answer her." # spk:hero
    "Many," said Garret. "I didn't count. Back then it seemed like work." # spk:garret
    Irena turned away. She did not like the answer, but there was no lie in it, and she heard that too.
* ["All that matters to me now is the road. Do you know it?"]
    "All that matters to me now is the road. Do you know it?" # spk:hero
    "I know it," said Garret. "Better than I'd like." # spk:garret
-
"The column you're after is coming from the west," he said. "Before the descent they always stop for the night at the mine gates. They count heads and change the escort. Go straight across the Rust Hills and you'll make the halt." # spk:garret
"And the cart?" you asked. "The black one, with the crown." # spk:hero
Garret looked at you more closely.
"So someone of yours was taken by the list," he said. "Carts like that don't wait at the gates. They're let straight through." # spk:garret # mood:tense
He picked up a dead man's cleaver from the ground and weighed it in his hand.
"I'm coming with you. I left someone down there." # spk:garret
He stuck the cleaver in his belt and set off first towards the hills. Nobody asked whom he had left.
->->
