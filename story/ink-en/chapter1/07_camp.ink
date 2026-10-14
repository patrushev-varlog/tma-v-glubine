// Chapter 1, scene 7. "The camp". English parallel of story/ink/chapter1/07_camp.ink.
// The first camp between chapters: long rest, level 2, a merchant, a talk with a companion.
// Levelling, the merchant and equipment are game UI; here there is only text and tags.

VAR camp1_talk = ""   // who the hero talked to: "irena" / "garret" / "velior"

=== camp1 ===
The cage stopped on the lower level beside an old watch hut. The door hung on one hinge, but inside there was a hearth, bunks and silence. You could sleep here.
Irena said a short prayer over the threshold. Velior checked the windows. Garret made a fire.
// Long rest and level 2: the hero picks a class branch. The game opens the level-up screen on the tag.
For the first time in many days you slept without dreams. # rest:long # levelup:2
{ column_choice == "neighbors":
    In the morning there was a man with a handcart outside the hut: the smith from Ashmoor, the one whose wife you had freed at the fires. He had followed you all the way from the gates.
    "I owe you," he said shortly. "What I can give, I'll give." # spk:smith # shop:smith
- else:
    In the morning there was a man with a handcart outside the hut, scrawny, with shifty eyes. A sutler who had run away from his own baggage train.
    "Anything that isn't nailed down," he said. "And a few things that were." # spk:sutler # shop:sutler
}
Before going on, there was time to talk to one of them.
* [Sit down by Irena.]
    ~ camp1_talk = "irena"
    -> talk_irena
* [Sit down by Garret.]
    ~ camp1_talk = "garret"
    -> talk_garret
* [Sit down by Velior.]
    ~ camp1_talk = "velior"
    -> talk_velior

= talk_irena
Irena sat over her cracked bell, trying to straighten the bent clapper.
"All my life I thought death was when everything ends," she said without raising her head. "But here it works. It carries ore. It stands facing the wall until morning." # spk:irena
"Do you still believe?" # spk:hero
"I do. Only now I don't know in what, exactly." She rang the bell, dully. "Ask me again in a few levels." # spk:irena
{ ch1_choice == "slip":
    After a silence she added:
    "Back there, in the barracks. I understand why you decided the way you did. I just want you to know: I counted how many of them were left." # spk:irena # mood:tense
}
-> leave

= talk_garret
{ garret_tag_found:
    Garret was turning a copper token in his fingers. There was a number stamped on it and nothing else.
    "Annet," he said. "She did the washing here. I was standing guard on the next level and didn't know. Or maybe I knew and didn't want to." # spk:garret
    He held the token out to you.
    -> tag_choice
- else:
    Garret was sharpening his cleaver, though it was already sharp.
    "You're asking who I left down here," he said, though you had not asked. "My wife. She died in these mines. At the time I was standing guard on the next level, watching other people's." # spk:garret
    "I'm sorry." # spk:hero
    "So am I. Every day." # spk:garret
}
-> leave

= tag_choice
* ["Keep it."]
    "Keep it. It's yours." # spk:hero
    Garret nodded and hung the token round his neck, under his shirt. # item:garret_tag # to:garret
* [Take the token.]
    You took the token. It was warm from his hand.
    "Wear it," said Garret. "I can't bear to look at it. Can't throw it away either." # spk:garret # item:garret_tag
-
-> leave

= talk_velior
Velior lay on a bunk with his hands behind his head, looking at the ceiling.
"Come to interrogate me? I'm at your disposal." # spk:velior # mood:smile
* ["Who branded that crown on you?"]
    "Who branded that crown on you?" # spk:hero
    "The King himself. With his own hand. The day he took me into his service. It was... an honour." Velior touched the scar. "The line through it was mine. Also my own hand. With a knife, the day I left." # spk:velior
* ["What did you really do for the King?"]
    "What did you really do for the King?" # spk:hero
    "I searched," said Velior. "For people, things, old books. I was good at it." He turned to the wall. "Ask me again in a few levels, all right? Right now I'm too tired to lie nicely." # spk:velior # mood:tense
-
-> leave

= leave
The road led on, further down. To where, Velior said, the water began.
Chapter 2. The Flooded Workings # chapter:2
->->
