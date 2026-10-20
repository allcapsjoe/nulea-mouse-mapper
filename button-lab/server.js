const http = require("http");
const fs = require("fs");
const path = require("path");

const DEFAULT_PORT = 8765;
const MAX_PLAN_BYTES = 100_000;

function createButtonLabServer(options = {}) {
  const root = options.root || __dirname;
  const port = options.port || DEFAULT_PORT;
  const logger = options.logger || console;
  const allowedHosts = new Set(
    options.allowedHosts || [`127.0.0.1:${port}`, `localhost:${port}`]
  );
  return http.createServer((req, res) => {
    // Reject DNS-rebinding requests that reach the loopback port under another name.
    if (!allowedHosts.has(req.headers.host)) {
      res.writeHead(403).end();
      return;
    }

    if (req.method === "POST" && req.url === "/plan") {
      // Browser saves must be same-origin JSON requests from the Button Lab page.
      const origin = req.headers.origin;
      const mediaType = (req.headers["content-type"] || "")
        .split(";", 1)[0]
        .trim()
        .toLowerCase();
      if (origin !== `http://${req.headers.host}` || mediaType !== "application/json") {
        res.writeHead(403).end();
        return;
      }

      let body = "";
      let bodyBytes = 0;
      let tooLarge = false;

      req.on("data", chunk => {
        if (tooLarge) return;

        bodyBytes += chunk.length;
        if (bodyBytes > MAX_PLAN_BYTES) {
          tooLarge = true;
          res.writeHead(413, { "Content-Type": "text/plain; charset=utf-8" });
          res.end("Plan is too large.");
          return;
        }

        body += chunk;
      });

      req.on("end", () => {
        if (tooLarge) return;

        try {
          const plan = JSON.parse(body);
          fs.writeFileSync(
            path.join(root, "mapping-plan.json"),
            `${JSON.stringify(plan, null, 2)}\n`
          );
          res.writeHead(204).end();
        } catch (error) {
          logger.error("Plan save failed:", error);
          res.writeHead(400, { "Content-Type": "text/plain; charset=utf-8" });
          res.end("Invalid plan.");
        }
      });
      return;
    }

    fs.readFile(path.join(root, "index.html"), (error, data) => {
      if (error) {
        logger.error("Button Lab page load failed:", error);
        res.writeHead(500).end();
        return;
      }
      res.writeHead(200, {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "no-store",
        "X-Content-Type-Options": "nosniff"
      });
      res.end(data);
    });
  });
}

if (require.main === module) {
  createButtonLabServer().listen(DEFAULT_PORT, "127.0.0.1", () => {
    console.log(`Button Lab: http://127.0.0.1:${DEFAULT_PORT}`);
  });
}

module.exports = { createButtonLabServer, MAX_PLAN_BYTES };
