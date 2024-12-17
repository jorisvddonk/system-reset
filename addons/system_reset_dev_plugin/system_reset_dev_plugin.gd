@tool
extends EditorPlugin
var script_ide_plugin: EditorPlugin = null

func _enter_tree():
	if OS.has_feature("editor"):
		# Add script-ide plugin if it's found locally and we are in Editor mode
		add_script_ide()

func _exit_tree():
	if OS.has_feature("editor"):
		# Remove script-ide plugin if it was added previously
		remove_script_ide()
		
func add_script_ide():
	if ResourceLoader.exists("res://addons/script-ide/plugin.gd"):
		printt("Adding script-ide plugin")
		const ScriptIDEPlugin = preload("res://addons/script-ide/plugin.gd")
		script_ide_plugin = ScriptIDEPlugin.new()
		EditorInterface.get_editor_main_screen().add_child(script_ide_plugin)

func remove_script_ide():
	if script_ide_plugin != null:
		printt("Removing script-ide plugin")
		EditorInterface.get_editor_main_screen().remove_child(script_ide_plugin)
