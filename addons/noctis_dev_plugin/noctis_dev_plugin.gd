@tool
extends EditorPlugin

func _enter_tree():
	add_tool_menu_item("Simulate Vimana Flight", callback)

func callback():
	pass
	#Globals.vimanaFlight()

func _exit_tree():
	remove_tool_menu_item("Simulate Vimana Flight")
