const std = @import("std");
const runDay = @import("adventofcode2023.zig").runDay;

const TEST_CASE =
    \\
;

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;
        _ = allocator;
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;
        _ = allocator;
    }

    pub fn test1(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;

        return run1(allocator, TEST_CASE);
    }

    pub fn test2(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;

        return run2(allocator, TEST_CASE);
    }
};

pub fn main() !void {
    try runDay(Day, 0);
}
