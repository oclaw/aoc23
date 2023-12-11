const std = @import("std");
const assert = std.debug.assert;

const sample = .{
    .data = @embedFile("sample.txt"),
    .len = 6,
};

const task = .{
    .data = @embedFile("task9.txt"),
    .len = 21,
};

// T is expected to be any integer type
// overflow is not checked
fn sum(comptime T: type, arr: []const T) T {
    var res: T = 0;
    for (arr) |elem| {
        res += elem;
    }
    return res;
}

fn extrapolate_line(comptime size: usize, numbers: [size]i32) i32 {
    var temp = numbers;
    var prev = std.mem.zeroes([size + 1]i32);

    var depth: usize = 0;
    while (!std.mem.allEqual(i32, temp[0 .. size - depth], 0)) : (depth += 1) {
        assert(size - depth > 1);
        prev[depth] = temp[size - depth - 1];
        var new = temp;
        for (0..size - depth - 1) |i| {
            new[i] = temp[i + 1] - temp[i];
        }
        temp = new;
    }

    return sum(i32, prev[0..depth]);
}

fn extrapolate_line_reversed(comptime size: usize, numbers: [size]i32) i32 {
    var temp = numbers;
    for (0..size) |i| {
        temp[i] = numbers[size - i - 1];
    }
    return extrapolate_line(size, temp);
}

pub fn main() !void {
    const task_params = task;

    var line_iter = std.mem.splitScalar(u8, task_params.data, '\n');
    var numbuf = std.mem.zeroes([200][21]i32);
    var linecount: usize = 0;
    while (line_iter.next()) |line| {
        var num_iter = std.mem.splitScalar(u8, line, ' ');
        var count: usize = 0;

        while (num_iter.next()) |num| {
            numbuf[linecount][count] = try std.fmt.parseInt(i32, num, 10);
            count += 1;
        }
        linecount += 1;
    }
    var nums = numbuf[0..linecount];

    var res: i32 = 0;
    var res_reversed: i32 = 0;
    for (nums) |numline| {
        res += extrapolate_line(task_params.len, numline[0..task_params.len].*);
        res_reversed += extrapolate_line_reversed(task_params.len, numline[0..task_params.len].*);
    }

    std.debug.print("part 1: {} part 2: {}\n", .{ res, res_reversed });
}
