const std = @import("std");
const runDay = @import("adventofcode2023.zig").runDay;
const util = @import("util.zig");

const Point = util.Point;
const Allocator = std.mem.Allocator;

const TEST_CASE =
    \\...........
    \\.....###.#.
    \\.###.##..#.
    \\..#.#...#..
    \\....#.#....
    \\.##..S####.
    \\.##..#...#.
    \\.......##..
    \\.##.#.####.
    \\.##..##.##.
    \\...........
;

const Grid = struct {
    grid: util.Grid,
    neighborhoods: std.AutoHashMap(Point, [4]?Point),

    fn new(allocator: Allocator, input: []const u8) Grid {
        var grid = Grid{
            .grid = util.Grid.new(input),
            .neighborhoods = std.AutoHashMap(Point, [4]?Point).init(allocator),
        };

        grid.computeNeighborhoods() catch unreachable;

        return grid;
    }

    fn deinit(self: *Grid) void {
        self.*.neighborhoods.deinit();
    }

    fn printReachable(self: *const Grid, reachable: []const Point) void {
        for (0..self.*.grid.rows) |y| {
            for (0..self.*.grid.cols) |x| {
                const p = self.*.grid.get(x, y).?;
                const isO = for (reachable) |r| {
                    if (r.x == @as(isize, @bitCast(x)) and r.y == @as(isize, @bitCast(y))) break true;
                } else false;

                if (isO) {
                    std.debug.print("O", .{});
                } else {
                    std.debug.print("{c}", .{p});
                }
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }

    fn computeNeighborhoods(self: *Grid) !void {
        for (0..self.*.grid.rows) |y| {
            for (0..self.*.grid.cols) |x| {
                const v = self.*.grid.get(x, y);
                if (v == '.' or v == 'S') {
                    try self.computeNeighborhoodsFor(x, y);
                }
            }
        }
    }

    fn computeNeighborhoodsFor(self: *Grid, xx: usize, yy: usize) !void {
        const x: isize = @intCast(xx);
        const y: isize = @intCast(yy);
        var neighborhoods = [4]?Point{ null, null, null, null };
        // North
        neighborhoods[0] = self.filterPoint(Point{ .x = x, .y = y - 1 });
        // West
        neighborhoods[1] = self.filterPoint(Point{ .x = x - 1, .y = y });
        // South
        neighborhoods[2] = self.filterPoint(Point{ .x = x, .y = y + 1 });
        // East
        neighborhoods[3] = self.filterPoint(Point{ .x = x + 1, .y = y });

        try self.neighborhoods.put(Point{ .x = x, .y = y }, neighborhoods);
    }

    fn filterPoint(self: *const Grid, point: Point) ?Point {
        if (point.x < 0 or point.y < 0 or point.x >= self.*.grid.cols or point.y >= self.*.grid.rows) {
            return null;
        }

        if (self.*.grid.get(@intCast(point.x), @intCast(point.y)).? == '.') {
            return point;
        } else {
            return null;
        }
    }

    fn isStart(c: u8, x: usize, y: usize) bool {
        _ = y;
        _ = x;
        return (c == 'S');
    }

    fn getStart(self: *const Grid) Point {
        return self.*.grid.find(isStart).?;
    }

    fn stepNeighborhoods(self: *const Grid, points: []const Point) !std.AutoArrayHashMap(Point, bool) {
        var neigh = std.AutoArrayHashMap(Point, bool).init(self.*.neighborhoods.allocator);
        for (points) |point| {
            for (self.neighborhoods.getPtr(point).?.*) |n| {
                if (n) |nn| {
                    try neigh.put(nn, true);
                }
            }
        }

        return neigh;
    }

    fn stepsNeighborhoods(self: *const Grid, step_count: usize) !std.AutoArrayHashMap(Point, bool) {
        var neigh = try self.stepNeighborhoods(&[_]Point{self.*.getStart()});
        for (1..step_count) |_| {
            var foo = neigh;
            defer foo.deinit();
            neigh = try self.stepNeighborhoods(foo.keys());
        }

        return neigh;
    }
};

test "find the S" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var grid = Grid.new(allocator, TEST_CASE);
    defer grid.deinit();
    std.debug.print("{any}\n", .{grid});

    var n = try grid.stepsNeighborhoods(6);
    defer n.deinit();

    std.debug.print("{}\n", .{n.count()});
}

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        var grid = Grid.new(allocator, input);
        defer grid.deinit();

        var n = grid.stepsNeighborhoods(64) catch unreachable;
        defer n.deinit();

        return n.count() + 1;
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;
        _ = allocator;

        return 0;
    }
};

pub fn main() !void {
    try runDay(Day, 21);
}
