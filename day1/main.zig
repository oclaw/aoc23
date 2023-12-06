const std = @import("std");
const isDigit = std.ascii.isDigit;

const search = struct {
    numbers: [2]u8,
    pos: usize,
    total: usize,

    pub fn init() search {
        return search{
            .numbers = [2]u8{ 0, 0 },
            .pos = 0,
            .total = 0,
        };
    }

    pub fn addDigit(self: *search, digit: u8) void {
        self.numbers[self.pos] = digit;
        if (self.pos < (self.numbers.len - 1)) {
            self.pos += 1;
        }
        self.total += 1;
    }

    pub fn result(self: *search) u32 {
        if (self.total < 2) {
            return self.numbers[0] * 10 + self.numbers[0];
        }
        return self.numbers[0] * 10 + self.numbers[1];
    }
};

pub fn readCalibrationValueV1(line: []const u8) u32 {
    var res = search.init();

    for (line) |char| {
        if (isDigit(char)) {
            res.addDigit(char - '0');
        }
    }

    return res.result();
}

pub fn findDigit(word: []const u8) ?u8 {
    const digits = [10][]const u8{
        "zero",
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
    };

    for (digits, 0..) |digit, i| {
        var idx = std.mem.indexOf(u8, word, digit);
        if (idx != null) {
            return @as(u8, @intCast(i));
        }
    }

    return null;
}

pub fn readCalibrationValueV2(line: []const u8) u32 {
    var res = search.init();

    var windowStart: usize = 0;
    var windowEnd: usize = 0;

    for (line, 0..) |char, i| {
        var digit = findDigit(line[windowStart..windowEnd]);
        if (digit != null) {
            res.addDigit(digit.?);
        }

        if (isDigit(char)) {
            res.addDigit(char - '0');
            windowStart = i + 1;
            windowEnd = i + 1;
            continue;
        }

        windowEnd += 1;
        if (windowEnd - windowStart > 5) { // max length of a digit word is 5
            windowStart += 1;
        }

        digit = findDigit(line[windowStart..windowEnd]);
        if (digit != null) {
            res.addDigit(digit.?);
        }
    }

    return res.result();
}

pub fn calcCalibrationValuesSum(filename: []const u8) !u32 {
    var file = try std.fs.cwd().openFile(filename, .{});
    var reader = file.reader();
    var buf: [1024]u8 = undefined;
    var sum: u32 = 0;
    var end = false;

    while (!end) {
        var stream = std.io.fixedBufferStream(&buf);
        reader.streamUntilDelimiter(stream.writer(), '\n', buf.len) catch |err| switch (err) {
            error.EndOfStream => end = true,
            else => return err,
        };

        sum += readCalibrationValueV2(stream.getWritten());
    }

    return sum;
}

pub fn main() !void {
    const sum = try calcCalibrationValuesSum("task1.txt");
    try std.io.getStdOut().writer().print("outvalue: {d}\n", .{sum});
}
