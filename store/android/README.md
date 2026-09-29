# Google Play store assets

`metadata.json` contains the app name, short description, full description, and
capture order for English, Japanese, Simplified Chinese, Traditional Chinese,
and Korean. The shared renderer also creates the 512 × 512 icon and localized
1024 × 500 feature graphics.

Run from the repository root with the Android SDK and JDK 21 configured:

```sh
source/android/gradlew -p source/android :app:assembleDebug :app:assembleDebugAndroidTest
python3 scripts/capture-android-store.py --serial emulator-5560 \
  --output build/android-store/captures
swift scripts/render-store.swift store/android/metadata.json \
  build/android-store/captures build/android-store/rendered android
```

Use a dedicated emulator. The capture script installs the debug and test APKs,
changes display size, density, night mode, and app locale, then resets the display
overrides and sets English when it exits. It does not restore the previous night
mode. The optional `--device phone` or `--device tablet` limits the capture set.

The opt-in `StoreScreenshotTest` uses the app's Compose screens with 48 fixture
answers and fake billing, ads, audio, and sharing services. Normal instrumented
runs skip this capture test. Images are native UI captures, not physical-device
evidence. Phone and tablet captures use 1080 × 1920 pixels at 420 and 240 dpi.

The Android renderer preserves the full UI image and exports RGB PNG files. It
uses the existing icon and renders feature graphics with fonts and kana glyphs.
The default iOS rendering path stays available without the `android` argument.

Output includes `index.html`, metadata, layout records, and screenshots. Serve
that directory over HTTP to preview each language and device size. The `upload/`
directory contains copies with unique names for the Play asset picker. Each store
language uses four phone screenshots and four tablet screenshots; the tablet
set can be used for the 7-inch and 10-inch slots.
