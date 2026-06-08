//! Turns the raw byte stream from the terminal into `Key` events.
//!
//! Terminals deliver special keys as escape sequences (e.g. Up == ESC [ A), and
//! printable input as UTF-8. Because a read() can split a sequence across reads,
//! the parser holds partial bytes and only emits a Key once a full token is seen.
const std = @import("std");
const Key = @import("key.zig").Key;

pub const Parser = struct {
    /// Holding buffer for a partial escape sequence / UTF-8 codepoint.
    pending: [8]u8 = undefined,
    pending_len: usize = 0,

    /// Feed bytes from a read(). TODO: append to `pending`, then drain complete
    /// tokens via `next()`.
    pub fn feed(self: *Parser, bytes: []const u8) void {
        const space = self.pending.len - self.pending_len;
        const n = @min(bytes.len, space);
        @memcpy(self.pending[self.pending_len..][0..n], bytes[0..n]);
        self.pending_len += n;
    }

    /// Pop the next fully-decoded key, or null if more bytes are needed.
    /// TODO: decode CSI/SS3 sequences and UTF-8 codepoints.
    pub fn next(self: *Parser) ?Key {
        if (self.pending_len == 0) return null;
        const b = self.pending[0];

        // Escape sequence (arrows, page keys, etc.)
        if (b == 0x1b) {
            if (self.pending_len < 2) return null; // wait for more
            if (self.pending_len >= 3 and self.pending[1] == '[') {
                switch (self.pending[2]) {
                    'A' => {
                        self.consume(3);
                        return .up;
                    },
                    'B' => {
                        self.consume(3);
                        return .down;
                    },
                    'C' => {
                        self.consume(3);
                        return .right;
                    },
                    'D' => {
                        self.consume(3);
                        return .left;
                    },
                    'H' => {
                        self.consume(3);
                        return .home;
                    },
                    'F' => {
                        self.consume(3);
                        return .end;
                    },
                    '5' => if (self.pending_len >= 4 and self.pending[3] == '~') {
                        self.consume(4);
                        return .page_up;
                    },
                    '6' => if (self.pending_len >= 4 and self.pending[3] == '~') {
                        self.consume(4);
                        return .page_down;
                    },
                    else => {},
                }
            }
            // Plain ESC (or unrecognised sequence - emit ESC and leave rest)
            self.consume(1);
            return .esc;
        }

        // Special single bytes
        if (b == '\r') {
            self.consume(1);
            return .enter;
        }
        if (b == '\t') {
            self.consume(1);
            return .tab;
        }
        if (b == 0x7f) {
            self.consume(1);
            return .backspace;
        }

        // Ctrl-A (0x01) through Ctrl-Z (0x1a), skipping tab (0x09) and CR (0x0d)
        if (b > 0 and b < 32) {
            self.consume(1);
            return Key{ .ctrl = b - 1 + 'a' };
        }

        // UTF-8 multi-byte codepoint
        const seq_len: usize = if (b & 0x80 == 0) 1 else if (b & 0xe0 == 0xc0) 2 else if (b & 0xf0 == 0xe0) 3 else 4;

        if (self.pending_len < seq_len) return null; // Wait for remaining
        // bytes
        const cp = std.unicode.utf8Decode(self.pending[0..seq_len]) catch {
            self.consume(1); // skip bad byte
            return null;
        };
        self.consume(seq_len);
        return Key{ .char = cp };
    }

    fn consume(self: *Parser, n: usize) void {
        std.mem.copyForwards(u8, &self.pending, self.pending[n..self.pending_len]);
        self.pending_len -= n;
    }
};
