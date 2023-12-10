pub fn Result(comptime T: type, comptime E: type) type {
    return union(enum) {
        ok: T,
        err: E,

        pub fn ok(payload: T) @This() {
            return .{ .ok = payload };
        }

        pub fn err(payload: E) @This() {
            return .{ .err = payload };
        }

        pub fn isOk(result: @This()) bool {
            return switch (result) {
                .ok => true,
                else => false,
            };
        }

        pub fn isErr(result: @This()) bool {
            return switch (result) {
                .err => true,
                else => false,
            };
        }
    };
}
