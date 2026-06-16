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
const Screen = @import("ui/screen.zig").Screen;
const Renderer = @import("ui/render.zig").Renderer;

pub const Editor = struct {
    allocator: Allocator,
    mode: Mode = .normal,
    document: Document,
    window: Window = .{},
    screen: Screen,
    /// Set whenever visible state changes; gates rendering so we never redraw
    /// an unchanged screen.
    dirty: bool = true,
    running: bool = false,

    pub fn init(allocator: Allocator, path: ?[]const u8) !Editor {
        var document = Document.init(allocator);
        if (path) |p| try document.openFile(p);
        return .{ .allocator = allocator, .document = document, .screen = Screen.init(allocator) };
    }

    pub fn deinit(self: *Editor) void {
        self.document.deinit();
    }

    /// Main loop. TODO Phase 0: enter raw mode + alt screen, read keys, render a
    /// frame, quit on Ctrl-Q.
    pub fn run(self: *Editor, io: std.Io) !void {
        var term = try Terminal.init(io);
        defer term.deinit();

        const sz = try term.size();
        try self.screen.resize(sz.cols, sz.rows -| 1); // Reverse botom row for
        // status
        self.window.width = sz.cols;
        self.window.height = sz.rows -| 1;

        var parser = Parser{};
        var read_buf: [64]u8 = undefined;
        self.running = true;
        self.dirty = true;

        while (self.running) {
            if (self.dirty) {
                Renderer.render(&self.screen, &self.document, self.window);
                try self.screen.flush(io, term.tty);
                self.dirty = false;
            }

            const n = try term.tty.readStreaming(io, &.{read_buf[0..]});
            if (n == 0) continue;
            parser.feed(read_buf[0..n]);
            while (parser.next()) |key| {
                try self.handleKey(key);
            }
        }
    }

    fn handleKey(self: *Editor, key: Key) !void {
        switch (key) {
            .ctrl => |c| if (c == 'q') {
                self.running = false;
                return;
            },
            .char => |ch| switch (ch) {
                'j' => self.scrollDown(1),
                'k' => self.scrollUp(1),
                else => {},
            },
            .down => self.scrollDown(1),
            .up => self.scrollUp(1),
            else => {},
        }
        self.dirty = true;
    }

    fn scrollDown(self: *Editor, n: usize) void {
        const max = self.document.line_index.lineCount() -| self.window.height;
        self.window.top_line = @min(self.window.top_line + n, max);
    }

    fn scrollUp(self: *Editor, n: usize) void {
        self.window.top_line -|= n;
    }
};
