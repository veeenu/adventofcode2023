const std = @import("std");
const runDay = @import("adventofcode2023.zig").runDay;

const TEST_CASE =
    \\.|...\....
    \\|.-.\.....
    \\.....|-...
    \\........|.
    \\..........
    \\.........\
    \\..../.\\..
    \\.-.-/..|..
    \\.|....-|.\
    \\..//.|....
;

fn trimString(str: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = str.len;

    while (start < end and std.ascii.isWhitespace(str[start])) : (start += 1) {}
    while (end > start and std.ascii.isWhitespace(str[end - 1])) : (end -= 1) {}

    return str[start..end];
}

const Grid = struct {
    string: []const u8,
    cols: usize,

    fn new(string: []const u8) Grid {
        var cols: usize = 0;
        while (string[cols] != '\n') : (cols += 1) {}

        return Grid{
            .string = string,
            .cols = cols,
        };
    }

    fn get(self: *const Grid, x: usize, y: usize) u8 {
        return self.string[y * (self.cols + 1) + x];
    }
};

test "grid works" {
    const grid = Grid.new(TEST_CASE);
    var x: usize = 0;
    var y: usize = 0;

    std.debug.print("{}\n>", .{grid.cols});
    while (y < 10) : (y += 1) {
        while (x < 10) : (x += 1) {
            std.debug.print("{c}", .{grid.get(x, y)});
        }
        x = 0;
        std.debug.print("\n>", .{});
    }
}

const Direction = enum { north, east, south, west };

fn splitter(self: Direction, char: u8) ?[2]Direction {
    return switch (char) {
        '-' => switch (self) {
            .north => .{ Direction.west, Direction.east },
            .south => .{ Direction.west, Direction.east },
            .west => null,
            .east => null,
        },
        '|' => switch (self) {
            .north => null,
            .south => null,
            .west => .{
                Direction.north,
                Direction.south,
            },
            .east => .{
                Direction.north,
                Direction.south,
            },
        },
        else => unreachable,
    };
}

fn mirror(self: Direction, char: u8) Direction {
    return switch (char) {
        '/' => switch (self) {
            .north => Direction.east,
            .east => Direction.north,
            .south => Direction.west,
            .west => Direction.south,
        },
        '\\' => switch (self) {
            .north => Direction.west,
            .west => Direction.north,
            .south => Direction.east,
            .east => Direction.south,
        },
        else => unreachable,
    };
}

const Beam = struct {
    x: usize,
    y: usize,
    direction: Direction,

    fn advance(self: *Beam, grid: *const Grid) bool {
        switch (self.direction) {
            .north => {
                if (self.y > 0) {
                    self.y -= 1;
                    return true;
                } else {
                    return false;
                }
            },
            .south => {
                if (self.y < grid.cols - 1) {
                    self.y += 1;
                    return true;
                } else {
                    return false;
                }
            },
            .west => {
                if (self.x > 0) {
                    self.x -= 1;
                    return true;
                } else {
                    return false;
                }
            },
            .east => {
                if (self.x < grid.cols - 1) {
                    self.x += 1;
                    return true;
                } else {
                    return false;
                }
            },
        }
    }
};

fn runBeam(grid: *const Grid, start: Beam) usize {
    const alloc = std.heap.page_allocator;
    var beams = std.ArrayList(Beam).init(alloc);
    defer beams.deinit();

    var electrified = std.AutoHashMap([2]usize, bool).init(alloc);
    defer electrified.deinit();

    var cache = std.AutoHashMap(Beam, bool).init(alloc);
    defer cache.deinit();

    beams.append(start) catch unreachable;

    var l: usize = 0;
    while (true) {
        l += 1;
        var to_remove = std.ArrayList(usize).init(alloc);
        defer to_remove.deinit();

        var to_add = std.ArrayList(Beam).init(alloc);
        defer to_add.deinit();

        var i: usize = 0;
        for (beams.items) |*beam| {
            electrified.put(.{ beam.x, beam.y }, true) catch unreachable;

            const state = grid.get(beam.x, beam.y);
            switch (state) {
                '.' => {
                    if (!beam.advance(grid)) {
                        to_remove.append(i) catch unreachable;
                    }
                },
                '-', '|' => {
                    if (splitter(beam.direction, state)) |splits| {
                        var beam1 = Beam{ .x = beam.x, .y = beam.y, .direction = splits[0] };
                        if (beam1.advance(grid) and (beam1.x != beam.x or beam1.y != beam.y)) {
                            to_add.append(beam1) catch unreachable;
                        }
                        var beam2 = Beam{ .x = beam.x, .y = beam.y, .direction = splits[1] };
                        if (beam2.advance(grid) and (beam2.x != beam.x or beam2.y != beam.y)) {
                            to_add.append(beam2) catch unreachable;
                        }
                        to_remove.append(i) catch unreachable;
                    } else {
                        if (!beam.advance(grid)) {
                            to_remove.append(i) catch unreachable;
                        }
                    }
                },
                '/', '\\' => {
                    beam.direction = mirror(beam.direction, state);
                    if (!beam.advance(grid)) {
                        to_remove.append(i) catch unreachable;
                    }
                },
                else => unreachable,
            }

            i += 1;
        }

        // Remove the elements from the latest to the first
        std.mem.sort(usize, to_remove.items, {}, comptime std.sort.desc(usize));

        for (to_remove.items) |idx| {
            _ = beams.orderedRemove(idx);
        }

        for (to_add.items) |beam| {
            if (!cache.contains(beam)) {
                cache.put(beam, true) catch unreachable;
                beams.append(beam) catch unreachable;
            }
        }

        if (beams.items.len == 0) {
            break;
        }
    }

    return electrified.count();
}

fn findBestConfig(grid: *const Grid) u64 {
    var max_energized: usize = 0;

    var start_beams = std.ArrayList(Beam).init(std.heap.page_allocator);
    defer start_beams.deinit();

    var i: usize = 0;
    while (i < grid.cols) : (i += 1) {
        start_beams.append(Beam{ .x = i, .y = 0, .direction = Direction.south }) catch unreachable;
        start_beams.append(Beam{ .x = i, .y = grid.cols - 1, .direction = Direction.north }) catch unreachable;
        start_beams.append(Beam{ .x = 0, .y = i, .direction = Direction.east }) catch unreachable;
        start_beams.append(Beam{ .x = grid.cols - 1, .y = i, .direction = Direction.west }) catch unreachable;
    }

    for (start_beams.items) |start_beam| {
        const e = runBeam(grid, start_beam);
        if (max_energized < e) {
            max_energized = e;
        }
    }

    return max_energized;
}

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = allocator;

        const grid = Grid.new(input);
        return runBeam(&grid, Beam{ .x = 0, .y = 0, .direction = Direction.east });
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = allocator;

        const grid = Grid.new(input);
        return findBestConfig(&grid);
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
    try runDay(Day, 16);
}
