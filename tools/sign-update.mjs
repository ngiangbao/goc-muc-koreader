import { createPrivateKey, createPublicKey, sign } from "node:crypto";
import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const [pluginPath, keyPath, output] = process.argv.slice(2);
if (!pluginPath || !keyPath || !output) {
    throw new Error("Usage: node tools/sign-update.mjs <plugin-dir> <private-key.pem> <update.json>");
}
const files = {};
for (const entry of readdirSync(pluginPath, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    if (!entry.isFile() || !/^[A-Za-z0-9_-]+\.lua$/.test(entry.name)) {
        throw new Error("The OTA format accepts only top-level Lua files: " + entry.name);
    }
    files[entry.name] = readFileSync(join(pluginPath, entry.name), "utf8");
}
const version = files["_meta.lua"]?.match(/version\s*=\s*"(\d+\.\d+\.\d+)"/)?.[1];
if (!version || !files["main.lua"] || !files["ota.lua"] || !files["ota_key.lua"]) {
    throw new Error("Missing entry point, updater or valid version");
}
const key = createPrivateKey(readFileSync(keyPath));
const publicPem = createPublicKey(key).export({ type: "spki", format: "pem" }).trim();
if (key.asymmetricKeyType !== "rsa" || key.asymmetricKeyDetails.modulusLength !== 3072
    || !files["ota_key.lua"].includes(publicPem)) {
    throw new Error("Signing key differs from the public key installed in Góc Mực");
}
const payload = JSON.stringify({schema:1, project:"ngiangbao/goc-muc-koreader", version, files});
const signature = sign("sha256", Buffer.from(payload), key).toString("hex");
writeFileSync(output, JSON.stringify({payload,signature}) + "\n", {flag:"wx"});