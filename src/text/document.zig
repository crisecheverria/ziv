//! An open file: text storage (via the swappable `TextStore`), filename, dirty
//! flag, cached line index, and undo history. All buffer mutations go through
//! here so the line index and dirty flag stay consistent.
const std = @import("std");
const Allocator = std.mem.Allocator;
const GapBuffer = @import("gap_buffer.zig").GapBuffer;
const LineIndex = @import("line_index.zig").LineIndex;
const History = @import("undo.zig").History;
const TextStore = @import("store.zig").TextStore;

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

    pub fn openFile(self: *Document, path: []const u8) !void {
        const io = std.Io.Threaded.global_single_threaded.io();
        const file = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer file.close(io);

        var buf: [4096]u8 = undefined;
        var reader = file.reader(io, &buf);
        const contents = try reader.interface.allocRemaining(self.allocator, .limited(128 * 1024 * 1024));
        defer self.allocator.free(contents);

        try self.buffer.loadBytes(contents);
        self.path = path;
        self.dirty = false;
        try self.line_index.rebuild(self.allocator, self.store());
    }

    pub fn store(self: *Document) TextStore {
        return self.buffer.textStore();
    }
    // TODO Phase 3: insert/delete that update line_index, history, and dirty.
};
