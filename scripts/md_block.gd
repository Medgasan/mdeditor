class_name MdBlock extends VBoxContainer

# Señales que el contenedor (MdEditor) escucha
signal split_requested(before_text: String, after_text: String)
signal merge_requested
signal focus_prev_requested
signal focus_next_requested

@onready var editor: TextEdit = $TextEdit
@onready var preview: RichTextLabel = $RichTextLabel
@onready var edit_button: TextureButton = $RichTextLabel/EditButton
@onready var bar := HBoxContainer.new()

var tween : Tween

func _ready():
	_build_toolbar()
	preview.bbcode_enabled = true
	preview.fit_content = true
	preview.scroll_active = false
	preview.selection_enabled = true
	#preview.gui_input.connect(_on_preview_input)
	preview.mouse_entered.connect(_on_mouse_entered)
	preview.mouse_exited.connect(_on_mouse_exited)
	preview.gui_input.connect(func(event):
		if event is InputEventMouseButton and not event.pressed:
			var sel := preview.get_selected_text()
			if not sel.is_empty():
				DisplayServer.clipboard_set(sel)
				Global.show_toast(self, "Guardado en el portapapeles")
	)	
	edit_button.pressed.connect(edit)
	editor.focus_exited.connect(_to_preview)
	editor.gui_input.connect(_on_editor_input)
	editor.text_changed.connect(_on_text_changed)
	preview.fit_content = true
	preview.meta_clicked.connect(_on_meta_clicked)
	_to_preview()


func set_text(md: String) -> void:
	if editor == null:
		# _ready aún no ha corrido
		await ready
	editor.text = md
	_to_preview()


func get_text() -> String:
	return editor.text


func _build_toolbar() -> void:
	bar.name = "Toolbar"
	bar.hide()
	add_child(bar)
	move_child(bar, 0)  # encima del TextEdit

	_add_tool_button(bar, "B",  func(): _wrap_selection("**", "**"))
	_add_tool_button(bar, "I",  func(): _wrap_selection("*",  "*"))
	_add_tool_button(bar, "~~", func(): _wrap_selection("~~", "~~"))
	_add_tool_button(bar, "</>",func(): _wrap_selection("`",  "`"))
	_add_tool_button(bar, "🔗", func(): _wrap_selection("[",  "](url)"))
	_add_tool_button(bar, "H1", func(): _prefix_line("# "))
	_add_tool_button(bar, "H2", func(): _prefix_line("## "))
	_add_tool_button(bar, "H3", func(): _prefix_line("### "))
	_add_tool_button(bar, "—",  func(): _insert_at_line("---"))


func _add_tool_button(parent: HBoxContainer, label: String, action: Callable) -> void:
	var btn := Button.new()
	btn.text = label
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE  # no roba el foco del TextEdit
	btn.pressed.connect(func():
		editor.grab_focus()
		action.call()
	)
	parent.add_child(btn)


func _prefix_line(prefix: String) -> void:
	editor.begin_complex_operation()
	var line := editor.get_caret_line()
	var current := editor.get_line(line)
	if current.begins_with(prefix):
		editor.set_line(line, current.substr(prefix.length()))
	else:
		editor.set_line(line, prefix + current)
	editor.end_complex_operation()


func _insert_at_line(text: String) -> void:
	editor.begin_complex_operation()
	editor.insert_line_at(editor.get_caret_line(), text)
	editor.end_complex_operation()


## Pasa al modo edición y enfoca el TextEdit
func focus_editor(at_end: bool = true) -> void:
	return
	_to_editor()
	editor.grab_focus()
	if at_end:
		var last_line := editor.get_line_count() - 1
		editor.set_caret_line(last_line)
		editor.set_caret_column(editor.get_line(last_line).length())
	else:
		editor.set_caret_line(0)
		editor.set_caret_column(0)


# Pasa al modo edición y posiciona el caret en (línea, columna)
func focus_editor_at(line: int, col: int) -> void:
	_to_editor()
	editor.grab_focus()
	editor.set_caret_line(line)
	editor.set_caret_column(col)


# ---- Internos ----

func _to_editor() -> void:
	editor.show()
	preview.hide()
	bar.show()


func _to_preview() -> void:
	# Si el bloque está vacío, mantenemos el editor visible
	# para que sea clicable y no desaparezca del layout.
	if editor.text.is_empty():
		_to_editor()
		return
	preview.text = MdToBBCode.convert(editor.text)
	editor.hide()
	preview.show()
	bar.hide()


func _on_mouse_entered() -> void:
	edit_button.modulate = Color(1.,1.,1.,0)
	tween = get_tree().create_tween()
	tween.tween_property(edit_button, "modulate",Color(1.,1.,1.,1.),0.5)


func _on_mouse_exited() -> void:
	if tween.is_running(): tween.kill()
	edit_button.modulate = Color(1.,1.,1.,0.)


#func _on_preview_input(e: InputEvent) -> void:
	#if e is InputEventMouseButton and e.pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and Status.editable:
		#accept_event()
		#edit()

func edit() -> void:
	_to_editor()
	editor.grab_focus()
	# caret al final por defecto (mapeo pixel→md no implementado)
	var last_line := editor.get_line_count() - 1
	editor.set_caret_line(last_line)
	editor.set_caret_column(editor.get_line(last_line).length())	


func _on_editor_input(e: InputEvent) -> void:
	if not (e is InputEventKey): return
	var ke := e as InputEventKey
	if not ke.pressed: return
	# --- UNDO / REDO ---
	if ke.ctrl_pressed and ke.keycode == KEY_Z:
		print_debug("Ctrl+z presionado en el editor")
		accept_event()                  # evita que el evento suba
		if ke.shift_pressed:
			editor.redo()               # Ctrl+Shift+Z → rehacer
		else:
			editor.undo()               # Ctrl+Z        → deshacer
		return

	if ke.ctrl_pressed: 
		# Ctrl+B → **negrita**
		if ke.keycode == KEY_B:
			accept_event()
			_wrap_selection("**", "**")
			return
		# Ctrl+I → *cursiva*
		elif ke.keycode == KEY_I:
			accept_event()
			_wrap_selection("*", "*")
			return
		# Ctrl+K → [texto](url)
		elif ke.keycode == KEY_K:
			accept_event()
			_wrap_selection("[", "](url)")
			return
		# Ctrl+` → `código`
		elif ke.keycode == KEY_QUOTELEFT:
			accept_event()
			_wrap_selection("`", "`")
			return
	# Enter sin shift -> partir bloque
	elif (ke.keycode == KEY_ENTER || ke.keycode == KEY_KP_ENTER) and Input.is_key_pressed(KEY_SHIFT):
		var line := editor.get_caret_line()
		var col := editor.get_caret_column()
		var lines := editor.text.split("\n")
		var before_arr: Array[String] = []
		var after_arr: Array[String] = []
		for i in lines.size():
			if i < line:
				before_arr.append(lines[i])
			elif i == line:
				before_arr.append((lines[i] as String).substr(0, col))
				after_arr.append((lines[i] as String).substr(col))
			else:
				after_arr.append(lines[i])
		var before := "\n".join(before_arr)
		var after := "\n".join(after_arr)
		accept_event()
		split_requested.emit(before, after)
		return
	# Backspace al inicio absoluto -> fundir con el bloque anterior
	elif ke.keycode == KEY_BACKSPACE:
		if editor.get_caret_line() == 0 and editor.get_caret_column() == 0 and not editor.has_selection():
			accept_event()
			merge_requested.emit()
			return
	# Flechas arriba/abajo en borde del bloque -> saltar bloque
	elif ke.keycode == KEY_UP and editor.get_caret_line() == 0:
		accept_event()
		focus_prev_requested.emit()
		return
	elif ke.keycode == KEY_DOWN and editor.get_caret_line() == editor.get_line_count() - 1:
		accept_event()
		focus_next_requested.emit()
		return


func _on_text_changed() -> void:
	Events.changes_not_saved.emit()


func _on_meta_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))	


func _wrap_selection(prefix: String, suffix: String) -> void:
	editor.begin_complex_operation()
	if editor.has_selection():
		var sel := editor.get_selected_text()
		var from_line := editor.get_selection_from_line()
		var from_col  := editor.get_selection_from_column()
		editor.delete_selection()
		editor.insert_text_at_caret(prefix + sel + suffix)
		editor.set_caret_line(from_line)
		editor.set_caret_column(from_col + prefix.length())
	else:
		editor.insert_text_at_caret(prefix + suffix)
		editor.set_caret_column(editor.get_caret_column() - suffix.length())
	editor.end_complex_operation()
