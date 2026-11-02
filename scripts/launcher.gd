extends Control

const SAVE_PATH := "user://knockout_roster.json"
var roster: Array = []
var chosen: Array = []
var panel: VBoxContainer
var name_edit: LineEdit
var status: Label
var music_dialog: FileDialog
var music_slot := "Opening Theme"
const MUSIC_SLOTS := ["Opening Theme", "KNOCKOUT Selection SFX", "KNOCKOUT Question Music", "Regular Question", "Final Knockout", "Sudden Death", "Champion Fanfare"]

func _ready() -> void:
	_load_roster()
	var background := ColorRect.new()
	background.color = Color("#0d1527")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 10)
	scroll.add_child(panel)
	_main_menu()

func _button(caption: String, action: Callable) -> void:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(360, 46)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(action)
	panel.add_child(b)

func _label(caption: String, large: bool = false) -> void:
	var l := Label.new()
	l.text = caption
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if large:
		l.add_theme_font_size_override("font_size", 40)
	panel.add_child(l)

func _clear() -> void:
	for n in panel.get_children():
		panel.remove_child(n)
		n.queue_free()

func _main_menu() -> void:
	_clear()
	_label("K N O C K O U T", true)
	_label("One show. Nine contestants. Six KNOCKOUTS.")
	_button("PLAY KNOCKOUT", _choose_players)
	_button("CREATE CONTESTANT", _create_screen)
	_button("MANAGE CONTESTANTS", _manage_screen)
	_button("IMPORT MUSIC / SFX", _audio_screen)
	_button("QUIT", func(): get_tree().quit())

func _create_screen() -> void:
	_clear()
	_label("CREATE CONTESTANT", true)
	_label("Enter the contestant's display name")
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Contestant name"
	name_edit.custom_minimum_size = Vector2(400, 48)
	panel.add_child(name_edit)
	status = Label.new()
	panel.add_child(status)
	_button("SAVE CONTESTANT", _save_new)
	_button("BACK", _main_menu)

func _save_new() -> void:
	var name_text := name_edit.text.strip_edges()
	if name_text.is_empty():
		status.text = "Enter a name before saving."
		return
	for p in roster:
		if str(p["name"]).to_lower() == name_text.to_lower():
			status.text = "That name is already saved."
			return
	roster.append({"name": name_text, "human": false})
	_save_roster()
	_manage_screen()

func _manage_screen() -> void:
	_clear()
	_label("SAVED CONTESTANTS", true)
	if roster.is_empty():
		_label("No saved contestants yet.")
	for i in range(roster.size()):
		var item: Dictionary = roster[i]
		_button(str(item["name"]) + "  — DELETE", _delete_player.bind(i))
	_button("CREATE CONTESTANT", _create_screen)
	_button("BACK", _main_menu)

func _delete_player(index: int) -> void:
	roster.remove_at(index)
	chosen.clear()
	_save_roster()
	_manage_screen()

func _choose_players() -> void:
	_clear()
	_label("CHOOSE NINE CONTESTANTS", true)
	_label("%d of 9 selected" % chosen.size())
	_label("Select saved contestants, or fill remaining slots with AI players.")
	for i in range(roster.size()):
		var marker := "[SELECTED] " if chosen.has(i) else "[ ] "
		_button(marker + str(roster[i]["name"]), _toggle.bind(i))
	_button("FILL EMPTY SLOTS WITH AI & START", _start_game)
	_button("CREATE CONTESTANT", _create_screen)
	_button("BACK", _main_menu)

func _toggle(index: int) -> void:
	if chosen.has(index):
		chosen.erase(index)
	elif chosen.size() < 9:
		chosen.append(index)
	_choose_players()

func _start_game() -> void:
	var names: Array = []
	for index in chosen:
		names.append(str(roster[index]["name"]))
	while names.size() < 9:
		names.append("AI Contestant %d" % (names.size() + 1))
	var file := FileAccess.open("user://knockout_lineup.json", FileAccess.WRITE)
	if file == null:
		_label("Could not save the contestant lineup.")
		return
	file.store_string(JSON.stringify(names))
	file.close()
	_label("Opening nine-contestant board...")
	call_deferred("_enter_board")

func _load_roster() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		roster = parsed

func _save_roster() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(roster))

func _audio_screen() -> void:
	_clear()
	_label("KNOCKOUT AUDIO IMPORT", true)
	_label("Choose a cue, then import your MP3, OGG or WAV file.")
	for slot in MUSIC_SLOTS:
		_button("IMPORT — " + slot, _open_audio.bind(slot))
	_button("BACK", _main_menu)

func _open_audio(slot: String) -> void:
	music_slot = slot
	music_dialog = FileDialog.new()
	music_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	music_dialog.access = FileDialog.ACCESS_FILESYSTEM
	music_dialog.use_native_dialog = true
	music_dialog.add_filter("*.mp3, *.ogg, *.wav", "Audio files")
	music_dialog.file_selected.connect(_import_audio)
	music_dialog.close_requested.connect(func(): music_dialog.queue_free())
	add_child(music_dialog)
	music_dialog.popup_centered_ratio(0.7)

func _import_audio(path: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://knockout_music.cfg")
	var files: Dictionary = cfg.get_value("audio", "files", {})
	var dir := "user://imported_audio/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var target := dir + music_slot.to_snake_case() + "." + path.get_extension().to_lower()
	var err := DirAccess.copy_absolute(path, ProjectSettings.globalize_path(target))
	if err == OK:
		files[music_slot] = ProjectSettings.globalize_path(target)
		cfg.set_value("audio", "files", files)
		cfg.save("user://knockout_music.cfg")
		_audio_screen()
		_label("Imported: " + music_slot)
	else:
		_label("Import failed (error %d)." % err)
	music_dialog.queue_free()

func _enter_board() -> void:
	var scene_path := "res://Main.tscn"
	if not ResourceLoader.exists(scene_path):
		_label("ERROR: Main.tscn is missing from the game package.")
		return
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		_label("ERROR: Gameplay scene failed to parse or load.")
		return
	var board := scene.instantiate()
	if board == null:
		_label("ERROR: Gameplay board could not be instantiated.")
		return
	# Attach and initialize the board before removing the launcher.
	get_tree().root.add_child(board)
	get_tree().current_scene = board
	queue_free()
