extends MarginContainer

@export var check_on_top: CheckBox
@export var save_texture_button: TextureButton 
@export var save_as_texture_button: TextureButton 
@export var load_texture_button: TextureButton 
@export var new_texture_button: TextureButton 
@export var tab_container: TabContainer
@export var footer: MarginContainer
@onready var center_container: CenterContainer = $CenterContainer

@export var over_all = false

const MD_DOCUMENT := preload("res://escenas/md_document.tscn")
const EMPTY_MSG := preload("res://escenas/tab_container.tscn")
const FOOT_ACTIVATE_MARGIN := 25

var current_doc: MDDocument


func _ready() -> void:
	# Eventos
	Events.connect("windows_status_change",_on_windows_status_change)
	Events.connect("changes_not_saved",_on_changes_not_saved)
	Events.connect("title_changed",_update_title)
	check_on_top.connect("toggled",_on_on_top_change)
	save_texture_button.connect("pressed", _on_save_changes)
	save_as_texture_button.connect("pressed", _on_save_as_changes)
	load_texture_button.connect("pressed", load_selected)
	new_texture_button.connect("pressed", _new_document)
	get_tree().auto_accept_quit = false
	get_tree().root.close_requested.connect(_on_close_requested)
	
	# Inicio
	var arguments = OS.get_cmdline_args()
	if arguments.size() > 0:
		var arg : String= arguments[arguments.size() -1]
		load_md(arg)
	get_window().files_dropped.connect(_on_files_dropped)
	
	# Valores de prueba
	if OS.is_debug_build():
		load_md("C:\\Users\\franm\\Desktop\\ComandosComunesGit.md")
		load_md("C:\\Users\\franm\\Desktop\\GDD_Starship_Disaster_v4.md")


func _on_files_dropped(files: PackedStringArray):
	for file_path in files:
		load_md(file_path)


func load_md(arg: String) -> void:
	if not arg.ends_with(".md"): return
	if tab_container == null: create_tab_container()
	_add_document(arg)


func _add_document(path: String) -> void:
	var new_doc: MDDocument = MD_DOCUMENT.instantiate()
	tab_container.add_child(new_doc)
	new_doc.tab_idx = tab_container.get_tab_count() - 1
	
	if new_doc.load_document(path) == null:
		Global.show_toast(self, "El archivo %s no existe" % path)
		new_doc.queue_free()
		return
	
	tab_container.set_tab_title(new_doc.tab_idx, new_doc.title)
	tab_container.current_tab = new_doc.tab_idx
	Global.show_toast(self, "Documento '%s' cargado" % new_doc.title)


func create_tab_container()->void:
	tab_container = TabContainer.new()
	add_child(tab_container)
	tab_container.tab_selected.connect(_on_tab_selected)
	var tab_bar = tab_container.get_tab_bar()
	tab_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ALWAYS
	tab_bar.tab_close_pressed.connect(_on_tab_close_pressed)
	tab_bar.custom_minimum_size.x = 50 * 1


func _input(event):
	if event is InputEventMouseMotion:
		var hovered := get_viewport().gui_get_hovered_control()
		# fixme: solucionar el parpadeo. Tal vez revisar otra forma de aparecer
		if (hovered == footer) || (get_window().size.y - event.global_position.y) < FOOT_ACTIVATE_MARGIN || !footer.visible:
			show_footer()
		else:
			hide_footer()
		#footer.visible = (hovered == margin_container) || (get_window().size.y - event.global_position.y) < FOOT_ACTIVATE_MARGIN
	if not (event is InputEventKey):
		return
	var ke := event as InputEventKey

	if not ke.pressed or not ke.ctrl_pressed: 
		return
	match ke.keycode:
		KEY_S:
			get_viewport().set_input_as_handled()
			_on_save_as_changes()
		KEY_N:
			get_viewport().set_input_as_handled()
			_new_document()
		KEY_O:
			load_selected()



func _on_close_requested() -> void:
	_check_unsaved_and_quit()


func _on_on_top_change(value) -> void:
	over_all = value
	Events.windows_status_change.emit()


func _on_windows_status_change() -> void:
	get_window().always_on_top = over_all


func _on_changes_not_saved() -> void:
	pass
	#save_texture_button.visible = true


func _on_save_changes() -> void:
	current_doc.save()
	#save_texture_button.visible = false


func _on_tab_selected(idx) -> void:
	if idx < 0:
		get_window().title = "Markdown Editor"
		return
	current_doc = tab_container.get_current_tab_control() as MDDocument
	#save_texture_button.visible = current_doc.changed
	get_window().title = current_doc.title


func _on_tab_close_pressed(index: int) -> void:
	var doc := tab_container.get_child(index) as MDDocument
	_check_unsaved(doc, func(): doc.queue_free())
	await doc.tree_exited
	if (tab_container.get_tab_count() < 1):
		current_doc = null
		tab_container.queue_free()
	else:
		current_doc = tab_container.get_current_tab_control() as MDDocument


func _check_unsaved_and_quit() -> void:
	if tab_container == null: return
	for doc in tab_container.get_children():
		if (doc as MDDocument).changed:
			_check_unsaved(doc, func(): get_tree().quit())
			return
	get_tree().quit()


func _check_unsaved(doc: MDDocument, on_done: Callable) -> void:
	if doc.changed:
		Global.question_message("'%s' not saved. Save it?" % doc.title.replace("*",""),
			func():
				await doc.save()
				on_done.call()
		,
			func():
				on_done.call()
		)
	else:
		on_done.call()


func _update_title():
	get_window().title = current_doc.title
	tab_container.set_tab_title(current_doc.tab_idx, current_doc.title)


func _on_save_as_changes():
	_save_as_dialog()


func _new_document() -> void:
	if tab_container == null:
		create_tab_container()
	var new_doc: MDDocument = MD_DOCUMENT.instantiate()
	tab_container.add_child(new_doc)
	new_doc.tab_idx = tab_container.get_tab_count() - 1
	new_doc.title = "Sin título"
	tab_container.set_tab_title(new_doc.tab_idx, new_doc.title)
	tab_container.current_tab = new_doc.tab_idx
	current_doc = new_doc
	current_doc.title = "new document"


func load_selected():
	get_viewport().set_input_as_handled()
	_open_file_dialog()


func _open_file_dialog() -> void:
	DisplayServer.file_dialog_show(
		"Abrir documento",       # título
		"",                      # directorio inicial
		"",                      # nombre de archivo inicial
		false,                   # modo guardar (false = abrir)
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		["*.md ; Markdown"],     # filtros
		_on_open_selected        # callback
	)


func _on_open_selected(status: bool, paths: PackedStringArray, _filter: int) -> void:
	if not status or paths.is_empty():
		return
	load_md(paths[0])


func _save_as_dialog() -> void:
	DisplayServer.file_dialog_show(
		"Guardar como",
		"",
		"sin_titulo.md",
		false,
		DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
		["*.md ; Markdown"],
		_on_save_as_selected
	)


func _on_save_as_selected(status: bool, paths: PackedStringArray, _filter: int) -> void:
	if not status or paths.is_empty():
		return
	if not is_instance_valid(current_doc):
		return
	current_doc.documento = paths[0]
	current_doc.title = paths[0].get_file().replacen(".md", "").capitalize()
	current_doc.save()
	tab_container.set_tab_title(current_doc.tab_idx, current_doc.title)
	
	
	
func show_footer():
	footer.visible = true
	footer.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(footer,"modulate:a",1.0,0.2)	


func hide_footer():
	var tween = create_tween()
	tween.tween_property(footer,"modulate:a",0.0,0.2)
	tween.finished.connect(func():
		footer.visible = false
	)
