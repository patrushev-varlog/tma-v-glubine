// Chapter 4, scene 2. "The reports". English parallel of story/ink/chapter4/02_reports.ink.
// ~8 minutes. The forges are Edric's order. The note "warned by the family" in the bearer's folder.

VAR ch4_report_read = false

=== reports ===
The works office was clean. After the vats it seemed indecent: whitewashed walls, writing desks, inkwells, neat stacks of paper. The window looked out on the conveyor, so the clerk could count without getting up.
The reports were filed by month. "On output." You opened the top one.
"Received: 214. Released fit for service: 188. Losses in processing: 26. Losses are to be reduced. E."
Below, in the same even hand, without a single blot: "Good."
"He signs every one," said Irena, turning the pages. "Every month. Every figure." # spk:irena
{ ch3_diary_read:
    You remembered the diary by the fresco. "Then why is it so hard to breathe." The same hand. It has not been hard for him to breathe for a long time now.
}
"He isn't evil," Garret repeated what he had said in the halls. Only now it sounded not like forgiveness, but like a diagnosis. "He counts." # spk:garret
In a separate drawer, under a lock that Garret knocked off with one blow, lay a single folder. On the cover: "The Bearer. House of Tal."
* [Open the folder.]
    ~ ch4_report_read = true
    -> folder
* [Don't open it. Not now.]
    You put the folder inside your coat, next to the "list" and the letter to Renna. Three papers, one hand. You were not ready for a fourth.
    -> leave

= folder
Inside was a single sheet. A description: height, colour of eyes, distinguishing marks. All correct, down to the mole. Someone had looked at {s("him", "her")} very closely.
"Bearer: {sp()}. House of Tal, on the mother's side. Transported to the bottom. Offers no resistance."
And below, in a different pen, later:
"Warned by the family. Knew of {s("his", "her")} blood. E."
You read the line three times.
{ legend_pressed:
    An evening by the hearth. "One day. Not tonight." {s("He", "She")} looked at you then, and for a moment you thought {s("he", "she")} was about to tell you. {s("He", "She")} knew. {s("He", "She")} knew all along.
- else:
    An evening by the hearth. Grandmother's sister, whom "the king took". A song without its last verse. {s("He", "She")} looked away then. {s("He", "She")} knew.
}
{
- hero_class == "wizard":
    You knew how the world was made. You sat over books until dawn. And you did not know what slept beside you.
- hero_class == "cleric":
    All your life you taught others that the truth sets free. {s("He", "She")} decided you were better off without it.
- hero_class == "rogue":
    All your life you noticed what others hide. Except for one thing.
- else:
    For so many years you stood between {s("him", "her")} and the whole world. And all that time {s("he", "she")} was standing between you and this.
}
"What is it?" asked Irena. # spk:irena
* [Show her.]
    Irena read it and was silent for a long time.
    "{s("He", "She")} kept quiet so that you could live in peace," she said at last. "That is love too. Not the kind you want, but love." # spk:irena # mood:sad
* ["Nothing. Let's go."]
    "Nothing," you said. "Let's go." # spk:hero
    Irena looked at you and did not ask.
-
-> leave

// On the office map: the garrison armoury (side spot 2, the storekeeper's book — a hunt clue) and the clerk's safe (side spot 3).
= leave
+ [Go through to the bright hall behind the office. #obj:hall_door]
-
->->
