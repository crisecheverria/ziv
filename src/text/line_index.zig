//! Cached byte offsets of each line start, giving O(1) line -> offset lookups
//! when rendering the viewport. Rebuilt on load and patched on each edit (an
//! edit only shifts offsets after the edit point, so we avoid full rebuilds).
const std = @import("std");

pub const LineIndex = struct {
    /// `starts.items[n]` is the byte offset where line `n` begins.
    starts: std.ArrayList(usize) = .empty,

    pub fn deinit(self: *LineIndex, allocator: std.mem.Allocator) void {
        self.starts.deinit(allocator);
    }

    pub fn lineCount(self: *const LineIndex) usize {
        return self.starts.items.len;
    }

    // TODO Phase 1: rebuild(store), patchAfterEdit(off, delta), lineStart(n),
    // and offset -> (line, col) conversion.
};
