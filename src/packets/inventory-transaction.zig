const std = @import("std");

const BinaryStream = @import("BinaryStream").BinaryStream;

pub const TransactionType = @import("../enums/transaction-type.zig").TransactionType;
const Packet = @import("../root.zig").Packet;
const BlockPosition = @import("../types/block-position.zig").BlockPosition;
const TransactionTypes = @import("../types/inventory-transaction-data.zig");
pub const TransactionData = TransactionTypes.TransactionData;
pub const NormalTransactionData = TransactionTypes.NormalTransactionData;
pub const UseItemTransactionData = TransactionTypes.UseItemTransactionData;
pub const UseItemOnEntityTransactionData = TransactionTypes.UseItemOnEntityTransactionData;
pub const ReleaseItemTransactionData = TransactionTypes.ReleaseItemTransactionData;
pub const InventoryAction = TransactionTypes.InventoryAction;
pub const LegacySetItemSlot = TransactionTypes.LegacySetItemSlot;
const NetworkItemStackDescriptor = @import("../types/network-item-stack-descriptor.zig").NetworkItemStackDescriptor;
const Vector3f = @import("../types/vector3f.zig").Vector3f;

pub const InventoryTransactionPacket = struct {
    legacy_request_id: i32,
    transaction_type: TransactionType,
    action_count: u32,
    transaction_data: TransactionData,

    pub fn deserialize(stream: *BinaryStream) !InventoryTransactionPacket {
        _ = try stream.readVarInt();

        const legacy_request_id = try stream.readZigZag();

        const has_legacy_slots = try stream.readBool();
        if (has_legacy_slots) {
            const slot_count = try stream.readVarInt();
            for (0..slot_count) |_| {
                _ = try stream.readUint8();
                const byte_count = try stream.readVarInt();
                for (0..byte_count) |_| {
                    _ = try stream.readUint8();
                }
            }
        }

        const transaction_type_raw = try stream.readVarInt();
        const transaction_type: TransactionType = std.enums.fromInt(TransactionType, transaction_type_raw) orelse return error.InvalidTransactionType;

        const action_count: u32 = @intCast(try stream.readVarInt());

        var normal_data = NormalTransactionData{};
        {
            var has_world_drop = false;
            var has_inventory_source = false;
            var world_drop_count: u16 = 0;
            var inventory_source_slot: u32 = 0;
            for (0..action_count) |_| {
                const source_type = try stream.readVarInt();

                var container_id: ?u8 = null;
                if (try stream.readBool()) {
                    container_id = try stream.readUint8();
                }
                if (try stream.readBool()) {
                    _ = try stream.readVarInt();
                }

                const slot = try stream.readVarInt();

                try NetworkItemStackDescriptor.skipShort(stream); // old item
                _ = try stream.readShort(.Little); // new item network id
                const new_count = try stream.readUint16(.Little);
                _ = try stream.readVarInt(); // meta
                if (try stream.readBool()) _ = try stream.readZigZag(); // net id
                _ = try stream.readVarInt(); // block rid
                const extra_len = try stream.readVarInt();
                for (0..extra_len) |_| _ = try stream.readUint8();

                if (source_type == 2 and slot == 0) {
                    has_world_drop = true;
                    world_drop_count = new_count;
                } else if (source_type == 0 and (container_id orelse 255) == 0) {
                    has_inventory_source = true;
                    inventory_source_slot = @intCast(slot);
                }
            }
            normal_data.is_drop = has_world_drop and has_inventory_source and world_drop_count > 0;
            normal_data.drop_slot = inventory_source_slot;
            normal_data.drop_count = world_drop_count;
        }

        // The type-specific payload rides AFTER the actions (empty for
        // Normal transactions with a legacy request id).
        const transaction_data: TransactionData = switch (transaction_type) {
            .UseItem => .{ .use_item = try readUseItem(stream) },
            .UseItemOnEntity => .{ .use_item_on_entity = try readUseItemOnEntity(stream) },
            .ReleaseItem => .{ .release_item = try readReleaseItem(stream) },
            .Normal => .{ .normal = normal_data },
            .Mismatch => .{ .mismatch = {} },
        };

        return .{
            .legacy_request_id = legacy_request_id,
            .transaction_type = transaction_type,
            .action_count = action_count,
            .transaction_data = transaction_data,
        };
    }
};

fn readUseItemOnEntity(stream: *BinaryStream) !UseItemOnEntityTransactionData {
    const target_entity_runtime_id = try stream.readVarLong();
    const action_type = try stream.readZigZag();
    const hot_bar_slot = try stream.readZigZag();
    const hand = try stream.readUint8();
    try NetworkItemStackDescriptor.skipShort(stream);
    const position = try Vector3f.read(stream);
    const clicked_position = try Vector3f.read(stream);

    return .{
        .target_entity_runtime_id = target_entity_runtime_id,
        .action_type = action_type,
        .hot_bar_slot = hot_bar_slot,
        .hand = hand,
        .position = position,
        .clicked_position = clicked_position,
    };
}

fn readReleaseItem(stream: *BinaryStream) !ReleaseItemTransactionData {
    const action_type = try stream.readZigZag();
    const hot_bar_slot = try stream.readZigZag();
    try NetworkItemStackDescriptor.skipShort(stream);
    const head_position = try Vector3f.read(stream);
    const hand = try stream.readUint8();

    return .{
        .action_type = action_type,
        .hot_bar_slot = hot_bar_slot,
        .head_position = head_position,
        .hand = hand,
    };
}

fn readUseItem(stream: *BinaryStream) !UseItemTransactionData {
    const action_type = try stream.readZigZag();
    const trigger_type = try stream.readUint8();
    const block_position = try BlockPosition.read(stream);
    const block_face = try stream.readUint8();
    const hot_bar_slot = try stream.readZigZag();
    const hand = try stream.readUint8();
    try NetworkItemStackDescriptor.skipShort(stream);
    const position = try Vector3f.read(stream);
    const clicked_position = try Vector3f.read(stream);
    const block_runtime_id = try stream.readVarInt();
    const client_prediction = try stream.readUint8();
    const client_cooldown_state = try stream.readUint8();

    return .{
        .action_type = action_type,
        .trigger_type = trigger_type,
        .block_position = block_position,
        .block_face = block_face,
        .hot_bar_slot = hot_bar_slot,
        .hand = hand,
        .position = position,
        .clicked_position = clicked_position,
        .block_runtime_id = block_runtime_id,
        .client_prediction = client_prediction,
        .client_cooldown_state = client_cooldown_state,
    };
}

fn skipInventorySource(stream: *BinaryStream) !void {
    if (try stream.readBool()) {
        if (try stream.readBool()) {
            _ = try stream.readUint8();
        }
    }
    if (try stream.readBool()) {
        if (try stream.readBool()) {
            _ = try stream.readVarInt();
        }
    }
}
