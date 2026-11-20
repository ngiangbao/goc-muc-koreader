import assert from "node:assert/strict";
import { once } from "node:events";
import { test } from "node:test";
import { createRoomServer } from "../server/room.mjs";

test("Two clients play to a win, with illegal turns and duplicate moves rejected", async t => {
    const server = createRoomServer().listen(0, "127.0.0.1");
    await once(server, "listening");
    t.after(() => {
        server.closeAllConnections();
        return new Promise(resolve => server.close(resolve));
    });
    const url = "http://127.0.0.1:" + server.address().port;

    async function post(path, payload, token) {
        const headers = { "content-type": "application/json" };
        if (token) headers.authorization = "Bearer " + token;
        const response = await fetch(url + path, { method: "POST", headers, body: JSON.stringify(payload) });
        return [response.status, await response.json()];
    }

    const landing = await fetch(url + "/");
    assert.equal(landing.status, 200);
    assert.match(await landing.text(), /Cờ caro/);

    const [created, x] = await post("/api/rooms", {});
    assert.equal(created, 200);
    assert.equal(x.mark, "X");
    assert.equal(x.joined, false);
    const room = "/api/rooms/" + x.code;

    const [joined, o] = await post(room + "/join", {});
    assert.equal(joined, 200);
    assert.equal(o.mark, "O");
    assert.equal(o.joined, true);
    assert.equal((await post(room + "/join", {}))[0], 409);
    assert.equal((await post(room + "/move", { index: 5, ply: 0 }, o.token))[0], 409);
    assert.equal((await post(room + "/move", { index: 5, ply: 0 }))[0], 403);
    for (let i = 0; i < 9; i++) {
        const index = i % 2 === 0 ? 82 + i / 2 : 108 + (i - 1) / 2;
        const [code, data] = await post(room + "/move", { index, ply: i }, i % 2 === 0 ? x.token : o.token);
        assert.equal(code, 200);
        assert.equal(data.moves.length, i + 1);
        if (i === 0) {
            assert.equal((await post(room + "/move", { index, ply: 1 }, o.token))[0], 409);
            assert.equal((await post(room + "/move", { index: 25, ply: 0 }, o.token))[0], 409);
        }
        if (i === 8) assert.equal(data.winner, "X");
    }
    assert.equal((await post(room + "/move", { index: 1, ply: 9 }, o.token))[0], 409);
    const publicState = await (await fetch(url + room)).json();
    assert.equal(publicState.winner, "X");
    assert.equal(publicState.token, undefined);
});
