const std = @import("std");
const lib = @import("lib.zig");
const readAll = lib.readAll;
const writeAll = lib.writeAll;
const readHeader = lib.readHeader;

test "length" {
    const reply = "world";
    std.debug.print("\n{}\n", .{reply.len});
}

test "endianness" {
    var buf = [_]u8{ 1, 2, 0, 0 };
    var len: u32 = std.mem.bytesToValue(u32, &buf);
    std.debug.print("\n{}\n", .{len});
}

test "asBytes" {
    const len: i32 = 10;
    const a = comptime std.mem.asBytes(&len);
    inline for (a) |d| {
        @compileLog(d);
    }
    @compileLog(a);
}

test "memcpy" {
    const len: u32 = 10;
    var wbuf = std.mem.zeroes([4 + 1]u8);
    @memcpy(wbuf[0..4], &(@as([4]u8, @bitCast(len))));
    @compileLog(wbuf);
}

test "write" {
    var buf: [10002320]u8 = undefined;
    @memset(&buf, 'o');
    const fd = try std.os.open("tx.txt", std.os.O.RDWR, std.os.S.IRWXU);
    const rv = try std.os.write(fd, &buf);
    std.debug.print("\n{} {}\n", .{ rv, buf.len });
}

test "header" {
    var buf = std.mem.zeroes([4]u8);
    const fd = try std.os.open("tx.txt", std.os.O.RDWR, std.os.S.IRWXU);
    const len = try readHeader(fd, &buf);
    std.debug.print("\n{}\n", .{len});
    std.debug.print("\n{d}\n", .{buf});
}

test "hw" {
    const fd = try std.os.open("tx.txt", std.os.O.RDWR, std.os.S.IRWXU);
    const len: u32 = 100000000;
    const buf: [4]u8 = @bitCast(len);
    _ = try std.os.write(fd, &buf);
}

test "tp" {
    comptime var add = [4]u8{ 1, 2, 2, 3 };
    const rex: []u8 = add[0..2];
    @compileLog(@TypeOf(rex));
}
