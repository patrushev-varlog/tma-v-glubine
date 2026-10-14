// Chapter 4, scene 3. "The flesh master". English parallel of story/ink/chapter4/03_flesh_master.ink.
// ~12 minutes including the chapter's battle 2. Master Gessar and the "Ring of the Pale King".

VAR ring_taken = false

=== flesh_master ===
Behind the office was an anatomy hall. High, bright, with stone tables in a row and gutters for drainage. On the tables lay parts. Not bodies. Parts, laid out with a watchmaker's neatness.
At the far table stood a man in a leather apron, stitching something and humming. He was thin, grey and very pale. When he turned, you saw that under the apron he wore no shirt, and beneath the skin of his chest thin dark threads were glowing. Necromancy kept him on his feet the same way it kept his work on theirs.
"Guests!" He was genuinely delighted. "Forgive me, my hands are busy. Master Gessar. And you must be the ones. He wrote that you might drop in." # spk:gessar # mood:smile
"He?" # spk:hero
"His Majesty. He writes to me every week. A very demanding client." Gessar wiped his hands on his apron. "He asked me not to keep you. But, you know, I so rarely get to talk to someone who can still answer." # spk:gessar
{
- hero_class == "wizard":
    He looked at you more closely.
    "Oh. You're one of us. I can tell by the hands. Would you like to see how the seam is made? It's more elegant than it looks." # spk:gessar
- hero_class == "fighter":
    He looked at you more closely.
    "And you're a soldier. I can tell by the way you stand. I have a hall full of those, and they stand just the same. Only they never get tired." # spk:gessar
}
"Do you know what you're doing?" asked Irena. Her voice was shaking. "Do you know these are people?" # spk:irena # mood:tense
"Were," Gessar corrected her gently. "Sister, I only finish what someone else began. Death comes to everyone. I simply make it useful." # spk:gessar
He raised his hand, and the tables around him stirred.
// Chapter battle 2: Master Gessar and his "works". Gessar stitches the fallen back together while he lives.
"Forgive me," he said. "It's nothing personal. It's output." # spk:gessar # battle:chapter4_2
-> after_fight

= after_fight
Gessar lay by his table. The dark threads under his skin went out one by one.
"A pity," he said, looking at the ceiling. "I never did get the knee right." # spk:gessar
He said nothing more.
On the master's table, among the instruments, a ring lay in a velvet box. A black stone in a setting of pale metal that looked like bone. Engraved on the inside: "For output. E."
The ring was warm. The stone seemed to turn slowly inside its setting, though that could not be.
{
- hero_class == "wizard":
    The whisper grew louder the moment you looked at it. It said: with this you will not need to count how many times you have called me. I will always be near.
- hero_class == "fighter":
    The sword in its sheath shuddered as you came to the table. The blade knew the ring before you did: they had drunk from the same source.
- else:
    You felt it calling. Not with a voice. With warmth. With a promise that the rest of the way would be easier.
}
* [Take the ring.]
    ~ ring_taken = true
    You put the ring on. It fitted perfectly, as if it had been made for you. # item:pale_ring
    Irena looked away.
    { velior_fate == "forgiven":
        "He has one just like it," said Velior. "The one he wears himself. This one's smaller." # spk:velior
    }
    Garret said nothing. He only took note. You saw him take note.
* [Leave the ring on the table.]
    You closed the box and left it on the table, beside the master. Let them lie together.
    Irena let out a breath. She seemed not to have breathed all this time.
-
// On the hall map after the battle: the door to the old cupola (the hunt site). The stairs up are the hunt's point of no return.
+ [Climb the stairs to the hall above the foundry. #obj:stairs_up]
-
->->
