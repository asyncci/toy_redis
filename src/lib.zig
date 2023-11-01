const std = @import("std");

const MultiArrayList = std.MultiArrayList;
const ArrayList = std.ArrayList;
const AutoArrayHashMapUnmanaged = std.AutoArrayHashMapUnmanaged;

const Allocator = std.mem.Allocator;
const pollfd = std.os.pollfd;

pub const maxMsg: u16 = 4096;

pub const ConnectionState = enum(u2) {
    Request,
    Response,
    End,
};

pub const Connection = struct {
    state: ConnectionState,
    rbuf: ArrayList(u8) = undefined,
    wbuf: ArrayList(u8) = undefined,
};

pub const ConnectionsMap = AutoArrayHashMapUnmanaged(i32, Connection);

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

pub fn decode(text: []const u8) ![]const u8 {
    _ = text;
}

fn intFromBytes(bytes: *const [4]u8) !u32 {
    return @bitCast(bytes.*);
}

pub fn encode(text: []const u8) ![]const u8 {
    var len: u32 = @intCast(text.len);
    if (len > maxMsg) return error.TooLong;

    var wbuf: [4 + maxMsg]u8 = undefined;
    @memcpy(wbuf[0..4], @as(*const [4]u8, @ptrCast(&len)));
    @memcpy(wbuf[4..(4 + len)], text);
    return wbuf[0 .. len + 4];
}

pub fn setNonBlock(fd: i32) !void {
    var flags = try std.os.fcntl(fd, std.os.F.GETFL, 0);
    flags |= std.os.O.NONBLOCK;
    _ = try std.os.fcntl(fd, std.os.F.SETFL, flags);
}

pub const server_lib = struct {
    var serverBuffer: [4 * maxMsg]u8 = undefined;
    var fb = std.heap.FixedBufferAllocator.init(&serverBuffer);
    pub var fb_allocator = fb.allocator();

    pub fn newConnection(fd: i32, connections: *ConnectionsMap) !void {
        var addr: std.net.Ip4Address = undefined;
        var addr_size = addr.getOsSockLen();
        const conn_fd = try std.os.accept(fd, @ptrCast(&addr.sa), &addr_size, 0);

        //try setNonBlock(conn_fd);
        try connections.put(fb_allocator, conn_fd, Connection{
            .state = .Request,
            .rbuf = ArrayList(u8).init(fb_allocator),
            .wbuf = ArrayList(u8).init(fb_allocator),
        });
    }

    pub fn connectionIO(fd: i32, connection: *Connection) !void {
        switch (connection.state) {
            .Request => try readRequestBETA(fd, connection),
            .Response => try writeResponseBETA(fd, connection),
            .End => {},
        }
    }

    pub fn readRequestBETA(fd: i32, connection: *Connection) !void {
        var rbuf = connection.rbuf;

        try rbuf.resize(4);
        try readAll(fd, rbuf.items, 4);

        const len = try intFromBytes(rbuf.items[0..4]);

        try rbuf.resize(4 + len);
        try readAll(fd, rbuf.items[4..], len);

        //message
        std.debug.print("client says: {s}\n", .{rbuf.items});
        //echo to writing buffer
        try connection.wbuf.resize(4 + len);
        @memcpy(connection.wbuf.items, rbuf.items);

        connection.state = .Response;
    }

    pub fn writeResponseBETA(fd: i32, connection: *Connection) !void {
        var buf = connection.wbuf.items;
        std.debug.print("resp: {s}\n", .{buf});
        try writeAll(fd, buf);

        connection.state = .Request;
    }
};
