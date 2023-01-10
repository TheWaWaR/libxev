const std = @import("std");
const Instant = std.time.Instant;
const xev = @import("xev");

pub const NUM_TIMERS: usize = 10 * 1000 * 1000;

pub fn main() !void {
    var loop = try xev.Loop.init(std.math.pow(u13, 2, 12));
    defer loop.deinit();

    const GPA = std.heap.GeneralPurposeAllocator(.{});
    var gpa: GPA = .{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var cs = try alloc.alloc(xev.Loop.Completion, NUM_TIMERS);
    defer alloc.free(cs);

    const before_all = try Instant.now();
    var i: usize = 0;
    var timeout: u64 = 1;
    while (i < NUM_TIMERS) : (i += 1) {
        if (i % 1000 == 0) timeout += 1;
        const timer = try xev.Timer.init();
        timer.run(&loop, &cs[i], timeout, void, null, timerCallback);
    }

    const before_run = try Instant.now();
    try loop.run(.until_done);
    const after_run = try Instant.now();
    const after_all = try Instant.now();

    std.log.info("{d:.2} seconds total", .{@intToFloat(f64, after_all.since(before_all)) / 1e9});
    std.log.info("{d:.2} seconds init", .{@intToFloat(f64, before_run.since(before_all)) / 1e9});
    std.log.info("{d:.2} seconds dispatch", .{@intToFloat(f64, after_run.since(before_run)) / 1e9});
    std.log.info("{d:.2} seconds cleanup", .{@intToFloat(f64, after_all.since(after_run)) / 1e9});
}

pub const log_level: std.log.Level = .info;

var timer_callback_count: usize = 0;

fn timerCallback(_: ?*void, c: *xev.Loop.Completion, result: xev.Timer.RunError!void) void {
    _ = c;
    _ = result catch unreachable;
    timer_callback_count += 1;
}
