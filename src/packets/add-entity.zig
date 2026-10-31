const BinaryStream = @import("BinaryStream").BinaryStream;
const Packet = @import("../enums/packet.zig").Packet;
const Vector3f = @import("../types/vector3f.zig").Vector3f;
const DataItem = @import("../types/data-item.zig").DataItem;
const PropertySyncData = @import("../types/property-sync-data.zig").PropertySyncData;
const PassengerOfBlockData = @import("../types/passenger-of-block-data.zig").PassengerOfBlockData;

pub const AddEntityPacket = struct {
    unique_entity_id: i64,
    runtime_entity_id: u64,
    entity_type: []const u8,
    position: Vector3f,
    velocity: Vector3f = Vector3f.init(0, 0, 0),
    pitch: f32 = 0,
    yaw: f32 = 0,
    head_yaw: f32 = 0,
    body_yaw: f32 = 0,
    entity_metadata: []const DataItem = &[_]DataItem{},
    entity_properties: PropertySyncData,
    passenger_of_block: ?PassengerOfBlockData = null,

    pub fn serialize(self: *const AddEntityPacket, stream: *BinaryStream) ![]const u8 {
        try stream.writeVarInt(Packet.AddEntity);
        try stream.writeZigZong(self.unique_entity_id);
        try stream.writeVarLong(self.runtime_entity_id);
        try stream.writeVarString(self.entity_type);
        try Vector3f.write(stream, self.position);
        try Vector3f.write(stream, self.velocity);
        try stream.writeFloat32(self.pitch, .Little);
        try stream.writeFloat32(self.yaw, .Little);
        try stream.writeFloat32(self.head_yaw, .Little);
        try stream.writeFloat32(self.body_yaw, .Little);

        // attributes (empty)
        try stream.writeVarInt(0);

        // entity metadata
        try stream.writeVarInt(@intCast(self.entity_metadata.len));
        for (self.entity_metadata) |item| {
            try item.write(stream);
        }

        try self.entity_properties.write(stream);

        // entity links (empty)
        try stream.writeVarInt(0);

        if (self.passenger_of_block) |passenger| {
            try stream.writeBool(true);
            try PassengerOfBlockData.write(stream, passenger);
        } else {
            try stream.writeBool(false);
        }

        return stream.getBuffer();
    }
};
