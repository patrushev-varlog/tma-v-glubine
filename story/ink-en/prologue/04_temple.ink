// Prologue, scene 4. "The ruined temple". English parallel of story/ink/prologue/04_temple.ink.
// About 10 minutes with battle 2. Meeting Irena. Darkness does not change.

VAR irena_hesitation_respected = false

=== temple ===
By noon the road brought you to an old temple at a fork. Its roof had long since fallen in, but services had been held there to the last: fresh fir branches lay at the threshold.
Singing came from inside. One voice, a woman's, steady. Then it broke off in the middle of a line.
* [Go in.]
    -> inside
* [First look through the gap in the wall.]
    Through the gap you could see the altar, the candles and people on the benches. The people sat too straight. Not one of them had stirred while the woman sang. Now they were all stirring.
    -> inside

= inside
At the altar stood a priestess in grey, with a staff from which hung a small cracked bell. The parishioners were rising from the benches and walking towards her, slowly, the way people walk up for a blessing.
"Marta," said the priestess, without raising her voice. "Marta, sit down. You know me. Oswin..." # spk:irena # mood:tense
Oswin had no arm. He did not sit.
The priestess saw you in the doorway.
"Don't touch them!" It rang out like an order, and at once, more quietly: "No. Help me. I can't... I named every one of them at that font." # spk:irena # mood:sad
{ hero_class == "cleric":
    You knew her vestments: a sister of the same order that taught you your prayers. The same words, the same bell on the staff. Only her bell was dented.
}
// Battle 2: the hero and Irena. For the first two rounds Irena only defends, then "Forgive me" and hallowed ground.
The dead turned towards you. # battle:prologue_2
-> after_fight

= after_fight
The last of the parishioners fell by the altar, and the candles around him went out all at once, as if someone had breathed on them.
The priestess stood in the middle of a circle of scorched earth that she had kindled herself. The staff trembled in her hand.
"I am Sister Irena," she said, looking not at you but at the benches. "This was my parish. Forty-three souls. I counted them." # spk:irena # mood:sad
* ["Say goodbye to them. I'll wait."]
    ~ irena_hesitation_respected = true
    -> farewell
* ["The dead don't care any more. The living do."]
    -> hurry

= farewell
You waited by the door. Irena went round the temple and called each of them by name, without a prayer. It took a long time. You did not hurry her.
Then she came over to you, and her eyes were dry.
"Thank you. Few would have waited. Especially now." # spk:irena
-> join

= hurry
"The dead don't care any more. The living do. I have to go." # spk:hero
Irena looked at you as if you had struck her. Then she nodded.
"You're right. That's what is hard: you're right." # spk:irena # mood:tense
-> join

= join
"Where are you going?" # spk:irena
* [Tell her everything: the raid, the cart, the "list".]
    You told her. About the bell, about the cart with the crown, about the sheet on which {sp()} stood apart from everyone else.
* ["North. To the mines."]
    "North. To the mines." # spk:hero
    She looked at your hands, at the blood on your sleeve, and did not ask why.
-
"A week ago a man with the royal seal came here," said Irena. "A scribe. He wrote down my parishioners. And last night they rose. All at once, as if someone had called them by that list." # spk:irena # mood:tense
She lifted the staff, and the cracked bell gave a dull clink. # sfx:handbell
"I'm coming with you. I want to look into the eyes of whoever draws up lists like that. And ask what he wants with my parishioners." # spk:irena
{ hero_class == "wizard":
    She straightened the bell on her staff and added:
    "Against the dead we could use someone who knows their magic. It seems we're in luck: we have such a person." # spk:irena # mood:tense
    It did not sound entirely like praise.
- else:
    "Against the dead we could use someone who knows their magic," she said, already stepping out onto the road. "But all we have is us." # spk:irena
}
->->
