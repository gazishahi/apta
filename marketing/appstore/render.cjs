// Renders every .slide in an HTML file to an opaque PNG at its native size.
// Usage: node render.cjs <file.html> <out dir>
const fs = require("fs");
const os = require("os");
const path = require("path");
const http = require("http");
const { chromium } = require("playwright");

function cachedChromium() {
  const root = path.join(os.homedir(), "Library/Caches/ms-playwright");
  const dirs = fs.existsSync(root) ? fs.readdirSync(root).filter((d) => /^chromium-\d+$/.test(d)).sort().reverse() : [];
  for (const d of dirs) {
    const bin = path.join(root, d, "chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing");
    if (fs.existsSync(bin)) return bin;
  }
  return undefined;
}

const TYPES = { ".html": "text/html", ".png": "image/png", ".css": "text/css", ".js": "text/javascript" };

// CSS masks are blocked on file:// pages, so serve this folder over localhost.
function serve(root) {
  const server = http.createServer((req, res) => {
    const file = path.join(root, decodeURIComponent(new URL(req.url, "http://x").pathname));
    if (!file.startsWith(root) || !fs.existsSync(file)) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((resolve) => server.listen(0, "127.0.0.1", () => resolve(server)));
}

(async () => {
  const [html, outDir] = process.argv.slice(2);
  const root = path.dirname(path.resolve(html));
  const server = await serve(root);
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN || cachedChromium() });
  const page = await browser.newPage({ viewport: { width: 5300, height: 3000 } });
  await page.goto(`http://127.0.0.1:${server.address().port}/${path.basename(html)}`, { waitUntil: "networkidle" });
  await page.evaluate(() => document.fonts.ready);
  for (const slide of await page.$$(".slide")) {
    const id = await slide.getAttribute("id");
    const file = path.join(outDir, `${id}.png`);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    await slide.screenshot({ path: file, omitBackground: false });
    console.log(file);
  }
  await browser.close();
  server.close();
})();
