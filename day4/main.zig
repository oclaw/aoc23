const std = @import("std");
const isDigit = std.ascii.isDigit;

const digitOrEOFTag = enum {
    value,
    eof,
};

const digitOrEOF = union(digitOrEOFTag) {
    value: u8,
    eof: bool,
};

const EOF = digitOrEOF{ .eof = true };

pub fn readNextDigit(reader: anytype) !digitOrEOF {
    var readingNumber = false;
    var acc: u8 = 0;

    while (true) {
        var byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => return if (acc > 0) digitOrEOF{ .value = acc } else EOF,
            else => return err,
        };

        switch (byte) {
            '0'...'9' => {
                readingNumber = true;
                acc = (acc * 10) + (byte - '0');
            },
            '|' => return EOF,
            else => if (readingNumber) {
                return digitOrEOF{ .value = acc };
            },
        }
    }
}

pub fn skipHeader(reader: anytype) !void {
    var byte: u8 = undefined;
    const stop = ':';

    while (byte != stop) {
        byte = try reader.readByte();
    }
}

pub fn readWinMap(reader: anytype, winmap: *[0xFF]bool) !void {
    while (true) {
        var read = try readNextDigit(reader);
        switch (read) {
            .value => |v| {
                winmap[v] = true;
            },
            .eof => return,
        }
    }
}

pub fn countPointsAndAddCopies(reader: anytype, cur: usize, copymap: *[0xFF]u32) !u32 {
    try skipHeader(reader);

    var winmap = [_]bool{false} ** 0xFF;
    try readWinMap(reader, &winmap);

    // part 1
    var points: u32 = 0;

    // part 2
    var currentCopy = cur + 1;
    var weight = copymap[cur];

    while (true) {
        var read = try readNextDigit(reader);
        switch (read) {
            .value => |v| {
                if (winmap[v]) {
                    // part 1
                    points = @max(1, points << 1);

                    // part 2
                    copymap[currentCopy] += weight;
                    currentCopy += 1;
                }
            },
            .eof => return points,
        }
    }
}

pub fn main() !void {
    var f = try std.fs.cwd().openFile("task4.txt", .{});
    defer f.close();

    var buf: [1024]u8 = undefined;
    var copymap = [_]u32{1} ** 0xFF;

    var pointSum: u32 = 0;
    var cardSum: u32 = 0;

    var cur: u32 = 0;
    var end = false;

    var reader = f.reader();
    while (!end) {
        var stream = std.io.fixedBufferStream(&buf);
        reader.streamUntilDelimiter(stream.writer(), '\n', buf.len) catch |err| switch (err) {
            error.EndOfStream => end = true,
            else => return err,
        };

        try stream.seekTo(0);
        pointSum += try countPointsAndAddCopies(stream.reader(), cur, &copymap);
        cardSum += copymap[cur];
        cur += 1;
    }

    std.debug.print("points: {} cards: {}\n", .{ pointSum, cardSum });
}
