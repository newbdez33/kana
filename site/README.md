# kana.jacky.jp

Static public site for the 五十音 (Kana) app, served by a Cloudflare Worker with
static assets on the custom domain `kana.jacky.jp` (same pattern as
Menkyo Practice's `bank-hosting`). No JavaScript, analytics, advertising or
external fonts.

- `public/`, `public/zh.html`, `public/en.html`: app pages in Japanese, Chinese and English.
- `public/privacy/`: privacy policy in the same three languages.
- `public/app-ads.txt`: the AdMob publisher record for app-ads.txt verification.
- `public/assets/`: app icon, App Store badges and the two screen images.

Deploy from this directory with the personal Cloudflare account:

```sh
cd site
npx wrangler deploy
```

The first deploy creates the `kana.jacky.jp` DNS record and certificate for the
custom domain. Verify afterwards:

```sh
curl -sI -A Google-adstxt https://kana.jacky.jp/app-ads.txt
```
