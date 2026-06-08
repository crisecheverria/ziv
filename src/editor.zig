//! Top-level orchestrator. Owns the open document(s), the current mode, the
//! window/viewport, registers, and drives the main loop:
//!
//!   poll(input + resize) -> dispatch keys -> mutate state -> render if dirty
const std = @import("std");
const Allocator = std.mem.Allocator;
const Terminal = @import("terminal/raw.zig").Terminal;
const Parser = @import("terminal/input.zig").Parser;
const Key = @import("terminal/key.zig").Key;
const Mode = @import("edit/mode.zig").Mode;
const Document = @import("text/document.zig").Document;
const Window = @import("ui/window.zig").Window;

pub const Editor = struct {
    allocator: Allocator,
    mode: Mode = .normal,
    document: Document,
    window: Window = .{},
    /// Set whenever visible state changes; gates rendering so we never redraw
    /// an unchanged screen.
    dirty: bool = true,
    running: bool = false,

    pub fn init(allocator: Allocator, path: ?[]const u8) !Editor {
        var document = Document.init(allocator);
        if (path) |p| document.path = p; // TODO Phase 1: actually load the file
        return .{ .allocator = allocator, .document = document };
    }

    pub fn deinit(self: *Editor) void {
        self.document.deinit();
    }

    /// Main loop. TODO Phase 0: enter raw mode + alt screen, read keys, render a
    /// frame, quit on Ctrl-Q.
    pub fn run(self: *Editor, io: std.Io) !void {
        var term = try Terminal.init(io);
        defer term.deinit();

        var parser = Parser{};
        var out: std.ArrayList(u8) = .empty;
        defer out.deinit(self.allocator);

        var read_buf: [64]u8 = undefined;

        self.running = true;
        self.dirty = true;

        while (self.running) {
            if (self.dirty) {
                const sz = try term.size();
                try self.drawWelcome(&out, self.allocator, sz.rows, sz.cols);
                try term.tty.writeStreamingAll(io, out.items);
                self.dirty = false;
            }

            const n = try term.tty.readStreaming(io, &.{read_buf[0..]});
            if (n == 0) continue;

            parser.feed(read_buf[0..n]);
            while (parser.next()) |key| {
                switch (key) {
                    .ctrl => |c| if (c == 'q') {
                        self.running = false;
                        break;
                    },
                    else => {
                        self.dirty = true;
                    },
                }
            }
        }
    }

    fn drawWelcome(self: *Editor, buf: *std.ArrayList(u8), gpa: Allocator, rows: usize, cols: usize) !void {
        _ = self;
        buf.clearRetainingCapacity();

        try buf.appendSlice(gpa, "\x1b[?25l\x1b[2J\x1b[H"); // hide cursor, clear, home

        const msg = "ziv -- press Ctrl-Q to quit";
        const row = rows / 2;
        const col = (cols -| msg.len) / 2;

        // Fill each row with ~ (vim-style)
        var r: usize = 0;
        while (r < rows) : (r += 1) {
            try buf.print(gpa, "\x1b[{d};1H", .{r + 1});
            if (r == row) {
                try buf.print(gpa, "\x1b[{d}G{s}", .{ col + 1, msg });
            } else if (r == 0) {
                // skip — top line is content area
            } else {
                try buf.appendSlice(gpa, "~");
            }
        }
        try buf.appendSlice(gpa, "\x1b[?25h"); // show cursor
    }
};
