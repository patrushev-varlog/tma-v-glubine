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

-> prologue -> chapter1 -> END

=== prologue ===
-> evening -> raid -> ashes -> temple -> deserter -> column -> interrogation_scene ->
->->

// Сцены главы подключаются по мере написания.
=== chapter1 ===
-> gate -> cage -> rest ->
->->
