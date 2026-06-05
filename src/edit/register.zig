//! Yank/delete registers: the unnamed register, named a–z, and (later) numbered
//! and the system clipboard. Linewise vs. charwise yanks are tracked so paste
//! (`p`/`P`) behaves correctly.
const std = @import("std");

pub const Registers = struct {
    // TODO Phase 4: unnamed + named[a..z], each storing bytes + a linewise flag.

    pub fn deinit(self: *Registers) void {
        _ = self;
    }
};
