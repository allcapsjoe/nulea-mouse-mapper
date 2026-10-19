const assert = require("node:assert/strict");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");
const { after, before, test } = require("node:test");
const { createButtonLabServer, MAX_PLAN_BYTES } = require("./server");

const testHost = "127.0.0.1:test";
const testOrigin = `http://${testHost}`;
const temporaryRoot = fs.mkdtempSync(path.join(os.tmpdir(), "nulea-button-lab-"));
fs.writeFileSync(path.join(temporaryRoot, "index.html"), "<!doctype html><title>Button Lab</title>");

const server = createButtonLabServer({
  root: temporaryRoot,
  allowedHosts: [testHost],
  logger: { error() {} }
});

let address;

before(async () => {
  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });
  address = server.address();
});

after(async () => {
  await new Promise(resolve => server.close(resolve));
  fs.rmSync(temporaryRoot, { recursive: true, force: true });
});

function request({ method = "GET", url = "/", host = testHost, origin, type, body }) {
  return new Promise((resolve, reject) => {
    const headers = { Host: host };
    if (origin) headers.Origin = origin;
    if (type) headers["Content-Type"] = type;
    if (body) headers["Content-Length"] = Buffer.byteLength(body);

    const req = http.request({
      hostname: "127.0.0.1",
      port: address.port,
      method,
      path: url,
      headers
    }, res => {
      let responseBody = "";
      res.setEncoding("utf8");
      res.on("data", chunk => { responseBody += chunk; });
      res.on("end", () => resolve({
        statusCode: res.statusCode,
        headers: res.headers,
        body: responseBody
      }));
    });

    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

test("serves Button Lab only for an allowed host", async () => {
  const response = await request({});
  assert.equal(response.statusCode, 200);
  assert.match(response.body, /Button Lab/);
  assert.equal(response.headers["cache-control"], "no-store");
});

test("saves a same-origin JSON plan", async () => {
  const response = await request({
    method: "POST",
    url: "/plan",
    origin: testOrigin,
    type: "application/json; charset=utf-8",
    body: JSON.stringify({ right: "disabled", back: "right-click" })
  });

  assert.equal(response.statusCode, 204);
  const saved = JSON.parse(fs.readFileSync(path.join(temporaryRoot, "mapping-plan.json"), "utf8"));
  assert.deepEqual(saved, { right: "disabled", back: "right-click" });
});

test("rejects cross-origin plan writes", async () => {
  const response = await request({
    method: "POST",
    url: "/plan",
    origin: "https://example.com",
    type: "application/json",
    body: "{}"
  });
  assert.equal(response.statusCode, 403);
});

test("rejects plan writes with a non-JSON content type", async () => {
  const response = await request({
    method: "POST",
    url: "/plan",
    origin: testOrigin,
    type: "text/plain",
    body: "{}"
  });
  assert.equal(response.statusCode, 403);
});

test("rejects requests using an untrusted Host header", async () => {
  const response = await request({ host: "attacker.example" });
  assert.equal(response.statusCode, 403);
});

test("rejects malformed JSON without exposing error details", async () => {
  const response = await request({
    method: "POST",
    url: "/plan",
    origin: testOrigin,
    type: "application/json",
    body: "{"
  });
  assert.equal(response.statusCode, 400);
  assert.equal(response.body, "Invalid plan.");
});

test("rejects oversized plans with 413", async () => {
  const response = await request({
    method: "POST",
    url: "/plan",
    origin: testOrigin,
    type: "application/json",
    body: `"${"x".repeat(MAX_PLAN_BYTES)}"`
  });
  assert.equal(response.statusCode, 413);
});
