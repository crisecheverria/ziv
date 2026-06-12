//! Double-buffered cell grid — this is where rendering performance lives.
//!
//!   1. compose the frame into `back`
//!   2. diff `back` against `front` cell-by-cell
//!   3. emit minimal ANSI (cursor moves + changed runs only) into `out`
//!   4. one write() to the tty, then swap front/back
//!
//! `front`, `back`, and `out` are allocated once (and on resize) — never per
//! frame — so steady-state rendering is allocation-free.
const std = @import("std");
const Allocator = std.mem.Allocator;
const Cell = @import("cell.zig").Cell;

pub const Screen = struct {
    front: std.ArrayList(Cell) = .empty,
    back: std.ArrayList(Cell) = .empty,
    /// Preallocated scratch for the escape-sequence bytes of one frame.
    out: std.ArrayList(u8) = .empty,
    cols: usize = 0,
    rows: usize = 0,
    allocator: Allocator,

    pub fn init(allocator: Allocator) Screen {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Screen) void {
        self.front.deinit(self.allocator);
        self.back.deinit(self.allocator);
        self.out.deinit(self.allocator);
    }

    pub fn resize(self: *Screen, cols: usize, rows: usize) !void {
        const n = rows * cols;
        // Resize both buffers.
        try self.front.resize(self.allocator, n);
        try self.back.resize(self.allocator, n);
        @memset(self.front.items, Cell{}); // force a full redraw
        @memset(self.back.items, Cell{});
        self.cols = cols;
        self.rows = rows;
        try self.out.ensureTotalCapacity(self.allocator, n * 16); // rough: 16
        // bytes/cell
        // worst-case
    }

    pub fn clearBack(self: *Screen) void {
        @memset(self.back.items, Cell{});
    }

    pub fn setCell(self: *Screen, row: usize, col: usize, cell: Cell) void {
        if (row >= self.rows or col >= self.cols) return;
        self.back.items[row * self.cols + col] = cell;
    }

    // Diff back vs front, emit minimal ANSI sequences, flush to tty, swap buffers.
    pub fn flush(self: *Screen, io: std.Io, tty: std.Io.File) !void {
        self.out.clearRetainingCapacity();
        try self.out.appendSlice(self.allocator, "\x1b[?25l"); // hide cursor while drawing

        var row: usize = 0;
        while (row < self.rows) : (row += 1) {
            var col: usize = 0;
            while (col < self.cols) : (col += 1) {
                const idx = row * self.cols + col;
                const back = self.back.items[idx];
                const front = self.front.items[idx];
                if (std.meta.eql(back, front)) continue; // unchanged cell — skip

                var tmp: [32]u8 = undefined;
                const move = try std.fmt.bufPrint(&tmp, "\x1b[{d};{d}H", .{ row + 1, col + 1 });
                try self.out.appendSlice(self.allocator, move);
                if (back.style.reverse)
                    try self.out.appendSlice(self.allocator, "\x1b[7m")
                else
                    try self.out.appendSlice(self.allocator, "\x1b[m");
                var utf8: [4]u8 = undefined;
                const n = std.unicode.utf8Encode(back.cp, &utf8) catch 1;
                try self.out.appendSlice(self.allocator, utf8[0..n]);

                self.front.items[idx] = back;
            }
        }
        try self.out.appendSlice(self.allocator, "\x1b[?25h"); // show cursor
        try tty.writeStreamingAll(io, self.out.items);
    }
};
