const std = @import("std");
const BinaryStream = @import("BinaryStream").BinaryStream;
const Packet = @import("../root.zig").Packet;

pub const AnimateAction = enum(u8) {
    SwingArm = 1,
    StopSleep = 3,
    CriticalHit = 4,
    MagicCriticalHit = 5,
    _,
};

pub const SwingSource = enum(u8) {
    None = 0,
    Build = 1,
    Mine = 2,
    Interact = 3,
    Attack = 4,
    UseItem = 5,
    ThrowItem = 6,
    DropItem = 7,
    Event = 8,
    _,

    pub fn wireName(self: SwingSource) []const u8 {
        return switch (self) {
            .None => "none",
            .Build => "build",
            .Mine => "mine",
            .Interact => "interact",
            .Attack => "attack",
            .UseItem => "useitem",
            .ThrowItem => "throwitem",
            .DropItem => "dropitem",
            .Event => "event",
            else => "none",
        };
    }

    pub fn fromWireName(name: []const u8) ?SwingSource {
        inline for (std.enums.values(SwingSource)) |source| {
            if (std.mem.eql(u8, name, source.wireName())) return source;
        }
        return null;
    }
};

pub const HandSlot = enum(u8) {
    MainHand = 0,
    OffHand = 1,
    _,
};

pub const AnimatePacket = struct {
    action: AnimateAction,
    runtime_entity_id: u64,
    data: f32 = 0,
    swing_source: ?SwingSource = null,
    hand: HandSlot = .MainHand,

    pub fn serialize(self: *const AnimatePacket, stream: *BinaryStream) ![]const u8 {
        try stream.writeVarInt(Packet.Animate);
        try stream.writeUint8(@intFromEnum(self.action));
        try stream.writeVarLong(self.runtime_entity_id);
        try stream.writeFloat32(self.data, .Little);
        if (self.swing_source) |source| {
            try stream.writeBool(true);
            try stream.writeVarString(source.wireName());
        } else {
            try stream.writeBool(false);
        }
        try stream.writeUint8(@intFromEnum(self.hand));
        return stream.getBuffer();
    }

    pub fn deserialize(stream: *BinaryStream) !AnimatePacket {
        _ = try stream.readVarInt();
        const action_raw = try stream.readUint8();
        const action: AnimateAction = std.enums.fromInt(AnimateAction, action_raw) orelse return error.UnknownAnimateAction;
        const runtime_entity_id: u64 = @intCast(try stream.readVarLong());
        const data = try stream.readFloat32(.Little);
        var swing_source: ?SwingSource = null;
        if (try stream.readBool()) {
            swing_source = SwingSource.fromWireName(try stream.readVarString());
        }
        const hand: HandSlot = @enumFromInt(try stream.readUint8());
        return AnimatePacket{
            .action = action,
            .runtime_entity_id = runtime_entity_id,
            .data = data,
            .swing_source = swing_source,
            .hand = hand,
        };
    }
};
