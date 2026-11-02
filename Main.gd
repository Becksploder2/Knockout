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
var questions: Array = [["Geography","What is the capital of Texas?","Austin"],
["Geography","What is the capital of Canada?","Ottawa"],
["Geography","Which country is home to the city of Kyoto?","Japan"],
["Geography","What is the largest ocean on Earth?","Pacific"],
["Geography","What river flows through London?","Thames"],
["Geography","Which continent contains Kenya?","Africa"],
["Geography","What is the capital of France?","Paris"],
["Geography","What country borders Portugal to the east?","Spain"],
["Science","What is the chemical symbol for gold?","Au"],
["Science","Which planet is called the Red Planet?","Mars"],
["Science","What gas do plants absorb during photosynthesis?","Carbon dioxide"],
["Science","How many bones are in the typical adult human body?","206"],
["Science","What force keeps planets in orbit around the Sun?","Gravity"],
["Science","What is the chemical formula for water?","H2O"],
["Science","What is the closest star to Earth?","Sun"],
["Science","What is the hardest naturally occurring mineral?","Diamond"],
["Sports","How many players are on the court for one basketball team?","5"],
["Sports","Which sport uses a puck?","Hockey"],
["Sports","How many bases are on a baseball diamond?","4"],
["Sports","What is the maximum score with one dart in standard darts?","60"],
["Sports","How many holes are played in a standard golf round?","18"],
["Sports","What sport awards a touchdown?","American football"],
["Sports","What is the standard number of players on a soccer team on the field?","11"],
["Sports","Which tennis tournament is played on grass in London?","Wimbledon"],
["History","Who was the first president of the United States?","George Washington"],
["History","In what year did the Berlin Wall fall?","1989"],
["History","Which civilization built Machu Picchu?","Inca"],
["History","What ship sank on its maiden voyage in 1912?","Titanic"],
["History","Which country gifted the Statue of Liberty to the United States?","France"],
["History","In what year did World War II end?","1945"],
["History","What ancient city was buried by Mount Vesuvius?","Pompeii"],
["History","Who was known as the Maid of Orleans?","Joan of Arc"],
["Entertainment","What is the name of the cowboy in Toy Story?","Woody"],
["Entertainment","What fictional city does Batman protect?","Gotham City"],
["Entertainment","Who wrote the Harry Potter novels?","J. K. Rowling"],
["Entertainment","What color is the character Shrek?","Green"],
["Entertainment","What instrument has black and white keys?","Piano"],
["Entertainment","What is the name of the kingdom in Frozen?","Arendelle"],
["Entertainment","What is the name of the hobbit played by Elijah Wood?","Frodo"],
["Entertainment","What is the first name of Sherlock Holmes's friend Watson?","John"],
["Games & Technology","What company created the original Sonic the Hedgehog game?","Sega"],
["Games & Technology","What does CPU stand for?","Central Processing Unit"],
["Games & Technology","What does USB stand for?","Universal Serial Bus"],
["Games & Technology","Which company released the Nintendo 64?","Nintendo"],
["Games & Technology","What is the name of Mario's brother?","Luigi"],
["Games & Technology","Which game features falling blocks called tetrominoes?","Tetris"],
["Games & Technology","What does HTML stand for?","HyperText Markup Language"],
["Games & Technology","What color is Pac-Man?","Yellow"],
["General Knowledge","How many sides does a hexagon have?","6"],
["General Knowledge","What is 12 multiplied by 8?","96"],
["General Knowledge","What is the square root of 81?","9"],
["General Knowledge","How many minutes are in two hours?","120"],
["General Knowledge","What is the freezing point of water in Celsius?","0"],
["General Knowledge","How many days are in a leap year?","366"],
["General Knowledge","What is the Roman numeral for 50?","L"],
["General Knowledge","How many letters are in the English alphabet?","26"]]

var question_index := 0
var category_board: Label
var used_question_ids: Dictionary = {}
const QUESTION_HISTORY := "user://knockout_used_questions.json"
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
var ai_clock: float = 0.0
var human_names: Array = []
var host_banner: Label
var round_questions: int = 0
var terminator_running: bool = false
var spotlight_index: int = -1
var spotlight_index_b: int = -1
var spotlight_clock: float = 0.0
var spotlight_steps: int = 0
var spotlight_target: Array = []
var studio_spotlight: OmniLight3D
var studio_spotlight_b: OmniLight3D
var square_labels: Array = []
const CUES := ["Main Menu", "Host Entrance", "Opening Round", "Terminator", "Final Knockout", "Sudden Death", "Jackpot Win", "Elimination"]


func _ready() -> void:
	randomize()
	_load_question_history()
	questions.shuffle()
	# Keep the loading overlay visible until the board has rendered successfully.
	# Create the interactive board first; initialize 3D after the first frame.
	var bg := ColorRect.new()
	bg.color = Color(0.015, 0.02, 0.05, 0.28)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main = VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.custom_minimum_size = Vector2(950, 0)
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
	category_board = Label.new()
	category_board.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category_board.add_theme_font_size_override("font_size", 25)
	category_board.add_theme_color_override("font_color", Color("#ffd36d"))
	main.add_child(category_board)
	grid = GridContainer.new()
	grid.columns = 3
	main.add_child(grid)
	grid.hide()
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
	# Remove the loading overlay only after all nine contestant controls exist.
	if grid.get_child_count() == 9:
		for node_name in ["FallbackBackground", "FallbackTitle", "FallbackStatus"]:
			var fallback_node := get_node_or_null(node_name)
			if fallback_node != null:
				fallback_node.queue_free()
	else:
		var status_node := get_node_or_null("FallbackStatus") as Label
		if status_node != null:
			status_node.text = "BOARD ERROR: Expected 9 contestants, found %d." % grid.get_child_count()
	# The studio is an optional visual layer; gameplay remains usable if it fails.
	_build_studio_behind_board()
	host_banner = Label.new()
	host_banner.text = "ARIANNA DAWSON  |  Welcome to KNOCKOUT!"
	host_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	host_banner.add_theme_font_size_override("font_size", 23)
	main.add_child(host_banner)


func new_episode() -> void:
	players.clear()
	for i in range(9):
		players.append({"name":"Player %d" % (i+1), "bank":0, "alive":true, "locked":false, "ai":true})
	var lineup_file := FileAccess.open("user://knockout_lineup.json", FileAccess.READ)
	if lineup_file != null:
		var lineup: Variant = JSON.parse_string(lineup_file.get_as_text())
		if lineup is Array:
			for i in range(min(9, lineup.size())):
				if lineup[i] is Dictionary:
					players[i]["name"] = str(lineup[i].get("name", "Contestant"))
					players[i]["ai"] = bool(lineup[i].get("ai", true))
				else:
					players[i]["name"] = str(lineup[i])
					players[i]["ai"] = str(lineup[i]).begins_with("AI Contestant")
	if episode > 1:
		players[4]["name"] = "Returning Champion"
	pot = carry
	phase = "questions"
	pair.clear()
	buzz = -1
	bonus = 0
	round_number = 1
	terminators_this_round = 0
	round_questions = 0
	terminator_running = false
	spotlight_index = -1
	spotlight_index_b = -1
	render()


func _process(delta: float) -> void:
	if players.size() != 9 or answer_field == null or phase == "question_bank_empty":
		return
	if terminator_running:
		spotlight_clock += delta
		if spotlight_clock >= 0.13:
			spotlight_clock = 0.0
			spotlight_steps += 1
			var available: Array = living()
			if not available.is_empty():
				if available.size() >= 2:
					available.shuffle()
					spotlight_index = int(available[0])
					spotlight_index_b = int(available[1])
					if spotlight_steps >= 23 and spotlight_target.size() == 2:
						spotlight_index = int(spotlight_target[0])
						spotlight_index_b = int(spotlight_target[1])
					if studio_spotlight != null:
						studio_spotlight.position = _square_light_position(spotlight_index)
					if studio_spotlight_b != null:
						studio_spotlight_b.position = _square_light_position(spotlight_index_b)
					render()
			if spotlight_steps >= 23:
				_finish_spotlight()
		return
	if phase == "questions" and round_number <= 2 and round_questions >= 3 and terminators_this_round < 3:
		_begin_host_terminator()
		return
	if phase == "questions" and round_number <= 2 and terminators_this_round == 3:
		next_round()
		return
	ai_clock += delta
	if ai_clock < 5.0:
		return
	ai_clock = 0.0
	if phase == "questions":
		var candidates: Array = []
		for i in range(9):
			if players[i]["alive"] and not players[i]["locked"] and players[i]["ai"]:
				candidates.append(i)
		if not candidates.is_empty():
			select_player(int(candidates.pick_random()))
	elif phase == "answer" and buzz >= 0 and players[buzz]["ai"]:
		answer_field.text = _ai_answer()
		submit_answer()
	elif phase == "terminator" and buzz < 0 and pair.size() == 2:
		var ai_pair: Array = []
		for index in pair:
			if players[int(index)]["ai"]:
				ai_pair.append(index)
		if not ai_pair.is_empty():
			buzz = int(ai_pair.pick_random())
			answer_field.text = _ai_answer()
			submit_answer()
	elif phase == "final" and final_cursor < final_tied.size():
		var finalist: int = int(final_tied[final_cursor])
		if players[finalist]["ai"]:
			var wager: int = randi_range(0, int(players[finalist]["bank"]))
			answer_field.text = "%d|%s" % [wager, _ai_answer()]
			submit_final()
	elif phase == "bonus" and champ >= 0 and champ < players.size() and players[champ]["ai"]:
		answer_field.text = _ai_answer()
		submit_answer()

func _ai_answer() -> String:
	# Difficulty baseline: approximately 70 percent correct.
	if randf() < 0.70:
		return str(_current_question()[2])
	return "Incorrect AI response"


func _current_question() -> Array:
	while question_index < questions.size():
		var candidate: Array = questions[question_index]
		if not used_question_ids.has(str(candidate[1])):
			return candidate
		question_index += 1
	return []

func _mark_question_used() -> void:
	var current: Array = _current_question()
	if current.is_empty():
		return
	used_question_ids[str(current[1])] = true
	var file := FileAccess.open(QUESTION_HISTORY, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(used_question_ids))

func _load_question_history() -> void:
	if not FileAccess.file_exists(QUESTION_HISTORY):
		return
	var file := FileAccess.open(QUESTION_HISTORY, FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			used_question_ids = parsed

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
	if _current_question().is_empty():
		phase = "question_bank_empty"
	category_board.text = "CATEGORY BOARD  |  " + ("QUESTION BANK EXHAUSTED" if phase == "question_bank_empty" else str(_current_question()[0]).to_upper())
	info.text = "EPISODE %d  |  CASH POT $%d  |  ROUND %d  |  %s" % [episode, pot, round_number, phase.to_upper()]
	for n in grid.get_children():
		grid.remove_child(n)
		n.queue_free()
	for i in range(9):
		var p: Dictionary = players[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(295, 105)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var state := "ACTIVE"
		if not p["alive"]:
			state = "ELIMINATED"
		elif p["locked"]:
			state = "LOCKED OUT"
		if pair.has(i):
			state = "TERMINATOR"
		if spotlight_index == i or spotlight_index_b == i:
			state = "SPOTLIGHT!"
			b.add_theme_color_override("font_color", Color("#ffed8c"))
		b.text = "%s\n$%d  |  %s" % [p["name"], p["bank"], state]
		b.disabled = not p["alive"] or (phase == "questions" and p["locked"])
		b.pressed.connect(select_player.bind(i))
		grid.add_child(b)
	if square_labels.size() == 9:
		for i in range(9):
			var nameplate: Label3D = square_labels[i]
			var contestant: Dictionary = players[i]
			nameplate.text = "%s\n$%d | %s" % [str(contestant["name"]), int(contestant["bank"]), "ELIMINATED" if not contestant["alive"] else "LOCKED" if contestant["locked"] else "ACTIVE"]
			nameplate.modulate = Color("#ffdf76") if spotlight_index == i or spotlight_index_b == i else Color.WHITE
	for n in actions.get_children():
		actions.remove_child(n)
		n.queue_free()
	if phase == "questions":
		for i in range(9):
			if not players[i]["ai"] and players[i]["alive"] and not players[i]["locked"]:
				add_button("BUZZ IN — %s" % str(players[i]["name"]), select_player.bind(i))
		question.text = _current_question()[1]
		if round_number <= 2:
			question.text = "ARIANNA: The Terminator activates automatically after three questions!" if round_questions >= 3 else question.text
		elif round_number == 3:
			add_button("Begin Final Knockout", start_final)
	elif phase == "answer":
		add_button("Submit answer", submit_answer)
	elif phase == "spotlight":
		question.text = "TERMINATOR SELECTING CONTESTANTS..."
	elif phase == "terminator":
		for index in pair:
			if not players[int(index)]["ai"]:
				add_button("BUZZ IN — %s" % str(players[int(index)]["name"]), select_player.bind(int(index)))
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
	var correct: bool = answer_field.text.strip_edges().to_lower() == str(questions[question_index % questions.size()][1]).to_lower()
	answer_field.clear()
	_mark_question_used()
	question_index += 1
	if phase == "answer":
		if correct:
			players[buzz]["bank"] += 1000
		else:
			players[buzz]["locked"] = true
		phase = "questions"
		round_questions += 1
	elif phase == "terminator":
		var loser: int = buzz
		if correct:
			loser = pair[1] if buzz == pair[0] else pair[0]
		pot += players[loser]["bank"]
		players[loser]["bank"] = 0
		players[loser]["alive"] = false
		pair.clear()
		phase = "questions"
		if terminators_this_round < 3:
			round_questions = 0
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
	round_questions = 0
	for p in players:
		if p["alive"]:
			p["locked"] = false
	render()

func _begin_host_terminator() -> void:
	if terminator_running or phase != "questions" or round_number > 2 or terminators_this_round >= 3:
		return
	var available: Array = living()
	if available.size() <= 3:
		return
	terminator_running = true
	if studio_spotlight != null:
		studio_spotlight.visible = true
	if studio_spotlight_b != null:
		studio_spotlight_b.visible = true
	phase = "spotlight"
	spotlight_steps = 0
	spotlight_clock = 0.0
	spotlight_target = available.duplicate()
	spotlight_target.shuffle()
	spotlight_target.resize(2)
	host_banner.text = "ARIANNA: The round is over... TERMINATOR, ACTIVATE!"
	_play_cue("KNOCKOUT Selection SFX")
	render()

func _square_light_position(index: int) -> Vector3:
	return Vector3(float(index % 3 - 1) * 5.0, 7.0 - float(index / 3) * 2.7, -9.6)

func _finish_spotlight() -> void:
	terminator_running = false
	spotlight_index = -1
	spotlight_index_b = -1
	if studio_spotlight != null:
		studio_spotlight.visible = false
	if studio_spotlight_b != null:
		studio_spotlight_b.visible = false
	pair = spotlight_target.duplicate()
	spotlight_target.clear()
	terminators_this_round += 1
	buzz = -1
	phase = "terminator"
	host_banner.text = "ARIANNA: %s versus %s. One of you is going home!" % [str(players[int(pair[0])]["name"]), str(players[int(pair[1])]["name"])]
	_play_cue("KNOCKOUT Question Music")
	render()

func start_terminator() -> void:
	# Kept for compatibility with existing button and scene connections.
	_begin_host_terminator()

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
	var high: int = int(final_scores.max())
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

func _build_studio_behind_board() -> void:
	_build_studio()
	move_child(studio_view, 0)

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
	camera.position = Vector3(0, 7.8, 24)
	camera.look_at_from_position(camera.position, Vector3(0, 4.2, -5), Vector3.UP)
	studio_root.add_child(camera)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, 25, 0)
	light.light_energy = 1.5
	studio_root.add_child(light)
	studio_spotlight = OmniLight3D.new()
	studio_spotlight.light_color = Color("#ffe9a3")
	studio_spotlight.light_energy = 6.0
	studio_spotlight.omni_range = 5.5
	studio_spotlight.shadow_enabled = false
	studio_spotlight.visible = false
	studio_root.add_child(studio_spotlight)
	studio_spotlight_b = OmniLight3D.new()
	studio_spotlight_b.light_color = Color("#a6d9ff")
	studio_spotlight_b.light_energy = 6.0
	studio_spotlight_b.omni_range = 5.5
	studio_spotlight_b.shadow_enabled = false
	studio_spotlight_b.visible = false
	studio_root.add_child(studio_spotlight_b)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#08112d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#5d7fae")
	env.ambient_light_energy = 0.5
	environment.environment = env
	studio_root.add_child(environment)
	_studio_box(Vector3(0, -0.4, 0), Vector3(32, 0.7, 28), Color("#11182a"))
	# Original branded cyc wall and illuminated stage framing.
	_studio_box(Vector3(0, 6.0, -14.2), Vector3(30, 14, 0.5), Color("#10172e"))
	_studio_box(Vector3(0, 11.6, -13.7), Vector3(18.8, 0.6, 0.55), Color("#f6bb47"))
	_studio_box(Vector3(0, 0.15, -10.8), Vector3(20.0, 0.45, 4.2), Color("#172a50"))
	for side in [-1, 1]:
		_studio_box(Vector3(float(side) * 9.9, 5.6, -11.3), Vector3(0.6, 11.3, 1.3), Color("#d9a849"))
		_studio_box(Vector3(float(side) * 12.4, 5.2, -13.7), Vector3(0.35, 10.0, 0.5), Color("#2266bb"))
	for row_index in range(3):
		for col_index in range(3):
			var x: float = float(col_index - 1) * 5.0
			var y: float = 7.0 - float(row_index) * 2.7
			var champion: bool = row_index == 1 and col_index == 1
			var accent: Color = Color("#ffcb62") if champion else Color("#218bff")
			# Each cell is a framed contestant bay rather than a flat floating panel.
			_studio_box(Vector3(x, y, -11.35), Vector3(4.7, 2.55, 0.65), Color("#b58c39"))
			_studio_box(Vector3(x, y, -11), Vector3(4.35, 2.3, 0.5), accent)
			_studio_box(Vector3(x, y, -10.69), Vector3(4.0, 2.0, 0.12), Color("#101f3d"))
			_studio_box(Vector3(x, y - 0.84, -10.5), Vector3(3.7, 0.2, 0.45), accent)
			var nameplate := Label3D.new()
			nameplate.position = Vector3(x, y, -10.35)
			nameplate.pixel_size = 0.008
			nameplate.font_size = 42
			nameplate.outline_size = 8
			nameplate.modulate = Color.WHITE
			nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			studio_root.add_child(nameplate)
			square_labels.append(nameplate)
	# Refresh 3D nameplates after the stage is constructed.
	render()
	# Downstage podiums, deliberately separated from the contestant wall.
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
