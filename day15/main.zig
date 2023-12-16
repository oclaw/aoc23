const std = @import("std");

// const data = @embedFile("sample.txt");
const data = @embedFile("task15.txt");

fn hash(s: []const u8) u8 {
    var res: usize = 0;
    for (s) |c| {
        res = ((res + c) * 17) % 256;
    }
    return @intCast(res);
}

const hashMap = struct {
    const lens = struct {
        label: []const u8 = "",
        focal_length: u8 = 0,
    };

    const box = struct {
        items: [20]lens,
        insert_pos: usize = 0,
    };

    boxes: [256]box = std.mem.zeroes([256]box),

    pub fn insert(self: *hashMap, l: []const u8, f: u8) void {
        var boxnum = hash(l);
        var _box = &self.boxes[boxnum];
        var pos: usize = 0;
        while (_box.items[pos].label.len != 0) {
            if (std.mem.eql(u8, _box.items[pos].label, l)) {
                _box.items[pos].focal_length = f;
                return;
            }
            if (pos == _box.items.len - 1) {
                @panic("box too small!");
            }
            pos += 1;
        }
        _box.items[pos] = .{ .label = l, .focal_length = f };
        _box.insert_pos = pos + 1;
    }

    pub fn remove(self: *hashMap, l: []const u8) void {
        var boxnum = hash(l);
        var _box = &self.boxes[boxnum];
        var pos: usize = 0;
        while (pos < _box.insert_pos) {
            if (!std.mem.eql(u8, _box.items[pos].label, l)) {
                pos += 1;
                continue;
            }
            while (pos < _box.insert_pos) {
                _box.items[pos] = _box.items[pos + 1];
                pos += 1;
            }
            _box.items[pos] = .{ .label = "", .focal_length = 0 };
            _box.insert_pos -= 1;
            return;
        }
    }
};

pub fn main() !void {
    var part1: usize = 0;
    var hashmap = hashMap{};
    var iter = std.mem.splitScalar(u8, data, ',');
    while (iter.next()) |line| {
        part1 += hash(line);
        if (std.mem.endsWith(u8, line, "-")) {
            var label = line[0 .. line.len - 1];
            hashmap.remove(label);
        } else {
            var insert_iter = std.mem.splitScalar(u8, line, '=');
            var label = insert_iter.first();
            var focal_length = try std.fmt.parseInt(u8, insert_iter.next().?, 10);
            hashmap.insert(label, focal_length);
        }
    }
    var part2: usize = 0;
    for (hashmap.boxes, 0..) |box, i| {
        for (0..box.insert_pos) |itm_idx| {
            part2 += (i + 1) * (itm_idx + 1) * box.items[itm_idx].focal_length;
            // std.debug.print("box {}: label '{s}' focal {}\n", .{ i, box.items[itm_idx].label, box.items[itm_idx].focal_length });
        }
    }

    std.debug.print("part 1: {} part 2: {}\n", .{ part1, part2 });
}

test "hash" {
    try std.testing.expectEqual(@as(u8, 52), hash("HASH"));
}
