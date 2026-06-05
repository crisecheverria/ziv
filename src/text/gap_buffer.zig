//! Gap buffer: one contiguous array with a movable gap.
//!
//!   data:  [ text before ][ gap (free) ][ text after ]
//!          0          gap_start      gap_end       data.len
//!
//! - logical length = data.len - (gap_end - gap_start)
//! - insert(off): move the gap to `off`, write into it, shrink the gap
//! - delete(range): move the gap to the range, grow the gap over the deleted bytes
//! - moving the gap is a single @memmove; this is what makes local edits cheap
//!   and cache-friendly.
const std = @import("std");
const Allocator = std.mem.Allocator;
const TextStore = @import("store.zig").TextStore;

/// A shared, immovable empty backing array so a freshly-init'd buffer holds a
/// valid (zero-length) slice without allocating.
var empty_backing: [0]u8 = .{};

pub const GapBuffer = struct {
    data: []u8,
    gap_start: usize,
    gap_end: usize,
    allocator: Allocator,

    pub fn init(allocator: Allocator) GapBuffer {
        return .{
            .data = &empty_backing,
            .gap_start = 0,
            .gap_end = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *GapBuffer) void {
        if (self.data.len != 0) self.allocator.free(self.data);
    }

    /// Logical text length, excluding the gap.
    pub fn len(self: *const GapBuffer) usize {
        return self.data.len - (self.gap_end - self.gap_start);
    }

    // TODO Phase 1+: moveGap(off), grow(min_gap), insert, delete, byteAt.

    /// Expose this buffer as the generic, swappable text store.
    pub fn textStore(self: *GapBuffer) TextStore {
        return .{ .ptr = self, .vtable = &vtable };
    }

    const vtable: TextStore.VTable = .{
        .len = vtLen,
        .byteAt = vtByteAt,
        .insert = vtInsert,
        .delete = vtDelete,
    };

    fn vtLen(ptr: *anyopaque) usize {
        const self: *GapBuffer = @ptrCast(@alignCast(ptr));
        return self.len();
    }
    fn vtByteAt(ptr: *anyopaque, off: usize) u8 {
        _ = ptr;
        _ = off;
        return 0; // TODO
    }
    fn vtInsert(ptr: *anyopaque, off: usize, bytes: []const u8) anyerror!void {
        _ = ptr;
        _ = off;
        _ = bytes;
        // TODO
    }
    fn vtDelete(ptr: *anyopaque, start: usize, end: usize) void {
        _ = ptr;
        _ = start;
        _ = end;
        // TODO
    }
};
