import { createServer } from "node:http";
import { randomBytes, randomInt } from "node:crypto";
import { readFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

const size = 13;
const alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";
const directions = [[1, 0], [0, 1], [1, 1], [1, -1]];
const html = readFileSync(new URL("index.html", import.meta.url));
const script = readFileSync(new URL("room-ui.js", import.meta.url));

function indexOf(x, y) {
    return x >= 0 && y >= 0 && x < size && y < size ? y * size + x + 1 : 0;
}

function hasWon(board, index, mark) {
    const x = (index - 1) % size;
    const y = Math.floor((index - 1) / size);
    return directions.some(([dx, dy]) => {
        let length = 1;
        let blocked = 0;
        for (const direction of [-1, 1]) {
            let step = direction;
            let next = indexOf(x + dx * step, y + dy * step);
            while (next && board[next] === mark) {
                length++;
                step += direction;
                next = indexOf(x + dx * step, y + dy * step);
            }
            if (!next || board[next]) blocked++;
        }
        return length >= 5 && blocked < 2;
    });
}

async function readJson(request) {
    const chunks = [];
    let bytes = 0;
    for await (const chunk of request) {
        bytes += chunk.length;
        if (bytes > 1024) throw new Error("Yêu cầu quá dài.");
        chunks.push(chunk);
    }
    return JSON.parse(Buffer.concat(chunks));
}

function reply(response, code, data) {
    response.writeHead(code, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
    response.end(JSON.stringify(data));
}

function state(room) {
    return { code: room.code, moves: room.moves, joined: !!room.tokens.O, winner: room.winner };
}

function serve(response, content, type) {
    response.writeHead(200, {
        "content-type": type + "; charset=utf-8",
        "content-security-policy": "default-src 'self'; style-src 'unsafe-inline'; frame-ancestors 'none'",
        "x-content-type-options": "nosniff",
        "referrer-policy": "no-referrer",
    });
    response.end(content);
}

export function createRoomServer() {
    const rooms = new Map();
    const ttl = 6 * 60 * 60 * 1000;
    return createServer({ requestTimeout: 15000, headersTimeout: 10000 }, async (request, response) => {
        try {
            const { method, url, headers } = request;
            if (method === "GET" && url === "/") return serve(response, html, "text/html");
            if (method === "GET" && url === "/room-ui.js") return serve(response, script, "text/javascript");

            if (method === "POST" && headers.origin) {
                let origin;
                try { origin = new URL(headers.origin); } catch {}
                if (!origin || origin.host !== headers.host) return reply(response, 403, { error: "Nguồn yêu cầu không hợp lệ." });
            }
            if (method === "POST" && !/^application\/json(?:;|$)/i.test(headers["content-type"] || "")) {
                return reply(response, 415, { error: "Yêu cầu phải ở định dạng JSON." });
            }

            const now = Date.now();
            if (method === "POST" && url === "/api/rooms") {
                await readJson(request);
                for (const [code, room] of rooms) if (room.updated + ttl < now) rooms.delete(code);
                if (rooms.size >= 256) return reply(response, 503, { error: "Máy chủ đã đủ phòng." });
                let code;
                do {
                    code = Array.from({ length: 6 }, () => alphabet[randomInt(alphabet.length)]).join("");
                } while (rooms.has(code));
                const token = randomBytes(24).toString("hex");
                const room = { code, moves: [], board: [], tokens: { X: token }, updated: now };
                rooms.set(code, room);
                return reply(response, 200, { ...state(room), token, mark: "X" });
            }
            const route = /^\/api\/rooms\/([A-Z0-9]{6})(?:\/(join|move))?$/.exec(url);
            if (!route) return reply(response, 404, { error: "Không tìm thấy đường dẫn." });
            const [, code, command] = route;
            const room = rooms.get(code);
            if (!room || room.updated + ttl < now) return reply(response, 404, { error: "Phòng đã đóng hoặc chưa tồn tại." });
            if (method === "GET" && !command) return reply(response, 200, state(room));
            if (method !== "POST") return reply(response, 405, { error: "Phương thức không hợp lệ." });

            const body = await readJson(request);
            if (!body || typeof body !== "object") return reply(response, 400, { error: "Dữ liệu không hợp lệ." });
            if (command === "join") {
                if (room.tokens.O) return reply(response, 409, { error: "Phòng đã đủ hai người." });
                const token = randomBytes(24).toString("hex");
                room.tokens.O = token;
                room.updated = now;
                return reply(response, 200, { ...state(room), token, mark: "O" });
            }
            if (command !== "move") return reply(response, 405, { error: "Phương thức không hợp lệ." });
            const token = headers.authorization?.match(/^Bearer ([a-f0-9]{48})$/)?.[1];
            const mark = token && room.tokens.X === token ? "X" : token && room.tokens.O === token ? "O" : null;
            if (!mark) return reply(response, 403, { error: "Bạn chưa tham gia phòng." });
            const { index, ply } = body;
            const turn = room.moves.length % 2 === 0 ? "X" : "O";
            if (room.winner || !room.tokens.O || mark !== turn || ply !== room.moves.length
                || !Number.isInteger(index) || index < 1 || index > size * size || room.board[index]) {
                return reply(response, 409, { error: "Nước đi chưa hợp lệ. Hãy làm mới bàn cờ." });
            }
            room.moves.push(index);
            room.board[index] = mark;
            room.updated = now;
            if (hasWon(room.board, index, mark)) room.winner = mark;
            else if (room.moves.length === size * size) room.winner = "draw";
            return reply(response, 200, state(room));
        } catch {
            if (!response.headersSent && !response.destroyed) reply(response, 400, { error: "Yêu cầu không hợp lệ." });
        }
    });
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
    const port = Number(process.env.PORT || 8080);
    const host = process.env.HOST || "0.0.0.0";
    createRoomServer().listen(port, host, () => console.log("Góc Mực · Cờ caro — " + host + ":" + port));
}