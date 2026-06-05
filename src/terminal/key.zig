//! A decoded terminal input event. The input parser turns raw bytes (including
//! multi-byte escape sequences and UTF-8) into these.
pub const Key = union(enum) {
    /// A decoded UTF-8 codepoint (printable input).
    char: u21,
    /// Ctrl-<byte>, e.g. Ctrl-Q arrives as `.{ .ctrl = 'q' }`.
    ctrl: u8,
    enter,
    tab,
    esc,
    backspace,
    up,
    down,
    left,
    right,
    home,
    end,
    page_up,
    page_down,
    /// Function key number (F1 == 1).
    fn_key: u8,
};
