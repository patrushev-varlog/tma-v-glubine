// Chapter 4, scene 5. "The foundry". English parallel of story/ink/chapter4/05_foundry.ink.
// ~10 minutes including the chapter's battle 3. The breakthrough to the descent to the bottom and the vision of Liara.

=== foundry ===
{ ch4_arithmetic == "refuse":
    The fight began right there in the hall and rolled down into the foundry, where liquid iron ran along the channels and the air shook with heat.
    // Battle 3 ("refusal" variant): the executioners from the hall and the foundry garrison at once. The prisoners in the cages are to be protected.
    Behind your backs the prisoners shouted at you not to die. # battle:chapter4_3_refuse
- else:
    The foundry lay between the hall and the descent to the bottom. Channels of liquid iron, ladles on chains, heat that split the skin. And a garrison that knew you were coming.
    // Chapter battle 3: the breakthrough through the foundry. The ladles and channels are a danger to both sides.
    The ladles overhead swayed. # battle:chapter4_3
}
-> after_fight

= after_fight
When it was all over, the foundry stood empty. The ladles were cooling. Somewhere ahead, beyond the last arch, a staircase began. Down. To where not even the heat rose from.
{ ch4_arithmetic == "refuse":
    The prisoners came out of the cages one by one, carefully, as if the floor might give way. Thirty. All of them.
    "All of them," said Irena, and laughed, for the first time in many days. "Every last one." # spk:irena # mood:smile
}
You stopped at the edge of a channel. The light still glinted in the cooling iron, and in that light a face appeared.
Liara.
{
- darkness < 25:
    She looked at you with tenderness. The way you look at someone who can still choose otherwise.
- darkness < 50:
    She looked at you with unease. The way you look at someone walking along an edge who cannot see where the edge is.
- darkness < 75:
    She looked at you coldly. As at a stranger. As she would perhaps have looked at Edric, if she could see him.
- else:
    She barely looked at you. Her lips moved, but there were no words. Only one, at the very end.
}
{
- darkness < 25:
    "Don't make {s("him", "her")} become me," said Liara. # spk:liara
    "He made me be strong," she added. "That is the most terrible thing you can do to someone you love." # spk:liara
- darkness < 50:
    "Don't make {s("him", "her")} become me," said Liara. "You can still choose not to count. He could too, once." # spk:liara
- darkness < 75:
    "Don't make {s("him", "her")} become me," said Liara. "Though you seem to have decided already what you will become yourself." # spk:liara
- else:
    "Edric," said Liara. Looking at you. # spk:liara
}
The reflection went out. The iron set, dull and grey.
+ [Go to the last furnace that still holds its heat. #obj:last_furnace]
-
->->
