//! The vim grammar accumulator. Normal mode feeds keys into this until a verb is
//! complete, then we resolve the motion/text object to a `Range` and apply the
//! operator. Encodes:
//!
//!   [count1] ["reg] [operator] [count2] {motion | text object}
//!
//! Examples: `2dw` -> count1=2, op=delete, motion=word_fwd;  `"ayy` -> reg='a',
//! op=yank, linewise current line;  `d2j` -> op=delete, count2=2, motion=down.
const Operator = @import("operator.zig").Operator;

pub const PendingOp = struct {
    count1: ?u32 = null,
    register: ?u8 = null,
    operator: ?Operator = null,
    count2: ?u32 = null,

    /// Effective repeat count (counts multiply, like vim: `2d3w` deletes 6 words).
    pub fn effectiveCount(self: PendingOp) u32 {
        return (self.count1 orelse 1) * (self.count2 orelse 1);
    }

    pub fn reset(self: *PendingOp) void {
        self.* = .{};
    }
};
