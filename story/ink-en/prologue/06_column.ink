// Prologue, scene 6. "The column". English parallel of story/ink/prologue/06_column.ink.
// About 10 minutes with battle 4 (the grey prototype battle). The main moral choice of the prologue.

VAR column_choice = ""   // "neighbors": freed the neighbours, "trail": went after the cart

=== column ===
You came out of the Rust Hills at nightfall. From the crest you could see the mine gates: two stone pillars driven straight into the mountain, and between them a black gap that breathed out cold.
Fires burned below the hill. Around them sat bound people, ten to a rope. You knew those backs. The Haskers. The smith's wife. Oldric's boy, very small among the grown-ups.
And along the road to the gates the black cart was rolling slowly, the yellow crown on its side. The escort's torches gleamed in the wet earth. A little longer, and it would vanish into the mountain.
"Not many guards at the fires, six or so," said Garret. "They change at dawn. Four with the cart, but there's more watch at the gates." # spk:garret
"If we go for the cart, the fires will raise the alarm," said Irena. "They'll drive your neighbours inside tonight." # spk:irena # mood:tense
"And if we go for the fires, the cart gets away," said Garret. "To the bottom. Nobody comes back from there." # spk:garret
They fell silent, and both of them looked at you.
"Those are your people down there by the fire," Irena said quietly. "Every one of them." # spk:irena
"Decide," said Garret. "I made my choice once already. The wrong one." # spk:garret
* [Free the neighbours. The cart gets away.]
    ~ column_choice = "neighbors"
    -> neighbors
* [Catch the cart. The neighbours stay.]
    ~ column_choice = "trail"
    ~ add_darkness(10)
    -> trail

= neighbors
You watched the cart until it rolled through the gates. You watched until the last torch of the escort went out.
Then you turned to the fires.
"Come on," you said. # spk:hero
Irena let out a breath as if she had not breathed all this time.
// Battle 4 at the fires.
The party went down the hill. # battle:prologue_4_camp
-> neighbors_after

= neighbors_after
The ropes were cut with Garret's knife, one at a time. Your neighbours got to their feet, not believing that no one held them any more.
{ buried_neighbors:
    "Oldric said you buried our dead," said the smith's wife. "Before you came after us. We won't forget." # spk:neighbor
- else:
    The smith's wife took your hand without a word and held it for a long time.
}
Oldric's boy looked up at you.
"Where's {sp()}?" # spk:boy
You found no answer.
"In the woods past the hills there's an old charcoal burners' camp," Garret told the neighbours. "Runaways go there. Go while it's dark." # spk:garret
Irena watched them leave.
"You did right," she said. # spk:irena
Garret stood to one side, scraping bits of rope off his knife. Only when the last neighbour had disappeared into the woods did he speak, to no one in particular:
"I chose strangers once too." # spk:garret
By the dead fire they found a wounded overseer with the "list" inside his coat. Brandt.
->->

= trail
"The cart," you said. # spk:hero
Irena looked at the fires, at the bound people, at the boy. Then at you.
"They saw you come for them," she said. "They'll see you leave." # spk:irena # mood:tense
Garret was already going down the slope to the road.
// Battle 4 at the gates. The cart breaks through.
The party rushed to cut it off. # battle:prologue_4_gate
-> trail_after

= trail_after
You reached the cart first and tore back the canvas.
It was empty inside. Only straw and a scrap of rope. Still warm.
"{s("He", "She")} was handed on," said Garret, looking into the gates. "While we were running. There's a lift down there." # spk:garret
Behind you there was shouting. At the fires the escort was getting people up and driving them into the mountain's mouth, ahead of time, at a run. One of your neighbours looked back at you. You could not make out who.
"You made a choice," said Irena. Her voice was even, as when she sang. "I won't say it was the wrong one. I'll say I saw it." # spk:irena # mood:tense
Garret put a hand on your shoulder, briefly and heavily.
"I understand," he said. "Better than you think." # spk:garret
Under the wheel lay a wounded overseer with the "list" inside his coat. Brandt.
->->
