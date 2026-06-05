//! ziv — internal module barrel.
//!
//! Re-exports every module under namespaces that mirror the `src/` directory
//! layout, plus a `refAllDeclsRecursive` test so `zig build test` type-checks the
//! whole tree at once. See the architecture note for the design rationale.
const std = @import("std");

pub const terminal = struct {
    pub const raw = @import("terminal/raw.zig");
    pub const input = @import("terminal/input.zig");
    pub const key = @import("terminal/key.zig");
};

pub const text = struct {
    pub const store = @import("text/store.zig");
    pub const gap_buffer = @import("text/gap_buffer.zig");
    pub const line_index = @import("text/line_index.zig");
    pub const document = @import("text/document.zig");
    pub const undo = @import("text/undo.zig");
};

pub const edit = struct {
    pub const mode = @import("edit/mode.zig");
    pub const command = @import("edit/command.zig");
    pub const motion = @import("edit/motion.zig");
    pub const operator = @import("edit/operator.zig");
    pub const textobject = @import("edit/textobject.zig");
    pub const register = @import("edit/register.zig");
    pub const ex = @import("edit/ex.zig");
};

pub const ui = struct {
    pub const cell = @import("ui/cell.zig");
    pub const screen = @import("ui/screen.zig");
    pub const window = @import("ui/window.zig");
    pub const render = @import("ui/render.zig");
    pub const statusline = @import("ui/statusline.zig");
};

pub const util = struct {
    pub const unicode = @import("util/unicode.zig");
};

/// Top-level orchestrator (documents, mode, windows, registers, main loop).
pub const Editor = @import("editor.zig").Editor;

test {
    // Force semantic analysis of every module so `zig build test` type-checks
    // the whole tree (0.16 has no recursive refAllDecls).
    inline for (.{
        terminal.raw,    terminal.input,     terminal.key,
        text.store,      text.gap_buffer,    text.line_index, text.document, text.undo,
        edit.mode,       edit.command,       edit.motion,     edit.operator,
        edit.textobject, edit.register,      edit.ex,
        ui.cell,         ui.screen,          ui.window,       ui.render,     ui.statusline,
        util.unicode,    @import("editor.zig"),
    }) |mod| std.testing.refAllDecls(mod);
}
