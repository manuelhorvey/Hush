#!/usr/bin/env python3
"""Smoke test for Sprint 7 — multi-participant group conversations with E2EE."""

import json, sys, time, urllib.request

AUTH = "http://localhost:8081"
IDENTITY = "http://localhost:8082"
MSG = "http://localhost:8083"

suffix = str(int(time.time() * 1000000))[-8:]

def req(method, url, body=None, headers=None):
    h = {"Content-Type": "application/json", **(headers or {})}
    data = json.dumps(body).encode() if body else None
    r = urllib.request.Request(url, data=data, method=method, headers=h)
    try:
        resp = urllib.request.urlopen(r)
        text = resp.read().decode()
        return resp.status, json.loads(text) if text.strip() else {}
    except urllib.error.HTTPError as e:
        text = e.read().decode()
        return e.code, json.loads(text) if text.strip() else {}

step = 0
def ok(msg):
    global step; step += 1
    print(f"  {step:2d}. PASS  {msg}")

def fail(msg, status, body):
    print(f"  FAIL  {msg} -> {status} {body}", file=sys.stderr)
    sys.exit(1)

# ── Register 3 users ────────────────────────────────────────────────
users = []
for i in range(3):
    username = f"smoke-user-{i}-{suffix}"
    s, b = req("POST", f"{AUTH}/api/v1/auth/register",
               {"username": username, "public_key": "A"*44})
    if s != 200: fail("register", s, b)
    users.append({"id": str(b["user_id"]), "token": b["token"], "username": username})
    ok(f"register {username} -> id {b['user_id'][:8]}")

# ── Upload exchange keys (X25519) ────────────────────────────────────
for u in users:
    s, b = req("POST", f"{IDENTITY}/api/v1/identity/keys/exchange",
               {"x25519_public_key": "X"*44},
               {"Authorization": f"Bearer {u['token']}"})
    if s != 200: fail("upload exchange key", s, b)
    ok(f"store exchange key for {u['username']}")

# ── Create 3-person conversation ────────────────────────────────────
encrypted_keys = {u["id"]: f"enc-key-{u['username']}" for u in users}
payload = {
    "participant_ids": [u["id"] for u in users[1:]],
    "encrypted_keys": encrypted_keys,
}
s, b = req("POST", f"{MSG}/api/v1/conversations", payload,
           {"Authorization": f"Bearer {users[0]['token']}"})
if s != 200: fail("create conversation", s, b)
conv_id = b.get("id", "")
if not conv_id: fail("no conv id", s, b)
ok(f"create 3-person conversation {conv_id[:8]}")

# ── Get group key for each participant ──────────────────────────────
for u in users:
    s, b = req("GET", f"{MSG}/api/v1/conversations/{conv_id}/key",
               headers={"Authorization": f"Bearer {u['token']}"})
    if s != 200: fail("get group key", s, b)
    expected = f"enc-key-{u['username']}"
    if b.get("encrypted_key") != expected: fail(f"key mismatch", s, b)
    ok(f"group key for {u['username']}")

# ── List participants ────────────────────────────────────────────────
s, b = req("GET", f"{MSG}/api/v1/conversations/{conv_id}/participants",
           headers={"Authorization": f"Bearer {users[0]['token']}"})
if s != 200: fail("list participants", s, b)
pids = [p["user_id"] for p in b.get("participants", [])]
for u in users:
    if u["id"] not in pids: fail(f"missing {u['username']}", s, b)
ok(f"{len(pids)} participants")

# ── Send message ──────────────────────────────────────────────────────
s, b = req("POST", f"{MSG}/api/v1/conversations/{conv_id}/messages",
           {"ciphertext": "encrypted:hello-group"},
           {"Authorization": f"Bearer {users[0]['token']}"})
if s != 200: fail("send message", s, b)
msg_id = b.get("id", "")
ok(f"send message {msg_id[:8]}")

# ── Get messages ─────────────────────────────────────────────────────
s, b = req("GET", f"{MSG}/api/v1/conversations/{conv_id}/messages",
           headers={"Authorization": f"Bearer {users[0]['token']}"})
if s != 200: fail("list messages", s, b)
msgs = b.get("messages", [])
if len(msgs) < 1: fail("no messages", s, b)
ok(f"{len(msgs)} message(s)")

# ── Complete conversation ────────────────────────────────────────────
s, b = req("PATCH", f"{MSG}/api/v1/conversations/{conv_id}/complete",
           headers={"Authorization": f"Bearer {users[0]['token']}"})
if s != 200: fail("complete conversation", s, b)
status = b.get("status", "")
if status != "completed": fail(f"expected completed, got {status}", s, b)
ok(f"complete -> {status}")

# ── Destroy conversation ─────────────────────────────────────────────
s, b = req("DELETE", f"{MSG}/api/v1/conversations/{conv_id}",
           headers={"Authorization": f"Bearer {users[0]['token']}"})
if s != 204: fail("destroy conversation", s, b)
ok("destroy -> 204")

# ── Key fetch returns 404 after destroy ─────────────────────────────
s, b = req("GET", f"{MSG}/api/v1/conversations/{conv_id}/key",
           headers={"Authorization": f"Bearer {users[0]['token']}"})
if s != 404: fail(f"expected 404 for destroyed conv key, got {s}", s, b)
ok("group key 404 after destroy")

# ── Participants returns 404 after destroy (rows deleted) ──────────
s, b = req("GET", f"{MSG}/api/v1/conversations/{conv_id}/participants",
           headers={"Authorization": f"Bearer {users[0]['token']}"})
if s != 404: fail(f"expected 404 for destroyed conv participants, got {s}", s, b)
ok("participants 404 after destroy")

print(f"\n✓ All {step} smoke tests passed!")
