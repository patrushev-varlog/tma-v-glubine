// Prologue, scene 2. "The raid". English parallel of story/ink/prologue/02_raid.ink.
// About 10 minutes with battle 1. Darkness does not change.
// The game starts a battle on the # battle:<id> tag and continues the story after it.

VAR raid_rushed = false     // ran for the cart
VAR raid_called = false     // called out the name

=== raid ===
The bell rang again. Close now: on the chapel by the well. It rang fast and ragged, the way a bell rings not for a service but because there is nothing else left to do. # sfx:bell_chapel
{sp()} was already standing at the window.
"There's fire," {s("he", "she")} said. "Oldric's house is burning. And the Haskers'." # spk:spouse # mood:tense
* [Grab a weapon and go out.]
    -> outside
* ["Stay here. Bar the door."]
    "Stay here. Bar the door behind me." # spk:hero
    {sp()} nodded. You heard the bolt slide home while you were still on the porch.
    -> outside

= outside
The street smelled of smoke and of something else, sweet and heavy. A figure in sodden rags tipped over the fence. Then a second.
// Battle 1: the hero alone by the house, a tutorial. It cannot be lost (see the plan, scene 2).
The first one had no lower jaw.
// The tag sits on the last line before the battle: the game shows the line and starts the battle.
It came for you all the same. # battle:prologue_1
-> after_fight

= after_fight
Only when the last corpse dropped by the porch did you notice that your hands were shaking.
The door of the house stood open. The bolt hung by a single nail.
A cart stood by the well, black, with a yellow sign on its side: a crown, and under it three prongs, like a pitchfork. Men with torches stood around it. Living men.
Further down the road a column was being driven along. You knew those backs: the Haskers, the smith's wife, Oldric's boy.
By the cart a man in a leather coat held a sheet of paper up to a torch.
"{sp()} of the house of Tal," he read slowly, as if tasting the words. # spk:brandt
You had never heard that house named. In Ashmoor {sp()} was just {sp()}, with no house at all, only a grandmother.
Two overseers came round the corner, and {sp()} walked between them. {s("He", "She")} did not struggle.
"This one in the column?" one of them asked. # spk:overseer
"Not in the column," said the man with the sheet. "This one goes on the cart. Separately. Gently. If there's so much as a bruise on {s("him", "her")}, I'll send you down the pit myself." # spk:brandt
* [Throw yourself at the cart.]
    ~ raid_rushed = true
    -> rush
* [Shout: "{sp()}!"]
    ~ raid_called = true
    -> call

= rush
You ran. You managed five steps, maybe six. Someone stepped out at your side, and the world turned over.
-> fall

= call
"{sp()}!" # spk:hero
{s("He", "She")} turned at your voice. So did the man with the sheet.
"Ah," he said, almost kindly. "Family. Family isn't on the list." # spk:brandt
The blow came from behind.
-> fall

= fall
The ground was cold and wet. You lay with your cheek in the mud and could see only the cart wheel and {s("his", "her")} face above the side.
{sp()} was looking straight at you. Not screaming. Not calling out. Only looking, the way people look when they have long known this day would come and still were not ready for it.
Then the wheel turned, and everything went dark.
->->
