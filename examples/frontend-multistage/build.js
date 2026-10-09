// Minimal "bundler": reads src/*, stamps a build banner, writes dist/*.
// No dependencies — the point is to show the multi-stage *pattern*, not a real build.
const fs = require("fs");
const path = require("path");

const SRC = path.join(__dirname, "src");
const DIST = path.join(__dirname, "dist");

fs.rmSync(DIST, { recursive: true, force: true });
fs.mkdirSync(DIST, { recursive: true });

const banner = `<!-- built at ${new Date().toISOString()} -->\n`;

for (const file of fs.readdirSync(SRC)) {
  const from = path.join(SRC, file);
  const to = path.join(DIST, file);
  let content = fs.readFileSync(from, "utf8");
  if (file.endsWith(".html")) content = banner + content;
  fs.writeFileSync(to, content);
  console.log(`emitted ${file} (${content.length} bytes)`);
}

console.log("build complete → dist/");
