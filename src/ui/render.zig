//! Composes a frame: walks the document's visible lines (via the line index),
//! decodes UTF-8, writes cells into the screen's back buffer, then overlays the
//! status line and command line. Knows nothing about the tty — it only fills
//! cells; `Screen` handles the diff and flush.
pub const Renderer = struct {
    // TODO Phase 1: render(editor, *Screen) — viewport text first.
    // TODO Phase 7: line numbers, gutter, scrolloff-aware scrolling.
};
