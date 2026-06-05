//! UTF-8 helpers and terminal display width (wcwidth-style). Wide CJK glyphs
//! occupy two cells and combining marks zero — the renderer needs this to place
//! the cursor and lay out cells correctly. Widths get cached per codepoint.
const std = @import("std");

/// Columns a codepoint occupies on screen. TODO: 0 for combining marks, 2 for
/// wide ranges; 1 otherwise.
pub fn displayWidth(cp: u21) u8 {
    _ = cp;
    return 1;
}
