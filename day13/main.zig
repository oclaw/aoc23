const std = @import("std");

// const data = @embedFile("sample.txt");
const data = @embedFile("task13.txt");

const orientation = enum {
    vertical,
    horizontal,
};

const reflectionParams = struct {
    orientation: orientation,
    coord: usize,

    pub fn toResult(self: *const reflectionParams) usize {
        return switch (self.orientation) {
            orientation.horizontal => (self.coord + 1) * 100,
            orientation.vertical => self.coord + 1,
        };
    }
};

fn findReflection(mtx: []const []const u8, allowedDiffs: usize) reflectionParams {
    // look for horizontal reflection
    outer: for (0..mtx.len - 1) |i| {
        var possibleReflectionSize = @min(i + 1, mtx.len - i - 1);
        var upIter: isize = @intCast(i);
        var downIter = i + 1;

        // std.debug.print("h_check i: {}, possibleReflectionSize: {}\n", .{ i, possibleReflectionSize });

        var diff: usize = 0;
        for (0..possibleReflectionSize) |_| {
            for (0..mtx[i].len) |j| {
                if (mtx[@intCast(upIter)][j] != mtx[downIter][j]) {
                    diff += 1;
                }
            }
            // std.debug.print("h_diff: {}\n", .{diff});
            if (diff > allowedDiffs) {
                continue :outer;
            }
            upIter -= 1;
            downIter += 1;
        }
        if (diff == allowedDiffs) {
            return reflectionParams{
                .orientation = orientation.horizontal,
                .coord = i,
            };
        }
    }

    const aux = struct {
        fn countDiffsInColumns(_mtx: []const []const u8, i: usize, j: usize) usize {
            var res: usize = 0;
            for (_mtx) |row| {
                if (row[i] != row[j]) {
                    res += 1;
                }
            }
            return res;
        }
    };

    // look for vertical reflection
    var cols = mtx[0].len;
    outer: for (0..cols - 1) |i| {
        var possibleReflectionSize = @min(i + 1, cols - i - 1);
        var leftIter: isize = @intCast(i);
        var rightIter = i + 1;

        // std.debug.print("v_check i: {}, possibleReflectionSize: {}\n", .{ i, possibleReflectionSize });

        var diff: usize = 0;
        for (0..possibleReflectionSize) |_| {
            diff += aux.countDiffsInColumns(mtx, @intCast(leftIter), rightIter);
            // std.debug.print("v_diff: {}\n", .{diff});
            if (diff > allowedDiffs) {
                continue :outer;
            }
            leftIter -= 1;
            rightIter += 1;
        }

        if (diff == allowedDiffs) {
            return reflectionParams{
                .orientation = orientation.vertical,
                .coord = i,
            };
        }
    }

    @panic("No reflection found");
}

pub fn main() !void {
    var iter = std.mem.splitScalar(u8, data, '\n');
    var mtx: [100][]const u8 = undefined;
    var i: usize = 0;
    var part1: usize = 0;
    var part2: usize = 0;
    var samplenum: usize = 0;

    var diffsum: usize = 0;
    _ = diffsum;

    while (iter.next()) |line| {
        if (line.len > 0) {
            mtx[i] = line;
            i += 1;
            continue;
        }
        if (i == 0) {
            continue;
        }

        part1 += findReflection(mtx[0..i], 0).toResult();
        part2 += findReflection(mtx[0..i], 1).toResult();

        std.debug.print("\n", .{});
        i = 0;
        samplenum += 1;
    }
    part1 += findReflection(mtx[0..i], 0).toResult();
    part2 += findReflection(mtx[0..i], 1).toResult();

    std.debug.print("part 1: {} part 2: {}\n", .{ part1, part2 });
}

test "sample 1" {
    const mtx = [_][]const u8{
        "#...##..#",
        "#....#..#",
        "..##..###",
        "#####.##.",
        "#####.##.",
        "..##..###",
        "#....#..#",
    };

    const params = findReflection(&mtx, 0);
    try std.testing.expectEqual(orientation.horizontal, params.orientation);
    try std.testing.expectEqual(@as(usize, 3), params.coord);

    std.debug.print("part 2\n", .{});

    const params2 = findReflection(&mtx, 1);
    try std.testing.expectEqual(orientation.horizontal, params2.orientation);
    try std.testing.expectEqual(@as(usize, 0), params2.coord);
}

test "sample 2" {
    const mtx = [_][]const u8{
        "#.##..##.",
        "..#.##.#.",
        "##......#",
        "##......#",
        "..#.##.#.",
        "..##..##.",
        "#.#.##.#.",
    };

    const params = findReflection(&mtx, 0);
    try std.testing.expectEqual(orientation.vertical, params.orientation);
    try std.testing.expectEqual(@as(usize, 4), params.coord);

    std.debug.print("part 2\n", .{});

    const params2 = findReflection(&mtx, 1);
    try std.testing.expectEqual(orientation.horizontal, params2.orientation);
    try std.testing.expectEqual(@as(usize, 2), params2.coord);
}
