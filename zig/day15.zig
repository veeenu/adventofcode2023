const std = @import("std");
const runDay = @import("adventofcode2023.zig").runDay;

const TEST_CASE = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";

fn parse() void {}

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = allocator;
        _ = input;
        return 0;
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = allocator;
        _ = input;
        return 0;
    }

    pub fn test1(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = allocator;
        _ = input;
        return 0;
    }

    pub fn test2(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = allocator;
        _ = input;
        return 0;
    }
};

pub fn main() !void {
    try runDay(Day, 15);
}
