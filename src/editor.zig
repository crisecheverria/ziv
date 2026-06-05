//! Top-level orchestrator. Owns the open document(s), the current mode, the
//! window/viewport, registers, and drives the main loop:
//!
//!   poll(input + resize) -> dispatch keys -> mutate state -> render if dirty
const std = @import("std");
const Allocator = std.mem.Allocator;

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
    pub fn run(self: *Editor) !void {
        _ = self;
    }
};
