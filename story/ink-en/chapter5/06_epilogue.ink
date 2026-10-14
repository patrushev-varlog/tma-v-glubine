// Chapter 5, scene 6. "The epilogue". English parallel of story/ink/chapter5/06_epilogue.ink.
// ~5 minutes. The epilogue for each ending. The count of prisoners saved over the whole game.

VAR saved_count = 0

=== epilogue ===
~ count_saved()
{
- ending == "love":
    -> epi_love
- ending == "peace":
    -> epi_peace
- ending == "guardian":
    -> epi_guardian
- else:
    -> epi_tyrant
}

= epi_love
The dead rose no more. Not in the capital, not in the mines, not in the graveyards. The Pale King's army lay where the sigh from the deep had caught it, and within a month nothing was left of it but armour.
The kingdom celebrated. Not for long.
Then in Ashmoor they noticed that for three months no one had died. Not the old, not the sick, not the babies in fever. At first they were glad. Then they stopped being glad.
They say that at night someone stands at the entrance to the mines. Vast and patient. Waiting. For what, no one knows.
You and {s("he", "she")} went back to Ashmoor and mended the roof. You finished it at last.
In the evenings you sit by the fire, as before. Only now {sp()} sometimes looks at you for a long time, without blinking. As if trying to remember who you are. Or to count what you cost the world.
{ irena_confronted != "left":
    Irena did not go back to the temple. They say she walks from village to village and prays over those who cannot die.
}
Garret came once, sat by your fire, drank and left. The wound in his side never healed. Nor did it kill him. You never saw him again.
{
- velior_fate == "forgiven":
    Velior led the people out of the pens, as he had promised, and vanished. Sometimes something turns up on the porch: a sack of salt, a knife, boots that fit. Never a note.
- velior_fate == "exiled":
    No one ever saw Velior again. He was the first to leave the hall of the seal, while Liara had not yet reached the way out.
- else:
    You buried the dagger with the crown behind the house. Sometimes {sp()} asks whose it was. You don't answer.
}
No one ever named the price.
{ ch5_hunt_done:
    You put the council seal in the chest with grandmother's embroidery. {sp()} never once asked what it was.
}
THE END. "Love". # ending:love
-> END

= epi_peace
When the party climbed to the surface, the dead up there were already gone. They had fallen in the same hour the seal held. The kingdom of Eldmar was free. Without a king, without a council, without an army. Simply free.
{saved_count} {people(saved_count)} came out of the mines.
{
- column_choice == "neighbors":
    Your neighbours were not among them: they never reached the mines. The Haskers, the smith's wife and Oldric's boy went back to Ashmoor that autumn, to old Oldric, and rebuilt the village together.
- ch1_choice == "riot":
    Your neighbours came out before anyone else, from the barracks, together with Mab. Oldric's boy kept his word and told his father that you had come.
- else:
    Your neighbours were not among them. The column had been driven into the shafts long before you could come back for them.
}
{ ch1_choice == "riot":
    Mab and her people from the barracks reached the runaways' camp on the surface. They say there is a village there now.
}
{ ch4_arithmetic == "refuse":
    Thirty people from the cages above the foundry. Every last one.
}
{ ch4_debt == "paid":
    Corvin Haas did not come out of the pens. A month later Renna Sol sent a small cask of wine, without a note. You poured it into a ditch.
}
{
- velior_fate == "forgiven":
    Velior went back for the people in the pens, as he had promised. He led them all out. Then he left without telling anyone where. They say he was seen in the south, among the old houses, the ones that are still hiding. He warns them.
- velior_fate == "exiled":
    Velior vanished during the fight. You never learned whose side he was on in that moment. Later someone took apart the stone at the third pillar.
- else:
    In Ashmoor they know nothing of Velior. You don't tell them. Sometimes it seems that only he would understand why you count.
}
{ irena_confronted != "left":
    Irena held a service for the one who went into the seal. Without a name. That way, she said, is more right: names are for the living.
}
You went back to Ashmoor. The roof was whole. The bowls stood where you had left them.
Sometimes, in your sleep, you see the light. And in it two figures in white. They stand side by side and look at you. They don't call. They just look.
You were not given a medal. You would not have taken it.
Ten years later you understood that Edric had been right. You count. Days, then years. But you cannot stop yet.
{ ch5_hunt_done:
    You took the council seal to the capital and laid it on the council's empty table. The order about Liara you kept.
}
THE END. "Peace". # ending:peace
-> END

= epi_guardian
The dead fell in the same hour the Sleeper's power entered you. You felt each of them. Like snow that had stopped falling.
{saved_count} {people(saved_count)} came out of the mines. You walked them all the way to the entrance. Further you could not go: what you held held you too.
{sp()} was the last to leave.
At the entrance to the mines, where an eternity ago you had stood at the gate and watched the cart drive away, the two of you stopped.
"You did to me what I did to you," {s("he", "she")} said. "Decided for me. So that I'd be all right." # spk:spouse # mood:sad
"Yes." # spk:hero
"Now I know what it's like." {s("He", "She")} smiled. "Forgive me." # spk:spouse
"For what?" # spk:hero
"For a few quiet years." # spk:spouse
{s("He", "She")} went up, towards the light. You watched for as long as you could.
Garret went up to the surface. He said he had stood over people underground long enough. Once a year he comes to the entrance{irena_confronted != "left": with Irena}. He tells you what is happening up there. You listen.
{ irena_confronted != "left":
    Irena reads a prayer. The one for the living.
}
{
- velior_fate == "forgiven":
    Velior led the people out of the pens, as he had promised. He did not stay to say goodbye. They say he now goes from one old house to the next, teaching them to hide better.
- velior_fate == "exiled":
    A year later Velior came. He sat at the edge of the seal and said that he had walled up the crack behind the pillar himself. You forgave him. Forgiving is easy for you now.
- else:
    Velior lies in the dwarven forge, under the slab by the hearth. You feel him, as you feel all the dead. He is the only one who does not ask to be let go.
}
You hold. As the dwarves held. As Liara held. Sometimes it seems to you that the one you hold is not an enemy. Just winter. You don't argue with him. You just hold.
{ ch5_hunt_done:
    The council seal lies by your hand, at the edge of the light. Sometimes you read the note "Found" and think that Edric was not so very wrong.
}
THE END. "Keeper of the Deep". # ending:guardian
-> END

= epi_tyrant
The dead did not fall.
They stopped. All at once, across the whole kingdom. They turned their heads. And walked down, to the mines, to you. Because now you were the one who holds death. And death, it turns out, can be more than held.
{saved_count} {people(saved_count)} came out of the mines. You let them go. By then you did not care how many.
{sp()} was the last to leave. At the very way out, {s("he", "she")} turned round.
{
- velior_fate == "killed":
    "You killed a man who didn't even defend himself," {s("he", "she")} said. "He told me. Edric. He was proud of you." # spk:spouse
- ch2_choice == "hand_over":
    "You sold the fugitives for safe passage," {s("he", "she")} said. "To get to me. For my sake. I didn't ask for that." # spk:spouse
- ch4_arithmetic == "pass":
    "You walked past the cages," {s("he", "she")} said. "Past thirty people. For my sake." # spk:spouse
- else:
    "You decided for me again," {s("he", "she")} said. "For the last time, you said. You lied." # spk:spouse
}
"I don't know you," said {sp()}. "The one I loved stayed somewhere up above. In Ashmoor. Under a leaking roof." # spk:spouse # mood:sad
{s("He", "She")} left and did not come back.
{ irena_confronted != "left":
    Irena left with {s("him", "her")}. Before she went she said only one thing to you: "He was a righteous man too."
}
{
- velior_fate == "forgiven":
    Velior led the people out of the pens, as he had promised. Then he came once, looked at your throne and left. He remembered too well who had sat on it before.
- velior_fate == "exiled":
    Velior came a year later. He knelt by the throne, as he once had before Edric. You took him in. As then, he had nowhere else to go.
- else:
    Sometimes you call for Velior. The dead come now when you call. He does not come. It is the only thing that does not obey you.
}
Garret stayed. The only one. He sits by your throne and says nothing. Sometimes he says that Annet would not have forgiven him. Then he is silent again.
Years later, in a village at the edge of the kingdom, {sp()} tells children a tale about the darkness in the deep. About someone who went down after the one they loved and never came back. {s("He", "She")} never says the name.
The children ask what became of the one who went down.
"{h("He", "She")} is still there," answers {sp()}. "Holding." # spk:spouse
{ ch5_hunt_done:
    You melted down the council seal in the very first winter. There is no council any more. There is you.
}
THE END. "The New Master of the Deep". # ending:tyrant
-> END

// How many prisoners came out of the mines over the whole game. The numbers are drafts, see chapter5-plan.md.
// The neighbours rescued from the column (column_choice == "neighbors", 38 people) are not counted here:
// they never reached the mines, and the "Peace" epilogue speaks of them separately.
=== function count_saved()
~ saved_count = 0
{ ch1_choice == "riot":
    ~ saved_count += 60
}
{ ch2_choice == "fight":
    ~ saved_count += 15
}
{ ch4_vats == "whisper":
    ~ saved_count += 12
- else:
    ~ saved_count += 7
}
{
- ch4_arithmetic == "refuse":
    ~ saved_count += 30
- ch4_arithmetic == "play":
    ~ saved_count += 10
}
{ ch5_secret_path:
    ~ saved_count += 40
- else:
    ~ saved_count += 25
}
{ ch4_debt == "paid":
    ~ saved_count -= 1
}

// The word "person" agreeing with the number: 1 person, 2 people, 21 people.
=== function people(n)
{ n == 1:
    ~ return "person"
- else:
    ~ return "people"
}
