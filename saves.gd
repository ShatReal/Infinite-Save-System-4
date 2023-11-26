extends PopupPanel


# Signals
# In your game scene, listen for this signal to know when to load the game.
signal game_loaded(data: String)
# This signal is not used in this demo, but you might want to use it for
# something.
signal game_saved()

# Constants
const SAVES_FOLDER := "user://saves/"
const SAVE_ENDING := ".save"
# We can't have colons for the time in file names, so we replace it with a
# letter, which isn't used in times.
const COLON_REPLACE := "a"
# Since unix time only changes every second, we give each file a second number
# to indicate it's different from another one saved at the same second. This
# is the separator for that number.
const NUM_SEP := "b"

# Normal variables
var save_files: Array
# Every button is added to this group to ensure that only one can be presssed
# at a time.
var save_group := ButtonGroup.new()

# Onready variables
@onready var save_container := %SaveContainer
@onready var save_button := %Save
@onready var load_button := %Load
@onready var delete_button := %Delete
@onready var clear_button := %Clear


func _ready() -> void:
	# PopupPanels show by default.
	hide()
	
	save_files = Array(list_saves())
	# Reverse to put in newest first order.
	save_files.reverse()
	for i in range(save_files.size() - 1, -1, -1):
		var text := get_button_text_from_file_name(save_files[i])
		# If the file is invalid delete it from the save files array.
		if text.is_empty():
			save_files.remove_at(i)
			continue
		make_save_button(text)
	
	clear_button.disabled = save_files.size() == 0


func list_saves() -> PackedStringArray:
	if not DirAccess.dir_exists_absolute(SAVES_FOLDER):
		DirAccess.make_dir_recursive_absolute(SAVES_FOLDER)
	return DirAccess.get_files_at(SAVES_FOLDER)


func make_save_button(text: String) -> void:
	var b := Button.new()
	b.toggle_mode = true
	b.text = text
	b.button_group = save_group
	save_container.add_child(b)
	# Moves the button to the top of the list, since most recent saves come
	# first.
	save_container.move_child(b, 0)
	b.toggled.connect(on_save_toggled)
	b.button_pressed = true
	clear_button.disabled = false


func get_button_text_from_file_name(file_name: String) -> String:
	var regex := RegEx.new()
	# You don't need to understand the regex, this just makes sure that the
	# file is named correctly.
	regex.compile(
		"^(\\d{4}-\\d{2}-\\d{2} \\d{2}%s\\d{2}%s\\d{2})%s\\d+%s$" %
		[COLON_REPLACE, COLON_REPLACE, NUM_SEP, SAVE_ENDING]
	)
	var m := regex.search(file_name)
	if m == null:
		return ""
	return m.get_string(1).replace(COLON_REPLACE, ":")


func _on_save_pressed() -> void:
	# You can't really overwrite a save since you have to change the filename
	# and the data in it, so it just gets deleted.
	_on_delete_pressed()
	_on_new_pressed()


func _on_new_pressed() -> void:
	var time_str := Time.get_datetime_string_from_system(false, true)
	var time_str_mod := time_str.replace(":", COLON_REPLACE)
	var num := 0
	var save_path := time_str_mod + NUM_SEP + str(num) + SAVE_ENDING
	while FileAccess.file_exists(SAVES_FOLDER + save_path):
		num += 1
		save_path = time_str_mod + NUM_SEP + str(num) + SAVE_ENDING
	var file = FileAccess.open(SAVES_FOLDER + save_path, FileAccess.WRITE)
	# You want to replace this with a call to your own save function.
	file.store_pascal_string(get_tree().current_scene.get_text())
	save_files.push_front(save_path)
	make_save_button(time_str)
	game_saved.emit()


func on_save_toggled(button_pressed: bool) -> void:
	if not button_pressed:
		return
	save_button.disabled = false
	load_button.disabled = false
	delete_button.disabled = false


func _on_delete_pressed() -> void:
	var i := save_group.get_pressed_button().get_index()
	DirAccess.remove_absolute(SAVES_FOLDER + save_files[i])
	save_files.remove_at(i)
	save_group.get_pressed_button().queue_free()
	save_button.disabled = true
	load_button.disabled = true
	delete_button.disabled = true
	clear_button.disabled = save_files.size() == 0


func _on_clear_pressed() -> void:
	for child in save_container.get_children():
		child.queue_free()
	while save_files.size() > 0:
		DirAccess.remove_absolute(SAVES_FOLDER + save_files.pop_front())
	save_button.disabled = true
	load_button.disabled = true
	delete_button.disabled = true
	clear_button.disabled = true


func _on_load_pressed() -> void:
	var i := save_group.get_pressed_button().get_index()
	var f := FileAccess.open(SAVES_FOLDER + save_files[i], FileAccess.READ)
	# You want to replace this with your own save decoding function.
	var content := f.get_pascal_string()
	game_loaded.emit(content)
	hide()
