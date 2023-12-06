const std = @import("std");
const isDigit = std.ascii.isDigit;

const _game = struct {
    id: u32 = 0,
    red: u32 = 0,
    green: u32 = 0,
    blue: u32 = 0,
};

fn extractNumber(buf: []const u8) u32 {
    var result: u32 = 0;
    for (buf) |c| {
        if (isDigit(c)) {
            result = result * 10 + (c - '0');
        }
    }
    return result;
}

pub fn parseGame(line: []const u8) _game {
    var localGame = _game{};

    var pos = std.mem.indexOfPos(u8, line, 0, ":").?;
    localGame.id = extractNumber(line[0..pos]);

    while (true) {
        var newPos = std.mem.indexOfPos(u8, line, pos, " ");
        if (newPos == null) {
            break;
        }
        pos = newPos.? + 1;

        var num: u32 = 0;
        var ptr: ?*u32 = null;
        var rpos = pos;
        while (true) {
            var c = line[rpos];
            if (isDigit(c)) {
                num = num * 10 + (c - '0');
            }

            ptr = switch (c) {
                'r' => &localGame.red,
                'g' => &localGame.green,
                'b' => &localGame.blue,
                else => null,
            };

            if (ptr != null) {
                break;
            }
            rpos += 1;
        }
        ptr.?.* = @max(ptr.?.*, num);
    }
    return localGame;
}

pub fn isGamePossible(gm: _game, line: []const u8) ?u32 {
    var localGame = parseGame(line);

    if (localGame.red > gm.red or localGame.green > gm.green or localGame.blue > gm.blue) {
        return null;
    }
    return localGame.id;
}

pub fn calcPowerOfGame(line: []const u8) u32 {
    var localGame = parseGame(line);

    return localGame.red * localGame.green * localGame.blue;
}

pub fn main() !void {
    const game = _game{
        .red = 12,
        .green = 13,
        .blue = 14,
    };

    var file = try std.fs.cwd().openFile("task2.txt", .{});
    var reader = file.reader();
    var buf: [1024]u8 = undefined;
    var possibleGamesSum: u32 = 0;
    var powersSum: u32 = 0;
    var end = false;

    while (!end) {
        var stream = std.io.fixedBufferStream(&buf);
        reader.streamUntilDelimiter(stream.writer(), '\n', buf.len) catch |err| switch (err) {
            error.EndOfStream => end = true,
            else => return err,
        };

        var gameId = isGamePossible(game, stream.getWritten());
        if (gameId != null) {
            possibleGamesSum += gameId.?;
        }
        powersSum += calcPowerOfGame(stream.getWritten());
    }

    try std.io.getStdOut().writer().print("gameidsum: {} powersum: {}\n", .{ possibleGamesSum, powersSum });
}
