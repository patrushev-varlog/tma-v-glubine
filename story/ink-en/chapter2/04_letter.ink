// Chapter 2, scene 4. "The letter". English parallel of story/ink/chapter2/04_letter.ink.
// About 8 minutes. Velior's secret: he compiled the "list". Velior's fate is decided in chapter 3.

VAR velior_confronted = ""   // "truth" / "rage" / "wait"

=== letter ===
The top letter was unsigned, but no signature was needed. You knew the hand at once. Even, without a single blot, almost courteous. The same as on the "list".
"To Mistress Sol. Terms as before: for each head, as agreed; for heads of the old houses, three times that, alive and unharmed. I enclose a register of the old houses for checking."
Below it, a column of family names. In the middle: "Tal".
And a postscript at the bottom, smaller:
"Scout V., who compiled this register for me, has left my service. Do not touch him. He will come back of his own accord, once he understands he has nowhere else to go."
Slowly you raised your head.
Velior stood by the door. He had already read the letter over your shoulder; you could tell by his face. There was no joke in it.
"Yes," he said, before you could ask. "It was me." # spk:velior # mood:tense
{ velior_terms == "conditions":
    "You promised to answer," you said. # spk:hero
    "And I did answer. You didn't ask the right way." # spk:velior # mood:tense
}
{ velior_asked_list:
    "I asked you straight out. About the list. You said: scribes in the capital." # spk:hero
    "I was a scribe. One of them. Just a very good one." # spk:velior # mood:tense
}
"He told me to find the old houses. The ones whose blood 'remembers'. I searched church books, gravestones, the songs grandmothers sing." Velior rubbed his burned cheek. "I found lines. I didn't know what he did with them. Then I found out. Then I left." # spk:velior
"You found my family too." # spk:hero
"Tal." He did not look away. "Yes. It was hard. They hid well. Sixty years." # spk:velior
* ["Tell me everything. Now. From the beginning."]
    ~ velior_confronted = "truth"
    -> confront_truth
* [Grab him by the throat.]
    ~ velior_confronted = "rage"
    -> confront_rage
* ["Not here. We'll talk when we're safe."]
    ~ velior_confronted = "wait"
    -> confront_wait

= confront_truth
"Tell me everything. From the beginning." # spk:hero
Velior sat on the edge of the desk, as if his legs had stopped holding him.
"The King saved me from the gallows. I was a thief and a tracker, and he said: you know how to find what people hide. Find me people. I found them. Twelve houses, in half a year. He was... grateful. He burned the crown into me with his own hand. I was proud." # spk:velior
"And then?" # spk:hero
"And then I saw what was done to the ones I'd found. Not yours. Others, earlier." He fell silent. "I left that same night. Struck through the crown. And ever since I've been waiting for him to come for me. And he doesn't come." # spk:velior
-> reactions

= confront_rage
You did not remember how you ended up next to him. You remembered only his throat under your fingers, and that he did not resist.
Garret pulled you off him, grabbing you from behind.
"Not like this," he said into your ear. "Not here. Not like this. Believe me, I know what it's like afterwards." # spk:garret
Velior slid down the wall, coughing.
"Fair," he wheezed. "I'd do the same in your place." # spk:velior
-> reactions

= confront_wait
"Not here. We'll talk when we're safe. You'll tell me everything later." # spk:hero
"Later," Velior repeated. "You're like Renna. Everything later." He smiled crookedly. "Fine. I'm not going anywhere. As you can see, I've nowhere to go." # spk:velior
-> reactions

= reactions
"I knew he was lying," said Irena. "I didn't know about what." # spk:irena # mood:tense
Garret was silent for a long time.
"I carried a whip myself," he said at last. "Who am I to judge him. But it's your call. Maybe not now. But yours." # spk:garret
You folded the letter and put it inside your shirt, next to the "list". Two papers, one hand.
->->
