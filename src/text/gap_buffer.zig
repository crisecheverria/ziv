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

    const MIN_GAP: usize = 256;

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

    pub fn byteAt(self: *const GapBuffer, off: usize) u8 {
        std.debug.assert(off < self.len());
        return self.data[self.toPhysical(off)];
    }

    // Move the gap to logical offset 'off' so insertion/deletion is cheap
    // there
    fn moveGap(self: *GapBuffer, off: usize) void {
        if (off == self.gap_start) return;
        const gap_len = self.gap_end - self.gap_start;

        if (off < self.gap_start) {
            const move = self.gap_start - off;
            // Shift text right into the gap's right side.
            std.mem.copyBackwards(u8, self.data[self.gap_end - move .. self.gap_end], self.data[off..self.gap_start]);
        } else {
            const move = off - self.gap_start;
            // Shift text left over the gap.
            @memcpy(self.data[self.gap_start .. self.gap_start + move], self.data[self.gap_end .. self.gap_end + move]);
        }
        self.gap_start = off;
        self.gap_end = off + gap_len;
    }

    fn ensureGap(self: *GapBuffer, need: usize) !void {
        const gap_len = self.gap_end - self.gap_start;
        if (gap_len >= need) return;

        const new_gap = @max(need, MIN_GAP);
        const new_len = self.data.len + new_gap - gap_len;
        const new_data = try self.allocator.alloc(u8, new_len);

        @memcpy(new_data[0..self.gap_start], self.data[0..self.gap_start]);
        const new_gap_end = self.gap_start + new_gap;
        @memcpy(new_data[new_gap_end..], self.data[self.gap_end..]);

        if (self.data.len != 0) self.allocator.free(self.data);
        self.data = new_data;
        self.gap_end = new_gap_end;
    }

    pub fn insert(self: *GapBuffer, off: usize, bytes: []const u8) !void {
        try self.ensureGap(bytes.len);
        self.moveGap(off);
        @memcpy(self.data[self.gap_start .. self.gap_start + bytes.len], bytes);
        self.gap_start += bytes.len;
    }

    pub fn delete(self: *GapBuffer, start: usize, end: usize) void {
        self.moveGap(start);
        self.gap_end += end - start;
    }

    pub fn loadBytes(self: *GapBuffer, bytes: []const u8) !void {
        if (self.data.len != 0) self.allocator.free(self.data);
        const cap = bytes.len + MIN_GAP;
        self.data = try self.allocator.alloc(u8, cap);
        @memcpy(self.data[0..bytes.len], bytes);
        self.gap_start = bytes.len;
        self.gap_end = cap;
    }

    fn toPhysical(self: *const GapBuffer, off: usize) usize {
        return if (off < self.gap_start) off else off + (self.gap_end - self.gap_start);
    }

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
        const self: *GapBuffer = @ptrCast(@alignCast(ptr));
        return self.byteAt(off);
    }
    fn vtInsert(ptr: *anyopaque, off: usize, bytes: []const u8) anyerror!void {
        const self: *GapBuffer = @ptrCast(@alignCast(ptr));
        return self.insert(off, bytes);
    }
    fn vtDelete(ptr: *anyopaque, start: usize, end: usize) void {
        const self: *GapBuffer = @ptrCast(@alignCast(ptr));
        self.delete(start, end);
    }
};
