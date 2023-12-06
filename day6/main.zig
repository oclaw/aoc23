const std = @import("std");

// const data = @embedFile("sample.txt");
const data = @embedFile("task6.txt");

fn read_nums(line: []const u8, buf: []u64) []u64 {
    var iter = std.mem.splitScalar(u8, line, ' ');
    var i: u64 = 0;
    while (iter.next()) |num| {
        buf[i] = std.fmt.parseInt(u64, num, 10) catch continue;
        i += 1;
    }
    return buf[0..i];
}

// part2
fn merge_nums_to_u64(nums: []u64) u64 {
    var result: u64 = 0;
    for (nums) |num| {
        var power: u32 = 0;
        var num_copy = num;
        while (num_copy > 0) {
            num_copy /= 10;
            power += 1;
        }
        for (0..power) |_| {
            result = result * 10;
        }
        result += num;
    }
    return result;
}

// soluttion is based on quadratic equation ax^2 + bx + c = 0
// a = 1
// b = -time
// c = min_dist
fn countWinningCombinations(time: u64, min_dist: u64) u64 {
    var b = -@as(i64, @intCast(time));
    var c = @as(i64, @intCast(min_dist));
    var d = b * b - 4 * c;

    var x = (-b - std.math.sqrt(@as(u64, @intCast(d)))); // lefr root is enough
    x = @divFloor(x, 2);

    if (x * (-b - x) <= c) {
        x += 1;
    }

    return time - @as(u64, @intCast(x)) * 2 + 1;
}

pub fn main() !void {
    var iter = std.mem.splitScalar(u8, data, '\n');
    var timebuf: [100]u64 = undefined;
    var distbuf: [100]u64 = undefined;

    var times = read_nums(iter.first(), &timebuf);
    var distances = read_nums(iter.next().?, &distbuf);

    var part1_result: u64 = 1;
    for (0..times.len) |i| {
        var total = countWinningCombinations(times[i], distances[i]);
        part1_result *= total;
    }

    std.debug.print("part1 result: {}\n", .{part1_result});

    var part2_time = merge_nums_to_u64(times);
    var part2_dist = merge_nums_to_u64(distances);
    var part2_result = countWinningCombinations(part2_time, part2_dist);
    std.debug.print("part2 result: {}\n", .{part2_result});
}
