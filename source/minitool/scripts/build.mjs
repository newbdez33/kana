import { copyFileSync, mkdirSync, readdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { readIOSData } from './ios-data.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const output = path.join(root, 'build/web');
mkdirSync(path.join(output, 'assets'), { recursive: true });
for (const file of readdirSync(path.join(root, 'app'))) {
  copyFileSync(path.join(root, 'app', file), path.join(output, file));
}
copyFileSync(path.join(root, 'assets/kana.woff2'), path.join(output, 'assets/kana.woff2'));
writeFileSync(path.join(output, 'data.js'), 'window.KanaData = ' + JSON.stringify(readIOSData()) + ';\n');
console.log(`Built ${output}`);
