import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const source = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(source, '../..');
const output = path.join(root, 'build/h5');
const nativeConfig = await readFile(path.join(root, 'source/kana/kana/configs/AppConfig.swift'), 'utf8');
const match = nativeConfig.match(/static let monographs:[^=]+=\s*(\[[\s\S]*?\n    \]);/);
if (!match) throw new Error('Cannot read the native kana table.');
const rows = JSON.parse(match[1]);
const entries = rows.flat().filter(entry => entry[0]);
if (entries.length !== 46 || entries.some(entry => entry.length !== 3 || entry.some(value => !value))) {
  throw new Error('The basic kana table must contain 46 complete entries.');
}

await mkdir(path.join(output, 'assets'), { recursive: true });
await cp(path.join(source, 'public'), output, { recursive: true });
await cp(path.join(root, 'source/kana/kana/resources/fonts/Hosohuwafont.ttf'), path.join(output, 'assets/kana.ttf'));
await writeFile(path.join(output, 'kana-data.mjs'), `export const rows = ${JSON.stringify(rows)};\nexport const entries = rows.flat().filter(entry => entry[0]);\n`);
const bannerAdUnitId = process.env.TAPTAP_BANNER_AD_UNIT_ID?.trim() ?? '';
await writeFile(path.join(output, 'ad-config.mjs'), `export const bannerAdUnitId = ${JSON.stringify(bannerAdUnitId)};\n`);
console.log(`Built ${output} from the native 46-kana table.`);
