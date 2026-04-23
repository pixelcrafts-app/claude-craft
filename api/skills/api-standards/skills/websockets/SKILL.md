---
name: websockets
description: Apply when implementing or reviewing real-time features using WebSockets — connection lifecycle, authentication on connect, reconnection strategy, event schema, room management. Conditional: active when craft.json features.realtime is true, OR when socket.io/ws/WebSocket found in package manifest AND WebSocket usage patterns exist in source files.
---

# WebSockets

**Activation (both conditions required for auto-trigger):**
1. `socket.io`, `ws`, or `WebSocket` present in any package manifest
2. WebSocket usage patterns in source: `@WebSocketGateway`, `io.connect()`, `new WebSocket()`, or event emission/subscription patterns

The `ws` package alone is not sufficient — many tools use it internally without exposing WebSocket APIs. Require both package presence AND usage pattern before activating.

When `craft.json features.realtime: true`: activate unconditionally.

---

## §W1 Authentication on Connection

Every WebSocket connection must authenticate before being permitted to subscribe to any room, channel, or event stream.

Authentication must happen on the `connection` event — not deferred to the first message.

```typescript
// NestJS Gateway
@WebSocketGateway()
export class EventsGateway {
  handleConnection(client: Socket) {
    const token = client.handshake.auth.token;
    const user = this.authService.verifyToken(token);
    if (!user) {
      client.disconnect(true); // true = close underlying connection
      return;
    }
    client.data.user = user;
  }
}
```

A connection that is not authenticated within the connection handler must be disconnected — not left open awaiting a future auth message. Unauthenticated connections that remain open are an information leak and a resource exhaustion vector.

---

## §W2 Reconnection with Exponential Backoff

Clients must implement reconnection with exponential backoff. Immediate reconnect loops on disconnect cause server-side thundering herd during outages.

Required backoff schedule:
- Attempt 1: 1 second
- Attempt 2: 2 seconds
- Attempt 3: 4 seconds
- Maximum: 3 retries, then surface connection error to the user

After max retries: show explicit offline/disconnected state. Do not silently retry indefinitely.

```typescript
// socket.io-client
const socket = io(url, {
  reconnection: true,
  reconnectionAttempts: 3,
  reconnectionDelay: 1000,
  reconnectionDelayMax: 4000,
});
```

---

## §W3 Event Names in Shared Enum

All WebSocket event names must be defined in a shared enum or constants file — not as raw strings in handlers or listeners.

```typescript
// shared/events.enum.ts
export enum SocketEvent {
  MESSAGE_SENT = 'message:sent',
  USER_JOINED = 'user:joined',
  ERROR = 'error',
}

// Usage — never raw strings
socket.emit(SocketEvent.MESSAGE_SENT, payload);
socket.on(SocketEvent.USER_JOINED, handler);
```

Raw string event names across multiple files produce silent mismatch bugs when names are renamed or typo'd. The enum is the contract — one change location, all usages break at compile time.

---

## §W4 Versioned Event Schema

Server emits a `schema` event on connection containing the current event schema version. Clients reject connections from incompatible schema versions before subscribing to events.

```typescript
// Server — on connection after auth
client.emit('schema', { version: '2.1.0', events: Object.values(SocketEvent) });

// Client — on schema event
socket.on('schema', ({ version }) => {
  if (!isCompatible(version, CLIENT_SCHEMA_VERSION)) {
    socket.disconnect();
    showUpdatePrompt();
  }
});
```

This prevents old client versions from silently misinterpreting events when the event schema changes.

---

## §W5 Room Authorization

Before joining a room, verify the authenticated user has permission for that room. Do not let clients join arbitrary rooms by name.

```typescript
@SubscribeMessage('join-room')
handleJoinRoom(client: Socket, roomId: string) {
  const canAccess = this.permissionService.canAccessRoom(client.data.user, roomId);
  if (!canAccess) {
    client.emit('error', { code: 'room.access_denied' });
    return;
  }
  client.join(roomId);
}
```

---

## Verification Checklist

When websockets skill is active, Phase 2 checks:

- `§W1` — grep for `handleConnection` or connection handler; confirm token verification and `disconnect()` on failure
- `§W2` — grep for reconnection config; confirm backoff values and max retry limit
- `§W3` — grep for raw string event names (`socket.emit('...', ` or `socket.on('...',`); flag any not referencing the enum
- `§W4` — grep for `schema` event emission on connection
- `§W5` — grep for `join` calls; confirm permission check precedes each `client.join()`
