extends Control
var dialogue_panel: PanelContainer
var dialogue_text: Label
var dialogue_last := ""
var dialogue_parts: Array[String] = []
var dialogue_step := 0
var dialogue_timer := 0.0

func _display_name(index: int) -> String:
	var full_name: String = str(players[index]["name"]).strip_edges()
	if bool(players[index]["ai"]):
		return full_name.get_slice(" ", 0)
	return full_name


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
var escape_time: float = 60.0
var escape_target: int = -1
var escape_selected: int = -1
var escape_steps: int = 0
var escape_clock: float = 0.0
var escape_actor: String = ""
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
var stage_category_board: Label3D
var freeze_target: int = -1
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
var square_bank_labels: Array = []
var square_status_labels: Array = []
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
	setup_dialogue()


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
	escape_target = -1
	escape_time = 60.0
	freeze_target = -1
	round_number = 1
	terminators_this_round = 0
	round_questions = 0
	terminator_running = false
	spotlight_index = -1
	spotlight_index_b = -1
	render()


func _process(delta: float) -> void:
	update_dialogue(delta)
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
	if phase == "escape_select":
		escape_clock += delta
		if escape_clock >= 0.12:
			escape_clock = 0.0
			escape_steps += 1
			spotlight_index = randi_range(0, 8)
			if escape_steps >= 24:
				spotlight_index = escape_selected
				champ = escape_selected
				phase = "escape_choose"
				host_banner.text = "ARIANNA: %s, you have 60 seconds to clear the board!" % _display_name(champ)
				if studio_spotlight != null:
					studio_spotlight.visible = false
				spotlight_index = -1
			elif studio_spotlight != null:
				studio_spotlight.position = _square_light_position(spotlight_index)
			render()
		return
	if phase == "escape_choose" or phase == "escape_panel" or phase == "escape_champion":
		var previous_second: int = int(ceil(escape_time))
		escape_time = maxf(0.0, escape_time - delta)
		if escape_time <= 0.0:
			_finish_escape(false)
			return
		if int(ceil(escape_time)) != previous_second:
			render()
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
			if players[i]["alive"] and not players[i]["locked"] and players[i]["ai"] and i != freeze_target:
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
	elif phase == "escape_choose" and players[champ]["ai"]:
		var available: Array = []
		for i in range(9):
			if i != champ and players[i]["alive"]:
				available.append(i)
		if not available.is_empty():
			choose_escape_opponent(int(available.pick_random()))
	elif phase == "escape_panel" and escape_target >= 0 and players[escape_target]["ai"]:
		answer_field.text = _ai_answer()
		submit_escape_answer()
	elif phase == "escape_champion" and players[champ]["ai"]:
		answer_field.text = _ai_answer()
		submit_escape_answer()

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
	if _current_question().is_empty() and phase != "finished":
		phase = "question_bank_empty"
	category_board.text = "CATEGORY BOARD  |  " + ("QUESTION BANK EXHAUSTED" if phase == "question_bank_empty" else str(_current_question()[0]).to_upper())
	if stage_category_board != null:
		stage_category_board.text = category_board.text
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
		if freeze_target == i and phase == "questions":
			state = "FROZEN"
		if spotlight_index == i or spotlight_index_b == i:
			state = "SPOTLIGHT!"
			b.add_theme_color_override("font_color", Color("#ffed8c"))
		b.text = "%s\n$%d  |  %s" % [_display_name(i), p["bank"], state]
		b.disabled = not p["alive"] or (phase == "questions" and (p["locked"] or freeze_target == i))
		b.pressed.connect(select_player.bind(i))
		grid.add_child(b)
	if square_labels.size() == 9:
		for i in range(9):
			var nameplate: Label3D = square_labels[i]
			var contestant: Dictionary = players[i]
			nameplate.text = _display_name(i).to_upper()
			nameplate.modulate = Color("#ffdf76") if spotlight_index == i or spotlight_index_b == i else Color.WHITE
			if square_bank_labels.size() == 9:
				square_bank_labels[i].text = "$%s" % str(contestant["bank"])
			if square_status_labels.size() == 9:
				square_status_labels[i].text = "OUT" if not contestant["alive"] else "FROZEN" if freeze_target == i and phase == "questions" else "LOCKED" if contestant["locked"] else "IN PLAY"
	for n in actions.get_children():
		actions.remove_child(n)
		n.queue_free()
	if phase == "questions":
		for i in range(9):
			if not players[i]["ai"] and players[i]["alive"] and not players[i]["locked"] and i != freeze_target:
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
		question.text = "TERMINATOR: " + _current_question()[1]
		add_button("Submit buzzer answer", submit_answer)
	elif phase == "final":
		question.text = "FINAL KNOCKOUT: %s — Wager (0 to $%d), then lock in answer: %s" % [players[final_tied[final_cursor]]["name"], players[final_tied[final_cursor]]["bank"], _current_question()[1]]
		add_button("Submit wager and answer", submit_final)
	elif phase == "escape_select":
		question.text = "ARIANNA: The full board is restored! TERMINATOR — SELECT OUR ESCAPE CHALLENGER!"
	elif phase == "escape_choose":
		question.text = "ESCAPE | %s | %d SECONDS | Choose a surviving panel member" % [str(players[champ]["name"]), int(ceil(escape_time))]
		for i in range(9):
			if i != champ and players[i]["alive"]:
				add_button("CHALLENGE %s" % str(players[i]["name"]), choose_escape_opponent.bind(i))
	elif phase == "escape_panel":
		question.text = "ESCAPE | %d SEC | %s answers first: %s" % [int(ceil(escape_time)), str(players[escape_target]["name"]), str(_current_question()[1])]
		if not players[escape_target]["ai"]:
			add_button("Submit panel answer", submit_escape_answer)
	elif phase == "escape_champion":
		question.text = "ESCAPE | %d SEC | %s must answer: %s" % [int(ceil(escape_time)), str(players[champ]["name"]), str(_current_question()[1])]
		if not players[champ]["ai"]:
			add_button("Submit champion answer", submit_escape_answer)
	elif phase == "bonus":
		question.text = "SUDDEN DEATH %d/5: %s" % [bonus+1, questions[question_index % questions.size()][0]]
		add_button("Submit bonus answer", submit_answer)
	elif phase == "finished":
		add_button("Next episode", advance_episode)

func select_player(i: int) -> void:
	if phase == "questions" and i != freeze_target and players[i]["alive"] and not players[i]["locked"]:
		buzz = i
		phase = "answer"
	elif phase == "terminator" and pair.has(i):
		buzz = i
	render()

func submit_answer() -> void:
	if phase != "bonus" and buzz < 0:
		return
	var correct: bool = answer_field.text.strip_edges().to_lower() == str(_current_question()[2]).to_lower()
	answer_field.clear()
	_mark_question_used()
	question_index += 1
	if phase == "answer":
		if correct:
			players[buzz]["bank"] += 1000
			# A correct answer freezes one active opponent for the next question only.
			var opponents: Array = []
			for i in range(players.size()):
				if i != buzz and players[i]["alive"] and not players[i]["locked"]:
					opponents.append(i)
			freeze_target = int(opponents.pick_random()) if not opponents.is_empty() else -1
		else:
			freeze_target = -1
			players[buzz]["locked"] = true
		phase = "questions"
		round_questions += 1
	elif phase == "terminator":
		var loser: int = buzz
		if correct:
			loser = pair[1] if buzz == pair[0] else pair[0]
		var winner: int = int(pair[1]) if loser == int(pair[0]) else int(pair[0])
		var transfer: int = int(players[loser]["bank"])
		players[winner]["bank"] += transfer
		pot += transfer
		players[loser]["bank"] = 0
		freeze_target = -1
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
	freeze_target = -1
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
	freeze_target = -1
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
	return Vector3(float(index % 3 - 1) * 5.0, 7.0 - float(index / 3) * 2.7, -6.6)

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
	var expected: String = str(_current_question()[2]).to_lower()
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
	# Restore all nine squares for the Escape Round.
	# Final Knockout winner is the provisional champion; the opening light
	# randomly selects the actual Escape challenger from the restored board.
	champ = int(winners[0])
	for p in players:
		p["alive"] = true
		p["locked"] = false
	escape_selected = randi_range(0, 8)
	escape_target = -1
	escape_time = 60.0
	escape_steps = 0
	escape_clock = 0.0
	phase = "escape_select"
	if studio_spotlight != null:
		studio_spotlight.visible = true
	if studio_spotlight_b != null:
		studio_spotlight_b.visible = false
	host_banner.text = "ARIANNA: All nine squares are back! TERMINATOR, ACTIVATE!"
	_play_cue("Terminator")
	render()

func choose_escape_opponent(index: int) -> void:
	if phase != "escape_choose" or index == champ or not players[index]["alive"]:
		return
	escape_target = index
	phase = "escape_panel"
	host_banner.text = "ARIANNA: %s, you're up first!" % str(players[index]["name"])
	render()

func submit_escape_answer() -> void:
	if phase != "escape_panel" and phase != "escape_champion":
		return
	var expected: String = str(_current_question()[2]).strip_edges().to_lower()
	var correct: bool = answer_field.text.strip_edges().to_lower() == expected
	answer_field.clear()
	_mark_question_used()
	question_index += 1
	if phase == "escape_panel":
		if correct:
			phase = "escape_champion"
			host_banner.text = "ARIANNA: Correct! Now the challenger must answer."
		else:
			_escape_knockout()
	else:
		if correct:
			_escape_knockout()
		else:
			escape_time = maxf(0.0, escape_time - 15.0)
			host_banner.text = "ARIANNA: Wrong! Fifteen seconds gone — panel member survives!"
			phase = "escape_choose"
			escape_target = -1
			if escape_time <= 0.0:
				_finish_escape(false)
				return
	render()

func _escape_knockout() -> void:
	players[escape_target]["alive"] = false
	host_banner.text = "ARIANNA: %s is KNOCKED OUT!" % str(players[escape_target]["name"])
	escape_target = -1
	var survivors: int = 0
	for i in range(9):
		if i != champ and players[i]["alive"]:
			survivors += 1
	if survivors == 0:
		_finish_escape(true)
	else:
		phase = "escape_choose"

func _finish_escape(won: bool) -> void:
	phase = "finished"
	if won:
		carry = pot
		host_banner.text = "ARIANNA: ESCAPE COMPLETE! %s wins $%d!" % [str(players[champ]["name"]), pot]
		question.text = "ESCAPE COMPLETE — JACKPOT WON!"
	else:
		for i in range(9):
			players[i]["alive"] = true
			players[i]["locked"] = false
			if i != champ:
				players[i]["bank"] = 0
		carry = pot
		host_banner.text = "ARIANNA: Time! Everyone returns next episode, panel banks reset!"
		question.text = "ESCAPE FAILED — BOARD RESTORED"
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
	camera.position = Vector3(-0.7, 6.5, 13.7)
	camera.fov = 74.0
	camera.look_at_from_position(camera.position, Vector3(0, 4.7, -5.2), Vector3.UP)
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
	env.background_color = Color("#090b25")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8294db")
	env.ambient_light_energy = 0.85
	environment.environment = env
	studio_root.add_child(environment)
	_studio_box(Vector3(0, -0.4, 0), Vector3(32, 0.7, 28), Color("#11182a"))
	# Colorful original studio cyclorama: tiered jewel-tone LED wall.
	for band in range(7):
		var palette: Array = [Color("#152b86"), Color("#442c9b"), Color("#822b9b"), Color("#b32e76"), Color("#bc443f"), Color("#8a3eac"), Color("#174ca0")]
		_studio_box(Vector3(0, float(band) * 1.9 + 0.8, -11.6), Vector3(30, 1.85, 0.25), palette[band])
	for column in range(15):
		var accent_color: Color = Color("#31d3ff") if column % 3 == 0 else Color("#f7ae3b") if column % 3 == 1 else Color("#f05bc1")
		_studio_box(Vector3(float(column - 7) * 2.0, 6.0, -11.2), Vector3(0.11, 12.8, 0.22), accent_color)
	# Original branded cyc wall and illuminated stage framing.
	_studio_box(Vector3(0, 6.0, -12.1), Vector3(30, 14, 0.5), Color("#10172e"))
	_studio_box(Vector3(0, 11.6, -10.7), Vector3(18.8, 0.6, 0.55), Color("#f6bb47"))
	_studio_box(Vector3(0, 0.15, -7.8), Vector3(20.0, 0.45, 4.2), Color("#172a50"))
	for side in [-1, 1]:
		_studio_box(Vector3(float(side) * 9.9, 5.6, -8.3), Vector3(0.6, 11.3, 1.3), Color("#d9a849"))
		_studio_box(Vector3(float(side) * 12.4, 5.2, -10.7), Vector3(0.35, 10.0, 0.5), Color("#2266bb"))
	# Dramatic colored lighting inspired by high-stakes quiz-show production.
	for light_index in range(6):
		var wash := OmniLight3D.new()
		wash.position = Vector3(float(light_index - 3) * 4.2, 10.8, -5.0)
		wash.light_color = Color("#296bff") if light_index % 3 == 0 else Color("#db39af") if light_index % 3 == 1 else Color("#ffb34d")
		wash.light_energy = 2.4
		wash.omni_range = 13.0
		studio_root.add_child(wash)
	for row_index in range(3):
		for col_index in range(3):
			var x: float = float(col_index - 1) * 5.0
			var y: float = 7.0 - float(row_index) * 2.7
			var champion: bool = row_index == 1 and col_index == 1
			var accent: Color = Color("#ffcb62") if champion else Color("#218bff")
			# Each cell is a framed contestant bay rather than a flat floating panel.
			_studio_box(Vector3(x, y, -8.35), Vector3(4.85, 2.55, 0.65), Color("#b58c39"))
			_studio_box(Vector3(x, y, -8), Vector3(4.65, 2.3, 0.5), accent)
			_studio_box(Vector3(x, y, -7.69), Vector3(4.42, 2.0, 0.12), Color("#101f3d"))
			_studio_box(Vector3(x, y - 0.84, -7.5), Vector3(3.7, 0.2, 0.45), accent)
			# Chase-style illuminated lower-third: bold name over a separate cash strip.
			_studio_box(Vector3(x, y - 0.35, -7.36), Vector3(4.25, 1.15, 0.16), Color("#07122e"))
			_studio_box(Vector3(x, y - 0.99, -7.32), Vector3(4.25, 0.32, 0.18), Color("#e6ad36"))
			var nameplate := Label3D.new()
			nameplate.position = Vector3(x, y - 0.27, -7.18)
			nameplate.pixel_size = 0.008
			nameplate.font_size = 70
			nameplate.outline_size = 8
			nameplate.modulate = Color.WHITE
			studio_root.add_child(nameplate)
			square_labels.append(nameplate)
			var cashplate := Label3D.new()
			cashplate.position = Vector3(x, y - 0.98, -7.16)
			cashplate.pixel_size = 0.005
			cashplate.font_size = 46
			cashplate.modulate = Color("#08142d")
			studio_root.add_child(cashplate)
			square_bank_labels.append(cashplate)
			var statusplate := Label3D.new()
			statusplate.position = Vector3(x, y + 0.67, -7.16)
			statusplate.pixel_size = 0.0045
			statusplate.font_size = 40
			statusplate.modulate = Color("#ffdb7c")
			studio_root.add_child(statusplate)
			square_status_labels.append(statusplate)
	# Physical category display mounted above the contestant bays.
	stage_category_board = Label3D.new()
	stage_category_board.position = Vector3(11.2, 7.0, -7.0)
	stage_category_board.pixel_size = 0.008
	stage_category_board.font_size = 62
	stage_category_board.outline_size = 12
	stage_category_board.modulate = Color("#ffe18d")
	studio_root.add_child(stage_category_board)
	_studio_box(Vector3(11.2, 7.0, -7.4), Vector3(7.5, 1.3, 0.25), Color("#152c70"))
	# Refresh 3D nameplates after the stage is constructed.
	render()
	# Downstage podiums, deliberately separated from the contestant wall.
	_studio_box(Vector3(-10.8, 0.6, 5), Vector3(3.2, 1.7, 1.7), Color("#b28b44"))
	_studio_box(Vector3(-3.5, 0.65, 5), Vector3(0.85, 1.3, 0.85), Color("#b8242f"))
	_studio_box(Vector3(-3.5, 1.36, 5), Vector3(0.9, 0.15, 0.9), Color("#ff3344"))
	_studio_box(Vector3(-0.6, 0.6, 5), Vector3(2.2, 1.7, 1.5), Color("#244aa2"))
	# Arianna Dawson: procedural 3D host avatar, visible behind the left podium.
	if not _studio_texture_panel("res://knockout_concept_assets/arianna_game.svg", Vector3(-9.0, 2.2, 3.4), Vector2(2.9, 4.3), true):
		_build_arianna_avatar(Vector3(-9.0, 0.0, 3.4))
	_studio_texture_panel("res://knockout_concept_assets/studio_game.svg", Vector3(0, 6.0, -10.9), Vector2(29.0, 12.0), false)

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

func _avatar_ellipsoid(parent: Node3D, at: Vector3, scale_xyz: Vector3, tint: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh_instance.mesh = sphere
	mesh_instance.scale = scale_xyz
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.83
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

func _build_arianna_avatar(at: Vector3) -> void:
	var host := Node3D.new()
	host.name = "AriannaDawson"
	host.position = at
	studio_root.add_child(host)
	var skin := Color("#efbd9e")
	var red := Color("#b91537")
	var hair := Color("#edc474")
	# Full figure, jacket, blouse, neck and natural oval face.
	_avatar_ellipsoid(host, Vector3(0, 1.06, 0), Vector3(0.82, 1.35, 0.48), red)
	_avatar_ellipsoid(host, Vector3(0, 1.52, 0.27), Vector3(0.31, 0.66, 0.08), Color("#111b3c"))
	_avatar_ellipsoid(host, Vector3(0, 2.08, 0), Vector3(0.23, 0.38, 0.24), skin)
	_avatar_ellipsoid(host, Vector3(0, 2.69, 0), Vector3(0.68, 0.92, 0.60), skin)
	# Blonde hair: crown, side locks and swept bangs.
	_avatar_ellipsoid(host, Vector3(0, 3.08, -0.14), Vector3(0.77, 0.48, 0.66), hair)
	for side in [-1.0, 1.0]:
		_avatar_ellipsoid(host, Vector3(side * 0.37, 2.53, -0.14), Vector3(0.25, 1.30, 0.40), hair)
		_avatar_ellipsoid(host, Vector3(side * 0.52, 1.46, 0), Vector3(0.27, 1.25, 0.30), red)
		_avatar_ellipsoid(host, Vector3(side * 0.38, 0.93, 0.08), Vector3(0.20, 0.38, 0.23), skin)
		# Black eyeglass rims and eyes.
		_avatar_ellipsoid(host, Vector3(side * 0.19, 2.76, 0.302), Vector3(0.31, 0.23, 0.055), Color("#12192c"))
		_avatar_ellipsoid(host, Vector3(side * 0.19, 2.76, 0.335), Vector3(0.245, 0.16, 0.045), Color("#d8e3ef"))
		_avatar_ellipsoid(host, Vector3(side * 0.19, 2.76, 0.367), Vector3(0.065, 0.08, 0.03), Color("#34465c"))
	_avatar_ellipsoid(host, Vector3(0, 2.76, 0.33), Vector3(0.14, 0.06, 0.05), Color("#12192c"))
	_avatar_ellipsoid(host, Vector3(0, 2.43, 0.31), Vector3(0.27, 0.09, 0.05), Color("#a74452"))
	# Small visible smile with orthodontic brackets.
	for tooth in range(4):
		_avatar_ellipsoid(host, Vector3(-0.12 + tooth * 0.08, 2.44, 0.35), Vector3(0.057, 0.055, 0.022), Color("#f8f7ef"))
	_avatar_ellipsoid(host, Vector3(0, 2.44, 0.37), Vector3(0.25, 0.012, 0.016), Color("#b0b6c2"))

# Loads optional real concept-art textures when the supplied assets folder is
# copied into the Godot project. The procedural set remains a safe fallback.
func _studio_texture_panel(path: String, center: Vector3, dimensions: Vector2, transparent: bool) -> bool:
	if not ResourceLoader.exists(path):
		return false
	var texture := load(path) as Texture2D
	if texture == null:
		return false
	var panel := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = dimensions
	panel.mesh = quad
	panel.position = center
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel.material_override = mat
	studio_root.add_child(panel)
	return true

func setup_dialogue() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.offset_left = 180.0
	dialogue_panel.offset_right = -180.0
	dialogue_panel.offset_top = -130.0
	dialogue_panel.offset_bottom = -15.0
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101d49")
	style.border_color = Color("#e9ba55")
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(14)
	dialogue_panel.add_theme_stylebox_override("panel", style)
	add_child(dialogue_panel)
	dialogue_text = Label.new()
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_text.add_theme_font_size_override("font_size", 19)
	dialogue_panel.add_child(dialogue_text)
	question.hide()
	host_banner.hide()

func update_dialogue(delta: float) -> void:
	if dialogue_panel == null:
		return
	var source := host_banner.text + "\n" + question.text
	if source != dialogue_last:
		dialogue_last = source
		dialogue_parts.clear()
		for passage in [host_banner.text, question.text]:
			var sentence := ""
			for character in passage:
				sentence += character
				if character == "." or character == "!" or character == "?":
					dialogue_parts.append(sentence.strip_edges())
					sentence = ""
			if not sentence.strip_edges().is_empty():
				dialogue_parts.append(sentence.strip_edges())
		dialogue_step = 0
		dialogue_timer = 0.0
		dialogue_panel.visible = not dialogue_parts.is_empty()
		if not dialogue_parts.is_empty():
			dialogue_text.text = dialogue_parts[0]
	elif dialogue_parts.size() > 1:
		dialogue_timer += delta
		if dialogue_timer >= 3.5:
			dialogue_timer = 0.0
			dialogue_step = (dialogue_step + 1) % dialogue_parts.size()
			dialogue_text.text = dialogue_parts[dialogue_step]
