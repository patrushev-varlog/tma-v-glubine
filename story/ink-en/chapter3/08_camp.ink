// Chapter 3, scene 8. "The camp". English parallel of story/ink/chapter3/08_camp.ink.
// Long rest, level 4, the forge, a talk with a companion. If Velior is gone, his place stays empty.

VAR camp3_talk = ""   // "irena" / "garret" / "velior"

=== camp3 ===
{
- ch3_camp_people == "many":
    The forge was crowded: the fugitives, the smith, voices, laughter. For the first time since you came below, someone was laughing.
- ch3_camp_people == "few":
    The hearth was burning in the forge, and people sat by it. Not many. But alive.
- else:
    The forge was empty. The hearth roared for the {velior_fate == "forgiven":four|three} of you.
}
{ velior_fate != "forgiven":
    The place by the fire where Velior used to sit, his back to the wall, stood empty. No one took it.
}
You slept long and without dreams. # rest:long # levelup:4
In the morning the hearth was already burning. # shop:dwarf_forge
Before going on, you could talk to one of them.
* [Sit down by Irena.]
    ~ camp3_talk = "irena"
    -> talk_irena
* [Sit down by Garret.]
    ~ camp3_talk = "garret"
    -> talk_garret
* {velior_fate == "forgiven"} [Sit down by Velior.]
    ~ camp3_talk = "velior"
    -> talk_velior

= talk_irena
{ velior_fate == "killed":
    Irena did not raise her head.
    "Not now," she said. "Maybe later. Maybe not." # spk:irena # mood:tense
- else:
    "All my life I preached that one life is worth nothing against thousands," said Irena. "And now I've seen what it looks like. A wet face on a wall." # spk:irena # mood:sad
    "And now what?" # spk:hero
    "Now I don't know." She paused. "But I still think he was right, back then. That's the most terrible part. I think he was right." # spk:irena
}
-> leave

= talk_garret
"She told you her name," said Garret. "The one in white." # spk:garret
"Liara." # spk:hero
"Annet never once came to me in a dream." He threw more coal on the hearth. "Maybe that's for the best. I don't know what I'd say to her." # spk:garret
{ velior_fate == "killed":
    He was silent, looking into the fire.
    "I'm with you," he repeated. "Just don't ask me to forget it." # spk:garret
}
-> leave

= talk_velior
{velior_dagger == "velior":Velior was cleaning the dagger, though it was clean already.|Velior sat by the fire, looking at his hands.}
"You know why he doesn't take revenge on me?" he said suddenly. "I've worked it out. Today, at the fresco." # spk:velior
"Why?" # spk:hero
"Because I'm not his enemy. I'm one of his losses. He counts me too." Velior smirked. "I'm a line in his book. Like you. Like {sp()}." # spk:velior
-> leave

= leave
The way down led past the hall of the seal and on, to where heat rose from cracks in the stone and the air smelled of burnt flesh and iron.
Chapter 4. The Flesh Forges # chapter:4
->->
