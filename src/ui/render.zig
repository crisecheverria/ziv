//! Composes a frame: walks the document's visible lines (via the line index),
//! decodes UTF-8, writes cells into the screen's back buffer, then overlays the
//! status line and command line. Knows nothing about the tty — it only fills
//! cells; `Screen` handles the diff and flush.
const std = @import("std");
const Screen = @import("screen.zig").Screen;
const Cell = @import("cell.zig").Cell;
const Document = @import("../text/document.zig").Document;
const Window = @import("window.zig").Window;

pub const Renderer = struct {
    pub fn render(
        screen: *Screen,
        doc: *Document,
        win: Window,
    ) void {
        screen.clearBack();

        const store = doc.store();
        const li = &doc.line_index;

        var screen_row: usize = 0;
        while (screen_row < win.height) : (screen_row += 1) {
            const doc_row = win.top_line + screen_row;

            if (doc_row >= li.lineCount()) {
                // Past end of file - show tilde
                screen.setCell(screen_row, 0, Cell{ .cp = '~' });
                continue;
            }

            const ls = li.lineStart(doc_row);
            const le = li.lineEnd(doc_row, store);

            var col: usize = 0;
            var off: usize = ls + win.left_col;
            while (off < le and col < win.width) : ({
                off += 1;
                col += 1;
            }) {
                const b = store.byteAt(off);
                // Simple ASCII rendering for Phase 1 - unicode in Phase 7
                screen.setCell(screen_row, col, Cell{ .cp = b });
            }
        }
    }
};
