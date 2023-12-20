const std = @import("std");
const runDay = @import("adventofcode2023.zig").runDay;

const Allocator = std.mem.Allocator;

const TEST_CASE =
    \\px{a<2006:qkq,m>2090:A,rfg}
    \\pv{a>1716:R,A}
    \\lnx{m>1548:A,A}
    \\rfg{s<537:gd,x>2440:R,A}
    \\qs{s>3448:A,lnx}
    \\qkq{x<1416:A,crn}
    \\crn{x>2662:A,R}
    \\in{s<1351:px,qqz}
    \\qqz{s>2770:qs,m<1801:hdj,R}
    \\gd{a>3333:R,R}
    \\hdj{m>838:A,pv}
    \\
    \\{x=787,m=2655,a=1222,s=2876}
    \\{x=1679,m=44,a=2067,s=496}
    \\{x=2036,m=264,a=79,s=2244}
    \\{x=2461,m=1339,a=466,s=291}
    \\{x=2127,m=1623,a=2188,s=1013}
;

const Field = enum { x, m, a, s };

const Range = struct {
    min_x: i32,
    max_x: i32,
    min_m: i32,
    max_m: i32,
    min_a: i32,
    max_a: i32,
    min_s: i32,
    max_s: i32,

    fn intersect(self: Range, rhs: Range) Range {
        return Range{
            .min_x = @max(self.min_x, rhs.min_x),
            .min_m = @max(self.min_m, rhs.min_m),
            .min_a = @max(self.min_a, rhs.min_a),
            .min_s = @max(self.min_s, rhs.min_s),
            .max_x = @min(self.max_x, rhs.max_x),
            .max_m = @min(self.max_m, rhs.max_m),
            .max_a = @min(self.max_a, rhs.max_a),
            .max_s = @min(self.max_s, rhs.max_s),
        };
    }

    fn count(self: Range) u64 {
        var ret: u64 = 1;
        ret *= @intCast(@max(1, self.max_x - self.min_x + 1));
        ret *= @intCast(@max(1, self.max_m - self.min_m + 1));
        ret *= @intCast(@max(1, self.max_a - self.min_a + 1));
        ret *= @intCast(@max(1, self.max_s - self.min_s + 1));
        return ret;
    }

    fn default() Range {
        return Range{ .min_x = 1, .max_x = 4000, .min_m = 1, .max_m = 4000, .min_a = 1, .max_a = 4000, .min_s = 1, .max_s = 4000 };
    }
};

const Rule = struct {
    field: Field,
    ordering: std.math.Order,
    value: i32,
    dest: []const u8,

    fn asRange(self: Rule) Range {
        const min_val = switch (self.ordering) {
            std.math.Order.lt => 1,
            std.math.Order.gt => self.value + 1,
            else => unreachable,
        };
        const max_val = switch (self.ordering) {
            std.math.Order.lt => self.value - 1,
            std.math.Order.gt => 4000,
            else => unreachable,
        };

        var range = Range.default();

        switch (self.field) {
            .x => {
                range.min_x = min_val;
                range.max_x = max_val;
            },
            .m => {
                range.min_m = min_val;
                range.max_m = max_val;
            },
            .a => {
                range.min_a = min_val;
                range.max_a = max_val;
            },
            .s => {
                range.min_s = min_val;
                range.max_s = max_val;
            },
        }

        return range;
    }

    fn asRangeInv(self: Rule) Range {
        const min_val = switch (self.ordering) {
            std.math.Order.lt => self.value,
            std.math.Order.gt => 1,
            else => unreachable,
        };
        const max_val = switch (self.ordering) {
            std.math.Order.lt => 4000,
            std.math.Order.gt => self.value,
            else => unreachable,
        };

        var range = Range.default();

        switch (self.field) {
            .x => {
                range.min_x = min_val;
                range.max_x = max_val;
            },
            .m => {
                range.min_m = min_val;
                range.max_m = max_val;
            },
            .a => {
                range.min_a = min_val;
                range.max_a = max_val;
            },
            .s => {
                range.min_s = min_val;
                range.max_s = max_val;
            },
        }

        return range;
    }

    fn parse(input: []const u8) Rule {
        var i: usize = 2;
        while (input[i] != ':') : (i += 1) {}

        return Rule{ .field = switch (input[0]) {
            'x' => Field.x,
            'm' => Field.m,
            'a' => Field.a,
            's' => Field.s,
            else => unreachable,
        }, .ordering = switch (input[1]) {
            '>' => std.math.Order.gt,
            '<' => std.math.Order.lt,
            else => unreachable,
        }, .value = std.fmt.parseInt(i32, input[2..i], 10) catch unreachable, .dest = input[i + 1 ..] };
    }

    fn check(self: *const Rule, piece: *const Piece) bool {
        const field_val = switch (self.*.field) {
            .x => piece.*.x,
            .m => piece.*.m,
            .a => piece.*.a,
            .s => piece.*.s,
        };

        switch (self.*.ordering) {
            std.math.Order.lt => return field_val < self.*.value,
            std.math.Order.gt => return field_val > self.*.value,
            else => unreachable,
        }
    }
};

const Workflow = struct {
    name: []const u8,
    rules: std.ArrayList(Rule),
    otherwise: []const u8,

    fn parse(allocator: Allocator, input: []const u8) !Workflow {
        var i: usize = 0;
        var j: usize = 0;

        while (input[i] != '{') : (i += 1) {}
        const name = input[0..i];
        i += 1;

        var rules = std.ArrayList(Rule).init(allocator);
        var otherwise: []const u8 = undefined;
        while (true) {
            while (input[j] != ',' and input[j] != '}') : (j += 1) {}
            if (input[j] == '}') {
                otherwise = input[i..j];
                break;
            } else {
                try rules.append(Rule.parse(input[i..j]));
            }
            j += 1;
            i = j;
        }

        return Workflow{ .name = name, .rules = rules, .otherwise = otherwise };
    }

    fn deinit(self: Workflow) void {
        self.rules.deinit();
    }
};

const Workflows = struct {
    workflows: std.StringHashMap(Workflow),
    pieces: std.ArrayList(Piece),

    fn parse(allocator: Allocator, input: []const u8) !Workflows {
        var it = std.mem.split(u8, input, "\n");

        var wf = Workflows{
            .workflows = std.StringHashMap(Workflow).init(allocator),
            .pieces = std.ArrayList(Piece).init(allocator),
        };

        while (it.next()) |row| {
            if (std.mem.eql(u8, row, "")) {
                break;
            }
            const workflow = try Workflow.parse(allocator, row);
            try wf.workflows.put(workflow.name, workflow);
        }

        while (it.next()) |row| {
            const piece = Piece.parse(row);
            try wf.pieces.append(piece);
        }

        return wf;
    }

    fn deinit(self: *Workflows) void {
        self.pieces.deinit();
        var it = self.workflows.valueIterator();
        while (it.next()) |v| {
            v.deinit();
        }
        self.workflows.clearAndFree();
    }

    fn process(self: Workflows, allocator: Allocator) !u64 {
        var accepted = std.ArrayList(Piece).init(allocator);
        defer accepted.deinit();

        pieces: for (self.pieces.items) |piece| {
            var workflow_name: []const u8 = "in";

            loop: while (true) {
                const wf = self.workflows.get(workflow_name).?;

                for (wf.rules.items) |rule| {
                    if (rule.check(&piece)) {
                        if (std.mem.eql(u8, rule.dest, "A")) {
                            try accepted.append(piece);
                            continue :pieces;
                        } else if (std.mem.eql(u8, rule.dest, "R")) {
                            continue :pieces;
                        } else {
                            workflow_name = rule.dest;
                            continue :loop;
                        }
                    }
                }

                if (std.mem.eql(u8, wf.otherwise, "A")) {
                    try accepted.append(piece);
                    continue :pieces;
                } else if (std.mem.eql(u8, wf.otherwise, "R")) {
                    continue :pieces;
                } else {
                    workflow_name = wf.otherwise;
                }
            }
        }

        var sum: i32 = 0;
        for (accepted.items) |piece| {
            sum += piece.x + piece.m + piece.a + piece.s;
        }

        return @intCast(sum);
    }

    fn countRanges(self: Workflows, allocator: Allocator) !u64 {
        const Step = struct {
            range: Range,
            workflow: []const u8,
        };

        var q = std.ArrayList(Step).init(allocator);
        defer q.deinit();

        var i: usize = 0;
        try q.append(Step{ .range = Range.default(), .workflow = "in" });

        var accepted = std.ArrayList(Range).init(allocator);
        defer accepted.deinit();

        while (i < q.items.len) : (i += 1) {
            const step = q.items[i];
            const wf = self.workflows.get(step.workflow).?;
            var range = step.range;
            for (wf.rules.items) |rule| {
                if (std.mem.eql(u8, rule.dest, "A")) {
                    try accepted.append(range.intersect(rule.asRange()));
                } else if (std.mem.eql(u8, rule.dest, "R")) {
                    // reject
                } else {
                    try q.append(Step{ .range = range.intersect(rule.asRange()), .workflow = rule.dest });
                }
                range = range.intersect(rule.asRangeInv());
            }

            if (std.mem.eql(u8, wf.otherwise, "A")) {
                try accepted.append(range);
            } else if (std.mem.eql(u8, wf.otherwise, "R")) {
                // reject
            } else {
                try q.append(Step{ .range = range, .workflow = wf.otherwise });
            }
        }

        var ret: u64 = 0;

        for (accepted.items) |range| {
            ret += range.count();
        }

        return ret;
    }
};

const PieceIterator = struct {
    i: usize,
    j: usize,
    input: []const u8,

    fn next(it: *PieceIterator) ?i32 {
        while (!std.ascii.isDigit(it.*.input[it.*.i])) : (it.*.i += 1) {
            if (it.*.i + 1 >= it.*.input.len) {
                return null;
            }
        }
        it.*.j = it.*.i;
        while (std.ascii.isDigit(it.*.input[it.*.j]) and it.*.j < it.*.input.len) : (it.*.j += 1) {
            if (it.*.j + 1 >= it.*.input.len) {
                return null;
            }
        }

        const val = std.fmt.parseInt(i32, it.*.input[it.*.i..it.*.j], 10) catch unreachable;
        it.*.i = it.*.j;
        return val;
    }
};

const Piece = struct {
    x: i32,
    m: i32,
    a: i32,
    s: i32,

    fn parse(input: []const u8) Piece {
        var piece = Piece{ .x = 0, .m = 0, .a = 0, .s = 0 };

        var it = PieceIterator{ .i = 0, .j = 0, .input = input };
        piece.x = it.next().?;
        piece.m = it.next().?;
        piece.a = it.next().?;
        piece.s = it.next().?;

        return piece;
    }
};

test "parses test case" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const p = Piece.parse("{x=787,m=2655,a=1222,s=2876}");
    try std.testing.expect(std.meta.eql(p, Piece{ .x = 787, .m = 2655, .a = 1222, .s = 2876 }));

    const w = try Workflow.parse(allocator, "px{a<2006:qkq,m>2090:A,rfg}");
    std.debug.print("{}\n", .{w});

    const wf = try Workflows.parse(allocator, TEST_CASE);
    std.debug.print("{}\n", .{wf});

    try std.testing.expect(try wf.process(allocator) == 19114);
}

test "part 2" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const wf = try Workflows.parse(allocator, TEST_CASE);
    std.debug.print("{}\n", .{wf});
    std.debug.print("{}\n", .{try wf.countRanges(allocator)});
}

const Input = struct {
    workflows: Workflows,
    pieces: std.ArrayList(Piece),
};

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        var wf = Workflows.parse(allocator, input) catch unreachable;
        defer wf.deinit();

        return wf.process(allocator) catch unreachable;
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        var wf = Workflows.parse(allocator, input) catch unreachable;
        defer wf.deinit();

        return wf.countRanges(allocator) catch unreachable;
    }
};

pub fn main() !void {
    try runDay(Day, 19);
}
