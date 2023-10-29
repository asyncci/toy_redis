const std = @import("std");

pub const maxMsg: u16 = 4096;

pub fn readAll(fd: i32, buf: []u8, bytes_to_read: usize) !void {
    var size = bytes_to_read;
    var last: usize = 0;
    while (size > 0) {
        const rv = try std.os.read(fd, buf[last..(last + size)]);
        std.debug.assert(rv <= size);
        size -= rv;
        last += rv;
    }
}

pub fn readHeader(fd: i32, buf: []u8) !u32 {
    try readAll(fd, buf, 4);
    return @bitCast(buf[0..4].*);
}

pub fn writeAll(fd: i32, buf: []const u8) !void {
    var last: usize = 0;
    while (last < buf.len) {
        const rv = try std.os.write(fd, buf[last..]);
        std.debug.assert(rv <= buf.len);
        last += rv;
    }
}

pub fn setNonBlock(fd: i32) !void {
    var flags = try std.os.fcntl(fd, std.os.F.GETFL, 0);
    flags |= std.os.O.NONBLOCK;
    _ = try std.os.fcntl(fd, std.os.F.SETFL, flags);
}
