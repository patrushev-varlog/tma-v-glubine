// Chapter 3. Exploration: three side spots and the return to the riddle door.
// English parallel of story/ink/chapter3/explore.ink.
// The game calls the inspection knots (see explore_common.ink). Where each object sits is in the comment above its knot.
//
// The chapter 3 hunt is the riddle door (01_arches): if the player stepped away without answering,
// the door can be revisited. Clues: the inscription on the arches (already in scene 1) and the tablet in the archive's side niche.
// The cache in the archive is a map object (ch3_rogue_cache): a rogue in the party (hero or Velior) or the foreman's lantern.
// Ingots of dwarven steel for the Forge of the Silent: the brewery and the gallery (the third is in the chapter 4 armoury).

VAR ch3_clue_tablet = false
VAR ch3_nook_brewery_done = false
VAR ch3_nook_gallery_done = false
VAR ch3_rogue_cache_done = false

// Return to the door. Scene 1 map ("The arches"), the door beyond the arch. Works until an answer is given.
=== ch3_riddle_door ===
{ ch3_riddle_tried:
    { ch3_riddle_solved:
        The empty room behind the door. A stone stand with nothing on it.
    - else:
        The door has sunk into the wall. The runes in the ring have gone dark. The dwarves give no second try.
    }
    -> DONE
}
A stone door with no handle. A ring of runes, and a line beneath it: "What is kept without being touched, and lost once it is named?"
{ ch3_clue_tablet:
    You remembered the tablet from the archive: "Everyone who lives here keeps it. Whoever names it loses it that same moment."
}
+ [Answer: "A promise."]
    -> wrong("A promise")
+ [Answer: "Silence."]
    -> right
+ [Answer: "Breath."]
    -> wrong("Breath")
+ [Step away. Think some more.]
    -> DONE

= right
~ ch3_riddle_tried = true
~ ch3_riddle_solved = true
"Silence," you said. # spk:hero
One by one, the runes in the ring slowly went out. The door sank into the floor without a sound.
Behind it was a tiny room. On a stone stand lay what the dwarves had seen fit to hide from all who do not know how to keep silent. # item:silent_crown
{ ch3_clue_tablet:
    "The archive," said Velior. "I'd never have gone there. Too dull. Seems I was wrong." # spk:velior # mood:smile
- else:
    "Good thing it was you who answered, and not me," said Velior. "I'd have said 'money'." # spk:velior # mood:smile
}
-> DONE

= wrong(answer)
~ ch3_riddle_tried = true
"{answer}," you said. # spk:hero
The runes flared red and went out. Something clicked heavily deep in the stone, and the door seemed to sink further into the wall.
"They don't give a second try," said Velior. "I told you." # spk:velior
-> DONE

// Clue to the door. Scene 4 map ("The archive"): a side niche with children's tablets (a nook, off the way to the battle).
=== ch3_look_tablet ===
{ ch3_clue_tablet:
    The children's tablets. Three riddles, and you already know two of them.
    -> DONE
}
~ ch3_clue_tablet = true
In a side niche of the archive stood tablets smaller than the rest: thin, with large runes, some with mistakes scratched out and corrected. Lesson tablets. Dwarven children, too, had once sat over their lessons.
{ hero_class == "wizard":
    You read the first one. They were riddles, three to a tablet, with the answers on the back.
- else:
    Velior pulled one out, turned it over and snorted.
    "Riddles. With the answers on the back. So dwarven children copied too." # spk:velior # mood:smile
}
One riddle was familiar. Not word for word, but almost: "Everyone who lives here keeps it. It cannot be seen or heard. Whoever names it loses it that same moment."
The answer on the back had been rubbed away. By someone's finger, long ago, many times.
{ ch3_riddle_tried:
    You remembered the door in the hall of arches.
- else:
    You remembered the door in the hall of arches. Now, it seemed, you knew what to answer it.
}
A note in the journal: "The door's riddle: a children's tablet from the archive." # journal:ch3_riddle_tablet
-> DONE

// Side spot 1. Scene 2 map ("The refuge"): the brewery of the Silent behind the forge.
=== ch3_nook_brewery ===
{ ch3_nook_brewery_done:
    The brewery. Empty barrels, a vat with a dry bottom.
    -> DONE
}
~ ch3_nook_brewery_done = true
Behind the forge there was a low door, and beyond it a hall of vats as tall as houses. A brewery. The dwarves, who lived in endless silence, had brewed beer in quantities that would have served the whole kingdom.
"Now I see how they bore it," said Garret. # spk:garret
Nearly all the barrels had dried out and split. Two, in the farthest corner, were sealed with wax, and the wax was whole. Beside them, in a stone casket, lay coins, small and square, with a hole in the middle. Dwarven silver. Under the coins was a bar of dark metal stamped with the mark of the forge: they must have paid the smiths for their beer with it.
{ ch3_camp_people != "none":
    One of the people you had saved brought mugs, and the barrel was opened right there. The beer was dark, thick and bitter, like water from the deep.
- else:
    You opened one barrel. The beer was dark, thick and bitter, like water from the deep. There was no one to drink it with but your own.
}
You poured the rest into flasks, and took the bar for the forge. # item:dwarf_ale # item:dwarf_ale # silver:20 # item:dwarf_steel
-> DONE

// Side spot 2. Scene 6 map ("The keeper"): the collapsed gallery on the way to the keeper.
=== ch3_nook_gallery ===
{ ch3_nook_gallery_done:
    The collapsed gallery. Bones by the wall.
    -> DONE
}
~ ch3_nook_gallery_done = true
The gallery had collapsed long ago, but someone had gone to the end of it all the same. There were five of them. They lay by the blind rockfall, close together, shoulder to shoulder, the way people lie down to keep warm.
Miners. Convicts' jackets, broken picks. Fugitives who had reached the dwarven halls before you, looked for a way up, and found a wall.
On the stone above them someone had scratched: "Got this far. Can't go on. Pray for Jarn, Olaf, Berta, Colm and me." The last one did not write his own name. He had no time, or decided it did not matter.
{ irena_bell == "blessed":
    Irena prayed for all five. And for the sixth, separately, without a name.
- else:
    Irena stood over them for a long time. Then she said the names aloud, all five, slowly. She did not say a prayer.
}
Beside them lay a mine greatsword: a long blade of the kind forged in miners' smithies from old drill rods. Heavy, crude, unadorned. The fugitives had carried it with them to the very end.
You took it. So that it would get further than they did. # item:mine_greatsword
Under the hand of the last one, the one who had written, lay a bar of dark steel wrapped in a rag, stamped with the mark of the Silent. He had been carrying it up to sell. He had nothing else.
{ ch3_camp_people != "none":
    "This is for the forge," said Garret, weighing the bar in his palm. "The smith in the camp would give his soul for one of these." # spk:garret
}
You took that too. # item:dwarf_steel
-> DONE

// The cache under the slab. Scene 4 map ("The archive"), the far wall: a floor slab that was lifted not long ago.
// Opens if there is a rogue in the party (has_rogue) or the party has the foreman's lantern (has_lantern).
// Replaces the rogue_cache insert in 04_archive.ink, where only a rogue hero had the cache.
=== ch3_rogue_cache ===
{ ch3_rogue_cache_done:
    The empty cache under the slab by the far wall.
    -> DONE
}
{ not has_rogue() && not has_lantern():
    Floor slabs by the far wall of the archive. Level, dusty, all alike.
    -> DONE
}
~ ch3_rogue_cache_done = true
{
- hero_class == "rogue":
    You lingered by the far wall. One slab in the floor lay slightly differently from the rest: a hair higher, and the dust on it was not as even. Someone had lifted it. Not centuries ago.
    { velior_terms != "" && velior_fate == "":
        Velior looked over your shoulder.
        "I didn't notice it," he said, almost offended. "Two years ago. And you found it in a minute." # spk:velior
    }
- has_rogue():
    Velior stopped by the far wall and crouched over one of the slabs.
    "Two years ago I walked right past this," he said. "And now I see it: it's been lifted. The dust is wrong. I suppose back then I only looked at what I was told to." # spk:velior
- else:
    You raised the foreman's lantern, and by the far wall one slab threw its shadow differently from its neighbours: a hair higher. The dust on it did not lie as evenly. Someone had lifted it. Not centuries ago.
}
Under the slab was a cache.
// The hidden legendary of chapter 3: Shadowskin.
You took out what lay inside. # item:shadowskin
-> DONE
