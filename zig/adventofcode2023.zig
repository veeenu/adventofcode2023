const std = @import("std");
const http = std.http;
const util = @import("util.zig");

fn readFile(allocator: std.mem.Allocator, filePath: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(filePath, .{});
    defer file.close();

    const fileSize = (try file.stat()).size;
    const buf = try allocator.alloc(u8, fileSize);
    _ = try file.reader().readAll(buf);

    return buf;
}

fn writeFile(filePath: []const u8, content: []const u8) !void {
    const file = try std.fs.cwd().createFile(filePath, .{});
    defer file.close();

    try file.writer().writeAll(content);
}

fn readCookie(allocator: std.mem.Allocator) ![]const u8 {
    return try readFile(allocator, ".cookie");
}

fn readInput(allocator: std.mem.Allocator, day: u32) ![]const u8 {
    const inputPath = try std.fmt.allocPrint(allocator, "input/day{}.txt", .{day});
    defer allocator.free(inputPath);

    return try readFile(allocator, inputPath);
}

fn downloadInput(allocator: std.mem.Allocator, day: u32) ![]const u8 {
    std.debug.print("Downloading day {}...\n", .{day});
    const cookie = try readCookie(allocator);
    defer allocator.free(cookie);

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();

    const uriString = try std.fmt.allocPrint(allocator, "https://adventofcode.com/2023/day/{}/input", .{day});
    defer allocator.free(uriString);

    const uri = std.Uri.parse(uriString) catch unreachable;

    var headers = std.http.Headers{ .allocator = allocator };
    defer headers.deinit();

    try headers.append("Cookie", cookie);

    var request = try client.open(.GET, uri, headers, .{});
    defer request.deinit();
    try request.send(.{});
    try request.wait();

    const body = request.reader().readAllAlloc(allocator, 65536) catch unreachable;

    const inputPath = try std.fmt.allocPrint(allocator, "input/day{}.txt", .{day});
    defer allocator.free(inputPath);

    try writeFile(inputPath, body);

    return body;
}

pub fn getInput(allocator: std.mem.Allocator, day: u32) ![]const u8 {
    if (readInput(allocator, day)) |content| {
        return content;
    } else |_| {
        return try downloadInput(allocator, day);
    }
}

fn getCurrentDay() !u8 {
    const now = std.time.now().toTimezone(std.time.utc);
    const local_date = std.time.localtime(now.unix);
    return @intCast(local_date.monthday);
}

fn parseDay(input: []const u8) !u8 {
    const parsedDay = try std.fmt.parseInt(u8, input, 10);
    if (parsedDay < 1 or parsedDay > 25) {
        return std.errors.InvalidData;
    }
    return parsedDay;
}

pub const DayFunctions = struct {
    run1: *const fn (*std.mem.Allocator, []const u8) i64,
    run2: *const fn (*std.mem.Allocator, []const u8) i64,
};

pub fn runDay(comptime day_functions: type, day: u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const input_full = try getInput(allocator, day);
    defer allocator.free(input_full);
    const input = util.trimString(input_full);

    std.debug.print("\x1b[32mPart 1\x1b[0m:\x1b[33m {}\x1b[0m\n", .{day_functions.run1(allocator, input)});
    std.debug.print("\x1b[32mPart 2\x1b[0m:\x1b[33m {}\x1b[0m\n", .{day_functions.run2(allocator, input)});
}
