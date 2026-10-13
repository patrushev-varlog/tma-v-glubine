// Chapter 1, scene 2. "The cage". English parallel of story/ink/chapter1/02_cage.ink.
// About 10 minutes. Meeting Velior and the first seed of his secret. Velior joins whatever happens.

VAR velior_terms = ""            // "free": no conditions, "conditions": on condition he answers questions
VAR velior_asked_list = false    // asked about the "list"; chapter 2 will call back to it
VAR velior_asked = 0             // how many questions have been asked

=== cage ===
The overseers' camp stood in a wide working: plank bunks, a cauldron over a cold hearth, a rack of picks. Empty. Only in the middle a cage hung on a chain, the kind they keep dogs in, or men being punished.
A man sat in the cage, whistling something.
He had been beaten so badly that one side of his face was swollen. On the other cheek a crown had been branded, and someone had struck it through with a knife, deep, down to the bone. A board hung on the bars: "Traitor to the King".
"Oh, guests," he said when he saw you. "Forgive me for not getting up. The ceiling's a little low." # spk:velior # mood:smile
Garret stopped so sharply that Irena walked into him.
"I know you," said Garret. "You came to the mines with special orders. Grey cloak, no badges. Even Holt bowed to you." # spk:garret # mood:tense
"It was a good cloak," the man agreed. "It was the first thing they took. Velior, at your service. Formerly a royal scout. Currently..." he tapped the board, "well, you've read it." # spk:velior # mood:smile
"Another one of them," said Irena. # spk:irena # mood:tense
"I was one of them. Like this gentleman in the Crown-issue boots, if I see rightly." Velior nodded at Garret. "You've got a whole club of formers, I see." # spk:velior
{ hero_class == "rogue":
    You looked at the lock on the cage. Simple, old, with a bent shackle. You could have opened it in ten heartbeats. Velior, judging by the look on his face, knew it too, and for some reason had not.
}
"What did they put you in there for?" # spk:hero
"For seeing what the King does with the prisoners, and no longer helping him do it." Velior shrugged, as far as the cage allowed. "A dull story. A good one, but dull." # spk:velior
* [Open the cage, no conditions.]
    ~ velior_terms = "free"
    -> free
* ["I'll let you out. But you come with us and answer questions."]
    ~ velior_terms = "conditions"
    -> conditions

= free
You knocked the lock off with a hilt. The little door creaked open.
Velior did not climb out at once. He sat and looked at you, as if trying to find the catch.
"No conditions? Just like that?" # spk:velior
"Just like that." # spk:hero
"Strange," he said, and climbed out, wincing. "Nobody's let me out of anything for nothing in a long time. Usually you pay for it afterwards." # spk:velior
-> questions_intro

= conditions
"I'll let you out. But you come with us, and you answer when I ask." # spk:hero
"A fair bargain." Velior smiled with half his face. "I'll answer. I don't promise the truth, but I'll always answer." # spk:velior # mood:smile
Irena snorted. You knocked the lock off with a hilt, and Velior climbed out, wincing.
-> questions_intro

= questions_intro
~ velior_asked = 0
He stretched his shoulders, looked around and, without asking, took a pick from the rack, then put it back and chose a knife instead.
"Well. You didn't come down here for nothing. Ask." # spk:velior
-> questions

= questions
{ velior_asked >= 2:
    -> join
}
* [Ask about the lift and the lower levels.]
    ~ velior_asked++
    -> ask_lift
* [Ask why they didn't kill him.]
    ~ velior_asked++
    -> ask_why_alive
* [Ask about the "list".]
    ~ velior_asked++
    ~ velior_asked_list = true
    -> ask_list

= ask_lift
"The lift's by the barracks. It goes down once a shift," said Velior. "Below are the Middle Levels, then the water, then what's left of the dwarves. And under them, whatever all this digging is for." # spk:velior
"What's down there?" # spk:hero
"I don't know. I really don't. They wouldn't even let me down there." He paused. "That's the first time I've said that honestly, remember it." # spk:velior
-> questions

= ask_why_alive
"Why didn't they kill you? Traitors hang." # spk:hero
Velior took a long time to answer. This time no joke came.
"The King doesn't take revenge," he said at last. "Not ever. I walked away, he could have found me in a day. He didn't bother. I was caught by accident, by the locals. They put me in here and wrote upstairs. A month now, and no answer." # spk:velior # mood:tense
"Maybe the letter got lost." # spk:hero
"Nothing of his gets lost." Velior rubbed his branded cheek. "He just decided I'm not worth a line. Or I am, but later. I don't know which is worse." # spk:velior # mood:tense
-> questions

= ask_list
You took out the sheet you had taken from Brandt and showed it to him.
"Do you know who drew this up?" # spk:hero
Velior took the sheet between two fingers. He looked at the column of names, at the line at the very bottom. He looked too long, you thought.
"Scribes in the capital," he said lightly. "There's a whole chamber doing nothing else. Copying out the old church books, finding out who was born to whom." # spk:velior
He handed the sheet back and added, as if in passing:
"A good hand, by the way. Old school. Nobody writes like that any more." # spk:velior # mood:smile
You did not remember asking about the handwriting.
-> questions

= join
{ velior_terms == "conditions":
    "Any more questions?" asked Velior. "I did promise to answer." # spk:velior
- else:
    "Thank you," said Velior, unexpectedly serious. "For the no conditions." # spk:velior
}
"There will be," said Irena before you could answer. "Lots. And I'll be listening to every answer." # spk:irena # mood:tense
"Sister, you frighten me. I like it." # spk:velior # mood:smile
Garret silently handed him his flask. Velior drank half and gave it back.
"The barracks are further down the tunnel, round the bend," he said. "But let's sit down somewhere first. I've been on my knees for a month, and my knees aren't speaking to me any more." # spk:velior
->->
