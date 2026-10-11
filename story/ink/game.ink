// Точка входа всей истории. Каждая глава — туннель из сцен-туннелей.
// Для отладки игра может начать с любой главы: story.ChoosePathString("chapter1").
INCLUDE common.ink

INCLUDE prologue/01_evening.ink
INCLUDE prologue/02_raid.ink
INCLUDE prologue/03_ashes.ink
INCLUDE prologue/04_temple.ink
INCLUDE prologue/05_deserter.ink
INCLUDE prologue/06_column.ink
INCLUDE prologue/07_interrogation.ink

INCLUDE chapter1/01_gate.ink
INCLUDE chapter1/02_cage.ink
INCLUDE chapter1/03_rest.ink
INCLUDE chapter1/04_barracks.ink
INCLUDE chapter1/05_white_woman.ink
INCLUDE chapter1/06_lift.ink
INCLUDE chapter1/07_camp.ink

INCLUDE chapter2/01_black_water.ink
INCLUDE chapter2/02_fugitives.ink
INCLUDE chapter2/03_smugglers.ink
INCLUDE chapter2/04_letter.ink
INCLUDE chapter2/05_projection.ink
INCLUDE chapter2/06_sluice.ink
INCLUDE chapter2/07_camp.ink

INCLUDE chapter3/01_arches.ink
INCLUDE chapter3/02_refuge.ink
INCLUDE chapter3/03_fresco.ink
INCLUDE chapter3/04_archive.ink
INCLUDE chapter3/05_shrine.ink
INCLUDE chapter3/06_keeper.ink
INCLUDE chapter3/07_judgment.ink
INCLUDE chapter3/08_camp.ink

INCLUDE chapter4/01_workshops.ink
INCLUDE chapter4/02_reports.ink
INCLUDE chapter4/03_flesh_master.ink
INCLUDE chapter4/04_arithmetic.ink
INCLUDE chapter4/05_foundry.ink
INCLUDE chapter4/06_camp.ink

-> prologue -> chapter1 -> chapter2 -> chapter3 -> chapter4 -> END

=== prologue ===
-> evening -> raid -> ashes -> temple -> deserter -> column -> interrogation_scene ->
->->

=== chapter1 ===
-> gate -> cage -> rest -> barracks -> white_woman -> lift -> camp1 ->
->->

=== chapter2 ===
-> black_water -> fugitives -> smugglers -> letter -> projection -> sluice -> camp2 ->
->->

=== chapter3 ===
-> arches -> refuge -> fresco -> archive -> shrine -> keeper -> judgment -> camp3 ->
->->

=== chapter4 ===
-> workshops -> reports -> flesh_master -> arithmetic -> foundry -> camp4 ->
->->
