//! A viewport over a document: scroll offset, on-screen dimensions, the cursor,
//! and the sticky "desired column" used so vertical motion remembers the column
//! across short lines. Splits later become multiple Windows over documents.
pub const Window = struct {
    /// Topmost document line shown (vertical scroll).
    top_line: usize = 0,
    /// Leftmost column shown (horizontal scroll).
    left_col: usize = 0,
    width: usize = 0,
    height: usize = 0,
    cursor_line: usize = 0,
    cursor_col: usize = 0,
    /// Column the cursor "wants"; preserved across j/k over shorter lines.
    desired_col: usize = 0,
    /// Keep this many lines visible above/below the cursor (vim's scrolloff).
    scrolloff: usize = 3,
};
