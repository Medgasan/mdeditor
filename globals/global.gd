extends Node

func show_message(text: String):
	var dialog = AcceptDialog.new()
	dialog.title = "MD editor/viewer"
	dialog.dialog_text = text
	dialog.ok_button_text = "Aceptar"
	get_tree().root.add_child(dialog)
	dialog.popup_centered()           # Muestra en el centro
	# dialog.popup()                  # Muestra en posición por defecto
