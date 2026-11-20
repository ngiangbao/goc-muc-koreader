"use strict";

const lobby = document.getElementById("lobby");
const board = document.getElementById("board");
const status = document.getElementById("status");
let game;
let busy = false;
let pollTimer;

async function request(path, data, token) {
    const options = { headers: {} };
    if (data) {
        options.method = "POST";
        options.headers["content-type"] = "application/json";
        options.body = JSON.stringify(data);
    }
    if (token) options.headers.authorization = "Bearer " + token;
    const response = await fetch(path, options);
    const body = await response.json();
    if (!response.ok) throw new Error(body.error || "Lỗi máy chủ.");
    return body;
}

function render() {
    const turn = game.moves.length % 2 === 0 ? "X" : "O";
    const stage = game.winner === "draw" ? "Hòa" : game.winner ? game.winner + " thắng"
        : !game.joined ? "Đang chờ người thứ hai" : "Lượt " + turn;
    status.textContent = "Phòng " + game.code + " · Bạn " + game.mark + " · " + stage;
    const marks = [];
    game.moves.forEach((index, n) => { marks[index] = n % 2 === 0 ? "X" : "O"; });
    if (!board.firstChild) {
        for (let i = 1; i <= 169; i++) {
            const cell = document.createElement("button");
            cell.type = "button";
            cell.addEventListener("click", () => move(i));
            board.appendChild(cell);
        }
    }
    Array.from(board.children).forEach((cell, i) => {
        const mark = marks[i + 1];
        cell.textContent = mark || "";
        cell.disabled = !!(mark || !game.joined || game.winner || turn !== game.mark);
        cell.classList.toggle("last", game.moves[game.moves.length - 1] === i + 1);
        cell.setAttribute("aria-label", "Hàng " + (Math.floor(i / 13) + 1) + ", cột " + (i % 13 + 1)
            + (mark ? ", " + mark : ""));
    });
}

function schedulePoll() {
    clearTimeout(pollTimer);
    if (game && !game.winner) pollTimer = setTimeout(poll, 3500);
}

async function poll() {
    if (busy) return schedulePoll();
    busy = true;
    try {
        const latest = await request("/api/rooms/" + game.code);
        if (latest.joined !== game.joined || latest.moves.length !== game.moves.length || latest.winner !== game.winner) {
            Object.assign(game, latest);
            render();
        }
    } catch (err) {
        status.textContent = err.message;
    } finally {
        busy = false;
        schedulePoll();
    }
}

async function move(index) {
    if (busy) return;
    busy = true;
    try {
        const updated = await request("/api/rooms/" + game.code + "/move", { index, ply: game.moves.length }, game.token);
        Object.assign(game, updated);
        render();
    } catch (err) {
        status.textContent = err.message;
    } finally {
        busy = false;
        schedulePoll();
    }
}

async function start(path) {
    if (busy) return;
    busy = true;
    try {
        game = await request(path, {});
        render();
    } catch (err) {
        status.textContent = err.message;
    } finally {
        busy = false;
        schedulePoll();
    }
}

document.getElementById("new").addEventListener("click", () => start("/api/rooms"));
lobby.addEventListener("submit", event => {
    event.preventDefault();
    const code = document.getElementById("code").value.trim().toUpperCase();
    if (/^[A-Z0-9]{6}$/.test(code)) start("/api/rooms/" + code + "/join");
    else status.textContent = "Nhập mã phòng gồm 6 ký tự.";
});