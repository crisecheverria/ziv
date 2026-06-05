//! Owns the tty: enters raw mode (termios) and the alternate screen, queries the
//! window size, and restores everything on deinit. SIGWINCH handling (resize)
//! lands here too.
const std = @import("std");

pub const Terminal = struct {
    // TODO: original termios (restored on deinit), tty fd, current dimensions.

    /// Enter raw mode + alternate screen.
    /// TODO Phase 0: tcgetattr -> save, clear ICANON/ECHO/ISIG/IXON etc.,
    /// tcsetattr; write the alt-screen enter sequence (\x1b[?1049h).
    pub fn init() !Terminal {
        return .{};
    }

    /// Leave alternate screen and restore the saved termios. Must run on every
    /// exit path (including panics) so the user's shell isn't left in raw mode.
    pub fn deinit(self: *Terminal) void {
        _ = self;
    }

    /// Current terminal size in cells. TODO: ioctl(TIOCGWINSZ).
    pub fn size(self: *const Terminal) struct { cols: usize, rows: usize } {
        _ = self;
        return .{ .cols = 80, .rows = 24 };
    }
};
