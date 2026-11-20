import assert from "node:assert/strict";
import { once } from "node:events";
import { test } from "node:test";
import { createMuseBridge } from "../server/muse.mjs";

test("Muse bridge authenticates, sends a single prompt, and returns the answer", async t => {
    const token = "ab".repeat(32);
    const id = "a1b2c3d4-0000-0001-0002-000000000001";
    let resolveAnswer, received;
    const answer = new Promise(resolve => { resolveAnswer = resolve; });
    const server = createMuseBridge({ token, sessionId: id, send: (message, session) => {
        received = {message, session};
        return answer;
    }}).listen(0, "127.0.0.1");
    await once(server, "listening");
    t.after(() => {
        server.closeAllConnections();
        return new Promise(resolve => server.close(resolve));
    });
    const address = "http://127.0.0.1:" + server.address().port + "/api/muse/";
    const headers = { authorization: "Bearer " + token, "content-type": "application/json" };
    const request = (path, method = "GET", value) => fetch(address + path,
        {headers, method, ...(value ? {body: JSON.stringify(value)} : {})});

    assert.equal((await fetch(address + "status")).status, 401);
    assert.deepEqual(await (await request("status")).json(), { service: "goc-muc-muse" });
    assert.equal((await request("jobs", "POST", { message: " " })).status, 400);
    const submit = await request("jobs","POST",{message:"Xin chào Muse"});
    assert.equal(submit.status, 200);
    const job = await submit.json();
    assert.equal((await request("jobs","POST",{message:"Tin nhắn thứ hai"})).status, 409);
    assert.deepEqual(received, {message:"Xin chào Muse", session:id});
    assert.deepEqual(await (await request("jobs/" + job.id)).json(), {state:"waiting"});
    resolveAnswer({state:"done",answer:"Xin chào từ Muse"});
    assert.deepEqual(await (await request("jobs/" + job.id)).json(), {state:"done",answer:"Xin chào từ Muse"});
});