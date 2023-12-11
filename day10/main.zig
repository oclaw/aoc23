const std = @import("std");

// const data = @embedFile("sample_inner.txt");
const data = @embedFile("task10.txt");

const point = struct {
    x: usize,
    y: usize,

    pub fn get_next_points(cur: point, dir: u8) [2]point {
        return switch (dir) {
            '-' => [2]point{ cur.shift_x(-1), cur.shift_x(1) },
            'L' => [2]point{ cur.shift_x(1), cur.shift_y(-1) },
            '|' => [2]point{ cur.shift_y(-1), cur.shift_y(1) },
            'F' => [2]point{ cur.shift_y(1), cur.shift_x(1) },
            '7' => [2]point{ cur.shift_x(-1), cur.shift_y(1) },
            'J' => [2]point{ cur.shift_x(-1), cur.shift_y(-1) },
            else => unreachable,
        };
    }

    fn safeDiff(val: usize, diff: i32) usize {
        var casted: i32 = @as(i32, @intCast(val)) + diff;
        if (casted < 0) {
            return 0;
        }
        return @as(u32, @intCast(casted));
    }

    pub fn shift_x(self: point, dx: i32) point {
        return point{ .x = safeDiff(self.x, dx), .y = self.y };
    }

    pub fn shift_y(self: point, dy: i32) point {
        return point{ .x = self.x, .y = safeDiff(self.y, dy) };
    }

    pub fn eq(self: point, other: *const point) bool {
        return self.x == other.x and self.y == other.y;
    }
};

const grid = struct {
    mapbuf: ?[][]u8 = null,
    cyclebuf: ?[]bool = null,

    map: [][]const u8 = undefined,
    startpoint: point = undefined,
    startsym: u8 = undefined,
    cyclemap: [][]bool = undefined,

    pub fn init(_data: []const u8, allocator: std.mem.Allocator) !grid {
        var g = grid{};

        g.mapbuf = try allocator.alloc([]u8, 1000);
        g.map = g.mapbuf.?;

        var iter = std.mem.splitScalar(u8, _data, '\n');
        var linecount: usize = 0;
        while (iter.next()) |line| {
            g.map[linecount] = line;

            var startpos = std.mem.indexOfScalar(u8, line, 'S');
            if (startpos != null) {
                g.startpoint.x = @intCast(startpos.?);
                g.startpoint.y = @intCast(linecount);
            }
            linecount += 1;
        }
        g.map = g.map[0..linecount];

        g.set_start_sym();
        try g.fill_cyclemap(allocator);

        return g;
    }

    fn get_start_directions(self: *const grid) [2]point {
        var result: [2]point = undefined;
        var directions = [_]point{
            self.startpoint.shift_y(-1),
            self.startpoint.shift_y(1),
            self.startpoint.shift_x(-1),
            self.startpoint.shift_x(1),
        };

        var saved: usize = 0;
        var i: usize = 0;
        while (saved != result.len) : (i += 1) {
            var pt = directions[i];
            var ch = self.map[pt.y][pt.x];
            if (ch == '.' or ch == 'S') {
                continue;
            }
            var pts = pt.get_next_points(ch);
            if (pts[0].eq(&self.startpoint) or pts[1].eq(&self.startpoint)) {
                result[saved] = pt;
                saved += 1;
            }
        }

        return result;
    }

    // hack to guess real start symbol value
    fn set_start_sym(self: *grid) void {
        var directions = self.get_start_directions();

        var alldirs = "L|F7J-";
        for (alldirs) |dir| {
            var pts = self.startpoint.get_next_points(dir);

            // fixme
            if (pts[0].eq(&directions[0]) and pts[1].eq(&directions[1]) or pts[0].eq(&directions[1]) and pts[1].eq(&directions[0])) {
                self.startsym = dir;
                return;
            }
        }
        unreachable;
    }

    pub fn fill_cyclemap(self: *grid, allocator: std.mem.Allocator) !void {
        self.cyclebuf = try allocator.alloc(bool, self.map.len * self.map[0].len);
        @memset(self.cyclebuf.?, false);

        self.cyclemap = try allocator.alloc([]bool, self.map.len);
        for (0..self.map.len) |i| {
            self.cyclemap[i] = self.cyclebuf.?[i * self.map[0].len .. (i + 1) * self.map[0].len];
        }

        var pt = self.get_start_directions()[0];

        var prev = self.startpoint;
        self.cyclemap[self.startpoint.y][self.startpoint.x] = true;
        while (!self.cyclemap[pt.y][pt.x]) {
            var directions = pt.get_next_points(self.map[pt.y][pt.x]);
            self.cyclemap[pt.y][pt.x] = true;
            var next = if (!directions[0].eq(&prev)) directions[0] else directions[1];
            prev = pt;
            pt = next;
        }
    }

    pub fn is_cycle(self: *const grid, i: usize, j: usize) bool {
        return self.cyclemap[i][j];
    }

    pub fn deinit(self: grid, allocator: std.mem.Allocator) void {
        if (self.mapbuf != null) {
            allocator.free(self.mapbuf.?);
        }
        if (self.cyclebuf != null) {
            allocator.free(self.cyclebuf.?);
        }
    }
};

const enhanced_grid = struct {
    grid: grid = undefined,
    lines: [][]u8 = undefined,

    pub fn init(source: *const grid, allocator: std.mem.Allocator) !enhanced_grid {
        var lines = try allocator.alloc([]u8, source.map.len * 2);
        var startpoint: point = undefined;

        for (0..lines.len) |i| {
            lines[i] = try allocator.alloc(u8, source.map[0].len * 2);
        }

        for (0..source.map.len) |i| {
            for (0..source.map[0].len) |j| {
                var ch = source.map[i][j];
                lines[i * 2][j * 2] = ch;
                if (ch == 'S') {
                    ch = source.startsym;
                }
                lines[i * 2][j * 2 + 1] = switch (ch) {
                    '.' => '.',
                    'L', 'F', '-' => '-',
                    else => '.',
                };
            }

            var start = std.mem.indexOfScalar(u8, lines[i * 2], 'S');
            if (start != null) {
                startpoint.x = @intCast(start.?);
                startpoint.y = @intCast(i * 2);
            }

            for (lines[i * 2], 0..) |ch, k| {
                var _ch = if (ch == 'S') source.startsym else ch;
                lines[i * 2 + 1][k] = switch (_ch) {
                    '.' => '.',
                    '7', 'F', '|' => '|',
                    else => '.',
                };
            }
        }

        std.debug.print("==== EXPANDED GRID ====\n", .{});
        for (0..lines.len) |i| {
            for (0..lines[0].len) |j| {
                std.debug.print("{c} ", .{lines[i][j]});
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("==== EXPANDED GRID END ==== \n", .{});

        var eg = enhanced_grid{
            .grid = grid{
                .map = lines,
                .startpoint = startpoint,
                .startsym = source.startsym,
            },
            .lines = lines,
        };
        try eg.grid.fill_cyclemap(allocator);
        return eg;
    }

    pub fn deinit(self: enhanced_grid, allocator: std.mem.Allocator) void {
        self.grid.deinit(allocator);
        for (self.lines) |line| {
            allocator.free(line);
        }
        allocator.free(self.lines);
    }
};

// recursive search of path to the outer border
fn find_path_out(g: *const grid, start: point, allocator: std.mem.Allocator) !bool {
    var visited = try allocator.alloc([1000]bool, 1000);
    defer allocator.free(visited);
    @memset(visited, [_]bool{false} ** 1000);

    const aux = struct {
        fn find_path_out_rec(_g: *const grid, _visited: [][1000]bool, cur: point) bool {
            _visited[cur.y][cur.x] = true;
            if (cur.x == 0 or cur.y == 0 or cur.x == _g.map[0].len - 1 or cur.y == _g.map.len - 1) {
                return true;
            }

            var directions = [_]point{
                cur.shift_y(-1),
                cur.shift_y(1),
                cur.shift_x(-1),
                cur.shift_x(1),
            };

            for (directions) |dir| {
                if (dir.x >= _g.map[0].len or dir.y >= _g.map.len) {
                    continue;
                }
                if (dir.eq(&cur) or _g.is_cycle(dir.y, dir.x) or _visited[dir.y][dir.x]) {
                    continue;
                }
                if (find_path_out_rec(_g, _visited, dir)) {
                    return true;
                }
            }

            return false;
        }
    };

    return aux.find_path_out_rec(g, visited, start);
}

fn find_enclosed(g: *const grid, allocator: std.mem.Allocator) !usize {
    var eg = try enhanced_grid.init(g, allocator);
    defer eg.deinit(std.heap.page_allocator);

    var enclosed: usize = 0;
    for (0..eg.grid.map.len) |i| {
        if (i % 2 != 0) {
            continue; // no need to check added lines
        }

        for (0..eg.grid.map[0].len) |j| {
            if (j % 2 != 0) {
                continue; // no need to check added lines
            }

            if (eg.grid.is_cycle(i, j)) {
                std.debug.print("{c} ", .{eg.grid.map[i][j]});
                continue;
            }

            var pt = point{ .x = j, .y = i };
            var reachable = try find_path_out(&eg.grid, pt, allocator);
            if (!reachable) {
                enclosed += 1;
                std.debug.print("I ", .{});
            } else {
                std.debug.print("O ", .{});
            }
        }

        std.debug.print("\n", .{});
    }

    return enclosed;
}

fn find_longest_path(g: *const grid) usize {
    var points = g.get_start_directions();
    var prev_points = [2]point{ g.startpoint, g.startpoint };
    var paths = [2]usize{ 1, 1 };

    var visited = std.mem.zeroes([1000][1000]bool);

    outer: while (true) {
        for (0..2) |i| {
            var pt = points[i];
            if (visited[pt.y][pt.x]) {
                break :outer;
            }
            visited[pt.y][pt.x] = true;

            var directions = pt.get_next_points(g.map[pt.y][pt.x]);
            var next = if (!directions[0].eq(&prev_points[i])) directions[0] else directions[1];
            prev_points[i] = pt;
            points[i] = next;
            paths[i] += 1;
        }
    }

    return @min(paths[0], paths[1]);
}

pub fn main() !void {
    var g = try grid.init(data, std.heap.page_allocator);
    defer g.deinit(std.heap.page_allocator);

    var part1 = find_longest_path(&g);
    var part2 = try find_enclosed(&g, std.heap.page_allocator);

    std.debug.print("part 1: {} part 2: {}\n", .{ part1, part2 });
}
