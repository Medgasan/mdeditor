class_name MdToBBCode


# Convierte un texto markdown (un bloque) a BBCode para RichTextLabel.
static func convert(md: String) -> String:
	if md.is_empty():
		return ""
	var lines := md.split("\n")
	var out_lines: Array[String] = []
	var in_code_block := false
	var code_buffer: Array[String] = []
	var list_stack: Array = []  # cada elem: {"kind": "ul"|"ol", "indent": int}

	var i := 0
	while i < lines.size():
		var l: String = lines[i]

		# Bloque de código ```
		if l.strip_edges().begins_with("```"):
			_close_all_lists(out_lines, list_stack)
			if in_code_block:
				out_lines.append("[code]" + "\n".join(code_buffer) + "[/code]")
				code_buffer.clear()
				in_code_block = false
			else:
				in_code_block = true
			i += 1
			continue
		if in_code_block:
			code_buffer.append(_escape_bbcode(l))
			i += 1
			continue


		# Tabla: línea con '|' seguida de separador '|---|'
		if _is_table_start(lines, i):
			_close_all_lists(out_lines, list_stack)
			var consumed := _parse_table(lines, i, out_lines)
			i += consumed
			continue

		# Detección de item de lista (con indentación)
		var item := _parse_list_item(l)
		if item.is_item:
			_open_list_for_item(out_lines, list_stack, item)
			out_lines.append(_inline(item.content))
			i += 1
			continue
		else:
			_close_all_lists(out_lines, list_stack)


		# Encabezados
		if l.begins_with("#### "):
			out_lines.append("[font_size=16][b]%s[/b][/font_size]" % _inline(l.substr(5)))
			out_lines.append("[hr height=1 width=100% color=#ffffff89]")
		elif l.begins_with("### "):
			out_lines.append("[font_size=20][b]%s[/b][/font_size]" % _inline(l.substr(4)))
			out_lines.append("[hr height=1 width=100% color=#ffffff89]")
		elif l.begins_with("## "):
			out_lines.append("[font_size=24][b]%s[/b][/font_size]" % _inline(l.substr(3)))
			out_lines.append("[hr height=1 width=100% color=#ffffff89]")
		elif l.begins_with("# "):
			out_lines.append("[font_size=32][b]%s[/b][/font_size]" % _inline(l.substr(2)))
			out_lines.append("[hr height=1 width=100% color=#ffffff89]")
		elif l.begins_with("> "):
			out_lines.append("[indent][i]%s[/i][/indent]" % _inline(l.substr(2)))
		elif l.strip_edges() == "---":
			out_lines.append("[hr width=100%]")
		else:
			out_lines.append(_inline(l))
		i += 1

	_close_all_lists(out_lines, list_stack)
	if in_code_block:
		out_lines.append("[code]" + "\n".join(code_buffer) + "[/code]")

	return "\n".join(out_lines)


# ─── Tablas ────────────────────────────────────────────────────────────────

static func _is_table_start(lines: PackedStringArray, idx: int) -> bool:
	if idx + 1 >= lines.size():
		return false
	var header := lines[idx].strip_edges()
	var sep := lines[idx + 1].strip_edges()
	if not header.contains("|") or not sep.contains("|"):
		return false
	# separador: solo '|', '-', ':', espacios
	var rx := RegEx.new()
	rx.compile("^\\|?\\s*:?-{3,}:?\\s*(\\|\\s*:?-{3,}:?\\s*)+\\|?$")
	return rx.search(sep) != null


# Parsea desde idx hasta que termine la tabla, escribe BBCode en out, y devuelve nº líneas consumidas.
static func _parse_table(lines: PackedStringArray, idx: int, out: Array) -> int:
	var header_cells := _split_row(lines[idx])
	var cols := header_cells.size()
	var consumed := 2  # cabecera + separador
	var rows: Array = [header_cells]

	var j := idx + 2
	while j < lines.size():
		var ln := lines[j]
		if not ln.strip_edges().contains("|"):
			break
		var cells := _split_row(ln)
		if cells.is_empty():
			break
		# Ajusta a cols
		while cells.size() < cols:
			cells.append("")
		if cells.size() > cols:
			cells.resize(cols)
		rows.append(cells)
		consumed += 1
		j += 1

	# Emitir BBCode
	out.append("[table=%d shrink=false]" % cols)
	for r in range(rows.size()):
		var row: Array = rows[r]
		var ncell = 0
		for c in row:
			var content := _inline(String(c).strip_edges())
			var expand = 10
			if (ncell % 2) == 0:
				expand = 10
			if r == 0:
				out.append("[cell expand=%s shrink=false padding=10,6,6,6][b]%s[/b][/cell]" % [expand, content])
			else:
				out.append("[cell expand=%s shrink=false padding=10,6,6,6]%s[/cell]" % [expand, content])
			ncell+=1

	out.append("[/table]")
	return consumed


# Divide una fila '| a | b | c |' en ["a","b","c"]. Respeta '\|' escapado.
static func _split_row(line: String) -> Array:
	var s := line.strip_edges()
	# placeholder para pipes escapados
	const ESC := "\u0001"
	s = s.replace("\\|", ESC)
	# quita pipe inicial/final si existen
	if s.begins_with("|"):
		s = s.substr(1)
	if s.ends_with("|"):
		s = s.substr(0, s.length() - 1)
	var parts := s.split("|")
	var out: Array = []
	for p in parts:
		out.append(String(p).replace(ESC, "|"))
	return out


# ─── Listas (sin cambios) ──────────────────────────────────────────────────

static func _parse_list_item(line: String) -> Dictionary:
	var indent := 0
	var i := 0
	while i < line.length() and (line[i] == " " or line[i] == "\t"):
		indent += 4 if line[i] == "\t" else 1
		i += 1
	var rest := line.substr(i)
	if rest.begins_with("- [ ] ") or rest.begins_with("- [x] ") or rest.begins_with(" -[X] "):
		var checked := rest[3] != " "
		var icon := "☑" if checked else "🔳"
		return {"is_item": true, "kind": "ul", "indent": indent / 2, "content": icon + " " + rest.substr(6)}
	if rest.begins_with("- ") or rest.begins_with("* "):
		return {"is_item": true, "kind": "ul", "indent": indent / 2, "content": rest.substr(2)}
	var rx := RegEx.new()
	rx.compile("^(\\d+)\\.\\s(.*)$")
	var m := rx.search(rest)
	if m:
		return {"is_item": true, "kind": "ol", "indent": indent / 2, "content": m.get_string(2)}
	return {"is_item": false, "kind": "", "indent": 0, "content": ""}


static func _open_list_for_item(out: Array, stack: Array, item: Dictionary) -> void:
	while stack.size() > 0 and stack.back().indent > item.indent:
		var top: Dictionary = stack.pop_back()
		out.append("[/%s]" % top.kind)
	if stack.size() > 0 and stack.back().indent == item.indent and stack.back().kind != item.kind:
		var top2: Dictionary = stack.pop_back()
		out.append("[/%s]" % top2.kind)
	if stack.size() == 0 or stack.back().indent < item.indent:
		var open_tag := "[ul]" if item.kind == "ul" else "[ol type=1]"
		out.append(open_tag)
		stack.append({"kind": item.kind, "indent": item.indent})


static func _close_all_lists(out: Array, stack: Array) -> void:
	while stack.size() > 0:
		var top: Dictionary = stack.pop_back()
		out.append("[/%s]" % top.kind)


# ─── Inline ────────────────────────────────────────────────────────────────

static func _inline(s: String) -> String:
	if s.is_empty():
		return s
	var out := s
	out = _re(out, "`([^`]+?)`", " [bgcolor=#ffffff10][color=#7f7f7f][code]$1[/code][/color][/bgcolor]")
	out = _re(out, "\\[(.+?)\\]\\((.+?)\\)", "[url=$2]$1[/url]")
	out = _re(out, "\\*\\*(.+?)\\*\\*", "[b]$1[/b]")
	out = _re(out, "(?<!\\*)\\*([^*\\n]+?)\\*(?!\\*)", "[i]$1[/i]")
	out = _re(out, "~~(.+?)~~", "[s]$1[/s]")
	return out


static func _re(s: String, pat: String, repl: String) -> String:
	var rx := RegEx.new()
	rx.compile(pat)
	return rx.sub(s, repl, true)


static func _escape_bbcode(s: String) -> String:
	return s.replace("[", "[lb]")
