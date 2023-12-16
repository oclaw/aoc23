const std = @import("std");

// const data = @embedFile("sample.txt");
const data = @embedFile("task14.txt");

// const MatrixSize = 10;
const MatrixSize = 100;

const map = struct {
    data: [MatrixSize][MatrixSize]u8,

    fn rollNorth(self: *const map) map {
        var rolled = map{
            .data = self.data,
        };

        for (1..rolled.data.len) |row| {
            for (0..rolled.data[row].len) |col| {
                if (rolled.data[row][col] != 'O') {
                    continue;
                }
                var newRow = row;
                while (newRow >= 1 and rolled.data[newRow - 1][col] == '.') {
                    newRow -= 1;
                }
                if (newRow != row) {
                    rolled.data[row][col] = '.';
                    rolled.data[newRow][col] = 'O';
                }
            }
        }

        return rolled;
    }

    fn rollSouth(self: *const map) map {
        var rolled = map{
            .data = self.data,
        };

        for (1..rolled.data.len + 1) |i| {
            var row = rolled.data.len - i;
            for (0..rolled.data[row].len) |col| {
                if (rolled.data[row][col] != 'O') {
                    continue;
                }
                var newRow = row;
                while (newRow < rolled.data.len - 1 and rolled.data[newRow + 1][col] == '.') {
                    newRow += 1;
                }
                if (newRow != row) {
                    rolled.data[row][col] = '.';
                    rolled.data[newRow][col] = 'O';
                }
            }
        }

        return rolled;
    }

    fn rollEast(self: *const map) map {
        var rolled = map{
            .data = self.data,
        };

        for (1..rolled.data[0].len + 1) |i| {
            var col = rolled.data[0].len - i;
            for (0..rolled.data.len) |row| {
                if (rolled.data[row][col] != 'O') {
                    continue;
                }
                var newCol = col;
                while (newCol < rolled.data[row].len - 1 and rolled.data[row][newCol + 1] == '.') {
                    newCol += 1;
                }
                if (newCol != col) {
                    rolled.data[row][col] = '.';
                    rolled.data[row][newCol] = 'O';
                }
            }
        }
        return rolled;
    }

    fn rollWest(self: *const map) map {
        var rolled = map{
            .data = self.data,
        };

        for (1..rolled.data[0].len) |col| {
            for (0..rolled.data.len) |row| {
                if (rolled.data[row][col] != 'O') {
                    continue;
                }
                var newCol = col;
                while (newCol >= 1 and rolled.data[row][newCol - 1] == '.') {
                    newCol -= 1;
                }
                if (newCol != col) {
                    rolled.data[row][col] = '.';
                    rolled.data[row][newCol] = 'O';
                }
            }
        }
        return rolled;
    }

    fn print(self: *const map, title: []const u8) void {
        std.debug.print("\n{s}\n", .{title});
        for (self.data) |row| {
            std.debug.print("{s}\n", .{row});
        }
    }

    fn countLoad(self: *const map) usize {
        var count: usize = 0;
        for (self.data, 0..) |row, i| {
            for (row) |col| {
                if (col == 'O') {
                    count += (self.data.len - i);
                }
            }
        }
        return count;
    }
};

pub fn main() !void {
    var m = map{
        .data = undefined,
    };

    // part 1
    var iter = std.mem.splitScalar(u8, data, '\n');
    var cur: usize = 0;
    while (iter.next()) |line| {
        for (0..line.len) |col| {
            m.data[cur][col] = line[col];
        }
        cur += 1;
    }

    std.debug.print("part 1: {}\n", .{m.rollNorth().countLoad()});

    // part 2
    var rolled = m;
    var i: usize = 0;
    var loopPos: usize = 0;
    var loopVal: usize = 0;
    while (i < 1_000_000_000) {
        rolled = rolled.rollNorth().rollWest().rollSouth().rollEast();
        if (i > 1000) {
            if (loopPos == 0) {
                loopPos = i;
                loopVal = rolled.countLoad();
                std.debug.print("loop size: {} loop val: {}\n", .{ loopPos, loopVal });
            } else if (loopVal == rolled.countLoad()) {
                std.debug.print("loop size: {} loop val: {}\n", .{ i - loopPos, loopVal });
                var loopSize = i - loopPos;
                while (i < 1_000_000_000 - loopSize) {
                    i += loopSize;
                }
                std.debug.print("continue from {}\n", .{i});
            }
        }
        i += 1;
        std.debug.print("i: {} count: {}\n", .{ i, rolled.countLoad() });
    }

    std.debug.print("part 2: {}\n", .{rolled.countLoad()});
}
