// Chapter 3, scene 4. "The archive of the Silent". English parallel of story/ink/chapter3/04_archive.ink.
// About 12 minutes including the chapter's second battle. The dwarves' records: the voice of the Sleeper.

VAR ch3_dead_spoke = false

=== archive ===
Velior led with confidence, checking neither map nor signs. Through a narrow crawlway, down a scree slope, along a crack you had to squeeze through sideways.
"You've been here," you said. # spk:hero
"At the sluice you said you'd never gone further," said Irena. # spk:irena
"I did say that." Velior did not turn round. "Two years ago, on his orders, I found the archive and went back up. I told him I'd found nothing. That was the first lie I told him. It's not the first I've told you." # spk:velior
{ velior_confronted == "rage":
    He rubbed his neck, where the marks of your fingers still showed.
}
The archive was a long hall lined with stone shelves, and on the shelves were not books but tablets: thin slabs covered in runes on both sides. Thousands of slabs.
And between the shelves sat dwarves. Dead, dried down to skin and beard, in the very postures death had found them in: at their tables, chisels in hand.
"They stayed at their work," Irena whispered. "To the end." # spk:irena
One of the dead raised his head.
// Chapter battle 2: dead dwarf archivists. They do not pursue beyond the hall, but they hit hard.
Then a second. Then all of them. # battle:chapter3_2
-> after_fight

= after_fight
When it was over, the archive was silent again. Only one of the dead, an old one with a beard down to his knees, still moved his lips. Soundlessly, evenly, as if he were still reading aloud what he had begun reading centuries ago.
{ hero_class == "wizard":
    You heard the whisper. The same as at the column, at the sluice, always. It said: ask. It said: you know how. That was true.
- else:
    You heard the whisper. The same as in the temple and at the column. It said: ask. He knows. You can make him speak.
}
* [Listen to the whisper and make the dead dwarf speak.]
    ~ ch3_dead_spoke = true
    ~ add_darkness(5)
    -> dead_speaks
* [Leave the dead in peace. Read for yourselves.]
    -> records

= dead_speaks
You laid your hand on the old dwarf's forehead. The skin was like parchment. The whisper passed through you like water through a pipe.
The dead man's lips stopped moving. Then they opened.
"You have come to ask whether he is an enemy," said the dead dwarf. His voice was dry as dust. "We argued about that for three hundred years. I will tell you what is not on the slabs." # spk:dwarf_dead
"We held him not because he is evil. But because we were afraid. We wanted to live long. He is death. Not evil. Simply death. We locked death away and called it victory." # spk:dwarf_dead
"Let me go." # spk:dwarf_dead
You let him go. The dead man's head fell onto the table.
Irena was looking at you from across the hall. She said nothing. She did not even whisper a prayer.
-> records

= records
{ hero_class == "wizard":
    You read the slabs yourself, one after another, until your eyes ached. The others waited.
- else:
    Velior read the signs, and you guessed the rest from the pictures. Irena copied down whatever could be made out.
}
The dwarves did not call him the Sleeper. They had another word, which meant "the one who comes at the end". Not "the enemy". Not "evil". Simply: the end.
"He does not hate. He does not want. He comes, as winter comes."
"Master Brin says: we have locked winter in the cellar and boast of an endless summer. Master Brin has been cast out of the council."
"The blood of the house of men that lives at the foot of the mountains holds the seal more firmly than our stone. We taught them. May their children forgive us."
"If he wakes in a world where the dead do not die, who knows what he will do. Perhaps what he must."
"May their children forgive us," Irena repeated. "The house of Tal. That's them. The dwarves taught people to lay their own into the seal." # spk:irena # mood:tense
"Convenient," said Garret. "Saved their own stones." # spk:garret
// On the archive map after the battle: the children's tablets in a side niche (a clue to the door) and a slab by the far wall (the cache).
+ [Climb up out of the archive towards the shrine. #obj:archive_out]
-
->->
