extends "res://tests/npc_validation_6_3.gd"
func run():
	var adapter=load("res://scripts/juego/npc_visual_6_3.gd")
	adapter.config={"enabled":false,"batch":0}
	super.run()
