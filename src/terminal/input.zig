//! Turns the raw byte stream from the terminal into `Key` events.
//!
//! Terminals deliver special keys as escape sequences (e.g. Up == ESC [ A), and
//! printable input as UTF-8. Because a read() can split a sequence across reads,
//! the parser holds partial bytes and only emits a Key once a full token is seen.
const Key = @import("key.zig").Key;

pub const Parser = struct {
    /// Holding buffer for a partial escape sequence / UTF-8 codepoint.
    pending: [8]u8 = undefined,
    pending_len: usize = 0,

    /// Feed bytes from a read(). TODO: append to `pending`, then drain complete
    /// tokens via `next()`.
    pub fn feed(self: *Parser, bytes: []const u8) void {
        _ = self;
        _ = bytes;
    }

    /// Pop the next fully-decoded key, or null if more bytes are needed.
    /// TODO: decode CSI/SS3 sequences and UTF-8 codepoints.
    pub fn next(self: *Parser) ?Key {
        _ = self;
        return null;
    }
};
