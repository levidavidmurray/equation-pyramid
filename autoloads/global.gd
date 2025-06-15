@tool
extends Node

var ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("")

func wait(time: float) -> Signal:
	return get_tree().create_timer(time).timeout

func factorial(n: int) -> int:
	if n <= 1:
		return 1
	var result = 1
	for i in range(2, n + 1):
		result *= i
	return result
