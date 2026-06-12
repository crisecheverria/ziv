//! Cached byte offsets of each line start, giving O(1) line -> offset lookups
//! when rendering the viewport. Rebuilt on load and patched on each edit (an
//! edit only shifts offsets after the edit point, so we avoid full rebuilds).
const std = @import("std");
const TextStore = @import("store.zig").TextStore;

pub const LineIndex = struct {
    /// `starts.items[n]` is the byte offset where line `n` begins.
    starts: std.ArrayList(usize) = .empty,

    pub fn deinit(self: *LineIndex, allocator: std.mem.Allocator) void {
        self.starts.deinit(allocator);
    }

    pub fn lineCount(self: *const LineIndex) usize {
        return self.starts.items.len;
    }

    pub fn rebuild(self: *LineIndex, allocator: std.mem.Allocator, store: TextStore) !void {
        self.starts.clearRetainingCapacity();
        try self.starts.append(allocator, 0); // line 0 starts at offset 0

        const total = store.len();
        var off: usize = 0;
        while (off < total) : (off += 1) {
            if (store.byteAt(off) == '\n')
                try self.starts.append(allocator, off + 1);
        }
    }

    pub fn lineStart(self: *const LineIndex, line: usize) usize {
        return self.starts.items[line];
    }

    // End of line (exclusive, not including the newline character)
    pub fn lineEnd(self: *const LineIndex, line: usize, store: TextStore) usize {
        const next = if (line + 1 < self.starts.items.len)
            self.starts.items[line + 1]
        else
            store.len();
        // Exclude the trailing newline if present.
        if (next > 0 and next <= store.len() and store.byteAt(next - 1) == '\n')
            return next - 1;
        return next;
    }

    // Convert a byte offset to (line, col). Used for cursor positioning.
    pub fn offsetToLineCol(self: *const LineIndex, off: usize) struct { line: usize, col: usize } {
        const items = self.starts.items;
        // Binary search for the line whose start <= off.
        var lo: usize = 0;
        var hi: usize = items.len;
        while (lo + 1 < hi) {
            const mid = lo + (hi - lo) / 2;
            if (items[mid] <= off) lo = mid else hi = mid;
        }
        return .{ .line = lo, .col = off - items[lo] };
    }
};
