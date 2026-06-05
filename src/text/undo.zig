//! Linear undo/redo of edit records, grouped by insert session (one `u` undoes a
//! whole insert, not one keystroke). Vim's full undo *tree* is a later luxury.
const std = @import("std");

/// A single reversible edit: at `offset`, `deleted` bytes were removed and
/// `inserted` bytes were added. Applying the inverse swaps them.
pub const Edit = struct {
    offset: usize,
    deleted: []const u8,
    inserted: []const u8,
};

pub const History = struct {
    // TODO Phase 6: undo stack + redo stack of grouped Edits.

    pub fn deinit(self: *History) void {
        _ = self;
    }
};
