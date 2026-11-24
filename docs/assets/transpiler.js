// DSLX → Lua transpiler (browser)
// Mimics dslx.parser + dslx.runtime in pure JavaScript.
// Does NOT require LPeg — handles the XML-in-Lua syntax directly.

function luaQuote(str) {
    return '"' + str
        .replace(/\\/g, '\\\\')
        .replace(/"/g, '\\"')
        .replace(/\n/g, '\\n')
        .replace(/\r/g, '\\r')
        .replace(/\0/g, '\\0')
        + '"';
}

function isNameChar(ch) { return /[a-zA-Z0-9_.\-]/.test(ch); }
function isSpace(ch)    { return /[ \t\r\n]/.test(ch); }

// True if `<` at `pos` starts an XML element (not a Lua operator)
function isElementAt(code, pos) {
    if (code[pos] !== '<') return false;
    let i = pos + 1;
    while (i < code.length && isSpace(code[i])) i++;
    return i < code.length && isNameChar(code[i]);
}

// ── raw consumers (keep Lua code intact) ──────────────────────────────────

function consumeLuaString(code, pos) {
    const q = code[pos];
    let r = q; pos++;
    while (pos < code.length) {
        const ch = code[pos];
        r += ch; pos++;
        if (ch === '\\' && pos < code.length) { r += code[pos++]; continue; }
        if (ch === q) break;
    }
    return [r, pos];
}

function consumeLuaLongString(code, pos) {
    let r = '['; pos++;
    let level = 0;
    while (pos < code.length && code[pos] === '=') { level++; r += '='; pos++; }
    if (pos >= code.length || code[pos] !== '[') return [r, pos]; // not long string
    r += '['; pos++;
    const closing = ']' + '='.repeat(level) + ']';
    const idx = code.indexOf(closing, pos);
    if (idx === -1) { r += code.slice(pos); return [r, code.length]; }
    r += code.slice(pos, idx + closing.length);
    return [r, idx + closing.length];
}

function consumeLuaComment(code, pos) {
    let r = '--'; pos += 2;
    if (pos < code.length && code[pos] === '[') {
        let i = pos + 1; let lv = 0;
        while (i < code.length && code[i] === '=') { lv++; i++; }
        if (i < code.length && code[i] === '[') {
            const [ls, np] = consumeLuaLongString(code, pos);
            return [r + ls, np];
        }
    }
    while (pos < code.length && code[pos] !== '\n') r += code[pos++];
    return [r, pos];
}

// Parse content inside {...}, returns [content, posAfterClosingBrace]
function parseBlock(code, pos) {
    let content = ''; let depth = 1;
    while (pos < code.length && depth > 0) {
        const ch = code[pos];
        if      (ch === '{') { depth++; content += ch; pos++; }
        else if (ch === '}') { depth--; if (depth > 0) content += ch; pos++; }
        else if (ch === '"' || ch === "'") {
            const [s, np] = consumeLuaString(code, pos);
            content += s; pos = np;
        } else if (ch === '[' && (code[pos+1] === '[' || code[pos+1] === '=')) {
            const [s, np] = consumeLuaLongString(code, pos);
            content += s; pos = np;
        } else if (ch === '-' && code[pos+1] === '-') {
            const [c, np] = consumeLuaComment(code, pos);
            content += c; pos = np;
        } else { content += ch; pos++; }
    }
    return [content.trim(), pos];
}

// ── props ──────────────────────────────────────────────────────────────────

function parseProps(code, pos) {
    const props = [];
    while (pos < code.length) {
        while (pos < code.length && isSpace(code[pos])) pos++;
        const ch = code[pos];
        if (ch === '>' || (ch === '/' && code[pos+1] === '>')) break;
        if (!isNameChar(ch)) break;

        let name = '';
        while (pos < code.length && isNameChar(code[pos])) name += code[pos++];
        while (pos < code.length && isSpace(code[pos])) pos++;

        if (code[pos] === '=') {
            pos++;
            while (pos < code.length && isSpace(code[pos])) pos++;
            if (code[pos] === '{') {
                pos++;
                const [expr, np] = parseBlock(code, pos);
                props.push({ name, type: 'script', value: expr }); pos = np;
            } else if (code[pos] === '"' || code[pos] === "'") {
                const q = code[pos++];
                let str = '';
                while (pos < code.length && code[pos] !== q) {
                    if (code[pos] === '\\') str += code[pos++];
                    if (pos < code.length) str += code[pos++];
                }
                if (code[pos] === q) pos++;
                props.push({ name, type: 'string', value: str });
            }
        } else {
            props.push({ name, type: 'bool' });
        }
    }
    return [props, pos];
}

// ── children ───────────────────────────────────────────────────────────────

function isWhitespaceOnly(str) { return /\n/.test(str) && /^\s*$/.test(str); }

function parseChildren(code, pos) {
    const children = [];
    let text = '';

    const flushText = () => {
        if (text !== '' && !isWhitespaceOnly(text)) {
            children.push({ type: 'text', value: text });
        }
        text = '';
    };

    while (pos < code.length) {
        const ch = code[pos];

        // closing tag </...>
        if (ch === '<' && code[pos+1] === '/') {
            flushText();
            pos += 2;
            while (pos < code.length && isSpace(code[pos])) pos++;
            while (pos < code.length && isNameChar(code[pos])) pos++;
            while (pos < code.length && isSpace(code[pos])) pos++;
            if (code[pos] === '>') pos++;
            break;
        }

        // nested element
        if (ch === '<' && isElementAt(code, pos)) {
            flushText();
            const [lua, np] = parseElement(code, pos);
            children.push({ type: 'element', value: lua });
            pos = np; continue;
        }

        // expression block {expr}
        if (ch === '{') {
            flushText();
            pos++;
            const [expr, np] = parseBlock(code, pos);
            children.push({ type: 'script', value: expr });
            pos = np; continue;
        }

        text += ch; pos++;
    }
    flushText();
    return [children, pos];
}

// ── serializers ────────────────────────────────────────────────────────────

function serializeProps(props) {
    if (props.length === 0) return '{}';
    return '{' + props.map(p => {
        if (p.type === 'string') return `${p.name}=${luaQuote(p.value)}`;
        if (p.type === 'script') return `${p.name}=${p.value}`;
        return `${p.name}=true`;
    }).join(', ') + '}';
}

function serializeChildren(children) {
    if (children.length === 0) return '{}';
    return '{' + children.map(c =>
        c.type === 'text' ? luaQuote(c.value) : c.value
    ).join(', ') + '}';
}

// ── element parser ─────────────────────────────────────────────────────────

function parseElement(code, pos) {
    pos++; // skip '<'
    while (pos < code.length && isSpace(code[pos])) pos++;

    let name = '';
    while (pos < code.length && isNameChar(code[pos])) name += code[pos++];
    while (pos < code.length && isSpace(code[pos])) pos++;

    const [props, pos2] = parseProps(code, pos);
    pos = pos2;
    while (pos < code.length && isSpace(code[pos])) pos++;

    if (code[pos] === '/' && code[pos+1] === '>') {
        pos += 2;
        return [
            `${name}{name=${luaQuote(name)}, props=${serializeProps(props)}, childrens={}, node_type="element_self_close", self_close=true}`,
            pos
        ];
    }

    if (code[pos] === '>') {
        pos++;
        const [children, pos3] = parseChildren(code, pos);
        return [
            `${name}{name=${luaQuote(name)}, props=${serializeProps(props)}, childrens=${serializeChildren(children)}, node_type="full_element"}`,
            pos3
        ];
    }

    return [`<${name}`, pos]; // fallback: not a valid element
}

// ── main entry ─────────────────────────────────────────────────────────────

function transpile(code) {
    let pos = 0; let result = ''; const len = code.length;

    while (pos < len) {
        const ch = code[pos];

        if (ch === '"' || ch === "'") {
            const [s, np] = consumeLuaString(code, pos);
            result += s; pos = np; continue;
        }
        if (ch === '[' && pos + 1 < len && (code[pos+1] === '[' || code[pos+1] === '=')) {
            const [s, np] = consumeLuaLongString(code, pos);
            result += s; pos = np; continue;
        }
        if (ch === '-' && pos + 1 < len && code[pos+1] === '-') {
            const [c, np] = consumeLuaComment(code, pos);
            result += c; pos = np; continue;
        }
        if (ch === '<' && isElementAt(code, pos)) {
            const [lua, np] = parseElement(code, pos);
            result += lua; pos = np; continue;
        }

        result += ch; pos++;
    }

    return result;
}

window.DSLXTranspiler = { transpile, luaQuote };
