const BinaryStream = @import("BinaryStream").BinaryStream;

const BlockPosition = @import("block-position.zig").BlockPosition;
const Vector3f = @import("vector3f.zig").Vector3f;
const EmoteType = @import("../enums/emote-type.zig").EmoteType;

pub const PassengerOfBlockData = struct {
    block_pos: BlockPosition,
    offset: Vector3f,
    rotation: f32,
    rotation_limit: f32,
    emote_type: EmoteType,

    pub fn write(stream: *BinaryStream, value: PassengerOfBlockData) !void {
        try BlockPosition.write(stream, value.block_pos);
        try Vector3f.write(stream, value.offset);
        try stream.writeFloat32(value.rotation, .Little);
        try stream.writeFloat32(value.rotation_limit, .Little);
        try stream.writeUint8(@intFromEnum(value.emote_type));
    }
};
