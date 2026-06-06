class_name MdEditor extends VBoxContainer

const MD_BLOCK := preload("res://escenas/md_block.tscn")
var _undo_redo := UndoRedo.new()

func _ready() -> void:
	if get_child_count() == 0:
		var first := _add_block_at(0, "")
		first.call_deferred("focus_editor")


# Añade un bloque en una posición concreta. Devuelve el bloque creado.
func _add_block_at(idx: int, text: String) -> MdBlock:
	var block: MdBlock = MD_BLOCK.instantiate()
	add_child(block)
	move_child(block, idx)
	block.set_text(text)
	block.split_requested.connect(_on_split.bind(block))
	block.merge_requested.connect(_on_merge.bind(block))
	block.focus_prev_requested.connect(_on_focus_prev.bind(block))
	block.focus_next_requested.connect(_on_focus_next.bind(block))
	return block


# Devuelve el texto markdown completo (todos los bloques unidos por \n\n)
func get_markdown() -> String:
	var parts: Array[String] = []
	for c in get_children():
		if c is MdBlock:
			parts.append(c.get_text())
	return "\n\n".join(parts)


# Carga texto markdown completo, partiendo en bloques por línea en blanco
func set_markdown(md: String) -> void:
	# Borra el markdown actual
	for c in get_children():
		c.queue_free()
	var blocks := _split_into_blocks(md)
	if blocks.is_empty():
		blocks = [""]
	for i in blocks.size():
		_add_block_at(i, blocks[i])


func _split_into_blocks(md: String) -> Array[String]:
	var rx : RegEx = RegEx.new()
	rx.compile("\\n\\s*\\n")
	var pieces : PackedStringArray = _split_regex(rx,md)
	var result: Array[String] = []
	for p in pieces:
		result.append((p as String).strip_edges())
	return result


func _split_regex(rx: RegEx, s: String) -> PackedStringArray:
	var out: PackedStringArray = []
	var last := 0
	for m in rx.search_all(s):
		out.append(s.substr(last, m.get_start() - last))
		last = m.get_end()
	out.append(s.substr(last))
	return out


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var ke := event as InputEventKey
	if not ke.pressed or not ke.ctrl_pressed:
		return
	if not is_visible_in_tree():
		return
	if ke.ctrl_pressed and ke.keycode == KEY_Z:
		accept_event()                  # evita que el evento suba
		if ke.shift_pressed:
			_undo_redo.redo()               # Ctrl+Shift+Z → rehacer
		else:
			_undo_redo.undo()               # Ctrl+Z        → deshacer
		return


# ---- Handlers ----
func _on_split(before, after, source) -> void:
	_undo_redo.create_action("Split block")
	_undo_redo.add_do_method(_do_split.bind(source.get_index(), before, after))
	_undo_redo.add_undo_method(_undo_split.bind(source.get_index(), before + after))
	_undo_redo.commit_action()


func _do_split(idx: int, before: String, after: String) -> void:
	var block := get_child(idx) as MdBlock
	if block == null:
		return
	block.set_text(before)
	var new_block := _add_block_at(idx + 1, after)
	new_block.call_deferred("focus_editor", false)


func _undo_split(idx: int, original_text: String) -> void:
	if idx + 1 < get_child_count():
		get_child(idx + 1).queue_free()
	var block := get_child(idx) as MdBlock
	if block:
		block.set_text(original_text)
		block.call_deferred("focus_editor")


func _on_merge(source: MdBlock) -> void:
	var idx := source.get_index()
	if idx == 0:
		return
	var prev := get_child(idx - 1) as MdBlock
	if prev == null:
		return
	var prev_text := prev.get_text()
	var src_text  := source.get_text()
	_undo_redo.create_action("Merge blocks")
	_undo_redo.add_do_method(_do_merge.bind(idx - 1, prev_text, src_text))
	_undo_redo.add_undo_method(_undo_merge.bind(idx - 1, prev_text, src_text))
	_undo_redo.commit_action()


func _do_merge(prev_idx: int, prev_text: String, src_text: String) -> void:
	var prev := get_child(prev_idx) as MdBlock
	if prev == null:
		return
	var combined := prev_text + src_text
	var lc := _offset_to_line_col(combined, prev_text.length())
	prev.set_text(combined)
	if prev_idx + 1 < get_child_count():
		get_child(prev_idx + 1).queue_free()
	prev.call_deferred("focus_editor_at", lc.x, lc.y)


func _undo_merge(prev_idx: int, prev_text: String, src_text: String) -> void:
	var prev := get_child(prev_idx) as MdBlock
	if prev == null:
		return
	prev.set_text(prev_text)
	var restored := _add_block_at(prev_idx + 1, src_text)
	restored.call_deferred("focus_editor", false)


func _on_focus_prev(source: MdBlock) -> void:
	var idx := source.get_index()
	if idx == 0:
		return
	var prev := get_child(idx - 1) as MdBlock
	if prev:
		prev.focus_editor()


func _on_focus_next(source: MdBlock) -> void:
	var idx := source.get_index()
	if idx >= get_child_count() - 1:
		return
	var nxt := get_child(idx + 1) as MdBlock
	if nxt:
		nxt.focus_editor(false)


# Convierte un offset (en caracteres) a (línea, columna) dentro de `text`
func _offset_to_line_col(text: String, offset: int) -> Vector2i:
	var line := 0
	var col := 0
	var i := 0
	while i < offset and i < text.length():
		if text[i] == "\n":
			line += 1
			col = 0
		else:
			col += 1
		i += 1
	return Vector2i(line, col)
