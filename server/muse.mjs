import { createServer } from "node:http";
import { spawn } from "node:child_process";
import { randomUUID, timingSafeEqual } from "node:crypto";
import { pathToFileURL } from "node:url";

const waitSeconds = 120;
const requestLimit = 8192;
const resultLimit = 32768;

function tailnetIp(host) {
    const parts = host.split(".").map(Number);
    return /^100\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(host)
        && parts[1] >= 64 && parts[1] <= 127
        && parts[2] <= 255 && parts[3] <= 255;
}

function respond(res, code, value) {
    res.writeHead(code, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
    res.end(JSON.stringify(value));
}

function authorized(request, token) {
    const expected = Buffer.from("Bearer " + token);
    const actual = Buffer.from(request.headers.authorization || "");
    return actual.length === expected.length && timingSafeEqual(actual, expected);
}

async function readPrompt(request) {
    const parts = [];
    let length = 0;
    for await (const chunk of request) {
        length += chunk.length;
        if (length > requestLimit) throw new Error("Tin nhắn quá dài.");
        parts.push(chunk);
    }
    const decoded = JSON.parse(Buffer.concat(parts).toString("utf8"));
    const prompt = typeof decoded.message === "string" ? decoded.message.trim() : "";
    if (!prompt || Buffer.byteLength(prompt) > 4000) throw new Error("Tin nhắn trống hoặc quá dài.");
    return prompt;
}

function askGadget(prompt, sessionId, command) {
    return new Promise(resolve => {
        const process = spawn(command, ["send-user-msg", "--session-id", sessionId, "--wait", String(waitSeconds), "-"],
            { stdio: ["pipe", "pipe", "ignore"] });
        const timeout = setTimeout(() => process.kill("SIGKILL"), (waitSeconds + 20) * 1000);
        timeout.unref();
        const pieces = [];
        let used = 0;
        process.stdout.on("data", chunk => {
            if (used >= resultLimit) return;
            pieces.push(chunk.subarray(0, resultLimit - used));
            used += chunk.length;
        });
        process.stdin.on("error", () => {});
        process.on("error", () => {
            clearTimeout(timeout);
            resolve({ state: "error", message: "Cầu nối chưa gọi được Muse Gadget SDK." });
        });
        process.on("close", code => {
            clearTimeout(timeout);
            const answer = Buffer.concat(pieces).toString("utf8").trim();
            if (code === 0 && answer) resolve({ state: "done", answer });
            else if (code === 3 || code === null) resolve({ state: "timeout", answer,
                message: "Chưa nhận được câu trả lời đầy đủ. Kiểm tra chat phụ trong ứng dụng Muse." });
            else resolve({ state: "error", message: "Muse Gadget SDK không gửi được tin. Kiểm tra ghép nối trên máy chủ." });
        });
        process.stdin.end(prompt);
    });
}

export function createMuseBridge({ token, sessionId = randomUUID(),
    command = "musegadget", send = askGadget } = {}) {
    if (!/^[a-f0-9]{64}$/.test(token || "")) throw new Error("Set MUSE_BRIDGE_TOKEN to 32 random bytes in hex.");
    if (!/^[a-f0-9]{8}(?:-[a-f0-9]{4}){3}-[a-f0-9]{12}$/i.test(sessionId)) throw new Error("Invalid MUSE_SESSION_ID.");
    const jobs = new Map();
    let pending = false;
    return createServer({ requestTimeout: 10000, headersTimeout: 10000 }, async (request, res) => {
        if (!authorized(request, token)) return respond(res, 401, { error: "Khóa cầu nối không đúng." });
        const { method, url } = request;
        if (method === "GET" && url === "/api/muse/status") return respond(res, 200, { service: "goc-muc-muse" });
        const existing = url.match(/^\/api\/muse\/jobs\/([a-f0-9-]{36})$/);
        if (method === "GET" && existing) {
            const job = jobs.get(existing[1]);
            if (!job || Date.now() - job.created > 15 * 60_000) {
                return respond(res, 404, { error: "Tin nhắn đã hết thời gian lưu trên cầu nối." });
            }
            return respond(res, 200, job.result);
        }
        if (method !== "POST" || url !== "/api/muse/jobs") return respond(res, 404, { error: "Không tìm thấy." });
        if (!/^application\/json(?:;|$)/i.test(request.headers["content-type"] || "")) {
            return respond(res, 415, { error: "Cần nội dung JSON." });
        }
        let prompt;
        try { prompt = await readPrompt(request); }
        catch { return respond(res, 400, { error: "Tin nhắn không hợp lệ hoặc quá dài." }); }
        if (pending) return respond(res, 409, { error: "Muse đang xử lý tin nhắn trước." });
        if (jobs.size >= 32) jobs.delete(jobs.keys().next().value);
        const id = randomUUID();
        const job = { created: Date.now(), result: { state: "waiting" } };
        jobs.set(id, job);
        pending = true;
        respond(res, 200, { id });
        Promise.resolve().then(() => send(prompt, sessionId, command)).then(result => {
            job.result = result;
        }, () => {
            job.result = { state: "error", message: "Không nhận được phản hồi từ cầu nối Muse." };
        }).finally(() => { pending = false; });
    });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
    const host = process.env.MUSE_BIND || "127.0.0.1";
    const port = Number(process.env.MUSE_PORT || 8091);
    if (host !== "127.0.0.1" && !tailnetIp(host)) throw new Error("MUSE_BIND must be a Tailscale IPv4 address.");
    createMuseBridge({ token: process.env.MUSE_BRIDGE_TOKEN, sessionId: process.env.MUSE_SESSION_ID })
        .listen(port, host, () => console.log("Góc Mực · Muse — " + host + ":" + port));
}
