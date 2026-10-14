// Chapter 5, scene 4. "The offer". English parallel of story/ink/chapter5/04_offer.ink.
// ~10 minutes. Edric in the flesh, his last offer and the final choice.

VAR ending = ""   // "love" / "peace" / "guardian" / "tyrant"

=== offer ===
Edric Sayr, the Pale King, entered the hall of the seal on foot.
No retinue. No crown. An old, stooped man in that same high-collared robe, only now you could see his face. The skin was almost transparent, and under it dark threads showed, like Gessar's, only thicker. The eyes were alive. Very alive and very tired.
{ velior_fate == "exiled":
    At his shoulder, a step behind, walked Velior. He did not look at you. He looked at the floor.
    "You see," said Edric. "He came back. They never have anywhere else to go." # spk:edric
    "I walled up the crack behind the pillar myself," said Velior, without raising his eyes. "That was the price for him to take me back." # spk:velior
}
"Well then," said Edric. "Everyone is here at last." # spk:edric
He looked at the two of you. For a long time.
"You are like us," he said quietly. "You have no idea how much." # spk:edric
{ ch3_diary_read:
    "You read my diary. So you know how it was. Two hundred and forty-one steps. She wanted to tell her grandchildren." # spk:edric
}
{
- ch4_arithmetic == "refuse":
    "You refused to play in the foundry. Broke my lantern." He almost smiled. "I was the same. At first." # spk:edric
- ch4_arithmetic == "pass":
    "You walked past the cages. Didn't look back. You already know how it's done." # spk:edric
- else:
    "You paid twenty for ten. Good arithmetic. I checked." # spk:edric
}
{ ring_taken:
    "And you're wearing my gift." He nodded at the ring. "It suits you." # spk:edric
}
{ hero_class == "wizard":
    "You could have become me," he added. "A better me. You hear the whisper and you're not afraid of it. It took me twenty years to stop being afraid." # spk:edric
}
{ ch5_hunt_done:
    You took out the council seal and laid it on the stone between you. A tower over three stars.
    Edric fell silent mid-word. His hand twitched towards the seal and stopped.
    "You found the order," he said. His voice broke, for the first time. "And the note." He looked away. "She agreed for her sister's sake. I learned that twenty years later. From the stone." # spk:edric
    He straightened, and his face was polite again.
}
"I won't fight you unless I have to. I'm too old for it, and you're too good. I'll offer you a bargain." # spk:edric
"Let me finish the ritual. Your beloved's blood will wake the one who sleeps. Whoever wakes him gains power over death. I'll bring Liara back. You'll have your beloved alive. Whole. For ever." # spk:edric
"The world?" He spread his hands. "The world has already betrayed us both. The council gave away my Liara and decorated me for it. The king gave your village to the dead. Why should we protect it?" # spk:edric
{sp()} squeezed your hand.
"Don't," {s("he", "she")} said. "I've already decided." # spk:spouse
-> companions

= companions
{
- darkness >= 75 && irena_confronted != "left":
    Irena stepped forward and stood between you and the centre of the seal. Staff in hand, the bell on it silent.
    "I won't let you," she said. "Not to him, not in there. You're not the one I followed any more. I remember who you were. I won't let you do what he did." # spk:irena # mood:tense
- irena_confronted != "left":
    "The world matters more than one person," said Irena. Quietly, without pressing. "I've said that all my life. And I'll say it now. But it isn't mine to decide. And not yours alone. {s("He", "She")} has already decided." # spk:irena # mood:sad
}
"I understand you better than anyone," said Garret. "I'd have given the world for Annet. Without a second thought." He paused. "But I don't know if she'd have forgiven me. Think about that. Not about the world. About {s("him", "her")}." # spk:garret
{ velior_fate == "forgiven":
    "I served him," said Velior. "I'm the last one with any right to advise you. Decide. I'll follow you whatever you answer." # spk:velior
}
Everyone waited.
* ["Finish the ritual. Bring her back. And give {s("him", "her")} back to me."]
    ~ ending = "love"
    -> choice_love
* [Respect {s("his", "her")} choice. Stand against Edric.]
    ~ ending = "peace"
    -> choice_peace
* ["Not you, not the world. Me." Step into the seal yourself.]
    { darkness >= 75:
        ~ ending = "tyrant"
    - else:
        ~ ending = "guardian"
    }
    -> choice_self

= choice_love
"Finish the ritual," you said to Edric. "Bring her back. And give {s("him", "her")} back to me." # spk:hero
{sp()} looked at you as {s("he", "she")} never had before. Not in anger. In horror.
"You're deciding for me again," {s("he", "she")} said. "The way I decided for you. We're even." # spk:spouse # mood:sad
Edric nodded. There were tears in his eyes. The same ones as in the fresco.
"Thank you," he said. "You can't imagine... Thank you." # spk:edric
->->

= choice_peace
You looked at {s("him", "her")}. For a long time. Remembering.
"All right," you said. "It's your choice. Not mine. Not his." # spk:hero
{sp()} smiled. Through tears, but smiled.
Edric sighed. Heavily, like an old man.
"A pity," he said. "I hoped that you at least..." He straightened, and the threads under his skin flared. "Well then. I'll take {s("him", "her")} myself." # spk:edric
->->

= choice_self
"Not you, not the world," you said. "Me." # spk:hero
{sp()} seized your hand.
"No. You can't, you don't have the blood of the house..." # spk:spouse
"One who is not a Bearer can," Edric said slowly. He was looking at you in a new way. "If they let him in. If they become one who holds not by blood but by power." A pause. "Like me. Only the other way round." # spk:edric
{ darkness >= 75:
    "You're already halfway there," he added, almost with pity. "I can see it. The whisper in you is louder than your own voice." # spk:edric
}
"You're deciding for me again," whispered {sp()}. # spk:spouse # mood:sad
"Yes," you said. "For the last time." # spk:hero
Edric raised his hands. Not for the ritual. For battle.
"I won't give you his power," he said. "I need it. She needs it." # spk:edric
->->
