# MdBlockEditor

Editor y visor de Markdown construido con **Godot 4.6**.  
Cada párrafo se edita y renderiza de forma independiente: en reposo muestra la vista previa WYSIWYG; al editarlo, muestra un `TextEdit` en bruto. El cambio entre modos es automático.

---

## Características

### Edición por bloques
Cada bloque lógico (separado por línea en blanco) es un nodo independiente con dos modos:

- **Vista previa** — `RichTextLabel` renderiza el BBCode generado a partir del Markdown.
- **Modo edición** — `TextEdit` con el Markdown en bruto. Se activa al hacer clic en el botón de edición (aparece al pasar el ratón) o navegando con el teclado. Al perder el foco vuelve automáticamente a vista previa.

### Teclado
| Acción | Atajo |
| :----- | :---- |
| Dividir bloque en dos | `Shift + Enter` |
| Fusionar con el bloque anterior | `Backspace` al inicio del bloque |
| Moverse al bloque anterior | `↑` en la primera línea |
| Moverse al bloque siguiente | `↓` en la última línea |
| Deshacer | `Ctrl + Z` |
| Rehacer | `Ctrl + Shift + Z` / `Ctrl + Y` |
| Negrita | `Ctrl + B` |
| Cursiva | `Ctrl + I` |
| Enlace | `Ctrl + K` |
| Código inline | `Ctrl + `` ` |
| Nuevo documento | `Ctrl + N` |
| Abrir documento | `Ctrl + O` |
| Guardar | `Ctrl + S` |
| Guardar como | `Ctrl + Shift + S` |

### Barra de herramientas
Visible únicamente en modo edición. Botones: **B**, *I*, ~~tachado~~, `</>`, 🔗, H1, H2, H3, `—`.

### Deshacer / Rehacer
- **Dentro de un bloque** — historial nativo de `TextEdit`, incluyendo operaciones de la barra de herramientas agrupadas con `begin_complex_operation`.
- **Estructural** (split/merge) — `UndoRedo` en `MdEditor`.

### Selección y portapapeles
Al soltar el botón del ratón sobre texto seleccionado en la vista previa, el texto se copia automáticamente al portapapeles con confirmación toast.

### Flujo multidocumento
- **Pestañas** — múltiples ficheros abiertos simultáneamente.
- **Arrastrar y soltar** — arrastra uno o más `.md` sobre la ventana.
- **Línea de comandos** — pasa la ruta del fichero como último argumento al ejecutar.
- **Protección de cambios** — asterisco en el título de pestaña y botón de guardado al haber cambios pendientes; cerrar una pestaña modificada pregunta si guardar.

### Ventana
- **Siempre encima** — checkbox en la barra inferior para mantener la ventana flotante.
- **Barra inferior auto-ocultable** — aparece al acercar el cursor al borde inferior.
- **Notificaciones toast** — feedback no intrusivo para carga, guardado y portapapeles.

---

## Sintaxis Markdown soportada

### Bloques

| Elemento | Sintaxis |
| :------- | :------- |
| Encabezado H1 | `# texto` |
| Encabezado H2 | `## texto` |
| Encabezado H3 | `### texto` |
| Encabezado H4 | `#### texto` |
| Cita | `> texto` |
| Separador horizontal | `---` |
| Bloque de código | ` ```lang … ``` ` |
| Lista no ordenada | `- item` o `* item` |
| Lista ordenada | `1. item` |
| Lista de tareas | `- [ ] pendiente` / `- [x] hecho` |
| Tabla GFM | `\| col \| col \|` con fila separadora |
| Listas anidadas | Indentación con espacios o tabuladores |

> Los encabezados H1–H4 incluyen una línea separadora debajo.

### Inline

| Elemento | Sintaxis |
| :------- | :------- |
| Negrita | `**texto**` |
| Cursiva | `*texto*` |
| Tachado | `~~texto~~` |
| Código inline | `` `código` `` |
| Enlace | `[etiqueta](url)` |
| Imagen | `![alt](ruta)` |

> Las imágenes se renderizan con `[img]` de BBCode. Solo se soportan rutas locales (`res://`, `user://`, rutas absolutas); URLs remotas requieren descarga previa.

---

## Requisitos

| Dependencia | Versión |
| :---------- | :------ |
| Godot       | 4.6     |

Sin librerías externas ni plugins.

---

## Primeros pasos

### Desde el editor de Godot

1. Clona o descarga el repositorio.
2. Abre Godot 4.6 e importa `project.godot`.
3. Pulsa **F5** para ejecutar.

### Abrir un fichero

```bash
# Por argumento de línea de comandos
godot --path /ruta/al/proyecto -- /ruta/al/fichero.md

# Por arrastrar y soltar
Arrastra cualquier fichero .md sobre la ventana.

# Desde el menú
Ctrl+O abre el diálogo nativo del sistema operativo.

# Sin fichero
El editor arranca con una pestaña vacía lista para escribir.
```

### Guardar

- `Ctrl+S` — guarda en la ruta original (sobreescribe).
- `Ctrl+Shift+S` — abre diálogo nativo para elegir ruta y nombre.
- Botón en la barra inferior cuando hay cambios pendientes.
- Al cerrar una pestaña con cambios, pregunta si guardar.

---

## Estructura del proyecto

```
/
├── project.godot              # Configuración del proyecto
├── main.tscn                  # Escena raíz: ventana, pestañas, barra inferior
├── md_document.tscn           # Escena por documento: scroll + editor
├── md_block.tscn              # Bloque individual: TextEdit + RichTextLabel
├── empty_mensaje.tscn         # Pantalla de bienvenida sin fichero abierto
├── scripts/
│   ├── main.gd                # Ventana, pestañas, drag & drop, CLI
│   ├── md_document.gd         # Carga/guardado, título, estado de cambios
│   ├── md_editor.gd           # Orquestación de bloques, split/merge, undo estructural
│   ├── md_block.gd            # Modo edición/previa, toolbar, atajos inline
│   └── md_to_bbcode.gd        # Parser Markdown → BBCode (clase estática)
├── globals/
│   ├── events.gd              # Bus de señales global
│   ├── global.gd              # Diálogos, toasts, guardado de fichero
│   └── status.gd              # Nodo de estado de la aplicación
└── fonts/
    ├── Inter/                 # Fuente de interfaz
    ├── OpenSans/              # Fuente alternativa de interfaz
    └── FiraCode/              # Fuente monoespaciada para código
```

---

## Arquitectura

```
MDDocument  (ScrollContainer)
  └── MdEditor  (VBoxContainer)
        ├── MdBlock           ← bloque 1
        │     ├── HBoxContainer ← barra de herramientas (solo en edición)
        │     ├── TextEdit    ← edición en Markdown bruto
        │     └── RichTextLabel ← vista previa BBCode
        ├── MdBlock           ← bloque 2
        └── ...
```

**Flujo de señales entre bloques:**

```
Shift+Enter en MdBlock N
  → emite split_requested(antes, después)
    → MdEditor registra en UndoRedo y crea MdBlock N+1
      → el foco pasa al nuevo bloque

Backspace al inicio de MdBlock N
  → emite merge_requested
    → MdEditor registra en UndoRedo y concatena N al final de N-1
      → N se elimina, el foco vuelve a N-1
```

**Conversión Markdown → BBCode:**  
`MdToBBCode.convert()` es una función estática sin estado. Se llama cada vez que un bloque pierde el foco y pasa a vista previa. Opera línea a línea con expresiones regulares para los elementos inline.

---

## Limitaciones conocidas

- Las imágenes remotas (`https://`) no se renderizan; solo rutas locales.
- La navegación caret al volver de vista previa a edición siempre posiciona al final del bloque.
- El historial de undo estructural (split/merge) y el de texto son independientes y no están coordinados.

---

## Licencia

_No se ha especificado ninguna licencia. Todos los derechos reservados por defecto._
