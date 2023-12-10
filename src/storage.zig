const std = @import("std");

const refcount_1 = std.math.minInt(isize);

pub const Storage = union(enum) {
    readonly,
    ref_counted: isize,

    pub fn initRefCounted() @This() {
        return .{ .ref_counted = refcount_1 };
    }

    pub fn increment(storage: *@This()) void {
        switch (storage) {
            .ref_counted => |*rc| {
                rc.* += 1;

                if (rc.* == 0) {
                    storage.* = .readonly;
                }
            },
            .readonly => {},
        }
    }

    pub fn decrease(storage: *@This()) bool {
        switch (storage) {
            .ref_counted => |*rc| {
                if (rc.* == refcount_1) {
                    return true;
                }

                rc.* -= 1;

                if (rc.* == 0) {
                    @panic("A reference count was decremented all the way to zero, which should never happen.");
                }

                return false;
            },
            .readonly => return false,
        }
    }

    pub fn isReadonly(storage: @This()) bool {
        return switch (storage) {
            .readonly => true,
            else => false,
        };
    }

    pub fn isUnique(storage: @This()) bool {
        return switch (storage) {
            .ref_counted => |rc| rc == refcount_1,
            else => false,
        };
    }
};
