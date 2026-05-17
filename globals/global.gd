extends Node

func show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "MD editor/viewer"
	dialog.dialog_text = text
	dialog.ok_button_text = "Aceptar"
	get_tree().root.add_child(dialog)
	dialog.popup_centered()           # Muestra en el centro


func question_message(text: String, yes_event: Callable, no_event: Callable):
	var dialog =  ConfirmationDialog.new()
	dialog.title = "MD editor/viewer"
	dialog.dialog_text = text
	dialog.ok_button_text = "Yes"
	dialog.cancel_button_text = "No"
	dialog.add_cancel_button("Cancel")
	get_tree().root.add_child(dialog)
	dialog.connect("confirmed", yes_event)
	dialog.get_cancel_button().pressed.connect(no_event)
	dialog.popup_centered()           # Muestra en el centro


func show_toast(parent: Node, msg: String, duration := 2.5) -> void:
	var label := Label.new()
	label.text = msg
	label.modulate = Color(1,1,1,0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	label.top_level = true
	var normal_style = _style()
	label.add_theme_stylebox_override("normal", normal_style)
	label.add_theme_color_override("font_color",Color(1.0, 1.0, 1.0, 1.0))
	label.add_theme_font_override("font",load("res://fonts/OpenSans/OpenSans-Bold.ttf"))
	var vp := parent.get_viewport().get_visible_rect().size
	label.size = Vector2(label.get_minimum_size().x * 2., label.get_minimum_size().y)
	label.position = Vector2(0, vp.y - (label.get_minimum_size().y * 2) - 10)
	label.offset_left =(vp.x - label.get_minimum_size().x - normal_style.get_minimum_size().x) / 2

	parent.add_child(label)

	var tw := parent.create_tween()
	#tw.tween_interval(0.5)
	tw.tween_property(label, "modulate:a", 1.0, 0.2)
	tw.tween_interval(duration)
	tw.tween_property(label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(label.queue_free)


func _style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.0, 0.243, 0.0, 0.565)
	s.corner_radius_top_left = 16
	s.corner_radius_top_right = 16
	s.corner_radius_bottom_left = 16
	s.corner_radius_bottom_right = 16
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


func save_document(file_path: String, markdown: String) -> void:
	if !FileAccess.file_exists(file_path): return
	var file = FileAccess.open(file_path,FileAccess.WRITE)
	file.store_string(markdown)
	file.flush()
	file.close()
