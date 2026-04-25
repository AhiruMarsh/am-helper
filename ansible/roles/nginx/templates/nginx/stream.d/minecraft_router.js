// Minecraft Java handshake packet parser for Nginx NJS stream routing
// Packet format: [PacketLen: VarInt][PacketID: VarInt=0x00][ProtocolVer: VarInt][ServerAddr: String][Port: u16][NextState: VarInt]

function readVarInt(data, pos) {
    var result = 0;
    var shift = 0;
    var b;
    for (var i = 0; i < 5; i++) {
        if (pos >= data.length) return null;
        b = data.charCodeAt(pos++);
        result |= (b & 0x7F) << shift;
        shift += 7;
        if (!(b & 0x80)) return { value: result, next: pos };
    }
    return null;
}

function preread(s) {
    s.on('upload', function(data, flags) {
        if (data.length === 0) return;

        var pos = 0;

        // Packet length
        var pktLen = readVarInt(data, pos);
        if (!pktLen) { s.done(); return; }
        pos = pktLen.next;

        // Packet ID (must be 0x00 = Handshake)
        var pktId = readVarInt(data, pos);
        if (!pktId || pktId.value !== 0) { s.done(); return; }
        pos = pktId.next;

        // Protocol version
        var proto = readVarInt(data, pos);
        if (!proto) { s.done(); return; }
        pos = proto.next;

        // Server address string length
        var strLen = readVarInt(data, pos);
        if (!strLen) { s.done(); return; }
        pos = strLen.next;

        if (pos + strLen.value > data.length) { s.done(); return; }

        // Server address (strip Forge suffix: \0FML\0 etc.)
        var addr = data.substring(pos, pos + strLen.value);
        var nullIdx = addr.indexOf('\0');
        if (nullIdx !== -1) addr = addr.substring(0, nullIdx);

        s.variables.minecraft_server = addr.toLowerCase();
        s.done();
    });
}

export default { preread };
