# MdBlockEditor — editor markdown por bloques (Godot 4.4)

Estilo Typora / Obsidian Live Preview: cada párrafo es un bloque con dos vistas
intercambiables — `TextEdit` (raw markdown) cuando está enfocado y `RichTextLabel`
(BBCode renderizado) cuando no.

## Cómo probarlo

1. Importa la carpeta como proyecto Godot 4.4+.
2. Run.

## Cómo funciona

- `md_block.tscn` / `md_block.gd`: el bloque. TextEdit + RichTextLabel apilados.
  Al hacer click en el preview → se muestra el editor. Al perder foco → vuelve
  al preview con el markdown convertido a BBCode.
- `md_editor.gd`: contenedor (VBoxContainer). Crea/parte/funde bloques.
  - `Enter` parte el bloque (el texto antes del caret se queda, el de después
    se mueve a un bloque nuevo).
  - `Backspace` al inicio de un bloque lo funde con el anterior.
  - Flechas `↑`/`↓` en bordes saltan al bloque vecino.
  - `Shift+Enter` inserta salto de línea dentro del bloque.
- `md_to_bbcode.gd`: conversor markdown → BBCode. Soporta:
  - Encabezados `#`, `##`, `###`
  - Negrita `**...**`, cursiva `*...*`, tachado `~~...~~`
  - Código inline `` `...` `` y bloques ```` ``` ````
  - Enlaces `[texto](url)`
  - Citas `> ...`
  - Listas `- ` / `* ` / `1. `
  - Línea horizontal `---`

## Integrar en tu proyecto

Copia los 3 `.gd` y el `md_block.tscn` a tu proyecto. Instancia un
`VBoxContainer` con `md_editor.gd` y mete dentro de un `ScrollContainer`.

```gdscript
var ed: MdEditor = $ScrollContainer/MdEditor
ed.set_markdown("# Hola\n\nEsto es **negrita** y *cursiva*.")
print(ed.get_markdown())
```

## Limitaciones conocidas

- El click en preview no posiciona el caret en el carácter exacto (va al final
  del bloque). Para caret pixel-perfect hay que mantener un mapeo
  `bbcode_index → markdown_index` durante la conversión. No implementado.
- No hay soporte para tablas, imágenes ni HTML embebido.
- Bloques de código multilinea funcionan pero se editan como texto plano (sin
  resaltado de sintaxis).
- Sin undo/redo entre bloques (el TextEdit tiene undo solo dentro del bloque).
