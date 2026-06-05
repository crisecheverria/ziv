//! An open file: text storage (via the swappable `TextStore`), filename, dirty
//! flag, cached line index, and undo history. All buffer mutations go through
//! here so the line index and dirty flag stay consistent.
const std = @import("std");
const Allocator = std.mem.Allocator;
const GapBuffer = @import("gap_buffer.zig").GapBuffer;
const LineIndex = @import("line_index.zig").LineIndex;
const History = @import("undo.zig").History;

pub const Document = struct {
    buffer: GapBuffer,
    line_index: LineIndex = .{},
    history: History = .{},
    path: ?[]const u8 = null,
    dirty: bool = false,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Document {
        return .{ .buffer = GapBuffer.init(allocator), .allocator = allocator };
    }

    pub fn deinit(self: *Document) void {
        self.line_index.deinit(self.allocator);
        self.buffer.deinit();
    }

    // TODO Phase 1: openFile(path) -> read into buffer, build line index.
    // TODO Phase 3: insert/delete that update line_index, history, and dirty.
};
