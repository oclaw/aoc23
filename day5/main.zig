const std = @import("std");

const data = @embedFile("task5.txt");
// const data = @embedFile("sample.txt");

const RangeError = error{OutOfRange};

const Range = struct {
    source_start: u32,
    dest_start: u32,
    length: u32,

    pub fn dest_by_source(self: *const Range, source: u32) RangeError!u32 {
        if (self.source_start > source) {
            return RangeError.OutOfRange;
        }
        var distance = source - self.source_start;
        if (distance >= self.length) {
            return RangeError.OutOfRange;
        }

        return self.dest_start + distance;
    }
};

fn readSeedLine(line: []const u8, buf: []u32) ![]u32 {
    var idx: usize = 0;
    var iter = std.mem.splitScalar(u8, line, ' ');
    _ = iter.next(); // skip the first 'seeds:' part

    while (iter.next()) |part| {
        buf[idx] = try std.fmt.parseInt(u32, part, 10);
        idx += 1;
    }
    return buf[0..idx];
}

const RangeCount = 7;

const taskData = struct {
    ranges: [RangeCount][100]Range = undefined,
    rangesCount: [RangeCount]usize = [_]usize{0} ** RangeCount,

    pub fn add_range(self: *taskData, rangeKind: usize, range: Range) void {
        self.ranges[rangeKind][self.rangesCount[rangeKind]] = range;
        self.rangesCount[rangeKind] += 1;
    }

    pub fn processSeed(self: *const taskData, seed: u32) !u32 {
        var source = seed;
        inline for (self.ranges, 0..) |rangeKind, i| {
            source = for (rangeKind[0..self.rangesCount[i]]) |range| {
                break range.dest_by_source(source) catch continue;
            } orelse return RangeError.OutOfRange;
        }
        return source;
    }
};

pub fn main() !void {
    var lines = std.mem.splitScalar(u8, data, '\n');
    var seedBuf: [100]u32 = undefined;
    var seeds = try readSeedLine(lines.first(), &seedBuf);

    var curRangeKind: usize = 0;
    var task = taskData{};

    // parse ranges
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, "map") != null and
            (curRangeKind != 0 or task.rangesCount[curRangeKind] != 0)) // hack for the first range detection
        {
            curRangeKind += 1;
        }
        if (line.len == 0 or !std.ascii.isDigit(line[0])) {
            continue;
        }

        var iter = std.mem.splitScalar(u8, line, ' ');
        var range = Range{
            .dest_start = try std.fmt.parseInt(u32, iter.next().?, 10),
            .source_start = try std.fmt.parseInt(u32, iter.next().?, 10),
            .length = try std.fmt.parseInt(u32, iter.next().?, 10),
        };
        task.add_range(curRangeKind, range);
    }

    // part 1
    var minSeedLocation: usize = 0xFFFFFFFF;
    for (seeds) |seed| {
        var location = try task.processSeed(seed);
        minSeedLocation = @min(minSeedLocation, location);
    }

    // part 2
    var minRangeSeedLocation: usize = 0xFFFFFFFF;
    for (0..seeds.len / 2) |i| {
        var rangeStart = seeds[i * 2];
        var rangeLen = seeds[i * 2 + 1];

        var loc1 = try task.processSeed(rangeStart);
        var loc2 = try task.processSeed(rangeStart + rangeLen - 1);

        if (loc2 > loc1 and loc2 - loc1 == rangeLen - 1) {
            std.debug.print("seed range {} is monotonic, no need to full scan\n", .{i});
            minRangeSeedLocation = @min(minRangeSeedLocation, loc1);
            continue;
        }

        std.debug.print("non-monotonic range {}, try interpolation search\n", .{i});

        var base: usize = rangeStart;
        var baseLoc = loc1;
        var cur: usize = base + 1;
        var step: usize = 1;
        var lastCalculatedLoc = baseLoc;
        while (cur < rangeStart + rangeLen) {
            var loc = try task.processSeed(@as(u32, @intCast(cur)));

            var monotonic = loc > baseLoc and loc - baseLoc == cur - base;
            if (monotonic) {
                step *= 2;
            } else {
                if (step == 1 and loc < baseLoc) {
                    std.debug.print("found new local extremum at {} ({})\n", .{ cur, loc });
                    step *= 2;
                } else {
                    std.debug.print("detected local extremum, reset search pos {} --> {}, step {} --> 1) \n", .{ cur, cur - step, step });

                    baseLoc = lastCalculatedLoc;
                    base = cur - step;
                    cur -= step;

                    step = 1;
                }
            }
            cur += step;

            if (minRangeSeedLocation > loc) {
                std.debug.print("updated global extremum pos: {} ({})\n", .{ cur, loc });
                minRangeSeedLocation = loc;
            }

            lastCalculatedLoc = loc;
        }
    }

    std.debug.print("part 1: {} part 2: {}\n", .{ minSeedLocation, minRangeSeedLocation });
}
