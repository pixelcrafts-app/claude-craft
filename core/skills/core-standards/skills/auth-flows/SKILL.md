---
name: auth-flows
description: Apply when implementing or reviewing authentication and authorization in any stack — JWT lifecycle, refresh token rotation, guard composition, OAuth PKCE, session invalidation. Active when craft.json features.auth is non-false. Auto-invoke on any file containing auth guards, token handling, session logic, or OAuth flows.
---

# Auth Flows

Universal — applies across NestJS, Next.js, Flutter, and any other stack. Stack-specific implementation patterns live in the respective stack skills; this skill governs the auth contract regardless of implementation.

**Activation:** Active when `craft.json features.auth` is declared. When not declared but auth patterns are detected in changed code: emit INFO in verification, do not enforce.

---

## §A1 Guard Composition — ALWAYS-MANDATORY within auth scope

Every protected endpoint or route must have BOTH:
1. An **authentication guard** — verifies the token is valid and not expired
2. An **authorization guard** — verifies the authenticated identity has permission for this specific resource or action

Authentication alone is not sufficient. A valid token does not mean permission. Never merge auth + permission check into a single guard — they are separate concerns that fail independently.

```typescript
// NestJS — both guards required
@UseGuards(JwtAuthGuard, ResourcePermissionGuard)
@Get(':id')
getItem(@Param('id') id: string) { ... }
```

---

## §A2 Refresh Token Rotation

Every refresh token use must:
1. Issue a new access token
2. Issue a new refresh token
3. Invalidate the previous refresh token immediately

Issuing a new token without invalidating the old one creates a reuse window. If the old token was stolen, the attacker retains access indefinitely.

Refresh token family tracking: if an already-invalidated refresh token is presented (reuse attack), revoke the entire family immediately and force re-login.

---

## §A3 Server-Side Logout

Logout must revoke the refresh token server-side — not just clear the client-side cookie or local storage.

Client-only logout leaves the refresh token valid on the server. An attacker who captured the refresh token retains access until expiry.

Implementation: maintain a token denylist (Redis preferred) or rotate to a new family on logout.

---

## §A4 Token Expiry Bounds

- **Access token expiry: ≤ 15 minutes.** Never "1 hour" or "1 day." The access token is a short-lived credential — its window of usefulness if stolen must be minimal.
- **Refresh token expiry: bounded and explicit.** "Never expires" is not a valid setting. Set an absolute maximum (30 days typical for regular apps, 7 days for sensitive). Refresh tokens must also expire on inactivity (sliding window or last-used tracking).

---

## §A5 OAuth PKCE

For any OAuth 2.0 authorization code flow:
- Generate `code_verifier` client-side (≥ 43 characters, cryptographically random)
- Send only `code_challenge` (SHA-256 hash of verifier) in the authorization request
- Send `code_verifier` only in the token exchange request
- Never transmit `code_verifier` again after the token exchange completes
- Never store `code_verifier` beyond the token exchange

PKCE prevents authorization code interception. Without it, a stolen authorization code can be exchanged for tokens.

---

## §A6 Auth Error Handling

- Never return different error messages for "user not found" vs "wrong password" — both return the same generic response. Distinct messages enable user enumeration.
- Auth errors must be logged server-side with request context but never expose stack traces or internal identifiers to the client.
- Rate-limit auth endpoints: login, token refresh, password reset. Absence of rate limiting on these endpoints is a security gap, not a missing feature.

---

## Verification Checklist

When `craft.json features.auth` is active, Phase 2 verification checks:

- `§A1` — grep for auth-protected routes without both auth + permission guard
- `§A2` — grep for token issuance without corresponding invalidation of previous token
- `§A3` — confirm logout handler calls token revocation, not just cookie clear
- `§A4` — grep for token expiry config values; confirm access ≤15min
- `§A5` — if OAuth used: grep for code_verifier handling; confirm not stored beyond exchange
- `§A6` — confirm auth endpoints have rate limiting middleware
