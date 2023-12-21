const std = @import("std");

pub fn trimString(str: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = str.len;

    while (start < end and std.ascii.isWhitespace(str[start])) : (start += 1) {}
    while (end > start and std.ascii.isWhitespace(str[end - 1])) : (end -= 1) {}

    return str[start..end];
}

pub const Grid = struct {
    string: []const u8,
    cols: usize,
    rows: usize,

    pub fn new(string: []const u8) Grid {
        var n_cols: usize = 0;
        var n_rows: usize = 2;
        while (string[n_cols] != '\n') : (n_cols += 1) {}
        for (string[n_cols + 1 ..]) |c| {
            if (c == '\n') {
                n_rows += 1;
            }
        }

        return Grid{
            .string = string,
            .cols = n_cols,
            .rows = n_rows,
        };
    }

    pub fn find(self: *const Grid, comptime pred: fn (u8, usize, usize) bool) ?Point {
        for (0..self.rows) |y| {
            for (0..self.cols) |x| {
                if (pred(self.get(x, y) orelse return null, x, y)) {
                    return Point{ .x = @intCast(x), .y = @intCast(y) };
                }
            }
        }
        return null;
    }

    pub fn get(self: *const Grid, x: usize, y: usize) ?u8 {
        if (x >= self.cols or y >= self.rows) {
            return null;
        }
        return self.string[y * (self.cols + 1) + x];
    }
};

pub const Point = struct {
    x: isize,
    y: isize,
};

pub fn Queue(comptime Child: type) type {
    return struct {
        const Node = struct {
            data: Child,
            next: ?*Node,
        };
        allocator: std.mem.Allocator,
        start: ?*Node,
        end: ?*Node,

        pub fn init(allocator: std.mem.Allocator) Queue(Child) {
            return Queue(Child){
                .allocator = allocator,
                .start = null,
                .end = null,
            };
        }

        pub fn enqueue(self: *Queue(Child), value: Child) !void {
            const node = try self.allocator.create(Node);
            node.* = Node{ .data = value, .next = null };
            if (self.end) |end| {
                end.next = node;
            } else {
                self.start = node;
            }
            self.end = node;
        }

        pub fn dequeue(self: *Queue(Child)) ?Child {
            const start = self.start orelse return null;
            defer self.allocator.destroy(start);
            self.start = start.next;
            if (self.start == null) self.end = null;
            return start.data;
        }

        pub fn deinit(self: *Queue(Child)) void {
            while (self.start) {
                _ = self.dequeue();
            }
        }
    };
}
