const roc = @import("main.zig");

fn nextMultipleOf(lhs: usize, rhs: usize) usize {
    return switch (lhs % rhs) {
        0 => lhs,
        else => |r| lhs + (rhs - r),
    };
}

pub fn List(comptime T: type) type {
    return struct {
        elements: ?[*]T,
        length: usize,
        capacity_or_ref_ptr: usize,

        pub fn initEmpty() @This() {
            return .{
                .elements = null,
                .length = 0,
                .capacity_or_ref_ptr = 0,
            };
        }

        pub fn initCapacity(cap: usize) @This() {
            return .{
                .elements = elemsWithCapacity(cap),
                .length = 0,
                .capacity_or_ref_ptr = capacity,
            };
        }

        fn allocBytes(num: usize) usize {
            return nextMultipleOf(@sizeOf(roc.Storage), @alignOf(T)) + num * @sizeOf(T);
        }

        fn allocAlign() u32 {
            return @max(@alignOf(T), @alignOf(roc.Storage));
        }

        fn elemPtrFromAllocPtr(alloc_ptr: [*]anyopaque) [*]anyopaque {
            const ptrInt = @intFromPtr(alloc_ptr);
            return @ptrFromInt(ptrInt + @sizeOf(u8) * allocAlign());
        }

        fn elemsFromAlloc(alloc_ptr: [*]anyopaque) [*]T {
            const offset: u32 = allocAlign() - @sizeOf(*const u8);
            const rc_ptr: [*]anyopaque = @ptrFromInt(@intFromPtr(alloc_ptr) + @sizeOf(u8) * offset);

            const rc_ptr_storage: *roc.Storage = @ptrCast(rc_ptr);
            rc_ptr_storage.* = roc.Storage.initRefCounted();

            return elemPtrFromAllocPtr(alloc_ptr);
        }

        fn elemsWithCapacity(cap: usize) [*]T {
            const alloc_ptr = roc.alloc(allocBytes(cap), allocAlign()) orelse {
                @panic("Call roc_panic with the info that an allocation failed.");
            };

            return elemsFromAlloc(alloc_ptr);
        }

        pub fn firstElemFromPtr(list: @This()) ?*const T {
            const elements = list.elements orelse {
                return null;
            };

            return @ptrCast(elements);
        }

        pub fn allocFromPtr(list: @This()) ?[*]anyopaque {
            const alignment: usize = allocAlign();

            if (list.isSeamlessSlice()) {
                return @ptrFromInt((list.capacity_or_ref_ptr << 1) - alignment);
            } else {
                const first_elem = list.firstElemFromPtr() orelse {
                    return null;
                };

                const bytes_ptr: [*]const u8 = @ptrCast(first_elem);
                const bytes_ptr_int = @intFromPtr(bytes_ptr);

                return @ptrFromInt(bytes_ptr_int - @sizeOf(u8) * alignment);
            }
        }

        pub fn storage(list: @This()) ?*roc.Storage {
            const offset = switch (@alignOf(T)) {
                16 => 1,
                8, 4, 2, 1 => 0,
                else => @panic("Invalid alignment"),
            };

            const alloc_ptr = list.allocFromPtr() orelse {
                return null;
            };

            const storage_ptr: *roc.Storage = @ptrCast(alloc_ptr);
            const storage_ptr_int = @intFromPtr(storage_ptr) + offset;

            return @ptrFromInt(storage_ptr_int);
        }

        pub fn isSeamlessSlice(list: @This()) bool {
            return @as(isize, @intCast(list.length | list.capacity_or_ref_ptr)) < 0;
        }

        pub fn capacity(list: @This()) usize {
            return if (!list.isSeamlessSlice())
                list.capacity_or_ref_ptr
            else
                list.length;
        }

        pub fn isEmpty(list: @This()) bool {
            return list.length == 0;
        }

        pub fn reserve(list: *@This(), num: usize) void {
            const new_len = num + list.length;

            var elements: [*]T = undefined;
            var list_storage: *roc.Storage = undefined;

            {
                const storage_opt = list.storage();

                if (list.elements == null or storage_opt == null) {
                    list.* = initCapacity(new_len);
                    return;
                }

                elements = list.elements.?;
                list_storage = storage_opt.?;
            }

            var new_elems: [*]T = undefined;

            if (list_storage.isUnique()) {
                const old_alloc = list.allocFromPtr().?;

                const new_alloc = roc.realloc(
                    old_alloc,
                    list.allocBytes(new_len),
                    list.allocBytes(list.capacity()),
                    list.allocAlign(),
                ) orelse {
                    @panic("Reallocation failed");
                };

                if (new_alloc == old_alloc) {
                    return;
                }

                new_elems = elemsFromAlloc(new_alloc);
            } else {
                new_elems = elemsWithCapacity(new_len);
                @memcpy(new_elems, elements[0..list.length]);

                var new_storage = list_storage;

                if (new_storage.isReadonly()) {
                    const needs_dealloc = new_storage.decrease();

                    if (needs_dealloc) {
                        roc.dealloc(list.allocFromPtr(), allocAlign());
                    } else {
                        list_storage.* = new_storage;
                    }
                }
            }
        }
    };
}
