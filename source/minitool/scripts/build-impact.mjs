import { readFileSync, writeFileSync, mkdirSync, copyFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { readIOSData } from './ios-data.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const source = path.join(root, 'preview/impact');
const output = process.argv[2] ? path.resolve(process.argv[2]) : path.join(root, 'build/impact-preview');
const native = path.join(output, 'minitool');
mkdirSync(path.join(native, 'assets'), { recursive: true });
const assets = ['model.js', 'preview.js', 'style.css'];
assets.forEach(file => copyFileSync(path.join(source, file), path.join(native, file)));
['core.js', 'platform.js', 'feedback.js', 'haptics.js'].forEach(file => copyFileSync(path.join(root, 'app', file), path.join(native, file)));
copyFileSync(path.join(root, 'app/audio.js'), path.join(native, 'sound.js'));
copyFileSync(path.join(root, 'assets/kana.woff2'), path.join(native, 'assets/kana.woff2'));
writeFileSync(path.join(native, 'data.js'), 'window.KanaData = ' + JSON.stringify(readIOSData()) + ';\n');
const template = readFileSync(path.join(source, 'index.html'), 'utf8');
writeFileSync(path.join(native, 'index.html'), template.replace('  <!-- browser-adapter -->\n', ''));

const scripts = ['data.js', 'core.js', 'platform.js', 'feedback.js', 'model.js', 'haptics.js', 'browser-haptics.js', 'sound.js', 'preview.js'];
let standalone = template.replace('  <!-- browser-adapter -->', '  <script defer src="./browser-haptics.js"></script>');
const font = readFileSync(path.join(root, 'assets/kana.woff2')).toString('base64');
const css = readFileSync(path.join(source, 'style.css'), 'utf8').replace("url('./assets/kana.woff2')", `url('data:font/woff2;base64,${font}')`);
standalone = standalone.replace('  <link rel="stylesheet" href="./style.css">', '  <style>\n' + css + '\n  </style>');
scripts.forEach(file => { standalone = standalone.replace('  <script defer src="./' + file + '"></script>\n', ''); });
const javascript = scripts.map(file => readFileSync(file === 'browser-haptics.js' ? path.join(source, file) : path.join(native, file), 'utf8')).join('\n');
standalone = standalone.replace('</body>', '<script>\n' + javascript.replace(/<\/script/gi, '<\\/script') + '\n</script>\n</body>');
writeFileSync(path.join(output, 'preview.html'), standalone);
execFileSync('python3', ['-c', [
  'from pathlib import Path',
  'from zipfile import ZipFile, ZIP_DEFLATED',
  'import sys',
  'root = Path(sys.argv[1])',
  "with ZipFile(root.parent / 'kana-impact-preview.zip', 'w', ZIP_DEFLATED) as bundle:",
  "    for file in sorted(root.rglob('*')):",
  '        if file.is_file(): bundle.write(file, file.relative_to(root))'
].join('\n'), native]);
console.log(`HTML: ${path.join(output, 'preview.html')}`);
console.log(`Mini-tool preview: ${path.join(output, 'kana-impact-preview.zip')}`);
