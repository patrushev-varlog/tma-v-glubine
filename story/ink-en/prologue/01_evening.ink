// Prologue, scene 1. "Evening at home". English parallel of story/ink/prologue/01_evening.ink.
// Translation rule: one Russian line = one English line; the same choices, tags, diverts,
// VARs and ~ statements in the same order. Text is free: drop h()/s() where English
// needs no gender form, add them where it does (his/her).

VAR evening_roof = false
VAR evening_together = false
VAR evening_asked_scribe = false
VAR evening_asked_future = false
VAR evening_asked_songs = false
VAR legend_pressed = false      // insisted on the truth about the grandmother's sister
VAR legend_joked = false
VAR promise_made = false        // promised not to search
VAR promise_refused = false     // refused outright
VAR asked = 0                   // how many topics were asked about

=== evening ===
// Camera: a house at the edge of Ashmoor, dusk, rain.
Autumn always came to Ashmoor with the rain. This year it also came with silence: not one merchant had travelled the road since last winter.
They said the capital had fallen in a single winter. They said the dead now wore the king's colours. Ashmoor stood at the very edge of the map, and rumours reached it the way rain gets through an old roof: a drop at a time.
A drop fell into the bowl on the table. {sp()} did not look up from {s("the harness", "the sewing")}.
"Again," said {sp()}. "One more week of this and we'll be sleeping in a boat." # spk:spouse # mood:smile

* [Climb onto the roof before it gets dark.]
    ~ evening_roof = true
    -> roof
* [Let it be and sit down beside {s("him", "her")}.]
    ~ evening_together = true
    -> together

= roof
The ladder creaked on every rung. The shingles by the chimney had rotted through; you plugged the hole with a slab of bark and weighted it with a stone, the way your father taught you.
Through a gap between the boards you could see the lamp and the top of a head below: {sp()} was still sitting over {s("the harness", "the sewing")}.
"Are you going to be up there long?" called {sp()} from below. "I can talk to the ceiling, but you're better company." # spk:spouse # mood:smile
"Talk to the ceiling. Tonight the ceiling is more use than me." # spk:hero
"The ceiling can't take offence. That's its finest quality." # spk:spouse # mood:smile
-> talk

= together
You set a second bowl under the drip and sat down on the bench. {sp()} moved over without asking, as if the place beside {s("him", "her")} had always been yours.
"The roof will sulk," said {sp()}. # spk:spouse # mood:smile
"The roof will live. Tonight I want to sit with you." # spk:hero
{sp()} smiled into the fire, the way people smile at something they have long waited for and been afraid to ask for aloud.
-> talk

// The player asks two questions out of three.
= talk
~ asked = 0
-> talk_loop

= talk_loop
{ asked >= 2:
    -> legend
}
* [Ask about the scribe.]
    ~ evening_asked_scribe = true
    ~ asked++
    -> scribe
* [Ask what happens if the dead come this far.]
    ~ evening_asked_future = true
    ~ asked++
    -> future
* [Ask about the songs {sp()} sings when {s("he", "she")} thinks no one is listening.]
    ~ evening_asked_songs = true
    ~ asked++
    -> songs

= scribe
"That man last week. The one with the seal. What does a dead king want with our names?" # spk:hero
{sp()} was quiet longer than an answer needed.
"The king is counting his property. We're his property now." # spk:spouse # mood:tense
"He talked to you longer than to anyone else." # spk:hero
"He asked where my family comes from. I said: from here. That's true. Almost." # spk:spouse # mood:away
-> talk_loop

= future
"If they come this far... Maybe we should cross the pass while the roads are still open?" # spk:hero
"And what's past the pass? Another village, another roof. And other rumours." # spk:spouse # mood:sad
"But it would be us." # spk:hero
"It's us here too," said {sp()}, and took your hand. "Do you know what I'm afraid of? Not the dead. That one day we'll run from fear, and it will follow us. Better to live here while we can." # spk:spouse # mood:sad
-> talk_loop

= songs
"That song you sing at the well. About the water that remembers. Where is it from?" # spk:hero
{sp()} flushed, as if {s("he", "she")} had been caught peeking.
"From my grandmother. She sang it at the spinning wheel. There's a verse further on about a girl who sleeps under the mountain, but I don't remember it." # spk:spouse # mood:away
"You don't remember it, or you don't want to sing it?" # spk:hero
"I don't remember," said {sp()}, too quickly. # spk:spouse # mood:tense
-> talk_loop

= legend
// Leads into the legend. Plays whichever questions were chosen.
The fire sank low. {sp()} looked at the embers for a long time, and then said, as if carrying on an old argument with {s("himself", "herself")}:
"My grandmother had a sister. An older one. The king took her, the old king, some sixty years ago. Grandmother said it was 'for her beauty'. And she cried every time she said it." # spk:spouse # mood:away
"You never told me about her." # spk:hero
"There's nothing to tell. They took her and never gave her back. In our family it's... a legend. Like a song without its last verse." # spk:spouse # mood:away
{sp()} looked away.
* ["You're not telling me everything. Tell me."]
    ~ legend_pressed = true
    -> legend_pressed_branch
* [Ask nothing more. Lay a hand on {s("his", "her")} shoulder.]
    -> legend_let_go
* ["So there are royal brides in your family? Lucky me."]
    ~ legend_joked = true
    -> legend_joke

= legend_pressed_branch
"You're not telling me everything. I can see it. Tell me." # spk:hero
{sp()} looked at you, and for a moment you thought {s("he", "she")} would say it. Then {s("he", "she")} shook {s("his", "her")} head.
"One day. Not tonight. Tonight we have a roof and the rain, and I don't want anything else. Please." # spk:spouse # mood:sad
-> class_line

= legend_let_go
You laid your hand on {s("his", "her")} shoulder. It was tense, then slowly eased.
"Thank you," said {sp()} quietly. "For not asking." # spk:spouse # mood:sad
-> class_line

= legend_joke
"So there are royal brides in your family? I'm luckier than I thought." # spk:hero
{sp()} laughed, short and relieved, and the laugh was louder than the joke deserved.
"You're lucky the king died long ago. Both kings." # spk:spouse # mood:smile
-> class_line

// A line by hero class (special lines in key scenes follow the class, not the background).
= class_line
{ hero_class:
- "wizard":
    {sp()} nodded at your books on the shelf, their spines damp.
    "You sat up over them till dawn again. What are you looking for in there?" # spk:spouse
    "How the world works." # spk:hero
    "And what if it works badly?" # spk:spouse # mood:tense
- "fighter":
    {sp()} looked at the sword above the door, which you had not taken down since you came home.
    "You still oil it every seventh day. Think you'll need it?" # spk:spouse
    "I hope not." # spk:hero
    "So do I," said {sp()}, but kept looking at the sword for a long time. # spk:spouse # mood:tense
- "rogue":
    "The miller was asking about you again," said {sp()}. "He said you have 'clever hands'. Is that meant as praise?" # spk:spouse
    "It's an old debt. I paid it." # spk:hero
    "Good. I don't want you to have a single old debt here." # spk:spouse # mood:smile
- "cleric":
    "You prayed longer than usual today," said {sp()}. "What for?" # spk:spouse
    "For the rain to stop." # spk:hero
    "Liar. But a pretty one." # spk:spouse # mood:smile
}
-> promise

= promise
The lamp was burning down. Already in bed, in the dark, {sp()} said quietly, as if in passing:
"Promise me one thing. If anything happens to me... don't look for me. Go on living." # spk:spouse # mood:sad
"What could happen to you?" # spk:hero
"Nothing. Just promise." # spk:spouse # mood:sad
* ["I promise."]
    ~ promise_made = true
    "I promise," you said, so that {s("he", "she")} would settle. # spk:hero
    {sp()} let out a breath and fell asleep almost at once.
* ["No. I'll find you anywhere."]
    ~ promise_refused = true
    "No. Wherever you are, I'll find you." # spk:hero
    "I knew you'd say that," said {sp()}, and there was something in {s("his", "her")} voice like tenderness, and like fear. # spk:spouse # mood:sad
* [Say nothing and hold {s("him", "her")}.]
    You held {s("him", "her")} tighter than you meant to. {sp()} did not ask again.
-
{evening_roof: The rain drummed on the bark above the chimney.|The water kept dripping, into two bowls now.} Somewhere far off, beyond the forest, a bell struck. Once. Then it was quiet. # sfx:bell_far
->->
