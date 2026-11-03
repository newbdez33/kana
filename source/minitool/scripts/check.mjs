import assert from 'node:assert/strict';
import { existsSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { Script } from 'node:vm';
import { readIOSData } from './ios-data.mjs';

const root = fileURLToPath(new URL('../build/web/', import.meta.url));
const allowed = new Set(['.html', '.css', '.js', '.woff2']);
const files = [];
function collect(directory) {
  for (const name of readdirSync(directory)) {
    const file = path.join(directory, name);
    if (statSync(file).isDirectory()) collect(file);
    else files.push(file);
  }
}
collect(root);
assert.equal(files.filter((file) => path.extname(file) === '.html').length, 1, 'One HTML entry is required.');
const html = readFileSync(path.join(root, 'index.html'), 'utf8');
assert.doesNotMatch(html, /<script\b(?![^>]*\bsrc=)[^>]*>/i, 'Inline scripts are not supported.');
assert.doesNotMatch(html, /\bon\w+\s*=|javascript:|<iframe|<object|\bdownload\s*[=>]/i);
assert.doesNotMatch(html, /http-equiv="Content-Security-Policy"/i, 'The container owns its CSP.');
for (const match of html.matchAll(/(?:src|href)="(\.\/[^"#]+)"/g)) {
  assert.ok(existsSync(path.join(root, match[1])), `Missing resource: ${match[1]}`);
}
for (const file of files) {
  const extension = path.extname(file);
  assert.ok(allowed.has(extension), `Unsupported package file: ${file}`);
  if (extension === '.woff2') continue;
  const source = readFileSync(file, 'utf8');
  assert.doesNotMatch(source, /(?:https?:)?\/\/[^\s'"<>]+\.(?:com|net|org)\b/, `External resource: ${file}`);
  if (extension === '.js') {
    new Script(source, { filename: file });
    assert.doesNotMatch(source, /\b(?:fetch|XMLHttpRequest|WebSocket|Worker|SharedWorker|WebAssembly|eval)\b/);
    assert.doesNotMatch(source, /new\s+Function\b|navigator\.clipboard|window\.open\s*\(/);
    assert.doesNotMatch(source, /\?\.|\?\?|\.flat(?:Map)?\s*\(|\.at\s*\(|\.replaceAll\s*\(/);
    assert.doesNotMatch(source, /data:(?:audio|video)\//, 'Media data URLs are not supported.');
  }
}
const data = readIOSData();
const pool = data.rows.flat().filter((kana) => kana[0]);
assert.equal(pool.length, 46);
assert.equal(new Set(pool.map((kana) => kana[0])).size, 46);
assert.equal(Object.keys(data.copy).length, 8);
const bytes = files.reduce((sum, file) => sum + statSync(file).size, 0);
console.log(`Checked ${files.length} files, ${pool.length} kana, 8 languages, ${bytes} bytes.`);
console.log('Local checks passed. Official upload-skill validation and device checks are still required.');
