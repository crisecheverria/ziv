//! Editor modes. ziv is, at heart, a state machine over these.
const Operator = @import("operator.zig").Operator;

pub const Mode = union(enum) {
    normal,
    insert,
    visual: VisualKind,
    /// A verb has been entered and is waiting for a motion or text object
    /// (e.g. after `d`, before `w`).
    operator_pending: Operator,
    /// The ":" command line is active.
    command_line,
    replace,
};

pub const VisualKind = enum { char, line, block };
