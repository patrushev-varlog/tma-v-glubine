// Chapter 5, scene 2. "The hall of the seal". English parallel of story/ink/chapter5/02_seal_hall.ink.
// ~10 minutes including the chapter's battle 2. The hall's guards, chapter 5's dark act and Liara's last vision.

VAR ch5_raised_dead = false   // chapter 5's dark act (+10): raised the fallen prisoners against the guard

=== seal_hall ===
The hall of the seal was round, and so vast that the ceiling could not be seen. Only darkness overhead, and in it, far off, a pale patch: the slab you had seen from the dwarves' gallery. From here, below, it looked like a moon.
The floor of the hall was the seal. Stone scored with grooves, like the circle under the fresco, only a hundred times larger. The grooves glowed. At the centre, where they met, the light was so bright it hurt to look at.
By the entrance stood the dead in dress armour. Old armour, with the arms of Eldmar: a tower over three stars. The honour guard of the royal council. Sixty years at their posts.
{ hero_class == "wizard":
    A line was stamped on their breastplates. You read it: "Loyal to the end." Someone, it seemed, had taken that literally.
}
"They're the ones who stood around the circle," you said quietly. "In the fresco. The people in robes. That's the council." # spk:hero
"He raised them," said Garret. "The ones who told him to do it. And set them on guard. For ever." # spk:garret
The guards turned their heads.
By the wall, where the light of the seal did not reach, lay prisoners. Ten of them, maybe more. They had been driven down here to scrape the grooves and left here when the work was done. The blood under them had not yet turned black.
The whisper came on its own. It said: there are more guards than there are of you. It said: these no longer care, but you do.
{ hero_class == "wizard":
    The words stood in the book on that very page. You knew one would be enough.
}
* [Raise the fallen prisoners. Let them stand against the guard.]
    ~ ch5_raised_dead = true
    ~ add_darkness(10)
    You spoke the word. The prisoners rose all at once, as if at a command at roll call, and stood between you and the ranks.
    { irena_confronted == "stayed":
        "Once," said Irena. Only that. # spk:irena # mood:tense
    - else:
        { irena_confronted != "left":
            Irena turned away. The bell on her staff swayed and did not ring.
        }
    }
    Garret looked at the raised. Then at you. He had looked at Brandt that way, when Brandt stood over the column.
    // Chapter battle 2, variant: the raised prisoners fight on the hero's side (AI-controlled allies).
    For sixty years the guard had waited for an order. Yours waited less than a minute. # battle:chapter5_2_raised
* [Leave them lying there.]
    // Chapter battle 2: the honour guard of the Council of Eldmar. They fight in formation, as if on parade.
    For sixty years they had waited for an order. # battle:chapter5_2
-
-> after_fight

= after_fight
The last guard sank to one knee, as before a king, and crumbled.
{ ch5_raised_dead:
    The raised prisoners stayed standing, waiting for the next word. You released them, and they lay down where they had lain before. Only not so straight now.
}
// On the hall map after the fight: the fallen guards by the pedestals (hunt clue) and the small door behind the empty
// thirteenth pedestal (hunt site). The centre of the seal is the hunt's point of no return (leave_check: 5).
+ [Go to the centre of the seal. #obj:seal_center]
-
In the silence that followed, the light of the seal flickered. As if someone inside had caught their breath.
And you saw her. Not in a reflection, not in a niche. Right in the light of the seal, at your very feet.
Liara.
{
- darkness < 25:
    She was smiling. Tired, warm. The way you smile at someone who has made it.
- darkness < 50:
    She looked serious. Not uneasy, as before. Simply serious. The time for unease was over.
- darkness < 75:
    She looked at you coldly. The way, perhaps, you look at someone you no longer hope to hold back.
- else:
    She hardly looked at you. Her lips moved, but you could not hear the words. Only at the very end, as if through deep water.
}
{
- darkness < 50:
    "I don't regret it," said Liara. "He does. Decide for yourself what you will regret." # spk:liara
    "I won't tell you what is right. No one knows. Not even him. Least of all him." # spk:liara
- darkness < 75:
    "I don't regret it," said Liara. "He does. You will too. You've already begun, you just don't know it yet." # spk:liara
- else:
    "...not like him," came through at last. "Worse. At least he regretted it." # spk:liara
}
The light swallowed her. The grooves on the floor glowed brighter, and at the centre of the seal, where all the lines met, you saw a figure.
Alive. Sitting at the edge of the light, arms around {s("his", "her")} knees.
{sp()}.
->->
