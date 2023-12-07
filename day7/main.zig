const std = @import("std");

// const data = @embedFile("sample.txt");
const data = @embedFile("task7.txt");

// order cards by priority
fn getCharMapForPart1() [0xFF]u8 {
    const char_strengh = "AKQJT98765432";
    var charMap = [_]u8{0xFF} ** 0xFF;
    for (0..char_strengh.len) |i| {
        charMap[char_strengh[i]] = @as(u8, @intCast(i));
    }
    return charMap;
}

// order cards by priority with joker as lowest priority
fn getCharMapForPart2() [0xFF]u8 {
    var charMap = getCharMapForPart1();
    charMap['J'] = 0xFF;
    return charMap;
}

const freqTableEntry = struct {
    char: u8 = 0,
    freq: u8 = 0,
};

fn compareByFreq(_: void, lhs: freqTableEntry, rhs: freqTableEntry) bool {
    return lhs.freq > rhs.freq;
}

fn buildFreqtable(hand: []const u8) [5]freqTableEntry {
    var freqtable: [5]freqTableEntry = undefined;
    @memset(&freqtable, freqTableEntry{});

    inline for (hand[0..5]) |char| {
        var charIdx: usize = 0;
        for (0..freqtable.len) |i| {
            if (freqtable[i].char == char) {
                charIdx = i;
                break;
            }
            if (freqtable[i].char == 0 and freqtable[0].char != 0 and charIdx == 0) {
                charIdx = i;
            }
        }

        freqtable[charIdx].char = char;
        freqtable[charIdx].freq += 1;
    }
    return freqtable;
}

fn mergeJokerToMostFrequentCard(freqtable: *[5]freqTableEntry) void {
    for (0..5) |i| {
        if (freqtable[i].char == 'J') {
            var insert_pos: usize = 0;
            for (0..5) |j| {
                if (freqtable[j].char != 'J') {
                    insert_pos = j;
                    break;
                }
            }

            freqtable[insert_pos].freq += freqtable[i].freq;
            freqtable[i].freq = 0;
            std.sort.heap(freqTableEntry, freqtable, {}, compareByFreq);
            break;
        }
    }
}

fn getCombinationValue(hand: []const u8, use_joker: bool) u8 {
    var freqtable = buildFreqtable(hand);

    std.sort.heap(freqTableEntry, &freqtable, {}, compareByFreq);

    if (use_joker) {
        mergeJokerToMostFrequentCard(&freqtable);
    }

    return getValueFromSortedFreqTable(freqtable);
}

fn getValueFromSortedFreqTable(freqtable: [5]freqTableEntry) u8 {
    switch (freqtable[0].freq) {
        5 => return 0, // five of a kind
        4 => return 1, // four of a kind

        3 => { // full house or three of a kind
            switch (freqtable[1].freq) {
                2 => return 2, // full house
                else => return 3, // three of a kind
            }
        },

        2 => {
            switch (freqtable[1].freq) {
                2 => return 4, // two pairs
                else => return 5, // one pair
            }
        },

        else => return 6, // high card
    }
}

const sortCtx = struct {
    charMap: [0xFF]u8,
    useJoker: bool,
};

fn compareCombinations(ctx: sortCtx, lhs: []const u8, rhs: []const u8) bool {
    var lhand = lhs[0..5];
    var rhand = rhs[0..5];

    var lCombination = getCombinationValue(lhand, ctx.useJoker);
    var rCombination = getCombinationValue(rhand, ctx.useJoker);

    // combination comparison
    if (lCombination != rCombination) {
        return lCombination > rCombination;
    }

    // first high card comparison
    for (0..5) |i| {
        var l = ctx.charMap[lhand[i]];
        var r = ctx.charMap[rhand[i]];
        if (l != r) {
            return l > r;
        }
    }

    return true;
}

pub fn calcTotalWinnings(lines: [][]const u8) !usize {
    var result: usize = 0;
    for (lines, 0..) |line, rank| {
        var splitRes = std.mem.indexOfScalar(u8, line, ' ');
        var value = try std.fmt.parseInt(usize, line[splitRes.? + 1 ..], 10);
        result += (rank + 1) * value;
    }
    return result;
}

pub fn main() !void {
    var iter = std.mem.splitScalar(u8, data, '\n');
    var lineBuf: [1000][]const u8 = undefined;
    var lineCount: usize = 0;
    while (iter.next()) |line| {
        lineBuf[lineCount] = line;
        lineCount += 1;
    }
    var lines = lineBuf[0..lineCount];

    const charMap = getCharMapForPart1();
    std.sort.heap([]const u8, lines, sortCtx{ .charMap = charMap, .useJoker = false }, compareCombinations);
    var part1: usize = try calcTotalWinnings(lines);

    const charMap2 = getCharMapForPart2();
    std.sort.heap([]const u8, lines, sortCtx{ .charMap = charMap2, .useJoker = true }, compareCombinations);
    var part2: usize = try calcTotalWinnings(lines);

    std.debug.print("part1: {} part2: {}\n", .{ part1, part2 });
}
