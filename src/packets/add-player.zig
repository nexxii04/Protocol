const BinaryStream = @import("BinaryStream").BinaryStream;
const Packet = @import("../enums/packet.zig").Packet;
const Uuid = @import("../types/uuid.zig").Uuid;
const Vector3f = @import("../types/vector3f.zig").Vector3f;
const Rotation = @import("../types/rotation.zig").Rotation;
const DataItem = @import("../types/data-item.zig").DataItem;
const PropertySyncData = @import("../types/property-sync-data.zig").PropertySyncData;
const AbilityLayer = @import("../types/ability-layer.zig").AbilityLayer;
const NetworkItemStackDescriptor = @import("../types/network-item-stack-descriptor.zig").NetworkItemStackDescriptor;
const PassengerOfBlockData = @import("../types/passenger-of-block-data.zig").PassengerOfBlockData;

pub const AddPlayerPacket = struct {
    uuid: []const u8,
    username: []const u8,
    entity_runtime_id: i64,
    platform_chat_id: []const u8 = "",
    position: Vector3f,
    velocity: Vector3f = Vector3f.init(0, 0, 0),
    rotation: Rotation = Rotation.init(0, 0, 0),
    carried_item: NetworkItemStackDescriptor = .{ .network = 0 },
    game_type: i32 = 1,
    entity_metadata: []const DataItem = &[_]DataItem{},
    entity_properties: PropertySyncData,
    ability_entity_unique_id: i64 = 0,
    permission_level: u8 = 0,
    command_permission_level: u8 = 0,
    ability_layers: []const AbilityLayer = &[_]AbilityLayer{},
    device_id: []const u8 = "",
    build_platform: i32 = 0,
    passenger_of_block: ?PassengerOfBlockData = null,

    pub fn serialize(self: *const AddPlayerPacket, stream: *BinaryStream) ![]const u8 {
        try stream.writeVarInt(Packet.AddActor);
        try Uuid.write(stream, self.uuid);
        try stream.writeVarString(self.username);
        try stream.writeVarLong(@bitCast(self.entity_runtime_id));
        try stream.writeVarString(self.platform_chat_id);
        try Vector3f.write(stream, self.position);
        try Vector3f.write(stream, self.velocity);
        try stream.writeFloat32(self.rotation.pitch, .Little);
        try stream.writeFloat32(self.rotation.yaw, .Little);
        try stream.writeFloat32(self.rotation.head_yaw, .Little);

        try NetworkItemStackDescriptor.writeShort(stream, self.carried_item, stream.allocator);
        try stream.writeZigZag(self.game_type);

        try stream.writeVarInt(@intCast(self.entity_metadata.len));
        for (self.entity_metadata) |item| {
            try item.write(stream);
        }

        try self.entity_properties.write(stream);

        try stream.writeInt64(self.ability_entity_unique_id, .Little);
        try stream.writeUint8(self.permission_level);
        try stream.writeUint8(self.command_permission_level);
        try stream.writeUint8(@intCast(self.ability_layers.len));
        for (self.ability_layers) |layer| {
            try layer.write(stream);
        }

        try stream.writeVarInt(0);

        if (self.passenger_of_block) |passenger| {
            try stream.writeBool(true);
            try PassengerOfBlockData.write(stream, passenger);
        } else {
            try stream.writeBool(false);
        }

        try stream.writeVarString(self.device_id);
        try stream.writeInt32(self.build_platform, .Little);

        return stream.getBuffer();
    }
};
