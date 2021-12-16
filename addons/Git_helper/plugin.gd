tool
extends EditorPlugin


const dock = preload("res://addons/Git_helper/res/git_dock.tscn")


var dock_instance


func _enter_tree():
	dock_instance = dock.instance()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock_instance)


func _exit_tree():
	remove_control_from_docks(dock_instance)
	dock_instance.queue_free()
