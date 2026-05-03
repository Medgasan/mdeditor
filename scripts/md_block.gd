class_name MdBlock extends VBoxContainer

# Señales que el contenedor (MdEditor) escucha
signal split_requested(before_text: String, after_text: String)
signal merge_requested
signal focus_prev_requested
signal focus_next_requested

@onready var editor: TextEdit = $TextEdit
@onready var preview: RichTextLabel = $RichTextLabel
@onready var edit_button: TextureButton = $RichTextLabel/EditButton

var tween : Tween

func _ready():
	preview.bbcode_enabled = true
	preview.fit_content = true
	preview.scroll_active = false
	preview.selection_enabled = true
	preview.gui_input.connect(_on_preview_input)
	preview.mouse_entered.connect(_on_mouse_entered)
	preview.mouse_exited.connect(_on_mouse_exited)
	edit_button.pressed.connect(edit)
	editor.focus_exited.connect(_to_preview)
	editor.gui_input.connect(_on_editor_input)
	editor.text_changed.connect(_on_text_changed)
	preview.fit_content = true
	_to_preview()


func set_text(md: String) -> void:
	if editor == null:
		# _ready aún no ha corrido
		await ready
	editor.text = md
	_to_preview()


func get_text() -> String:
	return editor.text


# Pasa al modo edición y enfoca el TextEdit
func focus_editor(at_end: bool = true) -> void:
	if !Status.editable: return
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


func _to_preview() -> void:
	# Si el bloque está vacío, mantenemos el editor visible
	# para que sea clicable y no desaparezca del layout.
	if editor.text.is_empty():
		_to_editor()
		return
	preview.text = MdToBBCode.convert(editor.text)
	editor.hide()
	preview.show()


func _on_mouse_entered() -> void:
	edit_button.modulate = Color(1.,1.,1.,0)
	tween = get_tree().create_tween()
	tween.tween_property(edit_button, "modulate",Color(1.,1.,1.,1.),0.5)


func _on_mouse_exited() -> void:
	if tween.is_running(): tween.kill()
	edit_button.modulate = Color(1.,1.,1.,0.)


func _on_preview_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and Status.editable:
		accept_event()
		edit()

func edit() -> void:
	_to_editor()
	editor.grab_focus()
	# caret al final por defecto (mapeo pixel→md no implementado)
	var last_line := editor.get_line_count() - 1
	editor.set_caret_line(last_line)
	editor.set_caret_column(editor.get_line(last_line).length())	


func _on_editor_input(e: InputEvent) -> void:
	if not (e is InputEventKey):
		return
	var ke := e as InputEventKey
	if not ke.pressed:
		return

	# Enter sin shift -> partir bloque
	print_debug(Input.is_key_pressed(KEY_SHIFT))
	if (ke.keycode == KEY_ENTER || ke.keycode == KEY_KP_ENTER) and Input.is_key_pressed(KEY_SHIFT):
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
	if ke.keycode == KEY_BACKSPACE:
		if editor.get_caret_line() == 0 and editor.get_caret_column() == 0 and not editor.has_selection():
			accept_event()
			merge_requested.emit()
			return

	# Flechas arriba/abajo en borde del bloque -> saltar bloque
	if ke.keycode == KEY_UP and editor.get_caret_line() == 0:
		accept_event()
		focus_prev_requested.emit()
		return
	if ke.keycode == KEY_DOWN and editor.get_caret_line() == editor.get_line_count() - 1:
		accept_event()
		focus_next_requested.emit()
		return


func _on_text_changed() -> void:
	Events.changes_not_saved.emit()
	Status.changes_saved = false
