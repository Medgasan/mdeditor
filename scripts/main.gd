extends MarginContainer

@export var check_on_top: CheckBox
@export var save_texture_button: TextureButton 
@export var tab_container: TabContainer
@export var margin_container: MarginContainer

const MD_DOCUMENT := preload("res://md_document.tscn")


func _ready() -> void:
	# Eventos
	Events.connect("windows_status_change",_on_windows_status_change)
	Events.connect("changes_not_saved",_on_changes_not_saved)
	check_on_top.connect("toggled",_on_on_top_change)
	save_texture_button.connect("pressed", _on_save_changes)
	tab_container.tab_selected.connect(_on_tab_selected)
	# Inicialización de las tabs
	var tab_bar = tab_container.get_tab_bar()
	tab_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ALWAYS
	tab_bar.tab_close_pressed.connect(_on_tab_close_pressed)
	#tab_bar.add_theme_icon_override("close", preload("res://images/close_16dp.png"))
	tab_bar.custom_minimum_size.x = 50 * 1

	# Inicio
	var arguments = OS.get_cmdline_args()
	if arguments.size() > 0:
		var arg : String= arguments[arguments.size() -1]
		load_md(arg)
	get_window().files_dropped.connect(_on_files_dropped)


func _on_files_dropped(files: PackedStringArray):
	for file_path in files:
		# Ejemplos según el tipo de archivo:
		load_md(file_path)


# Carga el archivo pasado por la línea de comandos
func load_md(arg):
	if !arg.ends_with(".md"):
		return
	var md_document: MDDocument = MD_DOCUMENT.instantiate()
	tab_container.add_child(md_document)
	# Primero asignamos el índice correcto
	md_document.tab_idx = tab_container.get_tab_count() - 1
	# Ahora guardamos en Status
	Status.tabs_var[md_document.tab_idx] = {
		"documento": arg,
		"changed": false
	}
	var document = md_document.load_document(arg)
	if document == null:
		Global.show_message("El archivo %s no existe" % arg)
		return
	tab_container.set_tab_title(md_document.tab_idx, md_document.title)
	tab_container.current_tab = md_document.tab_idx


func save_md():
	var file = FileAccess.open(Status.file,FileAccess.WRITE)
	#file.store_string(md_editor.get_markdown())
	file.flush()
	file.close()


func _input(event):
	if event is InputEventMouseMotion:
		var hovered := get_viewport().gui_get_hovered_control()
		print(hovered)
		margin_container.visible = (hovered == margin_container) || (get_window().size.y - event.global_position.y) < 25



func _on_on_top_change(value) -> void:
	Status.over_all = value
	Events.windows_status_change.emit()


func _on_windows_status_change() -> void:
	get_window().always_on_top = Status.over_all


func _on_changes_not_saved() -> void:
	save_texture_button.visible = true
	Status.changes_saved = false


func _on_save_changes() -> void:
	save_md()
	save_texture_button.visible = false
	Status.changes_saved = true


func _on_tab_selected(idx) -> void:
	if idx < 0 or not Status.tabs_var.has(idx):
		get_window().title = "Markdown Editor"
		return
	get_window().title = Status.tabs_var[idx].get("documento", "Sin título")
	
	
func _on_tab_close_pressed(index: int) -> void:
	var content = tab_container.get_tab_control(index)
	content.queue_free()  # Elimina el contenido de la pestaña
	Status.tabs_var.erase(index)
	await content.tree_exited
	if tab_container.get_tab_count() < 1: get_tree().quit(0)
