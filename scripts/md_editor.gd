class_name MdEditor extends VBoxContainer

const MD_BLOCK := preload("res://md_block.tscn")


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


# ---- Handlers ----
func _on_split(before: String, after: String, source: MdBlock) -> void:
	var idx := source.get_index()
	source.set_text(before)
	var new_block := _add_block_at(idx + 1, after)
	new_block.call_deferred("focus_editor", false)


func _on_merge(source: MdBlock) -> void:
	var idx := source.get_index()
	if idx == 0:
		return
	var prev := get_child(idx - 1) as MdBlock
	if prev == null:
		return
	var prev_text := prev.get_text()
	var combined := prev_text + source.get_text()
	var lc := _offset_to_line_col(combined, prev_text.length())
	prev.set_text(combined)
	source.queue_free()
	prev.call_deferred("focus_editor_at", lc.x, lc.y)


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
