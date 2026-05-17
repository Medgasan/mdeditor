# MdBlockEditor

A lightweight Markdown editor and viewer built with **Godot 4.6**.  
Opens, edits, and renders `.md` files with live WYSIWYG preview powered by Godot's `RichTextLabel` BBCode layer.

---

## Features

### Editor
- **Block-based editing** — each paragraph is an independent node; `Enter` splits, `Backspace` at start merges blocks.
- **Live WYSIWYG rendering** — Markdown is converted to BBCode on every keystroke; no manual preview toggle needed.
- **Full CommonMark + GFM support**: headings (H1–H6), bold, italic, strikethrough, inline code, links, images, blockquotes, ordered/unordered lists, task lists (checkboxes), GFM tables, horizontal rules, footnotes, and a subset of HTML inline tags (`<kbd>`, `<mark>`, `<sup>`, `<sub>`, `<ins>`, `<del>`).

### Multi-document workflow
- **Tabbed interface** — open multiple files simultaneously.
- **Drag & drop** — drop one or more `.md` files onto the window to open them.
- **CLI argument** — pass a file path as the last argument to open it on launch.
- **Unsaved-changes guard** — asterisk (`*`) in the tab title and a save button appear when a document has pending changes; closing a modified document prompts to save.

### Window
- **Always on top** toggle — keep the editor floating above other applications.
- **Auto-hiding footer** — the status/save bar fades in when the cursor approaches the bottom edge.
- **Toast notifications** — non-intrusive feedback for load/save events.

---

## Requirements

| Dependency | Version |
| :--------- | :------ |
| Godot      | 4.6     |

No external libraries or plugins are required.

---

## Getting Started

### Run from the Godot editor

1. Clone or download this repository.
2. Open Godot 4.6 and import the project (`project.godot`).
3. Press **F5** (or the ▶ button) to run.

### Open a file

Three ways to load a Markdown file:

```
# Via CLI
godot --path /path/to/project -- /path/to/file.md

# Via drag & drop
Drop any .md file onto the application window.

# Via tab
If no file is provided, the editor starts with an empty tab ready to type.
```

### Save

- Press the **save icon** (bottom bar) or trigger it from the unsaved-changes dialog when closing a tab.
- The document is saved in-place (overwrites the original file).

---

## Supported Markdown Syntax

| Element | Syntax |
| :------ | :----- |
| Headings | `# H1` … `###### H6` |
| Bold | `**text**` or `__text__` |
| Italic | `*text*` or `_text_` |
| Bold + Italic | `***text***` |
| Strikethrough | `~~text~~` |
| Inline code | `` `code` `` |
| Fenced code block | ` ```lang … ``` ` |
| Blockquote | `> text` |
| Unordered list | `- item` |
| Ordered list | `1. item`, `a. item`, `i. item` |
| Task list | `- [ ] todo` / `- [x] done` |
| GFM table | `\| col \| col \|` with separator row |
| Horizontal rule | `---` or `***` |
| Link | `[label](url)` |
| Image | `![alt](url)` or `![alt](url){WxH}` |
| Footnote | `[^1]` / `[^1]: text` |
| Highlight | `<mark>text</mark>` |
| Keyboard key | `<kbd>K</kbd>` |

---

## Project Structure

```
/
├── project.godot              # Godot project configuration
├── main.tscn                  # Root scene (window, tab container, footer)
├── md_document.tscn           # Per-document scene (scroll + editor)
├── md_block.tscn              # Individual paragraph block
├── empty_mensaje.tscn         # Placeholder shown when no file is open
├── scripts/
│   ├── main.gd                # Window management, tab lifecycle, drag & drop
│   ├── md_document.gd         # Document load/save, tab state
│   ├── md_editor.gd           # Block orchestration, split/merge logic
│   ├── md_block.gd            # Single block editing and rendering
│   └── md_to_bbcode.gd        # Markdown → BBCode parser
├── globals/
│   ├── events.gd              # Global signal bus
│   ├── global.gd              # Shared utilities (dialogs, toasts, file save)
│   └── status.gd              # Application status node
└── fonts/
    ├── Inter/                 # UI font (Regular, Bold, Italic, BoldItalic)
    ├── OpenSans/              # Alternative UI font
    └── FiraCode/              # Monospace font for code blocks
```

---

## Architecture

The editor follows a **block-based document model**:

```
MDDocument (ScrollContainer)
  └── MdEditor (VBoxContainer)
        ├── MdBlock  ← paragraph / heading / list / code block
        ├── MdBlock
        └── ...
```

Each `MdBlock` holds the raw Markdown source for one logical block (separated by blank lines). On every edit, `md_to_bbcode.gd` converts the block's Markdown to BBCode, which `RichTextLabel` renders natively.

**Signal flow for split/merge:**

```
User presses Enter at block boundary
  → MdBlock emits split_requested
    → MdEditor inserts new MdBlock at next index
      → focus transfers to the new block
```

---

## Known Limitations

- `<sup>` / `<sub>` render at a smaller font size but without vertical offset (requires a custom `RichTextEffect`).
- Nested blockquotes and syntax highlighting in code blocks are not yet implemented.
- Save always overwrites the original file; there is no Save As dialog.
- The parser operates on the full Markdown source on every keystroke; very large documents may introduce noticeable latency.

---

## Roadmap

| Phase | Feature | Status |
| :---: | :------ | :----: |
| 1 | Inline parser (bold, italic, code, links) | ✅ |
| 2 | Block-based editor + split/merge | ✅ |
| 3 | Multi-tab + drag & drop | ✅ |
| 4 | GFM tables | ✅ |
| 5 | Footnotes | ✅ |
| 6 | Toolbar with formatting buttons | 🔄 In progress |
| 7 | `RichTextEffect` for sup/sub and blockquote bar | ⏳ Planned |
| 8 | Syntax highlighting in code blocks | ⏳ Planned |
| 9 | Save As / export | ⏳ Planned |
| 10 | IME support (CJK / Arabic) | ⏳ Planned |

---

## License

_No license has been specified. All rights reserved by default until one is added._


---
---

# MdBlockEditor

Editor y visor de Markdown ligero construido con **Godot 4.6**.  
Abre, edita y renderiza ficheros `.md` con previsualización WYSIWYG en tiempo real usando la capa BBCode de `RichTextLabel`.

---

## Características

### Editor
- **Edición por bloques** — cada párrafo es un nodo independiente; `Enter` divide el bloque, `Backspace` al inicio lo fusiona con el anterior.
- **Renderizado WYSIWYG en tiempo real** — el Markdown se convierte a BBCode en cada pulsación; sin necesidad de alternar entre modo edición y vista previa.
- **Soporte completo CommonMark + GFM**: encabezados (H1–H6), negrita, cursiva, tachado, código inline, enlaces, imágenes, citas, listas ordenadas/no ordenadas, listas de tareas (checkboxes), tablas GFM, separadores horizontales, notas al pie y un subconjunto de etiquetas HTML inline (`<kbd>`, `<mark>`, `<sup>`, `<sub>`, `<ins>`, `<del>`).

### Flujo multidocumento
- **Interfaz con pestañas** — abre varios ficheros simultáneamente.
- **Arrastrar y soltar** — arrastra uno o más ficheros `.md` sobre la ventana para abrirlos.
- **Argumento de línea de comandos** — pasa una ruta como último argumento para abrir el fichero al arrancar.
- **Protección contra cambios no guardados** — un asterisco (`*`) en el título de la pestaña y un botón de guardado aparecen cuando hay cambios pendientes; cerrar un documento modificado pregunta si guardar.

### Ventana
- **Siempre encima** — mantén el editor flotando sobre otras aplicaciones.
- **Barra inferior ocultable automáticamente** — la barra de estado/guardado aparece al acercar el cursor al borde inferior.
- **Notificaciones toast** — confirmaciones no intrusivas para eventos de carga y guardado.

---

## Requisitos

| Dependencia | Versión |
| :---------- | :------ |
| Godot       | 4.6     |

No se requieren librerías externas ni plugins.

---

## Primeros pasos

### Ejecutar desde el editor de Godot

1. Clona o descarga este repositorio.
2. Abre Godot 4.6 e importa el proyecto (`project.godot`).
3. Pulsa **F5** (o el botón ▶) para ejecutar.

### Abrir un fichero

Tres formas de cargar un fichero Markdown:

```
# Por línea de comandos
godot --path /ruta/al/proyecto -- /ruta/al/fichero.md

# Por arrastrar y soltar
Arrastra cualquier fichero .md sobre la ventana de la aplicación.

# Sin fichero
Si no se proporciona ninguno, el editor arranca con una pestaña vacía lista para escribir.
```

### Guardar

- Pulsa el **icono de guardado** (barra inferior) o responde al diálogo que aparece al cerrar una pestaña con cambios pendientes.
- El documento se guarda en su ubicación original (sobreescribe el fichero).

---

## Sintaxis Markdown soportada

| Elemento | Sintaxis |
| :------- | :------- |
| Encabezados | `# H1` … `###### H6` |
| Negrita | `**texto**` o `__texto__` |
| Cursiva | `*texto*` o `_texto_` |
| Negrita + Cursiva | `***texto***` |
| Tachado | `~~texto~~` |
| Código inline | `` `código` `` |
| Bloque de código | ` ```lang … ``` ` |
| Cita | `> texto` |
| Lista no ordenada | `- elemento` |
| Lista ordenada | `1. elemento`, `a. elemento`, `i. elemento` |
| Lista de tareas | `- [ ] pendiente` / `- [x] hecho` |
| Tabla GFM | `\| col \| col \|` con fila separadora |
| Separador horizontal | `---` o `***` |
| Enlace | `[etiqueta](url)` |
| Imagen | `![alt](url)` o `![alt](url){AxH}` |
| Nota al pie | `[^1]` / `[^1]: texto` |
| Resaltado | `<mark>texto</mark>` |
| Tecla de teclado | `<kbd>K</kbd>` |

---

## Estructura del proyecto

```
/
├── project.godot              # Configuración del proyecto Godot
├── main.tscn                  # Escena raíz (ventana, pestañas, pie de página)
├── md_document.tscn           # Escena por documento (scroll + editor)
├── md_block.tscn              # Bloque individual de párrafo
├── empty_mensaje.tscn         # Pantalla vacía cuando no hay fichero abierto
├── scripts/
│   ├── main.gd                # Gestión de ventana, ciclo de pestañas, drag & drop
│   ├── md_document.gd         # Carga/guardado de documentos, estado de pestaña
│   ├── md_editor.gd           # Orquestación de bloques, lógica de división/fusión
│   ├── md_block.gd            # Edición y renderizado de un bloque individual
│   └── md_to_bbcode.gd        # Parser Markdown → BBCode
├── globals/
│   ├── events.gd              # Bus de señales global
│   ├── global.gd              # Utilidades compartidas (diálogos, toasts, guardado)
│   └── status.gd              # Nodo de estado de la aplicación
└── fonts/
    ├── Inter/                 # Fuente de interfaz (Regular, Bold, Italic, BoldItalic)
    ├── OpenSans/              # Fuente de interfaz alternativa
    └── FiraCode/              # Fuente monoespaciada para bloques de código
```

---

## Arquitectura

El editor sigue un **modelo de documento basado en bloques**:

```
MDDocument (ScrollContainer)
  └── MdEditor (VBoxContainer)
        ├── MdBlock  ← párrafo / encabezado / lista / bloque de código
        ├── MdBlock
        └── ...
```

Cada `MdBlock` almacena el Markdown en bruto de un bloque lógico (separados por líneas en blanco). En cada edición, `md_to_bbcode.gd` convierte el Markdown del bloque a BBCode, que `RichTextLabel` renderiza de forma nativa.

**Flujo de señales para división/fusión:**

```
El usuario pulsa Enter al final de un bloque
  → MdBlock emite split_requested
    → MdEditor inserta un nuevo MdBlock en la posición siguiente
      → el foco se transfiere al nuevo bloque
```

---

## Limitaciones conocidas

- `<sup>` / `<sub>` se renderizan con un tamaño de fuente menor pero sin desplazamiento vertical (requiere un `RichTextEffect` personalizado).
- Las citas anidadas y el resaltado de sintaxis en bloques de código aún no están implementados.
- El guardado siempre sobreescribe el fichero original; no existe un diálogo «Guardar como».
- El parser procesa el Markdown completo del bloque en cada pulsación; documentos muy extensos pueden introducir latencia perceptible.

---

## Hoja de ruta

| Fase | Funcionalidad | Estado |
| :--: | :------------ | :----: |
| 1 | Parser inline (negrita, cursiva, código, enlaces) | ✅ |
| 2 | Editor por bloques + división/fusión | ✅ |
| 3 | Múltiples pestañas + arrastrar y soltar | ✅ |
| 4 | Tablas GFM | ✅ |
| 5 | Notas al pie | ✅ |
| 6 | Barra de herramientas con botones de formato | 🔄 En progreso |
| 7 | `RichTextEffect` para sup/sub y barra de cita | ⏳ Planificado |
| 8 | Resaltado de sintaxis en bloques de código | ⏳ Planificado |
| 9 | Guardar como / exportar | ⏳ Planificado |
| 10 | Soporte IME (CJK / árabe) | ⏳ Planificado |

---

## Licencia

_No se ha especificado ninguna licencia. Todos los derechos reservados por defecto hasta que se añada una._
