extends Control

var pot := 25000
var episode := 1
var round_number := 1
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
	var bg := ColorRect.new()
	bg.color = Color("#0d1527")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	main = VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	new_episode()

func new_episode() -> void:
	players.clear()
	for i in range(9):
		players.append({"name":"Player %d" % (i+1), "bank":0, "alive":true, "locked":false})
	if episode > 1:
		players[4]["name"] = "Returning Champion"
	pot = carry
	phase = "questions"
	pair.clear()
	buzz = -1
	bonus = 0
	round_number = 1
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
		add_button("Random Terminator", start_terminator)
		add_button("Next cash round", next_round)
	elif phase == "answer":
		add_button("Submit answer", submit_answer)
	elif phase == "terminator":
		question.text = "TERMINATOR: " + questions[question_index % questions.size()][0]
		add_button("Submit buzzer answer", submit_answer)
	elif phase == "final":
		question.text = "FINAL KNOCKOUT: " + questions[question_index % questions.size()][0]
		add_button("Resolve final (AI wagers)", resolve_final)
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
		if living().size() == 2:
			start_final()
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
	for p in players:
		if p["alive"]:
			p["locked"] = false
	render()

func start_terminator() -> void:
	var a := living()
	if a.size() <= 2:
		start_final()
		return
	a.shuffle()
	pair = [a[0], a[1]]
	buzz = -1
	phase = "terminator"
	render()

func start_final() -> void:
	pair = living()
	phase = "final"
	render()

func resolve_final() -> void:
	var a: int = pair[0]
	var b: int = pair[1]
	var wa: int = randi_range(0, int(players[a]["bank"]))
	var wb: int = randi_range(0, int(players[b]["bank"]))
	var sa: int = int(players[a]["bank"]) + (wa if randf() < 0.6 else -wa)
	var sb: int = int(players[b]["bank"]) + (wb if randf() < 0.6 else -wb)
	champ = a if sa >= sb else b
	var loser: int = b if champ == a else a
	pot += players[loser]["bank"]
	players[loser]["bank"] = 0
	players[loser]["alive"] = false
	phase = "bonus"
	bonus = 0
	render()

func advance_episode() -> void:
	episode += 1
	new_episode()
