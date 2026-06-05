//! Operators act on a `Range` resolved by a motion or text object. `dw`, `ciw`,
//! `2dd`, `y$` all reduce to (operator, range).
pub const Operator = enum {
    delete, // d
    change, // c
    yank, // y
    indent, // >
    dedent, // <
    // TODO: gu / gU / g~ (case), = (format), etc.
};

/// A resolved span of the buffer plus how the operator should treat it.
pub const Range = struct {
    start: usize,
    end: usize,
    kind: Kind = .charwise,
    /// Whether `end` is included (e.g. `e` is inclusive, `w` is exclusive).
    inclusive: bool = false,

    pub const Kind = enum { charwise, linewise };
};
