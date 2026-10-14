// Chapter 5, scene 5. "The finale". English parallel of story/ink/chapter5/05_finale.ink.
// ~8 minutes. The resolution of the chosen ending. Final battle in "Peace" (2 phases) and "The New Master" (3 phases).

=== finale ===
{
- ending == "love":
    -> love
- ending == "peace":
    -> peace
- else:
    -> master
}

= love
Edric walked out to the centre of the seal and knelt. {sp()} did not resist. Only looked at you while he took {s("his", "her")} hand.
{ darkness >= 75 && irena_confronted != "left":
    Irena rushed at them. Garret caught her, wrapped his arms round her, held her while she struggled and shouted something you could not make out. Then she stopped. She only wept.
}
A drop of blood fell on the stone.
The light of the seal went out. All of it, at once, like a candle blown out. In the darkness something sighed. Something vast, ancient, endlessly calm.
Then the floor shook, and you felt how far above, all across the kingdom, the dead were falling. All at once. Guards in the corridors, soldiers in their ranks, the dead by the vats. Like puppets whose strings had been cut.
The one who slept woke. And the first thing he did was what he had to do: he gave the dead back to death.
Edric fell with them. The threads under his skin went out one after another, and he toppled onto his side, still not letting go of {s("his", "her")} hand. He had been dead a long time. He simply had not noticed.
When the light came back, pale, ordinary, a woman in white rose at the centre of the seal.
Liara. Warm. With straight brows.
She looked at Edric at her feet. Politely. Without recognition. The way you look at a stranger in the street. Then she stepped over him and walked to the way out, evenly, without looking back. Her eyes were empty.
For sixty years he had not let go of her hand. She did not notice that he had let go.
{
- velior_fate == "forgiven":
    "I saw everyone he raised," Velior said quietly. "Not one came back as themselves. He knew. I didn't tell you before: you wouldn't have believed me. I wouldn't have believed it either." # spk:velior
- velior_fate == "exiled":
    Velior knelt by Edric's body and closed his eyes.
    "I told him," he said, without raising his head. "Not one of the raised came back as themselves. Not one." # spk:velior
}
Garret sat on a step, pressing his side where a guard's halberd had caught him. His palm was all blood. With a wound like that, you knew, no one gets up by morning.
"It doesn't hurt," he said, and looked at you. "Not at all. That can't be right." # spk:garret
{sp()} came over to you. Alive. Whole. Did not embrace you. Simply stood beside you.
"Let's get out of here," {s("he", "she")} said. "Please. Before he's fully awake." # spk:spouse
->->

= peace
// Final battle ("Peace" ending): phase 1 — Edric and the guards; phase 2 — the power of the half-woken Sleeper, the fallen rise.
The threads under Edric's skin flared, and the dead guards on the floor of the hall began to stir. # battle:chapter5_final_peace
Edric lay at the edge of the seal. The threads under his skin were going out.
{sp()} let go of your hand.
"Don't hold me back," {s("he", "she")} said. "Please. I want to do it myself." # spk:spouse
{ irena_confronted != "left":
    Irena began a prayer. Quietly, with her lips alone. The one read over those who are leaving.
}
{sp()} walked to the centre of the seal. Without looking back. Like walking into water.
The light rose to meet {s("him", "her")}. For a moment you saw two figures in it: one going in, the other coming out. They passed each other and, it seemed, their hands touched.
Then the light grew steady. Calm. The seal held.
Edric watched it from the floor.
"Now you'll understand me," he said. His voice was very weak. "In ten years. In twenty. You'll count the days. Then the years. Then you'll stop counting. And one day..." He coughed. "One day they'll tell you too that it was right. They'll give you a medal." # spk:edric
He closed his eyes.
"Liara didn't come," he said. "She walked past me. She didn't even look." # spk:edric
He said nothing more.
->->

= master
{ ending == "tyrant" && irena_confronted != "left":
    Irena did not step aside. She stood between you and the light, as she had promised, her staff raised.
    Garret took her by the shoulders and led her to the wall. She did not strike him. She would never have raised her staff against him, and he knew it.
    "I wouldn't have let you," she said to you over his shoulder. "If I could. Remember that I tried." # spk:irena # mood:sad
}
// Final battle ("The New Master" ending): phase 1 — Edric and the guards; phase 2 — the waking Sleeper; phase 3 — Edric tries to seize the power the hero is letting in.
You stepped into the light of the seal, and it poured into you like water through a breach. # battle:chapter5_final_master
You stood at the centre of the seal. There was something in you, vast. Ancient. Calm as winter.
Edric lay at your feet. He did not try to get up.
"Let me go," he said. "Please. You can now. You hold death. Let me go to it." # spk:edric
"At last I can die," he said, and it sounded like gratitude. # spk:edric
You let him go. It was easy. Too easy.
Above the seal rose a woman in white. Free. She looked at you.
{ ending == "guardian":
    "Thank you," said Liara. "Do you understand what you have done?" # spk:liara
    "Yes." # spk:hero
    "Then it will be easier for you than for him." # spk:liara
    She smiled. Bitterly. And went up, through the stone, to where, perhaps, there was sky.
- else:
    "Thank you," said Liara. Bitterly. "You freed me. And took his place. Not mine. His." # spk:liara
    She left without looking back. As she had once walked past Edric.
}
{sp()} stood at the edge of the seal. Alive. Free. And looked at you as if seeing you for the first time.
->->
