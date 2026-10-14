// Chapter 3, scene 5. "The shrine". English parallel of story/ink/chapter3/05_shrine.ink.
// About 8 minutes. Irena's bell (a relic) and a clear vision of Liara.

VAR irena_bell = ""        // "blessed" — legendary amulet, "cracked" — cracked (Darkness 50+)

=== shrine ===
Above the hall of the seal the dwarves had cut a small shrine: three steps, a niche, an iron hook in the ceiling. Nothing else. No statue, no sign. The dwarves, it seemed, had prayed to emptiness.
It was colder here than anywhere. And quieter. The silence pressed on your ears like deep water.
Irena stopped by the hook.
"A bell hung here," she said. "See how the stone is worn? Hundreds of years of ringing." # spk:irena
She untied her own bell from her staff: small, copper, dented on one side, the only thing she had carried out of her temple.
"In our temple they used to say a bell rings the way the one beside it hears it." She hung it on the dwarven hook. "I want to hear how it sounds here." # spk:irena
She touched the clapper.
// On the threshold of the Gloom (50–54) the bell decides by whether the hero waited for Irena in the temple (irena_hesitation_respected).
{
- darkness < 50:
    -> bell_blessed
- darkness < 55 && irena_hesitation_respected:
    -> bell_blessed
- else:
    -> bell_cracked
}

= bell_blessed
~ irena_bell = "blessed"
The sound was clear. So clear that your throat tightened. It did not die away, as bells do, but went down, through the stone, and came back from there as an echo for a long time, though there was no echo here.
Irena was weeping and did not hide it.
{ darkness >= 50:
    "You waited at the door that time," she said, without wiping her tears. "While I called them by their names. He remembers. So do I." # spk:irena
}
"He is here," she said. "My god. Even here." # spk:irena # mood:smile
She took down the bell and held it out to you on her palm. The copper was warm.
"Let the one who walks in front carry it. It will ring as long as you remember why you are going." # spk:irena # item:irena_bell
-> vision

= bell_cracked
~ irena_bell = "cracked"
The sound came out muffled, as if the bell had been wrapped in a rag. And then a crack ran down the copper from top to bottom, thin as a hair.
Irena took down the bell and looked at the crack for a long time.
Then she looked at you. She said nothing. She just tied the bell back onto her staff and stepped away.
Garret looked at you too. The way you look at someone in whom you recognise someone you know. Perhaps yourself.
-> vision

= vision
When you turned round, your companions were gone.
The shrine was the same. But the light had turned white, and a woman stood in the niche. The same one, from the end of the tunnel. Now you could see her face: young, tired, with straight brows. Familiar. You could not tell from where.
{ liara_ch2_heard:
    You knew her before she spoke: it was her voice that had called from the black water.
}
{
- darkness < 25:
    "My name is Liara," she said. Warmly, the way one speaks to someone who has walked a long way. "You did want to know." # spk:liara
- darkness < 50:
    "My name is Liara," she said. "You wanted to know who I am. And I don't yet know who you are." # spk:liara
    She looked at you as if checking whether you were the one she had been waiting for.
- else:
    "My name is Liara," she said. "He too asked my name of everyone he raised. Not one of them answered." # spk:liara
    She looked not at you but somewhere through you, as if searching you for someone else. And, it seemed, finding them.
}
"Look," she said. # spk:liara
And you saw.
A circle. Stone under bare feet, icy, wet. People in robes all around, and their faces really are all the same, you cannot tell them apart, you do not even try. You look only at one.
He is holding your hand. He is weeping. He does not even try not to weep. He says "Forgive me", and then he says words that make the stone under your feet turn hot, and then cold, and then you stop feeling it.
The last thing you see is his face. The last thing you feel is his hand. He does not let go until the very end.
The vision ended. Liara stood in the niche.
"He didn't let go," she said. "Sixty years have passed, and still he won't let go." # spk:liara
{ spouse_f:
    "The one you are following... She is of my blood. I know where she is being taken. I lie where she will lie." # spk:liara
- else:
    "The one you are following... He is of my blood. I know where he is being taken. I lie where he will lie." # spk:liara
}
* ["Tell me what to do."]
    "Tell me what to do." # spk:hero
    "No," said Liara. Without anger. "Once, someone already decided for me. I will not decide for you." # spk:liara
* ["Do you hate him?"]
    "Do you hate him? Edric?" # spk:hero
    Liara was silent for a long time.
    "I pity him," she said. "That is worse, for him. He would rather be hated." # spk:liara
* [Hold out your hand without a word.]
    You held out your hand without a word. She looked at it and did not take it.
    "Don't," said Liara. "He held out his hand once too." # spk:liara
-
The white light went out. Irena was shaking you by the shoulder.
"You were talking to someone again," she said. "You were crying." # spk:irena
"Her name is Liara," you said. # spk:hero
->->
