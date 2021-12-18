tool
extends Control

# EditorPlugin wiki
# https://docs.godotengine.org/en/stable/classes/class_editorplugin.html

# OS wiki
# https://docs.godotengine.org/en/stable/classes/class_os.html

# Check this out for inspiration
# https://gitless.com/
# I could reformat everything to use GitLess and save the binary in plugin folder

# TODO: add hints on buttons that explain how they work, which args they take

onready var helper_input = $VBoxContainer/VBoxContainer/button_input
onready var history = $VBoxContainer/VBoxContainer/history
onready var commandline = $VBoxContainer/VBoxContainer/HBoxContainer/commandline

var settings : Dictionary

var branch = "main"


# TODO: initiate settings from "user://conf.json"
func _init():
	# get settings from conf file or set defaults and save to conf file
	if !file_to_settings():
		settings.git_path = "git"
		
		settings_to_file()

func _ready():
	# so I can have it open in scene editor
	$VBoxContainer/VBoxContainer/more_buttons.visible = false
	$VBoxContainer/VBoxContainer/settings.visible = false
	
	# check if git is already initialised and also disable init button
	if try_set_init_to_done():
		# check on which branch we are and save that to branch variable
		var status = do_git_command(["status"], true)
		var arr = status.split(" ", false, 3)
		arr = arr[2].split("\n")
		branch = arr[0]
	
	is_origin_present()
	
	# add icon to settings button
	# TODO: check if this can be done directly in tscn somehow
	# TODO: get better icon, you can check available icons here
	# https://github.com/godotengine/godot/tree/master/editor/icons
	$VBoxContainer/VBoxContainer/HBoxContainer2/toggle_setings.icon = get_icon("PluginScript", "EditorIcons")


#
# Functions
#

func print_to_history(message:String) -> void:
	history.text += "\n" + message

func do_git_command(command:Array, silent:bool=false) -> String:
	var output = []
	var cmd = array_join(command, " ")
	
	# print the commands
	if !silent:
		print_to_history("$ git " + cmd)
	
	# run git bash script
	var ret = OS.execute(settings.git_path, command, true, output, true)
	var out = array_join(output, "\n")

	if !silent and out.length() > 0:
		print_to_history(out)
	
	if ret != OK:
		print_error("do_git_command failed: return code %d" % ret)
		return "error"

	return out


func do_git_button(command:Array) -> void:
	do_git_command(command)
	helper_input.text = ""

# checks for .git folder and disables Init button if it exists
func try_set_init_to_done() -> bool:
	var dir = Directory.new()
	if dir.dir_exists(".git"):
		$VBoxContainer/VBoxContainer/more_buttons/init.disabled = true
		$VBoxContainer/VBoxContainer/more_buttons/clone.disabled = true
		$VBoxContainer/VBoxContainer/more_buttons/init.text = "Initialised"
		
		return true
	
	return false

# checks for remote called origin and toggles Push, Pull and Set Origin buttons
func is_origin_present() -> bool:
	var remotes = do_git_command(["remote", "-v"], true)
	if "origin" in remotes:
		$VBoxContainer/VBoxContainer/buttons/push.disabled = false
		$VBoxContainer/VBoxContainer/more_buttons/pull.disabled = false
		$VBoxContainer/VBoxContainer/more_buttons/tag_push.disabled = false
		$VBoxContainer/VBoxContainer/more_buttons/set_origin.text = "Set Origin"
		
		return true
	
	else:
		$VBoxContainer/VBoxContainer/buttons/push.disabled = true
		$VBoxContainer/VBoxContainer/more_buttons/pull.disabled = true
		$VBoxContainer/VBoxContainer/more_buttons/tag_push.disabled = true
		$VBoxContainer/VBoxContainer/more_buttons/set_origin.text = "Add Origin"
		
		return false

# joins "arr" array with "glue" delimeter and returns string
func array_join(arr : Array, glue : String = '') -> String:
	var string : String = ''
	for index in arr.size():
		string += str(arr[index])
		if index < arr.size() - 1:
			string += glue
	return string

# checks if branch or tag name is valid
func is_name_ok(text:String) -> bool:
	# get response from git check-ref-format function
	var response = do_git_command(["check-ref-format", "--branch", text], true)
	# delete all newline characters
	response = response.replace("\n","")
	
	# if response is the same as provided text to check it means its valid
	if response == text:
		return true
	
	return false

# checks if remote repo link is valid
# TODO: make better test
func is_link_ok(link:String) -> bool:
	if (!(link == "") and
		!(" " in link) and
		("http" == link.left(4) or "git@" == link.left(4))):
			return true
	
	return false

func print_error(message:String) -> void:
	print_to_history("!ERR: "+message)

func settings_to_file() -> void:
	var save_file = File.new()
	save_file.open("user://conf.json", File.WRITE)
	save_file.store_string(to_json(settings))
	save_file.close()

func file_to_settings() -> bool:
	var save_file = File.new()
	if save_file.file_exists("user://conf.json"):
		save_file.open("user://conf.json", File.READ)
		settings = parse_json(save_file.get_as_text())
		save_file.close()

		return true

	return false

func clear_settings_input_fields():
	$VBoxContainer/VBoxContainer/settings/VBoxContainer/git_path_input.text = ""

func fill_settings_input_fields():
	$VBoxContainer/VBoxContainer/settings/VBoxContainer/git_path_input.text = settings.git_path


#
# Other signals
#

# automatically scrolls history TextEdit when it changes
func _on_history_cursor_changed() -> void:
	var cl = history.get_line_count()
	history.cursor_set_line(cl)


#
# Button signals
#

# TODO: add better checks for text input when present!

func _on_status_pressed() -> void:
	do_git_command(["status"])

func _on_commit_pressed() -> void:
	if helper_input.text != "":
		do_git_button(["commit", "-m", helper_input.text])
	else:
		print_error("empty input box")

func _on_push_pressed() -> void:
	if helper_input.text != "":
		if is_name_ok(helper_input.text):
			do_git_button(["push", "origin", helper_input.text])
		else:
			print_error("branch name has illegal characters")
	else:
		do_git_command(["push", "-u", "origin", branch])

func _on_pull_pressed() -> void:
	if helper_input.text != "":
		if is_name_ok(helper_input.text):
			do_git_button(["pull", "origin", helper_input.text])
		else:
			print_error("branch name has illegal characters")
	else:
		do_git_command(["pull", "origin", branch])

func _on_add_pressed() -> void:
	if helper_input.text != "":
		do_git_button(["add", helper_input.text])
	else:
		do_git_command(["add", "-A"])

func _on_toggle_more_toggled(button_pressed):
	$VBoxContainer/VBoxContainer/more_buttons.visible = button_pressed

func _on_init_pressed() -> void:
	if helper_input.text != "":
		if is_name_ok(helper_input.text):
			do_git_button(["init", "-b", helper_input.text])
		else:
			print_error("branch name has illegal characters")
	else:
		do_git_command(["init", "-b", "main"])
	
	try_set_init_to_done()

func _on_commit2_pressed() -> void:
	if helper_input.text != "":
		var arg = helper_input.text.split("|", false, 1)
		if arg.size() == 1:
			print_error("separate args with \"|\"")
		else:
			do_git_button(["commit", "-m", arg[0], "-m", arg[1].dedent()])
	else:
		print_error("empty input box")

# TODO: this is untested!
func _on_clone_pressed() -> void:
	if is_link_ok(helper_input.text):
		do_git_command(["remote", "add", "origin", helper_input.text])
		do_git_command([ "fetch"])
		do_git_command([ "reset", "origin", "main"])
		do_git_command([ "checkout", "-t", "origin", "master"])
		is_origin_present()
	else:
		print_error("link is invalid")

# TODO: refactor this, not sure it's correct
func _on_checkout_pressed() -> void:
	if helper_input.text != "":
		var arg = helper_input.text.split(" ")
		if arg.size() == 1:
			do_git_button(["checkout", arg[0]])
		else:
			# or should it be checkout --track [branch_name]
			do_git_button(["checkout", "-b", helper_input.text])
	else:
		print_error("can't checkout nothing")

# TODO: refactor this, not sure it's correct
func _on_merge_to_pressed() -> void:
	if helper_input.text != "":
		if is_name_ok(helper_input.text):
			var branch_to_merge = branch
			do_git_command(["add", "-A"], true)
			do_git_command(["commit", "-m", "merging_branches"], true)
			do_git_command(["checkout", helper_input.text], true)
			do_git_button(["merge", branch_to_merge])
		else:
			print_error("branch name has illegal characters")
	else:
		print_error("can't merge to nothing")

func _on_tags_pressed() -> void:
	do_git_command(["tag"])

func _on_tag_pressed():
	if helper_input.text != "":
		if is_name_ok(helper_input.text):
			do_git_button(["tag", helper_input.text])
		else:
			print_error("tag name has illegal characters")
	else:
		print_error("tag needs a name")

func _on_tag2_pressed() -> void:
	if helper_input.text != "":
		var arg = helper_input.text.split(" ", false, 1)
		if arg.size() == 1:
			print_error("separate args with \" \"")
		else:
			if is_name_ok(arg[0]):
				do_git_button(["tag", "-a", arg[0], "-m", arg[1].dedent()])
			else:
				print_error("tag name has illegal characters")
	else:
		print_error("need title and message")

func _on_del_tag_pressed() -> void:
	if helper_input.text != "":
		if is_name_ok(helper_input.text):
			do_git_button(["tag", "-d", helper_input.text])
		else:
			print_error("tag name has illegal characters")
	else:
		print_error("can't delete empty tag")

# TODO: do I have to do "git push -u origin main" after?
#       probably not as long as I only use origin and no other remotes... right?
#       also I don't use argument-less push or pull so meh...
func _on_set_origin_pressed() -> void:
	if is_link_ok(helper_input.text):
		if is_origin_present():
			# set origin link
			do_git_button(["remote", "set-url", "origin", helper_input.text])
		else:
			# set up origin
			do_git_button(["remote", "add", "origin", helper_input.text])
			# maybe use that if only ever using github
			#do_git_button(["branch", "-M", "main", helper_input.text])
	else:
		print_error("link is invalid")
	
	is_origin_present()

func _on_git_ignore_pressed() -> void:
	print("git ignore")

func _on_tag_push_pressed() -> void:
	if helper_input.text != "":
		if is_name_ok(helper_input.text):
			do_git_button(["push", "origin", "tag", helper_input.text])
		else:
			print_error("tag name has illegal characters")
	else:
		print_error("can't push empty tag")

func _on_enter_pressed(_arg:=null) -> void:
	if commandline.text != "":
		var arg = commandline.text.split(" ")
		var args : Array
		var temp := ""
		
		for a in arg:
			match ['"' in a, temp == ""]:
				# normal argument
				[false, true]:
					args.push_back(a)
				# first "
				[true, true]:
					temp += a
				# last "
				[true, false]:
					temp += a
					args.push_back(temp)
					temp = ""
				# string between ""
				[false, false]:
					temp += a
		
		do_git_command(arg)
		commandline.text = ""
	else:
		print_error("empty commandline box")

func _on_toggle_setings_toggled(button_pressed):
	$VBoxContainer/VBoxContainer/settings.visible = button_pressed
	if button_pressed:
		fill_settings_input_fields()
	else:
		clear_settings_input_fields()

func _on_cancel_pressed():
	_on_toggle_setings_toggled(false)
	$VBoxContainer/VBoxContainer/HBoxContainer2/toggle_setings.pressed = false

func _on_save_pressed():
	# save input to settings variable
	settings.git_path = $VBoxContainer/VBoxContainer/settings/VBoxContainer/git_path_input.text
	
	settings_to_file()
	
	_on_cancel_pressed()
