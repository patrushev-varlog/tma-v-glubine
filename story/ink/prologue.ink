// Точка входа пролога. Сцены подключаются по мере написания.
INCLUDE common.ink
INCLUDE prologue/01_evening.ink
INCLUDE prologue/02_raid.ink
INCLUDE prologue/03_ashes.ink
INCLUDE prologue/04_temple.ink
INCLUDE prologue/05_deserter.ink
INCLUDE prologue/06_column.ink
INCLUDE prologue/07_interrogation.ink

// Каждая сцена — туннель: заканчивается ->-> и возвращает управление сюда.
-> evening -> raid -> ashes -> temple -> deserter -> column -> interrogation_scene -> END
