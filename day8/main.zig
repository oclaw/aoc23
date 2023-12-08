const std = @import("std");
const assert = std.debug.assert;

const Error = error{NoSolutions};

const sample1 = @embedFile("sample.txt");
const sample2 = @embedFile("sample2.txt");
const sample3 = @embedFile("sample3.txt");
const taskData = @embedFile("task8.txt");

// for space economy we store 3 letters in 15 bits
const bits_for_byte = 5;

fn encode_vertex(vertex_str: []const u8) usize {
    var result: usize = 0;
    inline for (vertex_str[0..3]) |c| {
        assert(c >= 'A' and c <= 'Z');
        result = (result << bits_for_byte) | (c - 'A');
    }
    return result;
}

const MaxCode = encode_vertex("ZZZ") + 1; // about 26K array with 15K possible vertexes

const vertex = struct {
    left: usize,
    right: usize,
};

// graph is stored as linear array with 15 bit code as index
const graph = struct {
    vertexes: [MaxCode]vertex = std.mem.zeroes([MaxCode]vertex),
    bitmap: std.bit_set.StaticBitSet(MaxCode) = std.bit_set.StaticBitSet(MaxCode).initEmpty(),

    pub fn set_vertex(self: *graph, code: usize, v: vertex) void {
        self.vertexes[code] = v;
        self.bitmap.setValue(code, true);
    }

    pub fn is_set(self: *const graph, code: usize) bool {
        return self.bitmap.isSet(code);
    }

    pub fn get_next(self: *const graph, source: usize, move: u8) usize {
        return switch (move) {
            'L' => self.vertexes[source].left,
            'R' => self.vertexes[source].right,
            else => unreachable,
        };
    }
};

fn solve_part1(g: *const graph, moves: []const u8) !usize {
    var cur = encode_vertex("AAA");
    const end = encode_vertex("ZZZ");
    var movecount: u64 = 0;
    if (!g.is_set(cur) or !g.is_set(end)) {
        std.debug.print("no solution for part 1\n", .{});
        return Error.NoSolutions;
    }

    while (cur != end) {
        var move = moves[movecount % moves.len];
        cur = g.get_next(cur, move);
        movecount += 1;
    }

    return movecount;
}

fn solve_part2(g: *const graph, moves: []const u8) usize {
    // vertex start criteria: (code & 0b11111) == 0  (encoded 'A')
    // vertex end critertia:  (code & 0b11111) == 25 (encoded 'Z')
    const aux = struct {
        fn is_start(code: usize) bool {
            return code & ((1 << bits_for_byte) - 1) == 0; // 'A' - 'A'
        }

        fn is_end(code: usize) bool {
            return code & ((1 << bits_for_byte) - 1) == 'Z' - 'A';
        }
    };

    // find all start vertexes
    var cur_buf = [_]usize{0} ** MaxCode;
    var steps_to_end_buf = [_]usize{0} ** MaxCode;
    var starts_count: usize = 0;

    for (0..g.vertexes.len) |i| {
        if (!g.is_set(i) or !aux.is_start(i)) {
            continue;
        }
        cur_buf[starts_count] = i;
        starts_count += 1;
    }

    // find all paths and its lengths from start to end
    var cur = cur_buf[0..starts_count];
    var steps_to_end = steps_to_end_buf[0..starts_count];
    var longest_path: usize = 0;
    for (cur, 0..) |start, i| {
        var temp = start;
        var movecount: usize = 0;
        while (!aux.is_end(temp)) {
            var move = moves[movecount % moves.len];
            temp = g.get_next(temp, move);
            movecount += 1;
        }
        steps_to_end_buf[i] = movecount;
        longest_path = @max(longest_path, movecount);
    }

    // calc less common multiple between all path lengths with step == max path
    var lcm: u64 = 0;
    outer: while (true) {
        lcm += longest_path;
        for (steps_to_end) |divisor|
            if (lcm % divisor != 0)
                continue :outer;
        break;
    }

    return lcm;
}

const task = struct {
    graph: graph,
    moves: []const u8,
};

fn parse_task(data: []const u8) task {
    var g = graph{};
    var iter = std.mem.splitScalar(u8, data, '\n');
    var moves = iter.first();
    var count: usize = 0;
    while (iter.next()) |line| {
        if (line.len < 16 or !std.ascii.isAlphabetic(line[0])) {
            continue;
        }

        var code = encode_vertex(line[0..3]);
        var left = encode_vertex(line[7..10]);
        var right = encode_vertex(line[12..15]);
        g.set_vertex(code, vertex{ .left = left, .right = right });
        count += 1;
    }
    return task{ .graph = g, .moves = moves };
}

pub fn main() !void {
    var t = parse_task(taskData);

    std.debug.print("part 1: {any}\n", .{solve_part1(&t.graph, t.moves)});
    std.debug.print("part 2: {}\n", .{solve_part2(&t.graph, t.moves)});
}

const expect = std.testing.expect;

test "sample 1" {
    var t = parse_task(sample1);
    try expect(try solve_part1(&t.graph, t.moves) == 2);
    try expect(solve_part2(&t.graph, t.moves) == 2);
}

test "sample 2" {
    var t = parse_task(sample2);
    try expect(try solve_part1(&t.graph, t.moves) == 6);
    try expect(solve_part2(&t.graph, t.moves) == 6);
}

test "sample 3" {
    var t = parse_task(sample3);
    try expect(solve_part1(&t.graph, t.moves) == error.NoSolutions);
    try expect(solve_part2(&t.graph, t.moves) == 6);
}

test "task" {
    var t = parse_task(taskData);
    try expect(try solve_part1(&t.graph, t.moves) == 16697);
    try expect(solve_part2(&t.graph, t.moves) == 10668805667831);
}
