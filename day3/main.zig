const std = @import("std");
const isDigit = std.ascii.isDigit;

// why 140 rows is not enough?
const matrix = [141][141]u8;

const point = struct {
    X: usize,
    Y: usize,
};

const gearAttrs = struct {
    partCnt: u32,
    ratio: u64,
};

const gearMap = std.hash_map.AutoHashMap(point, gearAttrs);

// how to avoid anytype?
fn sumPartNumbers(mtx: matrix, map: anytype) u32 {
    var sum: u32 = 0;
    for (0..mtx.len) |i| {
        var acc: u32 = 0;
        var xStart: usize = 0;
        var readingNumber = false;

        for (0..mtx[i].len) |j| {
            if (isDigit(mtx[i][j])) {
                if (!readingNumber) {
                    readingNumber = true;
                    xStart = j;
                }
                acc = acc * 10 + (mtx[i][j] - '0');
            } else {
                if (readingNumber) {
                    readingNumber = false;
                    var isPart = isPartNumber(mtx, map, acc, xStart, j, i);
                    std.debug.print("line {}: {}-{} (val {}) isPart: {}\n", .{ i, xStart, j, acc, isPart });
                    if (isPart) {
                        sum += acc;
                    }
                    acc = 0;
                    xStart = 0;
                }
            }
        }
        std.debug.print("\n", .{});
    }
    return sum;
}

fn isPartNumber(mtx: matrix, map: anytype, num: u32, xStart: usize, xEnd: usize, y: usize) bool {
    var _xStart = if (xStart > 0) xStart - 1 else 0;
    var _xEnd = if (xEnd < mtx[y].len) xEnd + 1 else mtx[y].len;
    var _yStart = if (y > 0) y - 1 else 0;
    var _yEnd = if (y + 1 < mtx.len) y + 2 else mtx.len;

    var isPart = false;
    for (_yStart.._yEnd) |i| {
        for (_xStart.._xEnd) |j| {
            var c = mtx[i][j];
            std.debug.print("  {}-{}: {c}\n", .{ i, j, c });
            if (c != '.' and !isDigit(c)) {
                isPart = true;
                if (c == '*') {
                    var value = map.get(point{ .X = j, .Y = i });
                    var updated = if (value != null) value.? else gearAttrs{ .partCnt = 0, .ratio = 1 };
                    updated.partCnt += 1;
                    updated.ratio *= num;
                    map.put(point{ .X = j, .Y = i }, updated) catch unreachable;
                }
            }
        }
    }
    return isPart;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("task3.txt", .{});
    var reader = file.reader();

    var end = false;
    var buf: matrix = undefined;
    for (0..buf.len) |i| {
        for (0..buf[i].len) |j| {
            buf[i][j] = '.';
        }
    }

    var row: usize = 0;
    while (!end) {
        var stream = std.io.fixedBufferStream(&buf[row]);
        reader.streamUntilDelimiter(stream.writer(), '\n', buf.len) catch |err| switch (err) {
            error.EndOfStream => end = true,
            else => return err,
        };

        row += 1;
    }

    var map = gearMap.init(std.heap.page_allocator);
    defer map.deinit();

    var result = sumPartNumbers(buf, &map);

    var iter = map.iterator();
    var gearRatioSum: u64 = 0;
    while (true) {
        var item = iter.next();
        if (item == null) break;
        var val = item.?.value_ptr.*;
        if (val.partCnt == 2) {
            gearRatioSum += val.ratio;
        }
    }
    std.debug.print("Result: {} GearRatio: {}\n", .{ result, gearRatioSum });
}
