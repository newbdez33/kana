import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const ios = fileURLToPath(new URL('../../kana/kana/', import.meta.url));
const languages = ['en', 'ja', 'zh-Hans', 'zh-Hant', 'ko', 'de', 'fr', 'es'];
const keys = ['IntroText', 'Chart', 'Practice', 'StatAnswers', 'StatAverage', 'StatRecent', 'StatBest',
  'StatSeconds', 'Menu', 'CloseMenu', 'Close', 'More', 'Share', 'ContinuePractice'];

export function readIOSData() {
  const source = readFileSync(path.join(ios, 'configs/AppConfig.swift'), 'utf8');
  const match = source.match(/static let monographs:\[\[\[String\]\]\] = (\[[\s\S]*?\n    \]);/);
  if (!match) throw new Error('The iOS kana table was not found.');
  const rows = JSON.parse(match[1]);
  const copy = {};
  for (const language of languages) {
    const strings = readFileSync(path.join(ios, `${language}.lproj/Localizable.strings`), 'utf8');
    const values = {};
    for (const item of strings.matchAll(/^"([^"\n]+)"\s*=\s*("(?:[^"\\]|\\.)*");/gm)) {
      values[item[1]] = JSON.parse(item[2]);
    }
    copy[language] = {};
    for (const key of keys) {
      if (!values[key]) throw new Error(`Missing iOS string: ${language}.${key}`);
      copy[language][key] = values[key];
    }
  }
  return { rows, copy };
}
