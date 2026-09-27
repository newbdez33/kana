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

- [ ] **AdMob 付款门槛**：余额 $1,463.81 卡在 $1,500 自定义门槛下，按现在每月约 $1.5 的速度还要两年。在 Payments > Manage settings > Payment schedule 把门槛调回最低值（$100）即可在下个付款周期打款。先确认 ****3706 这张国内银行卡还能收款。Verification 标签页已看过：Address Verification 为 Completed，没有待办。（需要主人本人操作）
- [ ] **App Store Connect Marketing URL**：1.0.1 的 Marketing / Support URL 都是空的，AdMob crawler 靠这个找 app-ads.txt。填 `https://kana.jacky.jp/`（这类字段可直接改，不需要提交新版本）。要等第 1 节的站点上线后再填。

## 1. 主页 + app-ads.txt（https://kana.jacky.jp/）

参考 menkyo_practice：`hosting/`（纯静态 HTML，无 JS）+ `bank-hosting/wrangler.json`（Cloudflare Worker static assets + custom domain）。

- [ ] 新建 `site/`：`index.html`（日文）、`en.html`、`zh.html`、`privacy/`（三语隐私政策，UMP / ATT / App Store 隐私标签都需要这个 URL）、App Store 徽章链接 `https://apps.apple.com/jp/app/id1195345471`。
- [ ] `site/app-ads.txt` 内容一行：`google.com, pub-1295607594822275, DIRECT, f08c47fec0942fa0`（与 menkyo `config/app-ads.txt` 和 https://jacky.jp/app-ads.txt 相同）。
- [ ] `site/wrangler.json`：`name` = `kana-site`，`account_id` = `69b20790d259a1817f268a2c782ec7d1`，`routes` = `[{ "pattern": "kana.jacky.jp", "zone_id": "bad0a183259c863f56b9691468c3a756", "custom_domain": true }]`，`assets.directory` 指向静态目录。`npx wrangler deploy` 会自动创建 `kana.jacky.jp` 的 DNS 记录（目前没有该记录）。
- [ ] 验证：`curl -sI -A Google-adstxt https://kana.jacky.jp/app-ads.txt` 返回 200 且 `text/plain`。
- [ ] 完成第 0 节的 Marketing URL 后，在 AdMob Apps > app-ads.txt 等 crawler（最多 7 天），状态变为 verified。

## 2. 升级 AdMob SDK 到 13.x + UMP 同意流程

- [ ] 删除 `venders/Firebase/` 下的 GoogleMobileAds 等旧框架，用 SPM 引入 `swift-package-manager-google-mobile-ads`（13.x，最新 13.10.0，需要 Xcode 26.2+，本机 Xcode 27.0 满足）。UMP 和隐私清单随包自带。
- [ ] `Info.plist` 加 `GADApplicationIdentifier` = `ca-app-pub-1295607594822275~2834593518`（现在靠已废弃的 `GADMobileAds.configure(withApplicationID:)`）、`SKAdNetworkItems`（Google 官方列表 50 个，可直接复制 menkyo 的）、`NSUserTrackingUsageDescription`（三语）。
- [ ] API 改名（v12 起）：`GADBannerView` → `BannerView`、`GADRequest` → `Request`、`GADMobileAds` → `MobileAds`；`Question.storyboard` 里 `customClass="GADBannerView"` 要一起改，并设置 `adSize`（现在 storyboard 高度 0，靠代码把约束改成 55）。
- [ ] UMP：启动时 `ConsentInformation.shared.requestConsentInfoUpdate` → `ConsentForm.loadAndPresentIfRequired` → `canRequestAds` 为真后再 `MobileAds.shared.start`，之后才允许 `showBanner()`。ATT 在同意表单之后、App 处于 active 时请求。
- [ ] AdMob 后台 Privacy & messaging：现有的 European / US 消息只勾选了两个 Menkyo App，需要把 Japanese kana 也加进去，并填隐私政策 URL（第 1 节）。
- [ ] 决定 `answer-below` 广告单元的去留（代码里从未使用）。

## 3. 工程现代化（第 2 节的前置条件，Xcode 27 现在编不过）

- [ ] Deployment target 10.0 → 15.0（Xcode 27 最低），`UIRequiredDeviceCapabilities` armv7 → arm64，Swift 5.0 → 6 语言模式随 Xcode 默认。
- [ ] 删除 Fabric / Crashlytics（服务已关闭，`Answers.logShare` 等调用一并删）。如果还想要崩溃收集，改用 SPM 的 FirebaseCrashlytics。
- [ ] Firebase 3.x → firebase-ios-sdk 12.x（SPM）。保留 FirebaseAnalytics（AdMob 后台的用户指标依赖它），`FIRApp.configure()` → `FirebaseApp.configure()`。`GoogleService-Info.plist` 可以继续用。
- [ ] Realm：realm-cocoa 2.3.0 二进制无法在新 Swift 下导入。线上 1.0.1 用它保存每道题的答题记录，并在练习页顶部显示「总答题数 / 平均秒数 / 最近 10 次平均」；2020-09 的 `366679f`（upgrade to swift 4 staging，未发布）把写入和显示都注释掉了，所以当前源码里 Realm 是死代码，但老用户手机上有数据。二选一：① SPM 升到 realm-swift 20.x（Realm 2024 年起已停止维护，包体大）；② 删掉 Realm，改用 Codable JSON 文件存记录并恢复这三个数字的显示（老用户的历史统计归零一次）。
- [ ] 删除没在用的依赖：MonkeyKing、JZSpringRefresh、SwiftHEXColors（调用全部是注释掉的），Cartfile 一并删除。
- [ ] 删除没在用的推送配置：`aps-environment` entitlement、FirebaseInstanceID。
- [ ] `xcodebuild` 在模拟器上跑通，真机装一次确认广告、音效、分享都正常。

## 4. 「请作者喝咖啡」去广告（内购）

- [ ] App Store Connect：确认 Paid Apps Agreement、税务和银行信息有效（和 menkyo 同一个开发者账号 72T2SXUWHC，应该已经生效）；新建非消耗型内购 `com.salmonapps.app.kana.coffee`，三语名称 / 描述，定价（建议 ¥300 档）。
- [ ] 代码（StoreKit 2，不需要服务器）：`Product.products(for:)` 取价格、`purchase()`、`Transaction.currentEntitlements` 判断已购买、`AppStore.sync()` 做 Restore；结果存 `UserDefaults` 键 `adsRemoved`。
- [ ] 菜单页（`MenuViewController` / `Kana.storyboard`）加「☕ 请作者喝咖啡（去广告）」和「恢复购买」两个按钮（审核要求有 Restore）。
- [ ] `QuestionViewController.showBanner()` 开头检查 `adsRemoved`，已购买就不加载 banner，也不再弹 UMP / ATT。
- [ ] 沙盒账号测试购买、恢复、删除重装后恢复。

## 5. 发版

- [ ] 版本 1.1.0 (11)；App Privacy 标签补广告、崩溃数据；截图更新（6.9" iPhone、13" iPad）；What's New 三语。
- [ ] 提审后在 AdMob 观察 eCPM 是否从 $0.09 回升。

## 待主人拍板

1. 付款门槛要不要调低、国内银行卡是否还能收款（第 0 节）。
2. Realm 升级还是换成 JSON 文件（第 3 节）。
3. 咖啡定价和是否只做一次性买断（第 4 节）。
4. 是否保留崩溃收集（Crashlytics）。
