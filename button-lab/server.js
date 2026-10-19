const http = require("http");
const fs = require("fs");
const path = require("path");

const root = __dirname;
const port = 8765;

http.createServer((req, res) => {
  if (req.method === "POST" && req.url === "/plan") {
    let body = "";
    req.on("data", chunk => {
      body += chunk;
      if (body.length > 100_000) req.destroy();
    });
    req.on("end", () => {
      try {
        const plan = JSON.parse(body);
        fs.writeFileSync(path.join(root, "mapping-plan.json"), JSON.stringify(plan, null, 2) + "\n");
        res.writeHead(204).end();
      } catch (error) {
        console.error("Plan save failed:", error);
        res.writeHead(400, { "Content-Type": "text/plain; charset=utf-8" }).end(String(error));
      }
    });
    return;
  }

  fs.readFile(path.join(root, "index.html"), (error, data) => {
    if (error) {
      res.writeHead(500).end(String(error));
      return;
    }
    res.writeHead(200, {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store"
    });
    res.end(data);
  });
}).listen(port, "127.0.0.1", () => {
  console.log(`Button Lab: http://127.0.0.1:${port}`);
});
