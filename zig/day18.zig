const std = @import("std");
const Allocator = std.mem.Allocator;
const runDay = @import("adventofcode2023.zig").runDay;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const global_allocator = gpa.allocator();

const TEST_CASE =
    \\R 6 (#70c710)
    \\D 5 (#0dc571)
    \\L 2 (#5713f0)
    \\D 2 (#d2c081)
    \\R 2 (#59c680)
    \\D 2 (#411b91)
    \\L 5 (#8ceee2)
    \\U 2 (#caa173)
    \\L 1 (#1b58a2)
    \\U 2 (#caa171)
    \\R 2 (#7807d2)
    \\U 3 (#a77fa3)
    \\L 2 (#015232)
    \\U 2 (#7a21e3)
;

const Direction = enum { right, up, left, down };

const Dig = struct {
    direction: Direction,
    count: isize,
    color: u32,

    fn parse(row: []const u8) !Dig {
        var it = std.mem.split(u8, row, " ");

        const direction = switch (it.next().?[0]) {
            'R' => Direction.right,
            'L' => Direction.left,
            'U' => Direction.up,
            'D' => Direction.down,
            else => unreachable,
        };

        const count_slice = it.next().?;
        const count = try std.fmt.parseInt(isize, count_slice, 10);
        const color_slice = it.next().?;
        const color = try std.fmt.parseInt(u32, color_slice[2 .. color_slice.len - 1], 16);

        return Dig{ .direction = direction, .count = count, .color = color };
    }

    fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Dig) {
        var l = std.ArrayList(Dig).init(allocator);

        var it = std.mem.split(u8, input, "\n");
        while (it.next()) |row| {
            try l.append(try Dig.parse(row));
        }

        return l;
    }

    fn parse2(row: []const u8) !Dig {
        var it = std.mem.split(u8, row, " ");

        _ = it.next().?;
        _ = it.next().?;
        const color_slice = it.next().?;
        const color = try std.fmt.parseInt(u32, color_slice[2 .. color_slice.len - 1], 16);

        const direction = switch (color & 0xF) {
            0 => Direction.right,
            1 => Direction.down,
            2 => Direction.left,
            3 => Direction.up,
            else => unreachable,
        };

        const count = color >> 4;

        return Dig{ .direction = direction, .count = count, .color = color };
    }

    fn parseInput2(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(Dig) {
        var l = std.ArrayList(Dig).init(allocator);

        var it = std.mem.split(u8, input, "\n");
        while (it.next()) |row| {
            try l.append(try Dig.parse2(row));
        }

        return l;
    }
};

const Point = struct {
    x: isize,
    y: isize,

    fn advance(self: *Point, direction: Direction) void {
        switch (direction) {
            .up => self.y -= 1,
            .down => self.y += 1,
            .right => self.x += 1,
            .left => self.x -= 1,
        }
    }

    fn translate(self: *const Point, x: isize, y: isize) Point {
        return Point{ .x = self.x + x, .y = self.y + y };
    }
};

fn performDig(allocator: Allocator, digs: std.ArrayList(Dig)) !u64 {
    var points = std.ArrayList(Point).init(allocator);
    defer points.deinit();

    var current_point = Point{ .x = 0, .y = 0 };
    try points.append(current_point);

    var perimeter: isize = 0;

    for (digs.items) |dig| {
        const dx: isize = switch (dig.direction) {
            .up, .down => 0,
            .right => 1,
            .left => -1,
        };
        const dy: isize = switch (dig.direction) {
            .up => -1,
            .down => 1,
            .right, .left => 0,
        };

        perimeter += dig.count;

        current_point = current_point.translate(dx * dig.count, dy * dig.count);
        try points.append(current_point);
    }

    var area: isize = 0;
    var x: usize = 0;
    while (x < points.items.len - 1) : (x += 1) {
        const p1 = points.items[x];
        const p2 = points.items[x + 1];

        area += p1.x * p2.y - p2.x * p1.y;
    }

    area = @divFloor(area, 2);
    area += @divFloor(perimeter, 2) + 1;

    return @intCast(area);
}

test "perform dig" {
    const digs = Dig.parseInput(global_allocator, TEST_CASE) catch unreachable;
    defer digs.deinit();
    const mqs = try performDig(global_allocator, digs);
    std.debug.print("{}\n", .{mqs});
}

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        const digs = Dig.parseInput(allocator, input) catch unreachable;
        defer digs.deinit();

        return performDig(allocator, digs) catch unreachable;
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        const digs = Dig.parseInput2(allocator, input) catch unreachable;
        defer digs.deinit();

        return performDig(allocator, digs) catch unreachable;
    }
};

pub fn main() !void {
    try runDay(Day, 18);
}
