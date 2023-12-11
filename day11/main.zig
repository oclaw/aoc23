const std = @import("std");

const data = @embedFile("task11.txt");

const point = struct {
    row: usize,
    col: usize,

    pub fn eq(self: point, other: point) bool {
        return (self.row == other.row) and (self.col == other.col);
    }

    pub fn inc_col(self: point) point {
        return point{ .row = self.row, .col = self.col + 1 };
    }
};

fn nextGalaxy(map: []const []const u8, start: point) ?point {
    var _start = start;
    for (map[_start.row..map.len], 0..) |line, i| {
        var j = _start.col;
        while (j < line.len) : (j += 1) {
            if (line[j] != '.') {
                return point{ .row = start.row + i, .col = j };
            }
        }
        _start.col = 0;
    }
    return null;
}

fn findWaysLength(map: []const []const u8, expansion_coeff: usize) usize {
    const aux = struct {
        const expandmap = struct {
            coeff: usize = undefined,
            rows: [140]bool = [_]bool{false} ** 140,
            cols: [140]bool = [_]bool{false} ** 140,

            pub fn col_cost(self: *const expandmap, col: usize) usize {
                if (self.cols[col]) {
                    return self.coeff;
                }
                return 1;
            }

            pub fn row_cost(self: *const expandmap, row: usize) usize {
                if (self.rows[row]) {
                    return self.coeff;
                }
                return 1;
            }
        };

        fn calcPathWithExpansion(start: point, end: point, expand: expandmap) usize {
            var cur = start;
            var steps: usize = 0;
            while (!cur.eq(end)) {
                if (cur.row != end.row) {
                    steps += expand.row_cost(cur.row);
                    cur.row = if (cur.row < end.row) cur.row + 1 else cur.row - 1;
                }
                if (cur.col != end.col) {
                    steps += expand.col_cost(cur.col);
                    cur.col = if (cur.col < end.col) cur.col + 1 else cur.col - 1;
                }
            }
            return steps;
        }
    };

    var expand = aux.expandmap{
        .coeff = expansion_coeff,
    };

    for (map, 0..) |row, i| {
        if (std.mem.allEqual(u8, row, '.')) {
            expand.rows[i] = true;
        }
    }

    for (map[0], 0..) |col, i| {
        _ = col;
        var all_dots = true;
        for (map, 0..) |row, j| {
            _ = j;
            if (row[i] != '.') {
                all_dots = false;
                break;
            }
        }
        expand.cols[i] = all_dots;
    }

    var _start = nextGalaxy(map, point{ .row = 0, .col = 0 });
    var sum: usize = 0;
    while (_start != null) {
        var start = _start.?;

        var next = nextGalaxy(map, start.inc_col());
        while (next != null) {
            var pathlen = aux.calcPathWithExpansion(start, next.?, expand);
            sum += pathlen;
            next = nextGalaxy(map, next.?.inc_col());
        }
        _start = nextGalaxy(map, start.inc_col());
    }
    return sum;
}

pub fn main() !void {
    var linebuf: [1000][]const u8 = undefined;
    var iter = std.mem.splitScalar(u8, data, '\n');
    var linecnt: usize = 0;
    while (iter.next()) |line| {
        linebuf[linecnt] = line;
        linecnt += 1;
    }
    var lines = linebuf[0..linecnt];

    var part1 = findWaysLength(lines, 2);
    var part2 = findWaysLength(lines, 1000000);

    std.debug.print("part 1: {} part 2: {}\n", .{ part1, part2 });
}

const expectEqual = std.testing.expectEqual;

test "sample" {
    // zig fmt: off
    const sample = [_][]const u8{ 
        "...#......", 
        ".......#..", 
        "#.........", 
        "..........", 
        "......#...", 
        ".#........", 
        ".........#", 
        "..........", 
        ".......#..", 
        "#...#....." 
    };
    // zig fmt: on

    try expectEqual(findWaysLength(&sample, 2), 374);
    try expectEqual(findWaysLength(&sample, 100), 8410);
}
