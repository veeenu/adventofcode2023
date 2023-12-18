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
    count: usize,
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
        const count = try std.fmt.parseInt(usize, count_slice, 10);
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

const Beam = struct {
    point: Point,
    direction: Direction,
};

fn performDig(allocator: Allocator, input: []const u8) !u64 {
    const digs = try Dig.parseInput(allocator, input);
    defer digs.deinit();

    var point_set = std.AutoHashMap(Point, bool).init(allocator);
    defer point_set.deinit();

    var beams = std.ArrayList(Beam).init(allocator);
    defer beams.deinit();

    var current_point = Point{ .x = 0, .y = 0 };
    var min_x: isize = 0;
    var min_y: isize = 0;
    var max_x: isize = 0;
    var max_y: isize = 0;

    for (digs.items) |dig| {
        try beams.append(Beam{ .point = current_point, .direction = switch (dig.direction) {
            .up => Direction.right,
            .right => Direction.down,
            .down => Direction.left,
            .left => Direction.up,
        } });
        for (0..dig.count) |_| {
            try point_set.put(current_point, true);
            current_point.advance(dig.direction);
            try beams.append(Beam{ .point = current_point, .direction = switch (dig.direction) {
                .up => Direction.right,
                .right => Direction.down,
                .down => Direction.left,
                .left => Direction.up,
            } });

            min_x = @min(min_x, current_point.x);
            min_y = @min(min_y, current_point.y);
            max_x = @max(max_x, current_point.x);
            max_y = @max(max_y, current_point.y);
        }
    }

    var pixels = std.ArrayList(bool).init(allocator);
    defer pixels.deinit();

    const width: usize = @bitCast(max_x - min_x + 1);
    const height: usize = @bitCast(max_y - min_y + 1);

    std.debug.print("w={} h={} count={} min=({}, {}) max=({}, {})\n", .{ width, height, point_set.count(), min_x, min_y, max_x, max_y });

    {
        var x: isize = 0;
        var y: isize = 0;
        while (y < height) : (y += 1) {
            x = 0;
            while (x < width) : (x += 1) {
                const test_point = Point{ .x = x + min_x, .y = y + min_y };
                try pixels.append(point_set.contains(test_point));
            }
        }
    }

    for (beams.items) |beam| {
        const iwidth: isize = @intCast(width);
        var beam_point = beam.point;
        while (true) {
            const point = beam_point.translate(-min_x, -min_y);
            if (point.x < 0 or point.x >= width or point.y < 0 or point.y >= height) {
                break;
            }
            pixels.items[@bitCast(point.y * iwidth + point.x)] = true;
            beam_point.advance(beam.direction);
            if (point_set.contains(beam_point)) {
                break;
            }
        }
    }

    var count: u64 = 0;
    {
        const fs = std.fs;
        var file = try fs.cwd().createFile("day18.ppm", .{});
        defer file.close();

        try file.writer().print("P3\n{} {}\n1\n", .{ width, height });

        for (0..height) |y| {
            for (0..width) |x| {
                const val = pixels.items[y * width + x];

                const xx: isize = @intCast(x);
                const yy: isize = @intCast(y);

                if (point_set.contains(Point{ .x = xx + min_x, .y = yy + min_y })) {
                    try file.writer().writeAll("0 ");
                } else {
                    try file.writer().writeAll("1 ");
                }

                if (val) {
                    count += 1;
                    try file.writer().writeAll("1 1 ");
                } else {
                    try file.writer().writeAll("0 0 ");
                }
            }
            try file.writer().writeByte('\n');
        }
    }

    return count;
}

test "parses test case" {
    _ = try Dig.parseInput(global_allocator, TEST_CASE);
}

test "perform dig" {
    const mqs = try performDig(global_allocator, TEST_CASE);
    std.debug.print("{}\n", .{mqs});
}

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        return performDig(allocator, input) catch unreachable;
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;
        _ = allocator;
        return 0;
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
    try runDay(Day, 18);
}
