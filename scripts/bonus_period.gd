extends Control
# Playable Bonus Period referee prototype. Correct/wrong buttons record question outcomes.
const STATE_PATH := "user://knockout_bonus_state.json"
const LINEUP_PATH := "user://knockout_lineup.json"
var remaining: Array[String] = []
var champion := "Champion"
var selected := ""
var seconds := 60.0
var running := false
var finished := false
var cashpot := 25000
var title_label: Label
var clock_label: Label
var info_label: Label
var status_label: Label
var opponents: GridContainer
var actions: HBoxContainer

func _ready() -> void:
	var saved := _read_json(STATE_PATH)
	cashpot = int(saved.get("cashpot", 25000))
	var lineup: Array = _read_array(LINEUP_PATH)
	var survivors: Array = saved.get("returning", [])
	if not survivors.is_empty():
		lineup = survivors
	for entry in lineup:
		var name := str(entry.get("name", "")) if entry is Dictionary else str(entry)
		if not name.is_empty() and not remaining.has(name):
			remaining.append(name)
	while remaining.size() < 9:
		remaining.append("Opponent %d" % (remaining.size() + 1))
	if remaining.size() > 9:
		remaining.resize(9)
	var bg := ColorRect.new()
	bg.color = Color("#101322")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	scroll.add_child(root)
	title_label = _label(root, "KNOCKOUT — THE BONUS PERIOD", 34)
	clock_label = _label(root, "60.0", 46)
	info_label = _label(root, "", 20)
	status_label = _label(root, "Choose an opponent, then start the clock.", 18)
	opponents = GridContainer.new()
	opponents.columns = 3
	root.add_child(opponents)
	actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(actions)
	_button(root, "START / RESUME CLOCK", _start)
	_button(root, "RESET BONUS DEMO", _reset)
	_button(root, "BACK TO MAIN MENU", func(): get_tree().change_scene_to_file("res://scenes/launcher.tscn"))
	_refresh()

func _label(parent: Node, value: String, size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label

func _button(parent: Node, value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(230, 52)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _process(delta: float) -> void:
	if running and not finished:
		seconds = maxf(0.0, seconds - delta)
		if seconds <= 0.0:
			_finish(false)
		else:
			clock_label.text = "%.1f SECONDS" % seconds

func _start() -> void:
	if not finished and not selected.is_empty():
		running = true
		status_label.text = "Clock running! Record the next answer."

func _choose(name: String) -> void:
	if finished:
		return
	selected = name
	status_label.text = "Facing %s — who answers?" % name
	_refresh()

func _outcome(kind: String) -> void:
	if finished or not running or selected.is_empty():
		return
	match kind:
		"champion_correct", "opponent_wrong":
			var eliminated := selected
			remaining.erase(selected)
			selected = ""
			status_label.text = "%s KNOCKED OUT! Choose the next opponent." % eliminated
			if remaining.is_empty():
				_finish(true)
		"champion_wrong":
			seconds = maxf(0.0, seconds - 15.0)
			status_label.text = "Champion wrong! Minus 15 seconds."
			if seconds <= 0.0:
				_finish(false)
		"opponent_correct":
			status_label.text = "Opponent correct — they survive this question."
	_refresh()

func _refresh() -> void:
	clock_label.text = "%.1f SECONDS" % seconds
	info_label.text = "Cashpot: $%s    |    Opponents remaining: %d / 9" % [str(cashpot), remaining.size()]
	for child in opponents.get_children():
		opponents.remove_child(child)
		child.queue_free()
	for name in remaining:
		_button(opponents, ("▶ " if name == selected else "") + name, _choose.bind(name)).disabled = finished
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	if not finished:
		_button(actions, "CHAMPION CORRECT → KO", _outcome.bind("champion_correct"))
		_button(actions, "OPPONENT WRONG → KO", _outcome.bind("opponent_wrong"))
		_button(actions, "CHAMPION WRONG → −15s", _outcome.bind("champion_wrong"))
		_button(actions, "OPPONENT CORRECT", _outcome.bind("opponent_correct"))

func _finish(escaped: bool) -> void:
	finished = true
	running = false
	selected = ""
	if escaped:
		status_label.text = "ESCAPED! Champion wins the $%d cashpot!" % cashpot
		cashpot = 0
		_write_json(STATE_PATH, {"cashpot": cashpot, "returning": []})
	else:
		status_label.text = "TIME UP! %d survivors return with $0. Cashpot carries over." % remaining.size()
		var returning: Array = []
		for name in remaining:
			returning.append({"name": name, "ai": true, "bank": 0})
		_write_json(STATE_PATH, {"cashpot": cashpot, "returning": returning})
	_refresh()

func _reset() -> void:
	seconds = 60.0
	running = false
	finished = false
	selected = ""
	remaining.clear()
	for i in range(9):
		remaining.append("Opponent %d" % (i + 1))
	status_label.text = "Demo reset. Choose an opponent."
	_refresh()

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}

func _read_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Array else []

func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))
