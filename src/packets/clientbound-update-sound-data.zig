const std = @import("std");
const BinaryStream = @import("BinaryStream").BinaryStream;
const Packet = @import("../enums/packet.zig").Packet;

pub const SoundDataEventType = enum(u8) {
    Stop = 0,
    SetVolume = 1,
    SetPitch = 2,
    Fade = 3,
    SeekTo = 4,
    Pause = 5,
    Resume = 6,
};

pub const SoundDataEvent = union(SoundDataEventType) {
    Stop: void,
    SetVolume: f32,
    SetPitch: f32,
    Fade: struct { duration: f32, target_volume: f32 },
    SeekTo: f32,
    Pause: void,
    Resume: void,
};

pub const ClientboundUpdateSoundDataPacket = struct {
    server_sound_handle: i64 = 0,
    event: SoundDataEvent = .Stop,

    pub fn serialize(self: *const ClientboundUpdateSoundDataPacket, stream: *BinaryStream) ![]const u8 {
        try stream.writeVarInt(Packet.ClientboundUpdateSoundData);
        try stream.writeInt64(self.server_sound_handle, .Little);

        const type_id: u8 = @intFromEnum(std.meta.activeTag(self.event));
        try stream.writeVarInt(type_id);
        try stream.writeUint8(type_id);
        switch (self.event) {
            .Stop, .Pause, .Resume => {},
            .SetVolume => |v| try stream.writeFloat32(v, .Little),
            .SetPitch => |p| try stream.writeFloat32(p, .Little),
            .Fade => |f| {
                try stream.writeFloat32(f.duration, .Little);
                try stream.writeFloat32(f.target_volume, .Little);
            },
            .SeekTo => |s| try stream.writeFloat32(s, .Little),
        }

        return stream.getBuffer();
    }
};
