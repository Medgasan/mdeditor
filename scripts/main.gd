extends MarginContainer

@onready var md_editor: MdEditor = $ScrollContainer/MarginContainer/MdEditor
@onready var check_on_top: CheckBox = $"../HBoxContainer/CheckOnTop"
@onready var label_document: Label = $"../MarginContainer/CenterContainer/LabelDocument"
@onready var save_texture_button: TextureButton = $"../HBoxContainer/CenterContainer/SaveTextureButton"


func _ready() -> void:
	Events.connect("windows_status_change",_on_windows_status_change)
	Events.connect("changes_not_saved",_on_changes_not_saved)
	check_on_top.connect("toggled",_on_on_top_change)
	save_texture_button.connect("pressed", _on_save_changes)
	print_debug("En main")
	var arguments = OS.get_cmdline_args()
	if arguments.size() > 0:
		load_md(arguments)
	get_window().files_dropped.connect(_on_files_dropped)


func _on_files_dropped(files: PackedStringArray):
	for file_path in files:
		# Ejemplos según el tipo de archivo:
		if file_path.ends_with(".md"):
			load_md([file_path])


# Carga el archivo pasado por la línea de comandos
func load_md(args):
	var arg : String= args[args.size() -1]
	if FileAccess.file_exists(arg):
		md_editor.set_markdown(FileAccess.open(arg,FileAccess.READ).get_as_text())
		var path:PackedStringArray = arg.split("\\")
		label_document.text = path[path.size()-1].to_lower().replace(".md","")
		get_window().title = arg
		Status.file = arg


func save_md():
	var file = FileAccess.open(Status.file,FileAccess.WRITE)
	file.store_string(md_editor.get_markdown())
	file.flush()
	file.close()


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
