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

    // TODO Phase 0/1: resize(cols, rows), clearBack(), diffAndFlush(writer).
};
