const std = @import("std");
const runDay = @import("adventofcode2023.zig").runDay;
const util = @import("util.zig");

const Allocator = std.mem.Allocator;

const TEST_CASE =
    \\2413432311323
    \\3215453535623
    \\3255245654254
    \\3446585845452
    \\4546657867536
    \\1438598798454
    \\4457876987766
    \\3637877979653
    \\4654967986887
    \\4564679986453
    \\1224686865563
    \\2546548887735
    \\4322674655533
;

const Direction = enum { u, r, d, l };
const Step = enum { one, two, three };
const Point = struct {
    x: i32,
    y: i32,

    fn advance(self: Point, dir: Direction) Point {
        return switch (dir) {
            .u => Point{ .x = self.x, .y = self.y - 1 },
            .d => Point{ .x = self.x, .y = self.y + 1 },
            .l => Point{ .x = self.x - 1, .y = self.y },
            .r => Point{ .x = self.x + 1, .y = self.y },
        };
    }

    fn within(self: Point, width: i32, height: i32) bool {
        return self.x > 0 and self.y > 0 and self.x < width and self.y < height;
    }
};

fn cw(dir: Direction) Direction {
    return switch (dir) {
        .u => Direction.r,
        .r => Direction.d,
        .d => Direction.l,
        .l => Direction.u,
    };
}

fn ccw(dir: Direction) Direction {
    return switch (dir) {
        .u => Direction.l,
        .r => Direction.u,
        .d => Direction.r,
        .l => Direction.d,
    };
}

const Node = struct {
    point: Point,
    dir: Direction,
    step: u32,

    fn advance(self: Node) Node {
        return Node{ .point = self.point.advance(self.dir), .dir = self.dir, .step = self.step + 1 };
    }

    fn turn(self: Node, dir: Direction) Node {
        return Node{ .point = self.point.advance(dir), .dir = dir, .step = 0 };
    }

    fn filter(self: Node, width: i32, height: i32) ?Node {
        if (self.point.within(width, height)) {
            return self;
        } else {
            return null;
        }
    }
};

const NodeCost = struct {
    node: Node,
    cost: ?i32,
};

fn make_cost(maybe_self: ?NodeCost, rhs: Node, costs: *const std.AutoHashMap(Point, i32)) ?NodeCost {
    if (maybe_self) |self| {
        if (self.cost) |self_cost| {
            if (costs.get(rhs.point)) |cost| {
                return NodeCost{ .node = rhs, .cost = cost + self_cost };
            }
        }
    }
    return null;
}

const NodeEdges = struct {
    node: Node,
    adj: [6]?NodeCost,

    // For each direction, these are the possible edges.
    // The number indicates the consecutive steps.
    //      0    0
    //      ^    ^
    // 0 -> 1 -> 2
    //      v    v
    //      0    0
    fn iterator(point: Point, dir: Direction, costs: *std.AutoHashMap(Point, i32)) NodeEdges {
        const node = Node{ .point = point, .dir = dir, .step = 0 };
        const one_ahead = node.advance();
        const two_ahead = one_ahead.advance();
        const one_left = one_ahead.turn(ccw(one_ahead.dir));
        const one_right = one_ahead.turn(cw(one_ahead.dir));
        const two_left = two_ahead.turn(ccw(two_ahead.dir));
        const two_right = two_ahead.turn(cw(two_ahead.dir));

        const zero_cost = NodeCost{ .node = node, .cost = 0 };
        const one_ahead_c = make_cost(zero_cost, one_ahead, costs);
        const two_ahead_c = make_cost(one_ahead_c, two_ahead, costs);
        const one_left_c = make_cost(one_ahead_c, one_left, costs);
        const one_right_c = make_cost(one_ahead_c, one_right, costs);
        const two_left_c = make_cost(two_ahead_c, two_left, costs);
        const two_right_c = make_cost(two_ahead_c, two_right, costs);
        return NodeEdges{ .node = node, .adj = .{ one_ahead_c, two_ahead_c, one_left_c, one_right_c, two_left_c, two_right_c } };
    }
};

const AdjacencyLists = std.AutoHashMap(Node, std.ArrayList(NodeCost));

fn parse(allocator: Allocator, input: []const u8) !AdjacencyLists {
    var map = std.AutoHashMap(Point, i32).init(allocator);
    defer map.deinit();

    var edges = AdjacencyLists.init(allocator);

    var width: i32 = 0;
    var height: i32 = 0;

    var y: i32 = 0;
    {
        var it = std.mem.split(u8, util.trimString(input), "\n");
        while (it.next()) |line| {
            var x: i32 = 0;
            for (line) |c| {
                const cost = c - '0';
                try map.put(Point{ .x = x, .y = y }, cost);
                x += 1;
            }
            width = @max(width, x - 1);

            y += 1;
        }
        height = y - 1;
    }

    var map_it = map.keyIterator();
    while (map_it.next()) |point| {
        const directions = .{ Direction.u, Direction.r, Direction.d, Direction.l };
        inline for (directions) |dir| {
            const it = NodeEdges.iterator(point.*, dir, &map);
            for (it.adj) |adj| {
                if (!edges.contains(it.node)) {
                    try edges.put(it.node, std.ArrayList(NodeCost).init(allocator));
                }

                const al = edges.getPtr(it.node).?;
                if (adj) |adj_val| {
                    try al.append(adj_val);
                }
            }
        }
    }

    return edges;
}

fn contains(comptime T: type, haystack: []T, needle: T) bool {
    for (haystack) |h| {
        if (needle.point.x == h.point.x and needle.point.y == h.point.y and needle.step == h.step and needle.dir == h.dir) {
            return true;
        }
    }
    return false;
}

fn dijkstra_cmp(context: *std.AutoHashMap(Node, i32), lhs: Node, rhs: Node) std.math.Order {
    const l = context.*.get(lhs).?;
    const r = context.*.get(rhs).?;
    if (l < r) {
        return std.math.Order.lt;
    } else if (l > r) {
        return std.math.Order.gt;
    }
    return std.math.Order.eq;
}

fn dijkstra(allocator: Allocator, edges: *const AdjacencyLists) !void {
    var dist = std.AutoHashMap(Node, i32).init(allocator);
    defer dist.deinit();
    var prev = std.AutoHashMap(Node, Node).init(allocator);
    defer prev.deinit();

    var q = std.PriorityQueue(Node, *std.AutoHashMap(Node, i32), dijkstra_cmp).init(allocator, &dist);
    defer q.deinit();

    {
        var it = edges.iterator();
        while (it.next()) |kv| {
            const node = kv.key_ptr;
            try dist.put(node.*, 1 << 31 - 1);
            try q.add(node.*);
            for (kv.value_ptr.*.items) |v| {
                if (v.node.step != 0) {
                    try dist.put(v.node, 1 << 31 - 1);
                    try q.add(v.node);
                }
            }
        }
        try dist.put(Node{ .point = Point{ .x = 0, .y = 0 }, .dir = Direction.u, .step = 0 }, 0);
        try dist.put(Node{ .point = Point{ .x = 0, .y = 0 }, .dir = Direction.r, .step = 0 }, 0);
        try dist.put(Node{ .point = Point{ .x = 0, .y = 0 }, .dir = Direction.d, .step = 0 }, 0);
        try dist.put(Node{ .point = Point{ .x = 0, .y = 0 }, .dir = Direction.l, .step = 0 }, 0);
    }

    while (q.peek() != null) {
        const val = q.remove();
        const adjs = edges.get(val).?;
        for (adjs.items) |adj| {
            const alt = dist.get(val).? + adj.cost.?;
            if (alt < dist.get(adj.node).?) {
                try dist.put(adj.node, alt);
                try prev.put(adj.node, val);
            }
        }
    }

    var seq = std.ArrayList(Node).init(allocator);
    defer seq.deinit();
    var u: ?Node = Node{ .point = Point{ .x = 12, .y = 12 }, .dir = Direction.r, .step = 0 };
    while (u) |uu| {
        try seq.append(uu);
        u = prev.get(uu);
    }

    var it = prev.iterator();
    while (it.next()) |kv| {
        std.debug.print("{} -> {}\n", .{ kv.key_ptr.*, kv.value_ptr.* });
    }
    // for (seq.items) |s| {
    //     std.debug.print("{}\n", .{s});
    // }
}

test "parse test case" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const edges = parse(allocator, TEST_CASE) catch unreachable;

    var it = edges.iterator();
    while (it.next()) |kv| {
        std.debug.print("{}:\n", .{kv.key_ptr.*});
        for (kv.value_ptr.*.items) |val| {
            std.debug.print("   {}\n", .{val});
        }
    }

    dijkstra(allocator, &edges) catch unreachable;
}

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;
        _ = allocator;
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;
        _ = allocator;
    }
};

pub fn main() !void {
    try runDay(Day, 0);
}
