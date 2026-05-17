class_name MDDocument extends ScrollContainer

@export var md_editor : MdEditor


var title = ""
var documento = ""
var tab_idx = 0
var changed = false


'''
cargar el archivo y mostrarlo
Estar pendiente de si se ha modificado el documento
Guardar el documento
Cerrar el archivo
'''


func load_document(document : String) -> MDDocument:
	if !FileAccess.file_exists(document): return null
	md_editor.set_markdown(FileAccess.open(document,FileAccess.READ).get_as_text())
	var path:PackedStringArray = document.split("\\")
	title = path[path.size()-1].replacen(".md","").capitalize()
	documento = document
	return self
