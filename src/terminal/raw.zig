//! Owns the tty: enters raw mode (termios) and the alternate screen, queries the
//! window size, and restores everything on deinit. SIGWINCH handling (resize)
//! lands here too.
const std = @import("std");
const posix = std.posix;

pub const Terminal = struct {
    tty: std.Io.File,
    io: std.Io,
    orig_termios: posix.termios,
    /// Enter raw mode + alternate screen.
    /// TODO Phase 0: tcgetattr -> save, clear ICANON/ECHO/ISIG/IXON etc.,
    /// tcsetattr; write the alt-screen enter sequence (\x1b[?1049h).
    pub fn init(io: std.Io) !Terminal {
        const tty = try std.Io.Dir.openFileAbsolute(io, "/dev/tty", .{ .mode = .read_write });
        const orig = try posix.tcgetattr(tty.handle);
        var self = Terminal{ .tty = tty, .io = io, .orig_termios = orig };
        try self.enableRawMode();
        try self.enterAltScreen();
        return self;
    }

    /// Leave alternate screen and restore the saved termios. Must run on every
    /// exit path (including panics) so the user's shell isn't left in raw mode.
    pub fn deinit(self: *Terminal) void {
        self.leaveAltScreen() catch {};
        posix.tcsetattr(self.tty.handle, .FLUSH, self.orig_termios) catch {};
        self.tty.close(self.io);
    }

    fn enableRawMode(self: *Terminal) !void {
        var raw = self.orig_termios;

        // Disable: break-to-signal, CR->NL translation, parity, flow control
        // (Ctrl-S/Q);
        raw.iflag.BRKINT = false;
        raw.iflag.ICRNL = false;
        raw.iflag.INPCK = false;
        raw.iflag.ISTRIP = false;
        raw.iflag.IXON = false;

        // Disable oputput post-processing (we wmit our own escape sequences)
        raw.oflag.OPOST = false;

        // 8-bit characters
        raw.cflag.CSIZE = .CS8;

        // Disable: echo, canonical line buffering, signal keys, extended
        // processing.
        raw.lflag.ECHO = false;
        raw.lflag.ICANON = false;
        raw.lflag.IEXTEN = false;
        raw.lflag.ISIG = false;

        // read() returns after 1 byte with no timeout.
        raw.cc[@intFromEnum(posix.V.MIN)] = 1;
        raw.cc[@intFromEnum(posix.V.TIME)] = 0;

        try posix.tcsetattr(self.tty.handle, .FLUSH, raw);
    }

    fn enterAltScreen(self: *Terminal) !void {
        // Switch to alternate screeen buffer, clear it, move cursor to
        // top-left.
        try self.tty.writeStreamingAll(self.io, "\x1b[?1049h\x1b[2J\x1b[H");
    }

    fn leaveAltScreen(self: *Terminal) !void {
        try self.tty.writeStreamingAll(self.io, "\x1b[?1049l");
    }

    /// Current terminal size in cells. TODO: ioctl(TIOCGWINSZ).
    pub fn size(self: *const Terminal) !struct { cols: usize, rows: usize } {
        var ws: posix.winsize = undefined;
        const rc = posix.system.ioctl(self.tty.handle, posix.T.IOCGWINSZ, @intFromPtr(&ws));
        if (rc != 0) return error.IoctlFailed;
        return .{ .cols = ws.col, .rows = ws.row };
    }
};
