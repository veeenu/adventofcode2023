const std = @import("std");
const runDay = @import("adventofcode2023.zig").runDay;

const TEST_CASE = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";

const Lens = struct {
    name: [32]u8,
    focal_length: u64,

    fn zeroed() Lens {
        return Lens{
            .name = std.mem.zeroes([32]u8),
            .focal_length = 0,
        };
    }
};

const Action = enum { add, remove };

const LensAction = struct {
    lens: Lens,
    action: Action,
    hash: u64,
};

const Box = struct {
    lenses: std.ArrayList(Lens),

    fn power(self: *const Box, index: u64) u64 {
        var total_power: u64 = 0;
        var i: u64 = 1;

        for (self.*.lenses.items) |lens| {
            total_power += (1 + index) * i * lens.focal_length;
            i += 1;
        }

        return total_power;
    }

    fn print(self: *Box) void {
        std.debug.print("Box: ", .{});
        for (self.*.lenses.items) |lens| {
            std.debug.print("[{s} {}] ", .{ lens.name, lens.focal_length });
        }
        std.debug.print("\n", .{});
    }
};

fn calculateHash(input: []const u8, comptime only_label: bool) u64 {
    var cur_hash: u64 = 0;

    for (input) |c| {
        if (only_label and ((c == '=') or (c == '-'))) {
            break;
        }
        cur_hash += @as(u64, c);
        cur_hash *= 17;
        cur_hash %= 256;
    }

    return cur_hash;
}

fn parseLensActions(allocator: std.mem.Allocator, input: []const u8) std.ArrayList(LensAction) {
    var actions = std.ArrayList(LensAction).initCapacity(allocator, 32) catch unreachable;
    var it = std.mem.split(u8, input, ",");
    while (it.next()) |chunk| {
        var lens_action = LensAction{ .hash = calculateHash(chunk, true), .lens = Lens.zeroed(), .action = undefined };

        var i: u64 = 0;
        var add_to_name = true;
        for (chunk) |c| {
            if (c == '=') {
                var chunk_it = std.mem.split(u8, chunk, "=");
                _ = chunk_it.next();
                const num = std.fmt.parseInt(u64, chunk_it.next().?, 10) catch unreachable;
                lens_action.action = Action.add;
                lens_action.lens.focal_length = num;
                add_to_name = false;
            } else if (c == '-') {
                lens_action.action = Action.remove;
                add_to_name = false;
            } else if (add_to_name) {
                lens_action.lens.name[i] = c;
                i += 1;
            }
        }

        actions.append(lens_action) catch unreachable;
    }

    return actions;
}

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = allocator;

        var sum_hash: u64 = 0;
        var it = std.mem.split(u8, input, ",");
        while (it.next()) |chunk| {
            sum_hash += calculateHash(chunk, false);
        }

        return sum_hash;
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        var boxes: [256]Box = undefined;
        for (&boxes) |*box| {
            box.* = Box{ .lenses = std.ArrayList(Lens).init(allocator) };
        }

        defer {
            for (&boxes) |*box| {
                box.*.lenses.deinit();
            }
        }

        const lens_actions = parseLensActions(allocator, input);
        defer lens_actions.deinit();

        for (lens_actions.items) |lens_action| {
            switch (lens_action.action) {
                Action.add => {
                    var i: u64 = 0;
                    var added = false;
                    while (i < boxes[lens_action.hash].lenses.items.len) : (i += 1) {
                        var lens = &boxes[lens_action.hash].lenses.items[i];
                        if (std.mem.eql(u8, &lens.name, &lens_action.lens.name)) {
                            lens.* = lens_action.lens;
                            added = true;
                            break;
                        }
                    }

                    if (!added) {
                        const copy: Lens = lens_action.lens;
                        boxes[lens_action.hash].lenses.append(copy) catch unreachable;
                    }
                },
                Action.remove => {
                    var i: u64 = 0;
                    while (i < boxes[lens_action.hash].lenses.items.len) : (i += 1) {
                        var lens = &boxes[lens_action.hash].lenses.items[i];
                        if (std.mem.eql(u8, &lens.name, &lens_action.lens.name)) {
                            _ = boxes[lens_action.hash].lenses.orderedRemove(i);
                            break;
                        }
                    }
                },
            }
        }

        boxes[0].print();
        boxes[3].print();

        var total_power: u64 = 0;
        var i: u64 = 0;

        for (boxes) |box| {
            total_power += box.power(i);
            i += 1;
        }

        return total_power;
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
    try runDay(Day, 15);
}
