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
