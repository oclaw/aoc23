const std = @import("std");

// const data = @embedFile("sample.txt");
const data = @embedFile("task16.txt");

const grid = struct {
    map: []const []const u8,
    energy_map: [][]u32,

    const _point = struct {
        x: usize,
        y: usize,
    };

    const _dir = enum(u32) {
        up = 1,
        down = 1 << 1,
        left = 1 << 2,
        right = 1 << 3,

        fn apply(self: _dir, p: _point) _point {
            switch (self) {
                _dir.up => return _point{ .x = p.x, .y = p.y - 1 },
                _dir.down => return _point{ .x = p.x, .y = p.y + 1 },
                _dir.left => return _point{ .x = p.x - 1, .y = p.y },
                _dir.right => return _point{ .x = p.x + 1, .y = p.y },
            }
        }
    };

    fn set_energy(self: *grid, p: _point, direction: _dir) void {
        self.energy_map[p.y][p.x] |= @intFromEnum(direction);
    }

    fn get_energy(self: *grid, p: _point) u32 {
        return self.energy_map[p.y][p.x];
    }

    fn get_element(self: *grid, p: _point) u8 {
        return self.map[p.y][p.x];
    }

    pub fn run_beam(self: *grid, _start_point: _point, _init_dir: _dir) void {
        const aux = struct {
            fn trace_beam(g: *grid, init_point: _point, init_dir: _dir) void {
                var point = init_point;
                var dir = init_dir;

                if (point.x >= g.map[0].len or point.y >= g.map.len) {
                    return;
                }

                while (true) {
                    if (g.get_energy(point) & @intFromEnum(dir) > 0) {
                        return;
                    }

                    g.set_energy(point, dir);
                    // std.debug.print("point: {any}, dir={} char={c} \n", .{ point, dir, g.get_element(point) });
                    switch (g.get_element(point)) {
                        '.' => {},
                        '/' => {
                            switch (dir) {
                                _dir.right => dir = _dir.up,
                                _dir.up => dir = _dir.right,
                                _dir.down => dir = _dir.left,
                                _dir.left => dir = _dir.down,
                            }
                        },
                        '\\' => {
                            switch (dir) {
                                _dir.left => dir = _dir.up,
                                _dir.up => dir = _dir.left,
                                _dir.down => dir = _dir.right,
                                _dir.right => dir = _dir.down,
                            }
                        },
                        '|' => {
                            switch (dir) {
                                _dir.up, _dir.down => {},
                                _dir.right, _dir.left => {
                                    if (point.y > 0) {
                                        trace_beam(g, _dir.up.apply(point), _dir.up);
                                    }
                                    trace_beam(g, _dir.down.apply(point), _dir.down);
                                    return;
                                },
                            }
                        },
                        '-' => {
                            switch (dir) {
                                _dir.up, _dir.down => {
                                    if (point.x > 0) {
                                        trace_beam(g, _dir.left.apply(point), _dir.left);
                                    }
                                    trace_beam(g, _dir.right.apply(point), _dir.right);
                                    return;
                                },
                                _dir.right, _dir.left => {},
                            }
                        },
                        else => unreachable,
                    }
                    // var prev = point;
                    if ((dir == _dir.left and point.x == 0) or
                        (dir == _dir.up and point.y == 0) or
                        (dir == _dir.right and point.x == g.map[0].len - 1) or
                        (dir == _dir.down and point.y == g.map.len - 1))
                    {
                        return;
                    }
                    point = dir.apply(point);
                    // std.debug.print("dir: {any}, {any} ==> {any} \n", .{ dir, prev, point });
                }
            }
        };

        aux.trace_beam(self, _start_point, _init_dir);
    }

    pub fn reset_energy_map(self: *grid) void {
        for (0..self.energy_map.len) |i| {
            for (0..self.energy_map[0].len) |j| {
                self.energy_map[i][j] = 0;
            }
        }
    }

    pub fn collect_energy(self: *const grid) usize {
        var energy: usize = 0;
        for (self.energy_map) |row| {
            for (row) |val| {
                if (val > 0) {
                    energy += 1;
                    // std.debug.print("#", .{});
                } else {
                    // std.debug.print(".", .{});
                }
            }
            // std.debug.print("\n", .{});
        }
        return energy;
    }
};

pub fn main() !void {
    var alloc = std.heap.page_allocator;

    var linebuf = try alloc.alloc([]const u8, 1000);
    defer alloc.free(linebuf);

    var linecount: usize = 0;
    var linesize: usize = 0;
    var iter = std.mem.splitScalar(u8, data, '\n');

    while (iter.next()) |line| {
        linebuf[linecount] = line;
        linecount += 1;
        linesize = line.len;
    }
    var lines = linebuf[0..linecount];

    var mtxbuf = try alloc.alloc(u32, linesize * linecount);
    defer alloc.free(mtxbuf);
    @memset(mtxbuf, 0);

    var mtx = try alloc.alloc([]u32, linecount);
    defer alloc.free(mtx);

    for (0..linecount) |i| {
        mtx[i] = mtxbuf[linesize * i .. linesize * (i + 1)];
    }

    var g = grid{
        .map = lines,
        .energy_map = mtx,
    };

    g.run_beam(grid._point{ .x = 0, .y = 0 }, grid._dir.right);
    var part1 = g.collect_energy();

    // part 2
    const aux = struct {
        result: usize = 0,

        const Self = @This();

        fn run_beam_and_and_reset(self: *Self, _g: *grid, p: grid._point, d: grid._dir) void {
            _g.run_beam(p, d);
            var res = _g.collect_energy();
            _g.reset_energy_map();
            self.result = @max(self.result, res);
        }
    };
    var part2 = aux{};

    part2.run_beam_and_and_reset(&g, grid._point{ .x = 0, .y = 0 }, grid._dir.right);
    part2.run_beam_and_and_reset(&g, grid._point{ .x = lines[0].len, .y = 0 }, grid._dir.left);
    part2.run_beam_and_and_reset(&g, grid._point{ .x = 0, .y = linecount - 1 }, grid._dir.right);
    part2.run_beam_and_and_reset(&g, grid._point{ .x = lines[0].len, .y = linecount - 1 }, grid._dir.left);

    for (0..linesize) |i| {
        part2.run_beam_and_and_reset(&g, grid._point{ .x = i, .y = 0 }, grid._dir.down);
        part2.run_beam_and_and_reset(&g, grid._point{ .x = i, .y = linecount - 1 }, grid._dir.up);
    }

    for (0..linecount) |i| {
        part2.run_beam_and_and_reset(&g, grid._point{ .x = 0, .y = i }, grid._dir.right);
        part2.run_beam_and_and_reset(&g, grid._point{ .x = lines[0].len - 1, .y = i }, grid._dir.left);
    }

    std.debug.print("part 1: {} part 2: {}\n", .{ part1, part2.result });
}
