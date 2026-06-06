class_name MDDocument extends ScrollContainer

@export var md_editor : MdEditor
@export var title = "":
	set(v):
		title = v
		Events.title_changed.emit()
	get:
		return title

@export var documento = ""
@export var tab_idx = 0
@export var changed = false

signal  saved
@export var document_tab_changed_background_color = Color()
var document_tab_default_background_color
var current_background_tab_color

@export var scroll_speed := 120.0
@export var smoothness := 5.0

var target_scroll := 0.0



func _ready() -> void:
	target_scroll = scroll_vertical
	Events.connect("changes_not_saved", _changes_not_saved)
	var style := (get_parent() as TabContainer).get_theme_stylebox("tab_selected") as StyleBoxFlat
	document_tab_default_background_color = style.bg_color
	current_background_tab_color = document_tab_default_background_color


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_scroll -= scroll_speed
			accept_event()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_scroll += scroll_speed
			accept_event()	


func _process(delta):
	target_scroll = clamp(target_scroll,0,get_v_scroll_bar().max_value)
	scroll_vertical = lerp(scroll_vertical as float,target_scroll,smoothness * delta)



func load_document(document : String) -> MDDocument:
	if !FileAccess.file_exists(document): return null
	md_editor.set_markdown(FileAccess.open(document,FileAccess.READ).get_as_text())
	var path:PackedStringArray = document.split("\\")
	title = path[path.size()-1].replacen(".md","").capitalize()
	documento = document
	return self


func save() -> void:
	if documento.is_empty(): return;
	Global.save_document(documento, md_editor.get_markdown())
	changed = false
	title = title.replace("*", "")
	current_background_tab_color = document_tab_default_background_color
	saved.emit()


func _changes_not_saved():
	if !visible: return
	changed = true
	if !title.begins_with("*"):
		title = "*" + title
	current_background_tab_color = document_tab_changed_background_color
