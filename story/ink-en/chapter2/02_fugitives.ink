// Chapter 2, scene 2. "The fugitives". English parallel of story/ink/chapter2/02_fugitives.ink.
// About 8 minutes. Escaped prisoners on a dry ledge. If there was a riot in chapter 1, Mab leads them.

VAR ch2_fugitives_leader = ""   // "meb" / "tobin"

=== fugitives ===
{ ch1_choice == "riot":
    ~ ch2_fugitives_leader = "meb"
- else:
    ~ ch2_fugitives_leader = "tobin"
}
The tunnel climbed, and the water dropped to the knees. On a dry ledge under the roof someone was burning a tiny fire of splinters. People sat around it: thin, in the rags of convict shirts.
{ ch2_fugitives_leader == "meb":
    A woman with a shaved head rose to meet you.
    "Mab," said Garret. # spk:garret
    "Not all of us went up," said Mab. "There are guards up there too. We reckoned nobody would look for us down here." She looked at you. "You came for us in the barracks. I remember." # spk:meb
- else:
    A stooped man with a bandaged arm rose to meet you.
    "Tobin," he said. "We're from the lower barracks. Got out on our own while the overseers were fighting someone up top." # spk:tobin
    He looked you over and let his eyes rest on Garret, on his army boots.
    "You're not guards. Guards don't walk like that." # spk:tobin
}
"Where are you going?" you asked. # spk:hero
"Away from here," {ch2_fugitives_leader == "meb":said Mab|said Tobin}. "Only there are two ways out. Back to the barracks. Or through the sluice, to the old dwarven passages. They say there's a way up to the surface there." # spk:fugitive
"And the sluice?" # spk:hero
"Smugglers hold the sluice. Renna Sol. She trades with the King. Selling us pays her better than letting us through." # spk:fugitive # mood:tense
* ["You'll come with us. We'll work something out."]
    "You'll come with us. We'll work something out." # spk:hero
    Something flickered in the fugitives' eyes that you had not seen in anyone in these mines for a long time. Hope, perhaps.
* ["We promise nothing. But walk with us."]
    "We promise nothing. But walk with us, it's safer." # spk:hero
    "That's more than anyone's promised us," {ch2_fugitives_leader == "meb":said Mab|said Tobin}. # spk:fugitive
-
Velior walked last and said nothing. Irena noticed and looked at you.
// On the ledge map: the bedding at the far end (nook 2), the fugitives' leader (clue 2).
+ [Go on to the pumping station. #obj:path_on]
-
->->
