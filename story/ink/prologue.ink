// Точка входа пролога. Сцены подключаются по мере написания.
INCLUDE common.ink
INCLUDE prologue/01_evening.ink
INCLUDE prologue/02_raid.ink
INCLUDE prologue/03_ashes.ink

// Каждая сцена — туннель: заканчивается ->-> и возвращает управление сюда.
-> evening -> raid -> ashes -> END
