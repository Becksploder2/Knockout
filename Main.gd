extends Control

var pot := 25000
var episode := 1
var round_number := 1
var terminators_this_round := 0
var final_wagers: Array = []
var final_answers: Array = []
var final_cursor := 0
var final_scores: Array = []
var final_tied: Array = []
var final_result_text := ""
var phase := "questions"
var players: Array = []
var pair: Array = []
var buzz := -1
var bonus := 0
var carry := 25000
var champ := 4
var main: VBoxContainer
var grid: GridContainer
var actions: HBoxContainer
var info: Label
var question: Label
var questions := [
["What is the capital of Texas?", "Austin"],
["How many sides does a hexagon have?", "6"],
["Which planet is known as the Red Planet?", "Mars"],
["What is 12 multiplied by 8?", "96"],
["Which ocean is the largest?", "Pacific"],
["What is the chemical symbol for gold?", "Au"],
["What is the capital of France?", "Paris"],
["How many minutes are in two hours?", "120"],
["Which sport uses a puck?", "Hockey"],
["What is the square root of 81?", "9"]
]
var question_index := 0
var answer_field: LineEdit
var music_player: AudioStreamPlayer
var music_files: Dictionary = {}
var music_volume := 0.65
var music_enabled := true
var music_dialog: FileDialog
var selected_cue := "Main Menu"
var menu: VBoxContainer
var studio_view: SubViewportContainer
var studio_root: Node3D
const CUES := ["Main Menu", "Host Entrance", "Opening Round", "Terminator", "Final Knockout", "Sudden Death", "Jackpot Win", "Elimination"]


func _ready() -> void:
	randomize()
	var fallback := get_node_or_null("FallbackBackground")
	if fallback != null:
		fallback.queue_free()
	var fallback_title := get_node_or_null("FallbackTitle")
	if fallback_title != null:
		fallback_title.queue_free()
	var fallback_status := get_node_or_null("FallbackStatus")
	if fallback_status != null:
		fallback_status.queue_free()
	_build_studio()
	var bg := ColorRect.new()
	bg.color = Color(0.015, 0.02, 0.05, 0.28)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	main = VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.custom_minimum_size = Vector2(1100, 0)
	main.add_theme_constant_override("separation", 12)
	scroll.add_child(main)
	var title := Label.new()
	title.text = "K N O C K O U T"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("#ffd36d"))
	main.add_child(title)
	info = Label.new()
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.add_child(info)
	grid = GridContainer.new()
	grid.columns = 3
	main.add_child(grid)
	question = Label.new()
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.add_theme_font_size_override("font_size", 20)
	main.add_child(question)
	answer_field = LineEdit.new()
	answer_field.placeholder_text = "Type answer here after selecting a player"
	main.add_child(answer_field)
	actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	main.add_child(actions)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_dialog = FileDialog.new()
	music_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	music_dialog.access = FileDialog.ACCESS_FILESYSTEM
	music_dialog.add_filter("*.mp3, *.ogg, *.wav", "Audio")
	music_dialog.file_selected.connect(_on_music_file)
	add_child(music_dialog)
	_load_music()
	new_episode()
	# Launcher already handles menus and roster selection.
	# Enter the contestant board immediately.

func new_episode() -> void:
	players.clear()
	for i in range(9):
		players.append({"name":"Player %d" % (i+1), "bank":0, "alive":true, "locked":false})
	var lineup_file := FileAccess.open("user://knockout_lineup.json", FileAccess.READ)
	if lineup_file != null:
		var lineup: Variant = JSON.parse_string(lineup_file.get_as_text())
		if lineup is Array:
			for i in range(min(9, lineup.size())):
				players[i]["name"] = str(lineup[i])
	if episode > 1:
		players[4]["name"] = "Returning Champion"
	pot = carry
	phase = "questions"
	pair.clear()
	buzz = -1
	bonus = 0
	round_number = 1
	terminators_this_round = 0
	render()

func living() -> Array:
	var a: Array = []
	for i in range(9):
		if players[i]["alive"]:
			a.append(i)
	return a

func add_button(t: String, method: Callable) -> void:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(165, 48)
	b.pressed.connect(method)
	actions.add_child(b)

func render() -> void:
	info.text = "EPISODE %d  |  CASH POT $%d  |  ROUND %d  |  %s" % [episode, pot, round_number, phase.to_upper()]
	for n in grid.get_children():
		grid.remove_child(n)
		n.queue_free()
	for i in range(9):
		var p: Dictionary = players[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(300, 105)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var state := "ACTIVE"
		if not p["alive"]:
			state = "ELIMINATED"
		elif p["locked"]:
			state = "LOCKED OUT"
		if pair.has(i):
			state = "TERMINATOR"
		b.text = "%s  |  $%d\n%s" % [p["name"], p["bank"], state]
		b.disabled = not p["alive"] or (phase == "questions" and p["locked"])
		b.pressed.connect(select_player.bind(i))
		grid.add_child(b)
	for n in actions.get_children():
		actions.remove_child(n)
		n.queue_free()
	if phase == "questions":
		question.text = questions[question_index % questions.size()][0]
		if round_number <= 2 and terminators_this_round < 3:
			add_button("KNOCKOUT — Activate Terminator", start_terminator)
		elif round_number <= 2:
			add_button("Advance to next round", next_round)
		elif round_number == 3:
			add_button("Begin Final Knockout", start_final)
	elif phase == "answer":
		add_button("Submit answer", submit_answer)
	elif phase == "terminator":
		question.text = "TERMINATOR: " + questions[question_index % questions.size()][0]
		add_button("Submit buzzer answer", submit_answer)
	elif phase == "final":
		question.text = "FINAL KNOCKOUT: %s — Wager (0 to $%d), then lock in answer: %s" % [players[final_tied[final_cursor]]["name"], players[final_tied[final_cursor]]["bank"], questions[question_index % questions.size()][0]]
		add_button("Submit wager and answer", submit_final)
	elif phase == "bonus":
		question.text = "SUDDEN DEATH %d/5: %s" % [bonus+1, questions[question_index % questions.size()][0]]
		add_button("Submit bonus answer", submit_answer)
	elif phase == "finished":
		add_button("Next episode", advance_episode)

func select_player(i: int) -> void:
	if phase == "questions":
		buzz = i
		phase = "answer"
	elif phase == "terminator" and pair.has(i):
		buzz = i
	render()

func submit_answer() -> void:
	if phase != "bonus" and buzz < 0:
		return
	var correct := answer_field.text.strip_edges().to_lower() == questions[question_index % questions.size()][1].to_lower()
	answer_field.clear()
	question_index += 1
	if phase == "answer":
		if correct:
			players[buzz]["bank"] += 1000
		else:
			players[buzz]["locked"] = true
		phase = "questions"
	elif phase == "terminator":
		var loser: int = buzz
		if correct:
			loser = pair[1] if buzz == pair[0] else pair[0]
		pot += players[loser]["bank"]
		players[loser]["bank"] = 0
		players[loser]["alive"] = false
		pair.clear()
		phase = "questions"
		if terminators_this_round == 3:
			phase = "questions"
			if round_number == 2:
				round_number = 3
				terminators_this_round = 0
	elif phase == "bonus":
		if correct:
			bonus += 1
			if bonus == 5:
				carry = 25000
				phase = "finished"
				question.text = "JACKPOT WON!"
		else:
			carry = pot + 10000
			phase = "finished"
	buzz = -1
	render()

func next_round() -> void:
	round_number += 1
	terminators_this_round = 0
	for p in players:
		if p["alive"]:
			p["locked"] = false
	render()

func start_terminator() -> void:
	var a := living()
	if round_number > 2 or terminators_this_round >= 3 or a.size() <= 3:
		return
	terminators_this_round += 1
	a.shuffle()
	pair = [a[0], a[1]]
	buzz = -1
	phase = "terminator"
	_play_cue("KNOCKOUT Selection SFX")
	get_tree().create_timer(2.0).timeout.connect(func():
		if phase == "terminator":
			_play_cue("KNOCKOUT Question Music")
	)
	render()

func start_final() -> void:
	pair = living()
	final_tied = pair.duplicate()
	final_wagers.clear()
	final_answers.clear()
	final_scores.clear()
	final_cursor = 0
	phase = "final"
	_play_cue("Final Knockout")
	render()

func submit_final() -> void:
	var entry := answer_field.text.strip_edges()
	var parts := entry.split("|", false, 1)
	if parts.size() != 2:
		question.text = "Enter wager|answer (example: 1000|Austin)"
		return
	if not parts[0].strip_edges().is_valid_int():
		question.text = "Wager must be a whole number. Example: 1000|Austin"
		return
	var player_index: int = final_tied[final_cursor]
	var wager := int(parts[0].strip_edges())
	if wager < 0 or wager > int(players[player_index]["bank"]):
		question.text = "Wager must be between $0 and your bank."
		return
	final_wagers.append(wager)
	final_answers.append(parts[1].strip_edges())
	answer_field.clear()
	final_cursor += 1
	if final_cursor < final_tied.size():
		render()
		return
	var expected: String = str(questions[question_index % questions.size()][1]).to_lower()
	for i in range(final_tied.size()):
		var p_index: int = final_tied[i]
		var score: int = int(players[p_index]["bank"])
		if str(final_answers[i]).to_lower() == expected:
			score += int(final_wagers[i])
		else:
			score -= int(final_wagers[i])
		final_scores.append(score)
	var high: int = final_scores.max()
	var winners: Array = []
	for i in range(final_scores.size()):
		if int(final_scores[i]) == high:
			winners.append(final_tied[i])
	if winners.size() > 1:
		final_tied = winners
		final_cursor = 0
		final_wagers.clear()
		final_answers.clear()
		final_scores.clear()
		question_index += 1
		render()
		return
	champ = int(winners[0])
	for i in living():
		if i != champ:
			pot += int(players[i]["bank"])
			players[i]["bank"] = 0
			players[i]["alive"] = false
	phase = "bonus"
	bonus = 0
	question_index += 1
	_play_cue("Sudden Death")
	render()

func advance_episode() -> void:
	episode += 1
	new_episode()

func _show_menu() -> void:
	main.hide()
	menu = VBoxContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(menu)
	_show_main_menu()

func _menu_button(caption: String, callback: Callable) -> void:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = Vector2(350, 50)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(callback)
	menu.add_child(b)

func _clear_menu() -> void:
	for child in menu.get_children():
		menu.remove_child(child)
		child.queue_free()

func _show_main_menu() -> void:
	_clear_menu()
	var title := Label.new()
	title.text = "K N O C K O U T"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 50)
	menu.add_child(title)
	_menu_button("PLAY KNOCKOUT", _start_game)
	_menu_button("MUSIC OPTIONS", _show_music_options)
	_menu_button("QUIT", func(): get_tree().quit())
	_play_cue("Main Menu")

func _start_game() -> void:
	menu.hide()
	main.show()
	_play_cue("Opening Round")

func _show_music_options() -> void:
	_clear_menu()
	var title := Label.new()
	title.text = "MUSIC OPTIONS"
	menu.add_child(title)
	var toggle := CheckButton.new()
	toggle.text = "Enable music"
	toggle.button_pressed = music_enabled
	toggle.toggled.connect(func(v: bool):
		music_enabled = v
		if not v:
			music_player.stop()
		_save_music()
	)
	menu.add_child(toggle)
	var label_node := Label.new()
	label_node.text = "Music volume"
	menu.add_child(label_node)
	var slider_node := HSlider.new()
	slider_node.min_value = 0.0
	slider_node.max_value = 1.0
	slider_node.step = 0.05
	slider_node.value = music_volume
	slider_node.custom_minimum_size = Vector2(350, 32)
	slider_node.value_changed.connect(func(v: float):
		music_volume = v
		music_player.volume_linear = v
		_save_music()
	)
	menu.add_child(slider_node)
	var chooser := OptionButton.new()
	for cue in CUES:
		chooser.add_item(cue)
	chooser.selected = CUES.find(selected_cue)
	chooser.item_selected.connect(func(i: int): selected_cue = CUES[i])
	menu.add_child(chooser)
	_menu_button("IMPORT TRACK FOR SELECTED CUE", func(): music_dialog.popup_centered(Vector2i(850, 600)))
	_menu_button("PREVIEW TRACK", func(): _play_cue(selected_cue))
	_menu_button("CLEAR TRACK", func():
		music_files.erase(selected_cue)
		music_player.stop()
		_save_music()
	)
	_menu_button("BACK", _show_main_menu)

func _on_music_file(path: String) -> void:
	music_files[selected_cue] = path
	_save_music()
	_play_cue(selected_cue)

func _play_cue(cue: String) -> void:
	music_player.stop()
	if not music_enabled or not music_files.has(cue):
		return
	var path: String = str(music_files[cue])
	if not FileAccess.file_exists(path):
		return
	var stream: AudioStream = null
	var ext := path.get_extension().to_lower()
	if ext == "mp3":
		stream = AudioStreamMP3.load_from_file(path)
	elif ext == "ogg":
		stream = AudioStreamOggVorbis.load_from_file(path)
	elif ext == "wav":
		stream = AudioStreamWAV.load_from_file(path)
	if stream != null:
		music_player.stream = stream
		music_player.volume_linear = music_volume
		music_player.play()

func _save_music() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "music_enabled", music_enabled)
	cfg.set_value("audio", "files", music_files)
	cfg.save("user://knockout_music.cfg")

func _load_music() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://knockout_music.cfg") == OK:
		music_volume = float(cfg.get_value("audio", "music_volume", 0.65))
		music_enabled = bool(cfg.get_value("audio", "music_enabled", true))
		music_files = cfg.get_value("audio", "files", {})

func _build_studio() -> void:
	studio_view = SubViewportContainer.new()
	studio_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	studio_view.stretch = true
	studio_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(studio_view)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 800)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	studio_view.add_child(viewport)
	studio_root = Node3D.new()
	viewport.add_child(studio_root)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 7.2, 19)
	camera.look_at_from_position(camera.position, Vector3(0, 3.1, 0), Vector3.UP)
	studio_root.add_child(camera)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, 25, 0)
	light.light_energy = 1.5
	studio_root.add_child(light)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#08112d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#5d7fae")
	env.ambient_light_energy = 0.5
	environment.environment = env
	studio_root.add_child(environment)
	_studio_box(Vector3(0, -0.4, 0), Vector3(28, 0.7, 17), Color("#11182a"))
	for row_index in range(3):
		for col_index in range(3):
			var x: float = float(col_index - 1) * 5.0
			var y: float = 7.0 - float(row_index) * 2.7
			var champion := row_index == 1 and col_index == 1
			var accent := Color("#ffcb62") if champion else Color("#218bff")
			_studio_box(Vector3(x, y, -4), Vector3(4.35, 2.3, 0.5), accent)
			_studio_box(Vector3(x, y, -3.69), Vector3(4.0, 2.0, 0.12), Color("#101f3d"))
			_studio_box(Vector3(x, y - 0.84, -3.5), Vector3(3.7, 0.2, 0.45), accent)
	_studio_box(Vector3(-6.4, 0.6, 5), Vector3(3.2, 1.7, 1.7), Color("#b28b44"))
	_studio_box(Vector3(-3.5, 0.65, 5), Vector3(0.85, 1.3, 0.85), Color("#b8242f"))
	_studio_box(Vector3(-3.5, 1.36, 5), Vector3(0.9, 0.15, 0.9), Color("#ff3344"))
	_studio_box(Vector3(-0.6, 0.6, 5), Vector3(2.2, 1.7, 1.5), Color("#244aa2"))
	# Stylized Arianna Dawson: red outfit, blonde hair, glasses.
	_studio_box(Vector3(-6.4, 2.05, 5), Vector3(0.75, 1.55, 0.45), Color("#b52637"))
	_studio_box(Vector3(-6.4, 3.15, 5), Vector3(0.6, 0.72, 0.5), Color("#f2c9a2"))
	_studio_box(Vector3(-6.4, 3.55, 5), Vector3(0.78, 0.25, 0.55), Color("#efc95a"))
	_studio_box(Vector3(-6.4, 3.17, 5.29), Vector3(0.68, 0.12, 0.08), Color("#1c2230"))

func _studio_box(pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.35
	material.roughness = 0.3
	node.material_override = material
	node.position = pos
	studio_root.add_child(node)
