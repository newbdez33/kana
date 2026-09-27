# TODO — kana（五十音）复活计划

审计日期：2026-09-27。逐项完成后在这里打勾；决策点见文末「待主人拍板」。

## 现状摘要

| 项目 | 现状 |
| --- | --- |
| App Store 线上版本 | 1.0.1 (10)，2017-02-14 发布，App ID 1195345471，Bundle `com.salmonapps.app.kana` |
| AdMob SDK | GoogleMobileAds **7.16.0**（2017-01，手动放在 `source/kana/kana/venders/Firebase/`）。7.x 已于 2023-06-30 sunset，Google 标注「广告有可能不再投放」 |
| AdMob 后台实际投放 | 仍在填充：近 7 天 916 次请求、469 次展示、match rate 64.6%、eCPM $0.09、收入 $0.04；周活约 77 人 |
| AdMob App 状态 | `Japanese kana - learning, challenge yourself`（app id 2834593518）Ready / Ad serving enabled，已关联 App Store |
| 广告单元 | `answer-above` …/7264793113（代码在用）、`answer-below` …/7125192315（代码没用） |
| app-ads.txt | 未设置（AdMob 显示 No app-ads.txt file found，近 7 天 948 次查询） |
| 付款 | 账户余额 $1,463.81，自定义付款门槛 $1,500（97%），上次打款 2020-03-29 $2,990.09，收款方式：电汇到国内银行账户 ****3706 |
| 其他 SDK | Fabric/Crashlytics 1.6.11（Fabric 2020-11 已关闭）、Firebase 3.x（`FIRApp.configure()`）、Carthage realm-cocoa 2.3.0（`Carthage/Build` 未提交） |
| 工程 | Deployment target 10.0、Swift 5.0、`UIRequiredDeviceCapabilities` armv7、无 StoreKit 代码 |

## 0. 不用改代码就能做的

- [x] ~~**AdMob 付款门槛**~~：余额 $1,463.81 卡在 $1,500 自定义门槛下，Verification 标签页 Address Verification 为 Completed。2026-09-27 主人决定：门槛不动，不处理。
- [ ] **App Store Connect Marketing URL**：1.0.1 的 Marketing / Support URL 都是空的，AdMob crawler 靠这个找 app-ads.txt。2026-09-27 用 API 试过：线上版本的 marketingUrl / supportUrl / privacyPolicyUrl 都返回 409「当前状态不可编辑」，只能在新版本 1.1.0 上设置，随第 5 节发版一起生效。

## 1. 主页 + app-ads.txt（https://kana.jacky.jp/）

参考 menkyo_practice：`hosting/`（纯静态 HTML，无 JS）+ `bank-hosting/wrangler.json`（Cloudflare Worker static assets + custom domain）。

- [x] `site/public/`：`index.html`（日文）、`en.html`、`zh.html`、`privacy/`（三语隐私政策）。线上地址用无后缀路径：`/`、`/en`、`/zh`、`/privacy/`、`/privacy/en`、`/privacy/zh`。
- [x] `site/public/app-ads.txt`：`google.com, pub-1295607594822275, DIRECT, f08c47fec0942fa0`。
- [x] `site/wrangler.json` + `wrangler deploy`（2026-09-27 上线，Worker `kana-site`，自定义域名 kana.jacky.jp 已自动建 DNS）。部署用 wrangler profile `kana-site`（已绑定到 `site/` 目录；这个 profile 有 zone / routes 权限，menkyo 的 profile 没有）。
- [x] 验证：`https://kana.jacky.jp/app-ads.txt` 返回 200 `text/plain`，Google-adstxt UA 也正常。
- [ ] 1.1.0 上线并带上 Marketing URL 后，在 AdMob Apps > app-ads.txt 等 crawler（最多 7 天），状态变为 verified。

## 2. 升级 AdMob SDK 到 13.x + UMP 同意流程

- [x] 删除 `venders/`，用 SPM 引入 GoogleMobileAds 13.10.0 + GoogleUserMessagingPlatform 3.1.0（`source/kana/project.yml`，XcodeGen 生成工程）。
- [x] `Info.plist`：`GADApplicationIdentifier`、50 个 `SKAdNetworkItems`、`NSUserTrackingUsageDescription`（9 个语言的 InfoPlist.strings）。
- [x] API 改名：`BannerView` / `Request`；storyboard 里保留 `customClass="GADBannerView"`（ObjC 运行时名不变）；`showBanner()` 用 `currentOrientationAnchoredAdaptiveBanner` 并按实际高度改约束。
- [x] UMP：`services/AdsManager.swift`（requestConsentInfoUpdate → loadAndPresentIfRequired → ATT → MobileAds.start，`isReady` 后才允许 showBanner；菜单里有「广告隐私设置」入口，仅在 Google 要求时显示）。
- [x] AdMob Privacy & messaging：European / US 两条消息都已加入 Japanese kana（各 3 apps，仍为 Published），隐私 URL 填 https://kana.jacky.jp/privacy/en。⚠ 操作时误把同一 URL 填到了未发布的「Bricks!」App 上，后台不允许清空，主人有空可以在 AdMob > Apps 里改掉。
- [ ] 决定 `answer-below` 广告单元的去留（代码里从未使用）。

## 3. 工程现代化（第 2 节的前置条件，Xcode 27 现在编不过）

- [x] Deployment target 15.0，arm64，Swift 5 语言模式，版本号改由 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` 控制（1.1.0 / 11）。iOS 27 要求 Scene 生命周期，新增 `SceneDelegate.swift` + `UIApplicationSceneManifest`（没有它 App 启动即崩）。
- [x] 删除 Fabric / Crashlytics。
- [x] Firebase 12.19.2（SPM，只保留 FirebaseAnalytics），`FirebaseApp.configure()`。
- [ ] Realm：realm-cocoa 2.3.0 二进制无法在新 Swift 下导入。线上 1.0.1 用它保存每道题的答题记录，并在练习页顶部显示「总答题数 / 平均秒数 / 最近 10 次平均」；2020-09 的 `366679f`（upgrade to swift 4 staging，未发布）把写入和显示都注释掉了，所以当前源码里 Realm 是死代码，但老用户手机上有数据。2026-09-27 完成：`models/StatStore.swift`（Application Support/stats.json，只存总数、总耗时、最近 10 次），练习页三个数字恢复显示。
- [x] 删除 Carthage 依赖（MonkeyKing、JZSpringRefresh、SwiftHEXColors、Realm）和 Cartfile。
- [x] 删除 `kana.entitlements`（推送）和 FirebaseInstanceID。
- [x] 模拟器（iPhone 18 Pro / iOS 27）编译、运行通过；`xcodebuild test`：单元测试 8 个（StatStore 4、StoreKit 4）+ UI 测试 3 个全部通过。测试广告在答错后正常显示。
- [ ] 真机装一次确认广告、音效、分享都正常（需要主人的手机）。
- 备注：`xcodebuild test` 在测试全部结束后不会自动退出（要 `pkill`），结果包因此不完整；UI 测试截图改为通过 `TEST_RUNNER_KANA_SHOT_DIR=/path` 直接落盘。本机 Xcode 27 没有 Simulator.app 图形界面，只能用 `simctl` + XCUITest。

## 4. 「请作者喝咖啡」去广告（内购）

- [x] App Store Connect：用 API 新建非消耗型内购 `com.salmonapps.app.kana.coffee`（ASC id 6816632915，5 个语言的名称 / 描述，日本 ¥300 为基准价、175 个地区可用，审核截图已上传）。
- [x] 代码：`services/Store.swift`（StoreKit 2：`Product.products`、`purchase()`、`Transaction.currentEntitlements`、`AppStore.sync()`；`adsRemoved` 存 UserDefaults 并广播通知）。
- [x] 菜单行（`Question.storyboard` 的 MenuViewController 场景）加「☕ 请作者喝杯咖啡」「恢复购买」按钮，8 个语言的 Localizable.strings。
- [x] `showBanner()` 先检查 `adsRemoved` 和 `AdsManager.isReady`；已购买时不再走 UMP / ATT。
- [x] 本地 StoreKit 配置（`source/kana/Configuration.storekit`）+ 单元测试覆盖购买 / 恢复 / 无购买恢复。
- [ ] 沙盒账号在真机上测一次购买、恢复（需要主人的手机和沙盒账号）。

## 5. 发版

- [x] App Store Connect 版本 1.1.0 已用 API 建好（id cf9a54ab-…），5 个语言的 What's New、Marketing / Support URL（kana.jacky.jp）、隐私政策 URL 都已填；年龄分级的新问卷（广告、健康、社交等新字段）已填。
- [x] 截图：UI 测试在 iPhone 18 Pro Max（1320×2868）和 iPad Pro 13"（2064×2752）模拟器上按 en / ja / zh-Hans / zh-Hant / ko 各抓 3 张（题目、下拉菜单、五十音图），已上传到 1.1.0 的 APP_IPHONE_67 / APP_IPAD_PRO_3GEN_129，2017 年的 5.5" / 12.9" 旧图已删。
- [x] 内购 `com.salmonapps.app.kana.coffee` 状态 READY_TO_SUBMIT（审核截图用的是菜单页）。
- [ ] Build：build 11 / 13 导出失败（缺 1024 图标），已补 `Icon-1024.png` 后打 build 14 上传；处理完成后用 API 把 build 14 挂到 1.1.0 并声明不含加密（`ITSAppUsesNonExemptEncryption` 已写进 Info.plist，从 build 14 起生效）。
- [ ] **App Privacy（数据收集标签）要主人在 App Store Connect 网页上填**（API 没有这个接口，Chrome 里也没登录 ASC）。建议答案：收集「Identifiers › Device ID」「Usage Data › Product Interaction」「Usage Data › Advertising Data」，用途 Third-Party Advertising + Analytics，不与用户身份关联（Not linked）、用于追踪（Used for tracking，因为 AdMob + ATT）；不收集其他类别。
- [ ] 主人用真机 + 沙盒账号测一次：广告、同意弹窗 / ATT、购买、恢复。
- [ ] 提审：等主人一句话再 submit（App 与内购一起提交）。提审后在 AdMob 观察 eCPM 是否从 $0.09 回升。
- 备注：App Review 联系电话还是 2017 年填的国内号码，如需更新请在 ASC 改。

## 已定事项（2026-09-27）

1. 付款门槛不动。
2. Realm 删除，换 JSON 文件。
3. 咖啡：一次性买断（非消耗型），¥300 档。
4. 不保留崩溃收集。
5. 主页先出 preview（Tailscale URL）给主人确认，再部署。
6. 所有改动走 PR：https://github.com/newbdez33/kana/pull/1
