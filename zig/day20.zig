const std = @import("std");
const runDay = @import("adventofcode2023.zig").runDay;

const Allocator = std.mem.Allocator;

const TEST_CASE =
    \\broadcaster -> a, b, c
    \\%a -> b
    \\%b -> c
    \\%c -> inv
    \\&inv -> a
;

const TEST_CASE2 =
    \\broadcaster -> a
    \\%a -> inv, con
    \\&inv -> b
    \\%b -> con
    \\&con -> output
;

const Pulse = enum { high, low };
const ModuleKind = enum { Broadcast, FlipFlop, Conjunction, Untyped };
const ModuleBroadcast = struct {
    outputs: std.ArrayList([]const u8),

    fn receive(self: *ModuleBroadcast, pulse: Pulse, source: []const u8, modules: *ModuleMap) void {
        _ = source;

        for (self.*.outputs.items) |output| {
            modules.send(output, pulse, "broadcaster");
        }
    }

    fn print(self: *const ModuleBroadcast) !void {
        _ = self;
    }
};

const ModuleUntyped = struct {
    name: []const u8,

    fn receive(self: *ModuleUntyped, pulse: Pulse, source: []const u8, modules: *ModuleMap) void {
        _ = modules;
        std.debug.print("{s}: Received {} from {s}\n", .{ self.*.name, pulse, source });
    }

    fn print(self: *const ModuleUntyped) !void {
        _ = self;
    }
};

const ModuleFlipFlop = struct {
    name: []const u8,
    state: bool,
    outputs: std.ArrayList([]const u8),

    fn new(name: []const u8, outputs: std.ArrayList([]const u8)) ModuleFlipFlop {
        return ModuleFlipFlop{ .name = name, .state = false, .outputs = outputs };
    }

    fn receive(self: *ModuleFlipFlop, pulse: Pulse, source: []const u8, modules: *ModuleMap) void {
        _ = source;

        if (pulse == Pulse.high) {
            return;
        }

        self.state = !self.state;
        const next_pulse = switch (self.state) {
            true => Pulse.high,
            false => Pulse.low,
        };

        for (self.*.outputs.items) |output| {
            modules.send(output, next_pulse, self.*.name);
        }
    }

    fn print(self: *const ModuleFlipFlop) !void {
        std.debug.print("state={}", .{self.*.state});
    }

    fn deinit(self: Module) void {
        self.outputs.deinit();
    }
};

const ModuleConjunction = struct {
    name: []const u8,
    inputs: std.StringHashMap(Pulse),
    outputs: std.ArrayList([]const u8),

    fn new(allocator: Allocator, name: []const u8, outputs: std.ArrayList([]const u8)) !ModuleConjunction {
        const inputs = std.StringHashMap(Pulse).init(allocator);

        return ModuleConjunction{ .name = name, .inputs = inputs, .outputs = outputs };
    }

    fn receive(self: *ModuleConjunction, pulse: Pulse, source: []const u8, modules: *ModuleMap) void {
        self.*.inputs.put(source, pulse) catch unreachable;

        var all_high = true;
        var it = self.*.inputs.valueIterator();
        while (it.next()) |val| {
            all_high = all_high and (val.* == Pulse.high);
        }

        const next_pulse = switch (all_high) {
            true => Pulse.low,
            false => Pulse.high,
        };

        for (self.*.outputs.items) |output| {
            modules.send(output, next_pulse, self.*.name);
        }
    }

    fn print(self: *const ModuleConjunction) !void {
        std.debug.print("inputs=(", .{});
        var it = self.*.inputs.iterator();
        while (it.next()) |kv| {
            std.debug.print("{s}={}, ", .{ kv.key_ptr.*, kv.value_ptr.* });
        }
        std.debug.print(")", .{});
    }

    fn deinit(self: Module) void {
        self.inputs.deinit();
        self.outputs.deinit();
    }
};

const Module = union(ModuleKind) {
    Broadcast: ModuleBroadcast,
    FlipFlop: ModuleFlipFlop,
    Conjunction: ModuleConjunction,
    Untyped: ModuleUntyped,

    fn new_untyped(m_name: []const u8) Module {
        return Module{ .Untyped = ModuleUntyped{ .name = m_name } };
    }

    fn parse(allocator: Allocator, input: []const u8) !Module {
        var it = std.mem.split(u8, input, " -> ");
        var m_name = it.next().?;

        var m_outputs = std.ArrayList([]const u8).init(allocator);
        var it_outputs = std.mem.split(u8, it.next().?, ", ");
        while (it_outputs.next()) |o| {
            try m_outputs.append(o);
        }

        switch (m_name[0]) {
            '%' => return Module{ .FlipFlop = ModuleFlipFlop.new(m_name[1..], m_outputs) },
            '&' => return Module{ .Conjunction = try ModuleConjunction.new(allocator, m_name[1..], m_outputs) },
            else => if (std.mem.eql(u8, m_name, "broadcaster")) {
                return Module{ .Broadcast = ModuleBroadcast{ .outputs = m_outputs } };
            } else {
                return Module{ .Untyped = ModuleUntyped{ .name = m_name } };
            },
        }
    }

    fn name(self: *const Module) []const u8 {
        return switch (self.*) {
            .Broadcast => |_| "broadcaster",
            .Untyped => |m| m.name,
            .FlipFlop => |m| m.name,
            .Conjunction => |m| m.name,
        };
    }

    fn outputs(self: *const Module) [][]const u8 {
        return switch (self.*) {
            .Broadcast => |m| m.outputs.items,
            .Untyped => |_| &[_][]const u8{},
            .FlipFlop => |m| m.outputs.items,
            .Conjunction => |m| m.outputs.items,
        };
    }

    fn print(self: *const Module) void {
        std.debug.print("{}({s}) -> ", .{ @as(ModuleKind, self.*), self.*.name() });
        for (self.*.outputs()) |item| {
            std.debug.print("{s}, ", .{item});
        }
        try switch (self.*) {
            .Broadcast => |m| m.print(),
            .Untyped => |m| m.print(),
            .FlipFlop => |m| m.print(),
            .Conjunction => |m| m.print(),
        };
        std.debug.print("\n", .{});
    }

    fn receive(self: *Module, pulse: Pulse, source: []const u8, modules: *ModuleMap) void {
        switch (self.*) {
            .FlipFlop => |*m| m.receive(pulse, source, modules),
            .Conjunction => |*m| m.receive(pulse, source, modules),
            .Broadcast => |*m| m.receive(pulse, source, modules),
            .Untyped => |*m| m.receive(pulse, source, modules),
        }
        modules.flush();
    }
};

const SentPulse = struct {
    output: []const u8,
    pulse: Pulse,
    source: []const u8,
};

const ModuleMap = struct {
    allocator: Allocator,
    modules: std.StringHashMap(Module),
    queue: std.ArrayList(SentPulse),
    count_low: usize = 0,
    count_high: usize = 0,

    fn new(allocator: Allocator) ModuleMap {
        return ModuleMap{ .allocator = allocator, .modules = std.StringHashMap(Module).init(allocator), .queue = std.ArrayList(SentPulse).init(allocator) };
    }

    fn parse(allocator: Allocator, input: []const u8) !ModuleMap {
        var self = ModuleMap.new(allocator);
        var it = std.mem.split(u8, input, "\n");
        while (it.next()) |row| {
            const module = try Module.parse(allocator, row);
            try self.modules.put(module.name(), module);
        }

        return self;
    }

    fn send(self: *ModuleMap, output: []const u8, pulse: Pulse, source: []const u8) void {
        std.debug.print("{s} -{s}-> {s}\n", .{ source, switch (pulse) {
            .high => "high",
            .low => "low",
        }, output });

        if (pulse == Pulse.high) {
            self.*.count_high += 1;
        } else {
            self.*.count_low += 1;
        }

        self.get(output).?.receive(pulse, source, self);
        self.queue.append(SentPulse{ .output = output, .pulse = pulse, .source = source }) catch unreachable;
    }

    fn flush(self: *ModuleMap) void {
        while (self.*.queue.items.len > 0) {
            var q = self.*.queue;
            defer q.deinit();

            self.*.queue = std.ArrayList(SentPulse).init(self.allocator);

            for (q.items) |sent_pulse| {
                self.get(sent_pulse.output).?.receive(sent_pulse.pulse, sent_pulse.source, self);
            }
        }
    }

    fn get(self: *ModuleMap, name: []const u8) ?*Module {
        if (self.*.modules.getPtr(name)) |module| {
            return module;
        } else {
            self.*.modules.put(name, Module.new_untyped(name)) catch unreachable;
            return self.*.modules.getPtr(name).?;
        }
    }

    fn print(self: *const ModuleMap) void {
        var it = self.*.modules.valueIterator();
        while (it.next()) |module| {
            module.print();
        }
        std.debug.print("{} low and {} high: {}\n", .{ self.*.count_low, self.*.count_high, self.result_value() });
    }

    fn result_value(self: *const ModuleMap) usize {
        return self.*.count_low * self.*.count_high;
    }

    fn deinit(self: ModuleMap) void {
        var it = self.modules.valuesIterator();

        while (it.next()) |module| {
            module.deinit();
        }
        self.modules.deinit();
        self.queue.deinit();
    }
};

test "parse p1" {
    std.testing.refAllDecls(@This());

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    {
        var map = try ModuleMap.parse(allocator, TEST_CASE);
        for (0..1000) |_| {
            map.send("broadcaster", Pulse.low, "button");
            map.flush();
        }
        map.print();
    }
    {
        var map = try ModuleMap.parse(allocator, TEST_CASE2);
        for (0..4) |i| {
            std.debug.print("\n\n --- {}\n\n", .{i});
            map.send("broadcaster", Pulse.low, "button");
            map.flush();
        }
        map.print();
    }
}

const Day = struct {
    pub fn run1(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;
        _ = allocator;

        return 0;
    }

    pub fn run2(allocator: std.mem.Allocator, input: []const u8) u64 {
        _ = input;
        _ = allocator;

        return 0;
    }
};

pub fn main() !void {
    try runDay(Day, 0);
}
