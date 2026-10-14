// Chapter 5, scene 3. "The reunion". English parallel of story/ink/chapter5/03_reunion.ink.
// ~12 minutes. The spouse knew and kept silent. Echoes of the evening at home and of the column. The main turn: the spouse chooses to become the seal.

=== reunion ===
You did not remember crossing the hall. You remembered only that {sp()} raised {s("his", "her")} head and saw you, and {s("his", "her")} face became what it had been that evening when you first came to {s("his", "her")} house.
Then you were holding {s("him", "her")}. Just holding. There were no chains. No one was keeping {s("him", "her")} here by force.
"You came," said {sp()}. # spk:spouse
{
- promise_made:
    "You promised not to look for me," {s("he", "she")} said, and laughed and cried at once. # spk:spouse # mood:sad
    "I lied." # spk:hero
    "I knew you'd lie. I hoped you wouldn't. And I knew." # spk:spouse
- promise_refused:
    "You said you'd find me anywhere," {s("he", "she")} said. "It frightened me then. I knew you weren't lying." # spk:spouse # mood:sad
- else:
    "That evening you didn't answer. You just held me." {s("He", "She")} pressed {s("his", "her")} face into your shoulder. "I knew that meant 'I'll find you'." # spk:spouse # mood:sad
}
{ evening_roof:
    "The roof must be leaking again," {s("he", "she")} said, out of nowhere. "You never did finish it. Or did you? I don't remember any more. I only remember the rain." # spk:spouse
- else:
    "Remember that evening? The bowls under the drips. We sat and listened to the rain." {s("He", "She")} was silent for a moment. "I thought then: let there be one more evening like this. One more. And another." # spk:spouse
}
{ ch4_report_read:
    -> knew_already
- else:
    -> knew_question
}

= knew_already
"I read the report," you said. "In the forges. 'Warned by the family'." # spk:hero
{sp()} did not look away. For the first time.
-> knew_answer

= knew_question
* ["Did you know?"]
    "Did you know?" # spk:hero
    {sp()} did not look away. For the first time.
    -> knew_answer
* [Ask nothing.]
    You asked nothing. {s("He", "She")} understood and answered anyway.
    -> knew_answer

= knew_answer
"Grandmother told me when I was twelve. About the sister 'the king took'. About our blood. About how one day they would come for one of us again." # spk:spouse
{
- legend_pressed:
    "You asked me back then. By the hearth. I almost told you." # spk:spouse
- legend_joked:
    "You joked about royal brides back then. I laughed so I wouldn't have to tell you." # spk:spouse
}
"If you'd known, you'd have carried me off to the end of the world and lived your life in fear. Looked round at every knock. I didn't want that. I wanted us to have at least a few quiet years." # spk:spouse # mood:sad
"And we had them," {s("he", "she")} said. "We really did." # spk:spouse
* ["You had no right to decide for me."]
    "You had no right to decide for me." # spk:hero
    "No, I didn't," {s("he", "she")} agreed. "And in my place, would you?" # spk:spouse
    You did not answer.
* ["They were the best years of my life."]
    "They were the best years of my life," you said. # spk:hero
    {sp()} closed {s("his", "her")} eyes. As if that was all {s("he", "she")} had wanted to hear.
-
-> column_echo

= column_echo
"He told me about you," said {sp()}. "Every evening. How you were coming. What you had chosen." # spk:spouse
{ column_choice == "neighbors":
    "You freed the column. Oldric, the Haskers, everyone. You let the cart with me go to save them." {s("He", "She")} smiled. "He didn't understand. But I was proud. I've never been so proud." # spk:spouse # mood:smile
- else:
    "You left the column to catch up with me. The neighbours. Oldric." {s("He", "She")} was silent for a long time. "He was pleased. He said: see how {h("he", "she")} loves you. And I don't know how to live with it. With them being down there because of me." # spk:spouse # mood:sad
}
Then {s("he", "she")} drew back. Not far. Half a step. Just far enough to look you in the eyes.
"I have to tell you one more thing. Before he comes." # spk:spouse
"The seal is weakening. Liara has held it for sixty years, and she's tired. She has to be replaced. Or it has to be broken, the way he wants." {s("He", "She")} spoke calmly, as if about the weather. "I've decided. I'll become the seal." # spk:spouse
"Not because he forced me. Not because of the council. Myself. Me. No one will hold my hand and weep. I'll walk in on my own, like walking into water." # spk:spouse
{ spouse_f:
    "She's been there sixty years alone," said {sp()}. "Liara. My blood. I want her to be let go." # spk:spouse
- else:
    "She's been there sixty years alone," said {sp()}. "Liara. My blood. I want her to be let go." # spk:spouse
}
Somewhere behind you, at the entrance to the hall, there were footsteps. Slow. Shuffling. The footsteps of a very old man.
->->
