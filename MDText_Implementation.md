# MDText — Editor Markdown WYSIWYG sobre RichTextLabel

Componente `MDTextInput : RichTextLabel` que soporta **todos** los elementos
de Markdown (CommonMark + GFM) renderizados en tiempo real mediante la capa
BBCode de `RichTextLabel`.

---

## 1. Mapa completo Markdown → BBCode

### 1.1 Elementos de bloque

| Elemento MD | Sintaxis MD | BBCode equivalente | Soporte RTL nativo |
|---|---|---|---|
| Párrafo | línea en blanco | `[p]...[/p]` o `\n\n` | ✅ |
| H1 | `# texto` | `[font_size=32][b]texto[/b][/font_size]\n` | ✅ |
| H2 | `## texto` | `[font_size=28][b]texto[/b][/font_size]\n` | ✅ |
| H3 | `### texto` | `[font_size=24][b]texto[/b][/font_size]\n` | ✅ |
| H4 | `#### texto` | `[font_size=20][b]texto[/b][/font_size]\n` | ✅ |
| H5 | `##### texto` | `[font_size=16][b]texto[/b][/font_size]\n` | ✅ |
| H6 | `###### texto` | `[font_size=14]texto[/font_size]\n` | ✅ |
| Blockquote | `> texto` | `[indent][color=#888]▌[/color] texto[/indent]` | ⚠️ simulado |
| Bloque código | ` ```lang\n...\n``` ` | `[code]...[/code]` + bgcolor | ✅ |
| Lista no ordenada | `- item` | `[ul][li]item[/li][/ul]` | ✅ |
| Lista ordenada | `1. item` | `[ol][li]item[/li][/ol]` | ✅ |
| Lista ordenada letra | `a. item` | `[ol type=a][li]item[/li][/ol]` | ✅ |
| Lista ordenada romana | `i. item` | `[ol type=i][li]item[/li][/ol]` | ✅ |
| Checkbox vacío | `- [ ] item` | `[ul bullet=☐]item[/ul]` | ✅ via bullet |
| Checkbox marcado | `- [x] item` | `[ul bullet=☑]item[/ul]` | ✅ via bullet |
| Tabla | `\| a \| b \|` | `[table=2]...[cell]...[/cell]...[/table]` | ✅ |
| Línea horizontal | `---` / `***` | `[hr width=100%]` | ✅ |
| Salto de línea | `\` o 2 espacios | `[br]` | ✅ |

### 1.2 Elementos de línea (inline)

| Elemento MD | Sintaxis MD | BBCode equivalente | Soporte RTL nativo |
|---|---|---|---|
| Negrita | `**t**` / `__t__` | `[b]t[/b]` | ✅ |
| Cursiva | `*t*` / `_t_` | `[i]t[/i]` | ✅ |
| Negrita+Cursiva | `***t***` | `[b][i]t[/i][/b]` | ✅ |
| Tachado | `~~t~~` | `[s]t[/s]` | ✅ |
| Subrayado | `__t__` (GFM ext.) | `[u]t[/u]` | ✅ |
| Código inline | `` `t` `` | `[code]t[/code]` | ✅ |
| Link | `[t](url)` | `[url=url]t[/url]` | ✅ |
| Link con title | `[t](url "tip")` | `[url=url hint="tip"]t[/url]` | ✅ |
| Imagen | `![alt](url)` | `[img tooltip="alt"]url[/img]` | ✅ |
| Imagen con tamaño | `![alt](url){200x100}` | `[img width=200 height=100]url[/img]` | ✅ |
| Nota al pie ref | `[^1]` | `[url=#fn1][sup][color=#06c][1][/color][/sup][/url]` | ⚠️ simulado |
| Nota al pie def | `[^1]: texto` | Appended al final + `[hint=texto]` en ref | ⚠️ simulado |
| HTML `<kbd>` | `<kbd>K</kbd>` | `[code]K[/code]` + fgcolor | ⚠️ simulado |
| HTML `<mark>` | `<mark>t</mark>` | `[bgcolor=#FFD700]t[/bgcolor]` | ✅ |
| HTML `<sup>` | `<sup>t</sup>` | `[font_size=10]t[/font_size]` | ⚠️ sin offset vertical |
| HTML `<sub>` | `<sub>t</sub>` | `[font_size=10]t[/font_size]` | ⚠️ sin offset vertical |
| HTML `<ins>` | `<ins>t</ins>` | `[u][color=#0a0]t[/color][/u]` | ⚠️ simulado |
| HTML `<del>` | `<del>t</del>` | `[s][color=#a00]t[/color][/s]` | ⚠️ simulado |

> **Leyenda:** ✅ soporte nativo RTL · ⚠️ simulado con combinación de tags ·
> ❌ no soportado (requiere `RichTextEffect` personalizado)

---

## 2. Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    MDTextInput                          │
│                                                         │
│  String _md_source          ← fuente de verdad (MD)    │
│  String _bbcode_cache       ← resultado del parser      │
│  int    _caret_pos          ← índice en _md_source      │
│  bool   _dirty              ← requiere re-parseo        │
│                                                         │
│  MDParser    _parser        ← MD → BBCode               │
│  MDToolbar  *_toolbar       ← UI de formato             │
│  UndoStack   _undo          ← historial de cambios      │
│                                                         │
│  hereda: RichTextLabel (renderizado, scroll, selección) │
└─────────────────────────────────────────────────────────┘
```

**Flujo de datos:**
```
Keystroke / Toolbar
      │
      ▼
_md_source  (String)
      │  MDParser::to_bbcode()
      ▼
_bbcode_cache (String)
      │  RichTextLabel::parse_bbcode()
      ▼
Árbol Item interno → Renderizado WYSIWYG
```

---

## 3. Parser MD → BBCode (`MDParser`)

Clase interna stateless. Un único método público:

```cpp
class MDParser {
public:
    // Convierte Markdown a BBCode compatible con RichTextLabel.
    // p_base_font_size: tamaño base para calcular headings proporcionalmente.
    static String to_bbcode(const String &p_md,
                             int p_base_font_size = 16,
                             bool p_gfm_tables = true,
                             bool p_gfm_checkboxes = true);

private:
    // ── Bloques ────────────────────────────────────────────────────
    static String _parse_blocks(const Vector<String> &p_lines,
                                 int p_base_fs, bool p_gfm_tables);
    static String _parse_heading(const String &p_line, int p_base_fs);
    static String _parse_hr(const String &p_line);
    static String _parse_blockquote(const Vector<String> &p_lines,
                                    int p_start, int &r_end, int p_base_fs);
    static String _parse_fenced_code(const Vector<String> &p_lines,
                                     int p_start, int &r_end);
    static String _parse_list(const Vector<String> &p_lines,
                               int p_start, int &r_end, int p_base_fs);
    static String _parse_table(const Vector<String> &p_lines,
                                int p_start, int &r_end);
    static String _parse_footnote_defs(const Vector<String> &p_lines);

    // ── Inline ─────────────────────────────────────────────────────
    static String _parse_inline(const String &p_text);
    static String _parse_inline_code(const String &p_text, int p_from, int &r_end);
    static String _parse_link(const String &p_text, int p_from, int &r_end);
    static String _parse_image(const String &p_text, int p_from, int &r_end);
    static String _parse_emphasis(const String &p_text);
    static String _parse_html_inline(const String &p_text, int p_from, int &r_end);

    // ── Helpers ────────────────────────────────────────────────────
    static int    _heading_size(int p_level, int p_base_fs);
    static bool   _is_hr_line(const String &p_line);
    static bool   _is_heading(const String &p_line, int &r_level, String &r_text);
    static bool   _is_list_item(const String &p_line, bool &r_ordered,
                                int &r_level, bool &r_checked, String &r_text);
    static bool   _is_table_row(const String &p_line);
    static String _escape_bbcode(const String &p_text);
};
```

### 3.1 Tamaños de heading proporcionales

```cpp
int MDParser::_heading_size(int p_level, int p_base_fs) {
    // Escala relativa similar a navegadores
    const float scales[] = { 2.0f, 1.75f, 1.5f, 1.25f, 1.1f, 0.875f };
    return (int)(p_base_fs * scales[CLAMP(p_level - 1, 0, 5)]);
}
```

### 3.2 Parseo de inline (negrita, cursiva, código, links)

```cpp
String MDParser::_parse_emphasis(const String &p_text) {
    // Orden de precedencia: *** > ** > * > __ > _
    // Implementar como autómata de estados para manejar anidado correcto.
    // Ejemplo de transformaciones:
    //   ***t***  →  [b][i]t[/i][/b]
    //   **t**    →  [b]t[/b]
    //   *t*      →  [i]t[/i]
    //   ~~t~~    →  [s]t[/s]
    //   `t`      →  [code]t[/code]
    //   __t__    →  [u]t[/u]   (GFM)
    //   ==t==    →  [bgcolor=#FFD700]t[/bgcolor]  (extensión highlight)
    // ...
}
```

### 3.3 Tabla GFM

```cpp
String MDParser::_parse_table(const Vector<String> &p_lines,
                               int p_start, int &r_end) {
    // Línea 0: headers  | col1 | col2 |
    // Línea 1: alineación  | :--- | ---: |  (determina [p align=...] por celda)
    // Línea 2+: filas de datos
    //
    // Salida:
    // [table=N]
    // [cell][b]header[/b][/cell]...
    // [cell]data[/cell]...
    // [/table]
}
```

### 3.4 Notas al pie

```cpp
// Estrategia: dos pasadas
// Pasada 1: recopilar definiciones [^id]: texto
// Pasada 2: sustituir referencias [^id] por superíndice numerado
//           con [url=#fn_id] para scroll interno + hint con texto completo
//
// Al final del documento añadir sección de notas:
// [hr width=50%]
// [p][url=#fn_1][1][/url] texto definición[/p]
```

---

## 4. Encabezado: `md_text_input.h`

```cpp
#pragma once
#include "scene/gui/rich_text_label.h"
#include "scene/main/timer.h"
#include "md_parser.h"

class HBoxContainer;
class Button;
class PopupMenu;

class MDTextInput : public RichTextLabel {
    GDCLASS(MDTextInput, RichTextLabel);

public:
    // ── Enums ──────────────────────────────────────────────────────
    enum BlockFormat {
        BLOCK_PARAGRAPH,
        BLOCK_H1, BLOCK_H2, BLOCK_H3,
        BLOCK_H4, BLOCK_H5, BLOCK_H6,
        BLOCK_CODE,
        BLOCK_BLOCKQUOTE,
        BLOCK_UL, BLOCK_OL,
        BLOCK_HR,
    };

    enum InlineFormat {
        INLINE_BOLD,
        INLINE_ITALIC,
        INLINE_BOLD_ITALIC,
        INLINE_UNDERLINE,
        INLINE_STRIKETHROUGH,
        INLINE_CODE,
        INLINE_HIGHLIGHT,
        INLINE_LINK,
        INLINE_IMAGE,
        INLINE_FOOTNOTE,
    };

    // ── Señales ────────────────────────────────────────────────────
    // "text_changed"          (new_md_source: String)
    // "caret_changed"         (pos: int)
    // "link_clicked"          (url: String)
    // "checkbox_toggled"      (line: int, checked: bool)

protected:
    static void _bind_methods();
    void _notification(int p_what);
    virtual void gui_input(const Ref<InputEvent> &p_event) override;
    virtual void _update_theme_item_cache() override;

private:
    // ── Fuente de verdad ───────────────────────────────────────────
    String _md_source;
    String _bbcode_cache;
    bool   _dirty          = false;
    bool   _editable       = true;

    // ── Caret ──────────────────────────────────────────────────────
    int    _caret_pos      = 0;   // índice en _md_source
    Timer *_caret_timer    = nullptr;
    bool   _caret_visible  = true;
    float  _caret_blink_speed = 0.65f;

    // ── Parser ─────────────────────────────────────────────────────
    MDParser _parser;
    int _base_font_size    = 16;

    // ── Toolbar ────────────────────────────────────────────────────
    HBoxContainer *_toolbar        = nullptr;
    bool           _show_toolbar   = true;
    bool           _toolbar_built  = false;

    // ── Undo/Redo ──────────────────────────────────────────────────
    struct Snapshot { String md; int caret; };
    Vector<Snapshot> _undo_stack;
    int              _undo_idx = -1;
    static const int UNDO_MAX  = 200;

    // ── Internos ───────────────────────────────────────────────────
    void _commit(bool p_push_undo = true);
    void _insert_at_caret(const String &p_text);
    void _delete_at_caret(bool p_backspace);
    void _delete_selection_md();

    // Envuelve la selección en MD (no en BBCode)
    void _wrap_selection_md(const String &p_open, const String &p_close);

    // Establece / alterna bloque en la línea actual del caret
    void _set_block_format(BlockFormat p_fmt);

    // Convierte un rango MD a posición BBCode (para dibujar caret)
    Vector2 _caret_to_screen_pos() const;

    // Gestión de checkboxes GFM
    void _toggle_checkbox_at_line(int p_md_line);

    // Helpers
    int  _get_md_line_number() const;
    void _push_undo();
    void _build_toolbar();
    void _update_toolbar_state();

    // Callbacks toolbar
    void _on_format_block(BlockFormat p_fmt);
    void _on_format_inline(InlineFormat p_fmt);
    void _on_insert_link();
    void _on_insert_image();
    void _on_insert_table();
    void _on_undo();
    void _on_redo();
    void _on_caret_blink();

public:
    // ── API ────────────────────────────────────────────────────────
    void   set_markdown(const String &p_md);
    String get_markdown() const { return _md_source; }

    void   set_editable(bool p_editable);
    bool   is_editable() const { return _editable; }

    void set_show_toolbar(bool p_show);
    bool get_show_toolbar() const { return _show_toolbar; }

    void set_base_font_size(int p_size);
    int  get_base_font_size() const { return _base_font_size; }

    // Aplica formato inline a la selección actual
    void apply_inline_format(InlineFormat p_fmt,
                             const String &p_param = "");
    // Cambia el bloque de la línea actual
    void apply_block_format(BlockFormat p_fmt);

    void undo();
    void redo();

    MDTextInput();
    ~MDTextInput() = default;
};

VARIANT_ENUM_CAST(MDTextInput::BlockFormat);
VARIANT_ENUM_CAST(MDTextInput::InlineFormat);
```

---

## 5. Implementación relevante

### 5.1 `set_markdown` + `_commit`

```cpp
void MDTextInput::set_markdown(const String &p_md) {
    _md_source = p_md;
    _dirty = true;
    _commit(false);
}

void MDTextInput::_commit(bool p_push_undo) {
    if (p_push_undo) _push_undo();
    _bbcode_cache = _parser.to_bbcode(_md_source, _base_font_size);
    parse_bbcode(_bbcode_cache);
    _dirty = false;
    emit_signal("text_changed", _md_source);
    _caret_visible = true;
    _caret_timer->start();
    queue_redraw();
}
```

### 5.2 Insertar texto respetando MD

```cpp
void MDTextInput::_insert_at_caret(const String &p_text) {
    _md_source = _md_source.substr(0, _caret_pos)
               + p_text
               + _md_source.substr(_caret_pos);
    _caret_pos += p_text.length();
    _commit();
}
```

> La inserción opera directamente sobre `_md_source` (string MD puro), no sobre
> BBCode. Esto es posible porque el parser convierte el MD completo en cada commit.

### 5.3 Wrap de selección en MD

```cpp
void MDTextInput::_wrap_selection_md(const String &p_open, const String &p_close) {
    // get_selection_from/to devuelve posición en texto PLANO renderizado.
    // Necesitamos mapearlo a posición en _md_source.
    // Estrategia: construir mapa plain_pos → md_pos en cada _commit(),
    // almacenado como PackedInt32Array _plain_to_md[].
    //
    // Alternativa simple (sin mapa): buscar en _md_source el texto seleccionado
    // con String::find() desde la estimación de posición.

    int from = _plain_to_md_pos(get_selection_from());
    int to   = _plain_to_md_pos(get_selection_to());

    _md_source = _md_source.substr(0, from)
               + p_open
               + _md_source.substr(from, to - from)
               + p_close
               + _md_source.substr(to);

    _caret_pos = to + p_open.length();
    _commit();
    deselect();
}
```

### 5.4 Formato de bloque (headings, listas, blockquote)

```cpp
void MDTextInput::_set_block_format(BlockFormat p_fmt) {
    // 1. Localizar inicio y fin de la línea MD actual
    int line_start = _md_source.rfind("\n", _caret_pos - 1) + 1;
    int line_end   = _md_source.find("\n", _caret_pos);
    if (line_end == -1) line_end = _md_source.length();

    String line = _md_source.substr(line_start, line_end - line_start);

    // 2. Quitar prefijo de bloque existente
    // Regex-like: eliminar `^(#{1,6}\s|>\s|-\s|\d+\.\s)`
    line = _strip_block_prefix(line);

    // 3. Añadir nuevo prefijo según formato
    String prefix = "";
    switch (p_fmt) {
        case BLOCK_H1: prefix = "# ";    break;
        case BLOCK_H2: prefix = "## ";   break;
        case BLOCK_H3: prefix = "### ";  break;
        case BLOCK_H4: prefix = "#### "; break;
        case BLOCK_H5: prefix = "##### ";break;
        case BLOCK_H6: prefix = "###### ";break;
        case BLOCK_BLOCKQUOTE: prefix = "> "; break;
        case BLOCK_UL: prefix = "- ";    break;
        case BLOCK_OL: prefix = "1. ";   break;
        case BLOCK_CODE:
            // Envolver en bloque de código con triple backtick
            line = "```\n" + line + "\n```";
            break;
        case BLOCK_HR:
            line = "---";
            break;
        default: break;  // BLOCK_PARAGRAPH: sin prefijo
    }

    String new_line = prefix + line;
    _md_source = _md_source.substr(0, line_start)
               + new_line
               + _md_source.substr(line_end);

    // Ajustar caret al final de la nueva línea
    _caret_pos = line_start + new_line.length();
    _commit();
}
```

### 5.5 Toolbar completa

```cpp
void MDTextInput::_build_toolbar() {
    _toolbar = memnew(HBoxContainer);
    add_child(_toolbar);

    // Bloque: selector de tipo de párrafo
    OptionButton *block_sel = memnew(OptionButton);
    block_sel->add_item("Párrafo",  BLOCK_PARAGRAPH);
    block_sel->add_item("H1",       BLOCK_H1);
    block_sel->add_item("H2",       BLOCK_H2);
    block_sel->add_item("H3",       BLOCK_H3);
    block_sel->add_item("H4",       BLOCK_H4);
    block_sel->add_item("H5",       BLOCK_H5);
    block_sel->add_item("H6",       BLOCK_H6);
    block_sel->add_item("Código",   BLOCK_CODE);
    block_sel->add_item("Cita",     BLOCK_BLOCKQUOTE);
    block_sel->connect("item_selected",
        callable_mp(this, &MDTextInput::_on_format_block));
    _toolbar->add_child(block_sel);

    // Separador
    _toolbar->add_child(memnew(VSeparator));

    // Inline: botones de formato
    struct BtnDef { String label; InlineFormat fmt; String shortcut; };
    const BtnDef btns[] = {
        { "B",   INLINE_BOLD,          "Ctrl+B" },
        { "I",   INLINE_ITALIC,        "Ctrl+I" },
        { "U",   INLINE_UNDERLINE,     "Ctrl+U" },
        { "~~",  INLINE_STRIKETHROUGH, "Ctrl+Shift+S" },
        { "`",   INLINE_CODE,          "Ctrl+`" },
        { "==",  INLINE_HIGHLIGHT,     "" },
    };
    for (const BtnDef &d : btns) {
        Button *b = memnew(Button);
        b->set_text(d.label);
        b->set_tooltip_text(d.shortcut);
        b->connect("pressed",
            callable_mp(this, &MDTextInput::_on_format_inline)
            .bind((int)d.fmt));
        _toolbar->add_child(b);
    }

    _toolbar->add_child(memnew(VSeparator));

    // Listas
    Button *ul_btn = memnew(Button);
    ul_btn->set_text("• Lista");
    ul_btn->connect("pressed",
        callable_mp(this, &MDTextInput::_on_format_block).bind((int)BLOCK_UL));
    _toolbar->add_child(ul_btn);

    Button *ol_btn = memnew(Button);
    ol_btn->set_text("1. Lista");
    ol_btn->connect("pressed",
        callable_mp(this, &MDTextInput::_on_format_block).bind((int)BLOCK_OL));
    _toolbar->add_child(ol_btn);

    _toolbar->add_child(memnew(VSeparator));

    // Inserciones
    Button *link_btn = memnew(Button);
    link_btn->set_text("🔗");
    link_btn->connect("pressed", callable_mp(this, &MDTextInput::_on_insert_link));
    _toolbar->add_child(link_btn);

    Button *img_btn = memnew(Button);
    img_btn->set_text("🖼");
    img_btn->connect("pressed", callable_mp(this, &MDTextInput::_on_insert_image));
    _toolbar->add_child(img_btn);

    Button *table_btn = memnew(Button);
    table_btn->set_text("⊞");
    table_btn->connect("pressed", callable_mp(this, &MDTextInput::_on_insert_table));
    _toolbar->add_child(table_btn);

    Button *hr_btn = memnew(Button);
    hr_btn->set_text("─");
    hr_btn->connect("pressed",
        callable_mp(this, &MDTextInput::_on_format_block).bind((int)BLOCK_HR));
    _toolbar->add_child(hr_btn);

    _toolbar->add_child(memnew(VSeparator));

    // Undo / Redo
    Button *undo_btn = memnew(Button);
    undo_btn->set_text("↩");
    undo_btn->connect("pressed", callable_mp(this, &MDTextInput::_on_undo));
    _toolbar->add_child(undo_btn);

    Button *redo_btn = memnew(Button);
    redo_btn->set_text("↪");
    redo_btn->connect("pressed", callable_mp(this, &MDTextInput::_on_redo));
    _toolbar->add_child(redo_btn);

    _toolbar_built = true;
}
```

### 5.6 Callbacks de formato inline → MD markers

```cpp
void MDTextInput::_on_format_inline(int p_fmt) {
    switch ((InlineFormat)p_fmt) {
        case INLINE_BOLD:          _wrap_selection_md("**", "**"); break;
        case INLINE_ITALIC:        _wrap_selection_md("*", "*");   break;
        case INLINE_BOLD_ITALIC:   _wrap_selection_md("***", "***"); break;
        case INLINE_UNDERLINE:     _wrap_selection_md("<u>", "</u>"); break;
        case INLINE_STRIKETHROUGH: _wrap_selection_md("~~", "~~"); break;
        case INLINE_CODE:          _wrap_selection_md("`", "`");   break;
        case INLINE_HIGHLIGHT:     _wrap_selection_md("==", "=="); break;
        case INLINE_LINK:          _on_insert_link();             break;
        case INLINE_IMAGE:         _on_insert_image();            break;
        default: break;
    }
}
```

### 5.7 Inserción de estructuras complejas

```cpp
void MDTextInput::_on_insert_link() {
    String sel = get_selected_text();
    String snippet = sel.is_empty()
        ? "[texto del link](https://url)"
        : "[" + sel + "](https://url)";
    _delete_selection_md();
    _insert_at_caret(snippet);
}

void MDTextInput::_on_insert_image() {
    _insert_at_caret("![texto alternativo](ruta/imagen.png)");
}

void MDTextInput::_on_insert_table() {
    // Inserta tabla GFM 3×2 de ejemplo
    const String tbl =
        "\n| Columna 1 | Columna 2 | Columna 3 |\n"
        "| :-------- | :-------: | --------: |\n"
        "| dato      | dato      | dato      |\n";
    _insert_at_caret(tbl);
}
```

### 5.8 Atajos de teclado en `gui_input`

```cpp
// Dentro de gui_input(), bloque Ctrl+Key:
if (k->is_ctrl_pressed()) {
    switch (k->get_keycode()) {
        case Key::B: _on_format_inline(INLINE_BOLD);     break;
        case Key::I: _on_format_inline(INLINE_ITALIC);   break;
        case Key::U: _on_format_inline(INLINE_UNDERLINE);break;
        case Key::K: _on_insert_link();                  break;
        case Key::Z: k->is_shift_pressed() ? redo() : undo(); break;
        case Key::Y: redo();                             break;
        case Key::A: select_all();                       break;
        case Key::C: /* heredado RTL */                  break;
        case Key::V: _insert_at_caret(
                         DisplayServer::get_singleton()->clipboard_get()); break;
        // Ctrl+1..6: headings
        case Key::KEY_1: _set_block_format(BLOCK_H1);   break;
        case Key::KEY_2: _set_block_format(BLOCK_H2);   break;
        case Key::KEY_3: _set_block_format(BLOCK_H3);   break;
        // Tab en lista: aumenta/disminuye indentación
        case Key::TAB:
            if (k->is_shift_pressed()) _decrease_list_indent();
            else                       _increase_list_indent();
            break;
        default: break;
    }
}
// Enter inteligente: continúa lista, sale de bloque código, etc.
if (k->get_keycode() == Key::ENTER) {
    _handle_smart_enter();
}
```

### 5.9 Enter inteligente

```cpp
void MDTextInput::_handle_smart_enter() {
    String line = _get_current_md_line();

    // Lista: si la línea tiene item de lista, continuar
    if (line.begins_with("- ") || line.begins_with("* ")) {
        if (line.strip_edges() == "-" || line.strip_edges() == "*") {
            // Lista vacía → salir de la lista
            _replace_current_md_line("");
        } else {
            _insert_at_caret("\n- ");
        }
        return;
    }
    // Lista ordenada
    if (RegEx().search("^\\d+\\. ", line).is_valid()) {
        // Incrementar número o continuar
        _insert_at_caret("\n" + _next_ol_prefix(line));
        return;
    }
    // Blockquote: continuar
    if (line.begins_with("> ")) {
        _insert_at_caret("\n> ");
        return;
    }
    // Bloque código: insertar tab
    // (detectado por contexto en _bbcode_cache)

    // Default: párrafo nuevo (doble newline para MD)
    _insert_at_caret("\n");
}
```

---

## 6. Mapa de posiciones plano → MD

Necesario para `_wrap_selection_md()` dado que `get_selection_from/to()`
devuelve posición en texto plano renderizado (sin tags BBCode ni MD markers).

```cpp
// Generado en _commit() después de parsear.
// Longitud = longitud del texto plano renderizado.
// _pos_map[i] = posición en _md_source que corresponde al carácter i del plain text.
PackedInt32Array _pos_map;

void MDTextInput::_build_pos_map() {
    _pos_map.clear();
    // Estrategia: recorrer _md_source en paralelo con get_parsed_text()
    // El texto plano es _md_source sin markers MD (**, *, #, etc.) ni BBCode.
    // Se puede construir durante el parseo MD: el parser emite pares
    // (md_offset, plain_char) al procesar cada carácter de texto real.
}

int MDTextInput::_plain_to_md_pos(int p_plain) const {
    if (p_plain < 0 || p_plain >= _pos_map.size()) return _md_source.length();
    return _pos_map[p_plain];
}
```

---

## 7. Limitaciones y elementos sin soporte nativo RTL

| Elemento | Problema | Solución |
|---|---|---|
| `<sup>` / `<sub>` | RTL no tiene offset vertical | `RichTextEffect` personalizado que desplaza Y del glifo |
| Blockquote anidado | `[indent]` no dibuja barra lateral | `RichTextEffect` + `NOTIFICATION_DRAW` para dibujar línea `\|` a la izquierda |
| Nota al pie scroll | `[url=#fn1]` no hace scroll interno | Conectar señal `meta_clicked` y llamar `scroll_to_paragraph()` |
| Tabla alineación | `[p align=]` dentro de celda | Implementado, requiere pasar alineación por columna al parser |
| Syntax highlight | `[code]` no colorea código | `RichTextEffect` de highlighting o pre-procesado en el parser |
| Imagen tamaño % | `[img width=50%]` | RTL soporta `IMAGE_UNIT_PERCENT` desde Godot 4.3 ✅ |
| HTML `<details>` | Sin equivalente RTL | No implementable sin nodo hijo externo |

---

## 8. Estructura de archivos

```
scene/gui/
├── md_text_input.h
├── md_text_input.cpp
├── md_parser.h
├── md_parser.cpp
└── md_text_effects/
    ├── md_effect_superscript.h/.cpp   (sup/sub)
    ├── md_effect_blockquote.h/.cpp    (barra lateral)
    └── md_effect_highlight.h/.cpp     (syntax highlight)
```

Registro en `scene/register_scene_types.cpp`:
```cpp
GDREGISTER_CLASS(MDTextInput);
GDREGISTER_CLASS(MDParser);
```

---

## 9. Roadmap

| Fase | Entregable | Prioridad |
|------|-----------|-----------|
| 1 | `MDParser::to_bbcode()` con inline + headings + HR | Alta |
| 2 | `MDTextInput` skeleton + inserción + backspace + commit | Alta |
| 3 | Toolbar + atajos Ctrl+B/I/U/K | Alta |
| 4 | Listas + Enter inteligente + indentación Tab | Alta |
| 5 | Tablas GFM | Media |
| 6 | `_pos_map` para wrap de selección exacto | Media |
| 7 | Blockquote + notas al pie | Media |
| 8 | `RichTextEffect` para sup/sub y barra blockquote | Baja |
| 9 | Syntax highlighting en bloques de código | Baja |
| 10 | IME (CJK/árabe) | Baja |
| 11 | Exportar MD limpio desde `get_markdown()` | Alta |
