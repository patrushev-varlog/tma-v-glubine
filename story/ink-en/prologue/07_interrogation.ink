// Prologue, scene 7. "The interrogation". English parallel of story/ink/prologue/07_interrogation.ink.
// About 5 minutes. The turn and the first temptation of necromancy. The prologue leads into chapter 1 with no purchase point.

VAR interrogation = ""   // "persuade" / "threaten" / "dead"

=== interrogation_scene ===
Brandt sat propped against {column_choice == "trail": the wheel|a log by the fire}, pressing a hand to the wound in his side. Blood ran through his fingers. With the other hand he held the sheet to his chest, as if that mattered more.
Garret pulled the sheet away and unfolded it by the torch.
A column of names. At the very bottom, underlined twice: "{sp()} of the house of Tal. Separately. To the bottom, in person."
"In person to whom?" you asked. # spk:hero
Brandt smiled with grey lips.
"Not to you." # spk:brandt
{ column_choice == "trail":
    "You'd better hurry," he added. "They're already counting your neighbours down below." # spk:brandt
}
{ raid_called:
    "I remember you, though. You shouted a name at the cart." Brandt closed his eyes. "I wrote it down. I write everything down." # spk:brandt
}
Then you heard another voice. It spoke inside you, quietly, like water under the earth: "He is dying. The dead do not lie. The dead talk to those who know how to ask."
{ hero_class == "wizard":
    The voice itself was strange to you, but you knew the language: it was written of in the books you hid on the top shelf.
}
* [Let Garret talk: he knows Brandt.]
    ~ interrogation = "persuade"
    -> persuade
* [Frighten him.]
    ~ interrogation = "threaten"
    -> threaten
* [Let him die and ask the dead man.]
    ~ interrogation = "dead"
    ~ add_darkness(10)
    -> dead

= persuade
Garret squatted down beside him.
"You've a daughter in Tremhall, Brandt. Red-haired. You showed me the locket yourself." # spk:garret
"Leave her out of it." # spk:brandt
"I'm not touching her. I want you to get back to her. We'll bind you up and you can go. Just tell us where they're taking {s("him", "her")}." # spk:garret
Brandt looked at Garret for a long time. Then at Irena, who was already getting out the bandages.
-> answer

= threaten
You took him by the collar and pulled his face close to yours.
"You'll bleed out here, in the mud. Or you talk, and they bind you up. Choose." # spk:hero
Irena looked away.
Brandt did not hold out for long.
-> answer

= dead
You did not call Irena over with the bandages. You waited and watched him turn pale.
"What are you doing?" Irena asked behind you. # spk:irena # mood:tense
You did not answer. Brandt went still. And then the whisper grew louder, and you repeated after it words you had never known.
The dead man opened his eyes. There were no pupils in them.
{ hero_class == "wizard":
    It turned out to be easy. Too easy. As if someone had long been waiting for you to try.
}
"Ask," said the dead man in Brandt's voice, but without his breath. # spk:brandt
Garret swore. Irena stepped back and raised her staff, and the bell on it trembled by itself.
-> answer

= answer
{ interrogation == "dead":
    "The one of the house of Tal is not being taken to work," said the dead man. "{s("He", "She")} is being taken to the bottom. To the King. He has waited sixty years for that name." # spk:brandt
    Then the light in his eyes went out, and he was only dead again.
- else:
    "The one of the house of Tal..." Brandt licked his lips. "Not for work. {s("He", "She")}'s being taken to the bottom. To the King in person. That's all I know, I swear. My orders were just to deliver, and not a bruise." # spk:brandt
}
-> leave

= leave
{
- interrogation == "dead":
    Irena did not lower her staff until the dead man was wholly still. Then she said:
    "I saw my parishioners rise because of a whisper like that. Don't do it again. Please." # spk:irena # mood:tense
    Garret spat at his feet. From then on he walked a little behind you, not beside you.
- interrogation == "threaten":
    Irena bandaged Brandt in silence, and tightly. When she was done, she spoke not to him but to you:
    "You know how to frighten people. I'd rather not know where you learned it." # spk:irena
- else:
    They bandaged Brandt and left him by the gates with a flask of water. Garret stood over him for a moment.
    "Go to your daughter," he said. "And don't come back here." # spk:garret
}
The mine gates stood open. Cold came out of the dark, and something like breath.
The whisper did not leave. It stayed somewhere under your ribs, quiet as a second heart, and you knew: call, and it will answer.
{
- hero_class == "wizard":
    The words it prompted were already in your book. On a page you had never seen before.
- hero_class == "fighter":
    The sword at your belt grew heavier, and the weight was a hungry one.
- hero_class == "rogue":
    Your shadow by the torch fell a little longer than it should. And a little later than your step.
- else:
    You began your usual prayer and halfway through understood that someone else was answering.
}
// From here on dark gifts are available in battle (canon: they open after the interrogation, whatever the choice).
You did not call it. Not yet. # unlock:dark_gifts
{ promise_made:
    You remembered promising not to look. And you stepped into the dark.
- else:
    You stepped into the dark first.
}
// Chapter title: the game shows it on the tag and loads chapter 1.
Chapter 1. The Upper Mines # chapter:1
->->
