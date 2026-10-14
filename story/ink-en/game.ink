// Точка входа английской истории (демо для Next Fest — английский пролог, решение 6 плана 07).
// Пролог, глава 1 и common.ink — переведённые файлы из этой папки; главы 2–5 пока подключены из
// story/ink и идут по-русски, пока их не переведут (каждую главу — перед её сборкой). Переведённую
// главу подключать отсюда так же, как пролог и главу 1. Структура обязана совпадать с story/ink/game.ink:
// игра переносит сохранения между языками проигрыванием журнала выборов.
INCLUDE common.ink
INCLUDE ../ink/explore_common.ink

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
INCLUDE chapter1/explore.ink

INCLUDE ../ink/chapter2/01_black_water.ink
INCLUDE ../ink/chapter2/02_fugitives.ink
INCLUDE ../ink/chapter2/03_smugglers.ink
INCLUDE ../ink/chapter2/04_letter.ink
INCLUDE ../ink/chapter2/05_projection.ink
INCLUDE ../ink/chapter2/06_sluice.ink
INCLUDE ../ink/chapter2/07_camp.ink
INCLUDE ../ink/chapter2/explore.ink

INCLUDE ../ink/chapter3/01_arches.ink
INCLUDE ../ink/chapter3/02_refuge.ink
INCLUDE ../ink/chapter3/03_fresco.ink
INCLUDE ../ink/chapter3/04_archive.ink
INCLUDE ../ink/chapter3/05_shrine.ink
INCLUDE ../ink/chapter3/06_keeper.ink
INCLUDE ../ink/chapter3/07_judgment.ink
INCLUDE ../ink/chapter3/08_camp.ink
INCLUDE ../ink/chapter3/explore.ink

INCLUDE ../ink/chapter4/01_workshops.ink
INCLUDE ../ink/chapter4/02_reports.ink
INCLUDE ../ink/chapter4/03_flesh_master.ink
INCLUDE ../ink/chapter4/04_arithmetic.ink
INCLUDE ../ink/chapter4/05_foundry.ink
INCLUDE ../ink/chapter4/06_camp.ink
INCLUDE ../ink/chapter4/explore.ink

INCLUDE ../ink/chapter5/01_descent.ink
INCLUDE ../ink/chapter5/02_seal_hall.ink
INCLUDE ../ink/chapter5/03_reunion.ink
INCLUDE ../ink/chapter5/04_offer.ink
INCLUDE ../ink/chapter5/05_finale.ink
INCLUDE ../ink/chapter5/06_epilogue.ink
INCLUDE ../ink/chapter5/explore.ink

-> prologue -> chapter1 -> chapter2 -> chapter3 -> chapter4 -> chapter5 -> END

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

// Глава 5 заканчивается эпилогом с -> END внутри: концовок четыре.
=== chapter5 ===
-> descent -> seal_hall -> reunion -> offer -> finale -> epilogue
