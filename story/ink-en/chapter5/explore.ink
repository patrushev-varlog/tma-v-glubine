// Chapter 5. Exploration: the hunt for the "Council Seal". English parallel of story/ink/chapter5/explore.ink.
// The inspection knots are called by the game (see explore_common.ink). Where each object lies is in the comment above its knot.
//
// The hunt: three clues, any two are needed. Velior's clue exists only on the secret way.
// The council plaque hangs in the guardroom, a side pocket at the start of the descent (the chapter's only side spot).
// The site is the cache behind the empty thirteenth pedestal: a separate small map behind a door in the wall of the hall of the seal.
// Open after the fight with the hall's guard, until the hero has gone up to the spouse.
// The council seal is a story relic with no combat properties: it gives the truth about Liara, a line in the talk
// with Edric (04_offer) and a mention in the epilogue. It does not go in the amulet slot.
// The first councillor's name (Averin Keil) is a placeholder.

VAR ch5_clue_plaque = false    // the memorial plaque on the descent
VAR ch5_clue_crests = false    // the breastplates of the council guard
VAR ch5_clue_velior = false    // Velior on the secret way
VAR ch5_hunt_clues = 0
VAR ch5_hunt_done = false

// Clue 1. Scene 1 map ("The descent"), at the top of the stairs, before the paths fork: the council guardroom,
// a side pocket in the wall (side spot). The memorial plaque. Present on both paths.
=== ch5_look_plaque ===
{ ch5_clue_plaque:
    The memorial plaque of the Council of Eldmar.
    -> DONE
}
~ ch5_clue_plaque = true
~ ch5_hunt_clues++
Beside the stairs a guardroom had been cut into the rock: a stone bench, hooks for lanterns, a niche for weapons. Once, people had stood here who saw the council off on its way down. A bronze plaque was set into the wall, green with age. The letters on it were human, ceremonial, full of flourishes.
"The Council of Eldmar, mindful of the good of the realm, descended here in full assembly and left by the seal the token of its authority, that the authority of the living might guard the sleep of the one who sleeps. First Councillor Lord Averin Keil."
{ ch3_diary_read:
    "They always ask, never order. It is easier afterwards." You remembered the diary by the fresco. Here the council had not asked. Here it had left its seal and gone back up. Easier afterwards.
}
"'The token of its authority'," Garret repeated. "That's what they called a seal. The kind you stamp orders with." # spk:garret
A note in the journal: "The council's seal was left by the Sleeper's seal." # journal:ch5_hunt_plaque
-> ch5_hunt_progress

// Clue 2. Scene 2 map ("The hall of the seal") after the fight: the fallen council guards by the entrance.
=== ch5_look_crests ===
{ ch5_clue_crests:
    Breastplates with the arms of Eldmar. One empty pedestal.
    -> DONE
}
~ ch5_clue_crests = true
~ ch5_hunt_clues++
The guards lay where they had fallen, in rows, as they had stood. On every breastplate, a tower over three stars and the line "Loyal to the end."
There were twelve of them. And along the wall, thirteen pedestals. The thirteenth was empty, and above it the stone was carved not with a tower but with an open palm with a seal on it. Behind the pedestal, a low door without a handle could just be made out in the wall.
{ hero_class == "wizard":
    Above the palm, runes, human but old: "Here it is kept."
- else:
    "Somebody stood watch here over something," said Garret. "Not over the entrance. Over a thing." # spk:garret
}
A note in the journal: "The empty thirteenth pedestal: a palm with a seal, a door in the wall." # journal:ch5_hunt_crests
-> ch5_hunt_progress

// Clue 3. Scene 1 map, the secret way: Velior stops above the hall of the seal. Only with ch5_secret_path.
=== ch5_talk_velior_niche ===
{ not ch5_secret_path:
    -> DONE
}
{ ch5_clue_velior:
    Velior nods down at the door behind the pedestals.
    -> DONE
}
~ ch5_clue_velior = true
~ ch5_hunt_clues++
On the ledge Velior stopped and pointed down at the wall of the hall of the seal, barely visible in the pale light.
"See the door? On the left, behind the pedestals. The council's seal lies there. The very one they stamped the order about Liara with." # spk:velior
"How do you know?" # spk:hero
"He used to sit opposite it. Every time. For hours. He looked at it and never touched it." Velior was silent for a moment. "Once I asked him why. He said: 'Let it lie. Let them know that I remember.' They all died long ago. But he still wanted them to know." # spk:velior
A note in the journal: "A door on the left, behind the pedestals. The seal they stamped the order about Liara with." # journal:ch5_hunt_velior
-> ch5_hunt_progress

=== ch5_hunt_progress ===
{ ch5_hunt_clues == 2:
    Now it is clear where to look: behind the empty pedestal in the hall of the seal, through the door in the wall. # journal:ch5_hunt_ready
}
-> DONE

// The hunt site. The door behind the empty thirteenth pedestal in the hall of the seal (scene 2) and the little room behind it,
// a separate small map. Open after the fight, until the hero has gone up to the spouse. Before two clues the door won't give.
=== ch5_hunt_site ===
{
- ch5_hunt_done:
    An empty little room behind the pedestal. Grey velvet on a stone shelf.
    -> DONE
- ch5_hunt_clues < 2:
    Behind the pedestals a low door without a handle shows dark in the wall. It won't give, and there is nothing to pull it by.
    -> DONE
}
~ ch5_hunt_done = true
You pressed the palm carved above the empty pedestal, and the door behind it swung inwards. Beyond it was a room two paces wide, a shelf, and on it, on velvet that had long since turned grey, a seal. Heavy, gold, on a chain. A tower over three stars, and small around the edge: "Council of Eldmar. For the good of the realm."
Beside it lay a scroll. You unrolled it, and it crumbled at the edges, but the middle survived.
"...deem it necessary. The Bearer of the house of Tal, Liara, to be handed over to the Archmage for the renewal of the seal. The Council expresses its hope that the Archmage will find the strength in himself. First Councillor Averin Keil."
Under the signature, the impression of that very seal. And one more line, in a different hand, at the side, small, as if added later, by someone who had read this order many times:
"Found."
{ hero_class == "cleric" || hero_class == "wizard":
    You took the seal, and in your head, quietly, like a whisper from the deep, but not the one you had grown used to, came the words: "She did not want to. She was not asked. She agreed later, when she understood that otherwise her sister would go."
- else:
    You took the seal, and in your head, quietly, like a whisper from the deep, came the words: "She did not want to. She was not asked. She agreed later, when she understood that otherwise her sister would go."
}
You did not know whose voice it was. Perhaps the seal's own. Perhaps that of the one who sleeps beneath it.
{ velior_fate == "forgiven":
    "He never told me the order was here," Velior said quietly. "Only the seal. So he didn't tell me everything either." # spk:velior
}
You tucked the seal inside your shirt. The gold was cold and did not warm. You did not want to wear it round your neck. You did want to show it to someone. # item:council_seal
-> DONE
