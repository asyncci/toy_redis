const std = @import("std");
const variable = 10;

pub fn main() !void {
    const sock = try std.os.socket(std.os.AF.INET, std.os.SOCK.STREAM, 0);
    try std.os.setsockopt(sock, std.os.SOL.SOCKET, std.os.SO.REUSEADDR, &[_]u8{ 1, 0, 0, 0 });
    const addr = std.net.Address.initIp4([_]u8{ 0, 0, 0, 0 }, 1234);

    std.debug.print("{any}\n", .{addr});
    try std.os.bind(sock, &addr.any, addr.getOsSockLen());
    try std.os.listen(sock, 4096);
    while (true) {
        const conn_fd = try std.os.accept(sock, null, null, 0);

        while (true)
            oneRequest(conn_fd) catch break;

        std.os.close(conn_fd);
    }
}

fn readFull(fd: i32, buf: []u8, st: usize) !void {
    var size = st;
    var last: usize = 0;
    while (size > 0) {
        const rv = try std.os.read(fd, buf[last..]);
        std.debug.assert(rv <= size);
        size -= rv;
        last = rv;
    }
}

fn writeAll(fd: i32, buf: []const u8, st: usize) !void {
    var start = st;
    var last: usize = 0;
    while (start < buf.len) {
        const rv = try std.os.write(fd, buf[last..]);
        std.debug.assert(rv <= buf.len);
        start -= rv;
        last = rv;
    }
}

const maxMsg: u16 = 4096;

fn oneRequest(fd: i32) !void {
    var rbuf = std.mem.zeroes([4 + maxMsg + 1]u8);
    try readFull(fd, &rbuf, 4);
    var len: u32 = @bitCast(rbuf[0..4].*);
    if (len > maxMsg) return error.TooLong;

    try readFull(fd, rbuf[4..len], 4);
    std.debug.print("{s}", .{rbuf[4..len]});

    const reply = "world";
    var wbuf = std.mem.zeroes([4 + reply.len + 1]u8);
    len = reply.len;
    @memcpy(wbuf[0..4], @as(*const [4]u8, @ptrCast(&len)));
    try writeAll(fd, &wbuf, 4 + len);
}

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
    var buf: [10000]u8 = undefined;
    @memset(buf, 'o');
    const fd = std.os.open("tx.txt", std.os.O.RDWR, std.os.S.IRWXU);
    const rv = try std.os.write(fd, &buf);
    std.debug.print("{} {}", .{ rv, buf.len });
}
