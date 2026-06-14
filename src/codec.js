// Compress + URL-safe base64 for anything that travels inside a link or token:
// challenge payloads (share.js) and WebRTC SDP offer/answer tokens (room.js).
// Reused verbatim from AgentHerd's encodeSDP/decodeSDP.

export async function pack(obj) {
  const json = JSON.stringify(obj);
  const cs = new CompressionStream('deflate-raw');
  const w = cs.writable.getWriter();
  w.write(new TextEncoder().encode(json));
  w.close();
  const buf = await new Response(cs.readable).arrayBuffer();
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

export async function unpack(token) {
  const b64 = token.trim().replace(/-/g, '+').replace(/_/g, '/');
  const padded = b64 + '='.repeat((4 - (b64.length % 4)) % 4);
  const bytes = Uint8Array.from(atob(padded), (c) => c.charCodeAt(0));
  const ds = new DecompressionStream('deflate-raw');
  const w = ds.writable.getWriter();
  w.write(bytes);
  w.close();
  const buf = await new Response(ds.readable).arrayBuffer();
  return JSON.parse(new TextDecoder().decode(buf));
}

// SDP <-> token helpers for the WebRTC handshake.
export const encodeSDP = (desc) => pack({ type: desc.type, sdp: desc.sdp });
export const decodeSDP = (token) => unpack(token);
