# TODO — kana（五十音）复活计划

更新日期：2026-09-28。逐项完成后在这里打勾；已确认的决策见文末「已定事项」。

## 现状摘要

1.1.0 (17) 已通过 TestFlight 验收，并于 2026-09-27 21:31（日本时间）与咖啡内购一起提交审核；最后记录的状态均为 **Waiting for Review**，审核通过后自动发布。商店文案、40 张截图和隐私标签已更新。Android **1.0.0 (2)** 已于 2026-09-28 20:00（日本时间）更新 Google Play 内部测试，状态 **Available to internal testers**；[加入测试](https://play.google.com/apps/internaltest/4701215213082302872)。S22 Ultra 已完成 Play 安装／更新、签名与购买恢复核验；正式版于 **2026-09-29 00:10（日本时间）**提交，受众 **13+**，提交记录 1 为 **In review**；记录时快速检查仍在运行，审核通过后自动全量发布，详见第 6 节。

### 初始审计基线（改造前）

| 项目 | 初始状态 |
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
- [x] **App Store Connect Marketing URL**：1.1.0 的 Marketing / Support URL 与隐私政策 URL 已配置，随版本上线生效。线上 1.0.1 不支持直接编辑这些字段；AdMob 抓取验证仍见第 1 节。

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
- [x] AdMob Privacy & messaging：European / US 两条消息都已加入 Japanese kana（各 3 apps，仍为 Published），隐私 URL 填 https://kana.jacky.jp/privacy/en。（操作时误把同一 URL 填到了未发布的「Bricks!」App 上，2026-09-27 主人决定不处理。）

## 3. 工程现代化

- [x] Deployment target 15.0，arm64，Swift 5 语言模式，版本号改由 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` 控制（1.1.0 / 11）。iOS 27 要求 Scene 生命周期，新增 `SceneDelegate.swift` + `UIApplicationSceneManifest`（没有它 App 启动即崩）。
- [x] 删除 Fabric / Crashlytics。
- [x] Firebase 12.19.2（SPM，只保留 FirebaseAnalytics），`FirebaseApp.configure()`。
- [x] Realm：realm-cocoa 2.3.0 二进制无法在新 Swift 下导入。线上 1.0.1 用它保存每道题的答题记录，并在练习页顶部显示「总答题数 / 平均秒数 / 最近 10 次平均」；2020-09 的 `366679f`（upgrade to swift 4 staging，未发布）把写入和显示都注释掉了，所以当前源码里 Realm 是死代码，但老用户手机上有数据。2026-09-27 完成：`models/StatStore.swift`（Application Support/stats.json，只存总数、总耗时、最近 10 次），练习页三个数字恢复显示。
- [x] 删除 Carthage 依赖（MonkeyKing、JZSpringRefresh、SwiftHEXColors、Realm）和 Cartfile。
- [x] 删除 `kana.entitlements`（推送）和 FirebaseInstanceID。
- [x] 模拟器（iPhone 18 Pro / iOS 27）编译、运行通过；`xcodebuild test`：单元测试 8 个（StatStore 4、StoreKit 4）+ UI 测试 3 个全部通过。测试广告在答错后正常显示。
- [x] 真机装一次确认广告、音效、分享都正常（需要主人的手机）。2026-09-27 主人真机测试通过。
- 备注：`xcodebuild test` 在测试全部结束后不会自动退出（要 `pkill`），结果包因此不完整；UI 测试截图改为通过 `TEST_RUNNER_KANA_SHOT_DIR=/path` 直接落盘。本机 Xcode 27 没有 Simulator.app 图形界面，只能用 `simctl` + XCUITest。

## 4. 「请作者喝咖啡」去广告（内购）

- [x] App Store Connect：用 API 新建非消耗型内购 `com.salmonapps.app.kana.coffee`（ASC id 6816632915，5 个语言的名称 / 描述，日本 ¥300 为基准价、175 个地区可用，审核截图已上传）。
- [x] 代码：`services/Store.swift`（StoreKit 2：`Product.products`、`purchase()`、`Transaction.currentEntitlements`、`AppStore.sync()`；`adsRemoved` 存 UserDefaults 并广播通知）。
- [x] 统计与咖啡支持重新设计：统计改为四列数字栏，菜单增加可见入口；「Buy me a coffee」打开独立支持面板，显示本地价格、永久去广告说明、一次性购买说明及恢复入口。保留 8 个语言，支持加载、重试、等待批准和感谢状态。
- [x] 展开菜单与支持面板时暂停答题计时；修正安全区布局，底部答案完整显示。设计预览和原生截图见 `design/README.md`，项目介绍与截图见 `README.md`。
- [x] `showBanner()` 先检查 `adsRemoved` 和 `AdsManager.isReady`；已购买时不再走 UMP / ATT。
- [x] 本地 StoreKit 配置（`source/kana/Configuration.storekit`）+ 单元测试覆盖购买 / 恢复 / 无购买恢复。
- [x] 沙盒账号在真机上测一次购买、恢复（需要主人的手机和沙盒账号）。2026-09-27 主人真机测试通过。

## 5. 发版

- [x] App Store Connect 版本 1.1.0 已用 API 建好（id cf9a54ab-…），5 个语言的 What's New、Marketing / Support URL（kana.jacky.jp）、隐私政策 URL 都已填；年龄分级的新问卷（广告、健康、社交等新字段）已填。
- [x] 截图：UI 测试在 iPhone 18 Pro Max（1320×2868）和 iPad Pro 13"（2064×2752）模拟器上按 en / ja / zh-Hans / zh-Hant / ko 各抓 3 张（题目、下拉菜单、五十音图），已上传到 1.1.0 的 APP_IPHONE_67 / APP_IPAD_PRO_3GEN_129，2017 年的 5.5" / 12.9" 旧图已删。
- [x] 内购 `com.salmonapps.app.kana.coffee` 已与 1.1.0 (17) 一起提交，状态 Waiting for Review；审核截图使用咖啡支持面板。
- [x] Build：补齐 `Icon-1024.png`，删除误打包的旧版 Info.plist 副本，并在 project.yml 排除 `**/Info.plist`；去掉 `UIRequiredDeviceCapabilities`，保留已上架 App 的设备兼容范围。**build 17 已处理完成（VALID）并随 1.1.0 提交审核**，`ITSAppUsesNonExemptEncryption=false` 在 Info.plist 里。
- [x] **App Privacy（数据收集标签）**：已按归档中的 SDK 隐私清单与 Google 官方文档核对数据类型、用途、身份关联及追踪情况，并在 App Store Connect 发布。
- [x] **TestFlight 1.1.0 (17)**：新界面与五十音图颜色修复已上传，Apple 处理状态 VALID，内部测试状态 IN_BETA_TESTING，已挂到 1.1.0。中日英测试说明已更新；两个现有内部测试账号均在测试组，新增账号已接受邀请并安装过测试版。
- [x] **五十音图文字颜色**：系统深色模式下出现白底白字；五十音图统一使用浅色外观。iPhone 浅色 / 深色与 iPad 深色三组截图测试通过，并逐张确认文字可读。
- [x] 商店介绍与更新说明：en-US / ja / zh-Hans / zh-Hant / ko 已更新，对应文案保存在 `store/metadata.json`。内购审核截图已替换为新支持页面，审核说明已更新为菜单按钮 → 咖啡入口 → 购买 / 恢复。
- [x] 新界面商店截图：5 种商店语言 × iPhone / iPad × 4 张，共 40 张，已全部上传并确认 COMPLETE；旧图已替换。新增 `--store-listing` 截图模式，10 组模拟器截图测试全部通过。
- [x] **参考 menkyo 更新商店素材**：大标题、简短卖点与原生截图组合，保留 Kana 暖纸色和朱红色；依次介绍练习、统计、五十音图与咖啡支持。五种语言的介绍、宣传文本、更新说明及 40 张图片已同步 ASC。宣传文案突出五秒答题与连对挑战，说明广告仅在答错或超时后触发；咖啡介绍为自愿支持作者。`scripts/render-store.swift` 可重复生成，HTML 预览与说明见 `store/README.md`。
- [x] 主人用真机 + 沙盒账号测一次：广告、同意弹窗 / ATT、购买、恢复。2026-09-27 主人真机测试通过。
- [x] **TestFlight 验收与提审**：用户已确认可以提审。1.1.0 (17) 与咖啡内购于 2026-09-27 21:31（日本时间）一起提交，两项均为 Waiting for Review，审核通过后自动发布。[审核记录](https://appstoreconnect.apple.com/apps/1195345471/distribution/reviewsubmissions/details/85c4f677-85ad-4bfe-a944-ca6a7ec9a0f4)。
- [ ] 上线后确认商店版本、截图和链接，并在 AdMob 观察填充率与 eCPM。
- 备注：App Review 联系电话还是 2017 年填的国内号码，如需更新请在 ASC 改。

## 6. Android 版实现与上架

- [x] **实现 Android 版**：对齐 iOS 的五秒四选一练习、连对挑战、设备内统计、五十音图、离线使用和多语言界面。2026-09-27 完成：`source/android/`（Kotlin + Compose），设计见 `docs/specs/2026-09-27-android-app-design.md`。
- [x] **接入广告与咖啡支持**：接入 Android AdMob、同意流程和 Google Play Billing；广告仅在答错或超时后触发，支持一次性咖啡购买与恢复。2026-09-27 完成代码；后台配置与发布验收见下方。

本次发布：`jp.jacky.kana` 的 Google Play **内部测试**版 `1.0.0 (2)` 已开放，测试名单为 `Kana internal testers`。使用名单内账号打开[加入链接](https://play.google.com/apps/internaltest/4701215213082302872)，接受邀请后从 Play 安装。正式版已按 13+ 定位提交审核；见[首个内部版本](docs/releases/2026-09-28-android-internal.md)与[正式版审核记录](docs/releases/2026-09-28-android-review.md)。

### 6.1 发布前置条件

- [x] **核对发布现状**：2026-09-28 已检查 Salmonapps 账号的应用列表，没有 Kana；GitHub 无 Release，当前仅有本地 Debug APK。Android 改动在 [PR #6](https://github.com/newbdez33/kana/pull/6)。
- [x] **核对 Play 账号验证**：2026-09-28 已确认身份、邮箱和手机验证记录；Policy status 无账号问题，页面加载完成后 Create app 可用。加载期间的禁用提示不是实际阻塞。
- [x] **创建 Kana 应用**：2026-09-28 创建 `Japanese kana - learning`，包名 `jp.jacky.kana`，默认 en-US，免费应用。主人已明确授权开发者政策和美国出口声明。[Play Console](https://play.google.com/console/u/0/developers/4896965748454075126/app/4975495341700861726/app-dashboard)。
- [x] **准备测试账号**：2026-09-28 创建并启用 `Kana internal testers` 名单，仅含主人现有 Google 账号；该名单已加入 License testing，保留现有名单与 `RESPOND_NORMALLY` 设置。

### 6.2 广告、购买与签名

- [x] **创建 Android AdMob 应用和横幅单元**：2026-09-28 创建 `Japanese kana - learning`（Android，暂未关联商店）及 `answer-banner`；正式 ID 已填入 `source/android/gradle.properties`，Debug 继续使用 Google 测试 ID。商店关联后核对 `jp.jacky.kana`。
- [x] **配置同意消息**：2026-09-28 Android Kana 已加入现有 European / US 消息，两条均为 Published、各 4 个应用；隐私 URL 为 `https://kana.jacky.jp/privacy/en`。三语隐私页已补充 Android、Google Play、系统备份及平台统计差异，上线后读回与源码一致。同意表单期间暂停计时已有测试覆盖。
- [x] **配置上传签名**：Kana 独立上传密钥保存在 `~/.local/share/kana/android-signing/`；密码文件、密钥和未跟踪的 `source/android/key.properties` 权限均为 `0600`。上传证书 SHA-256：`0E:06:97:1D:1C:36:74:5B:75:A3:2C:9A:14:3F:BC:6F:C0:55:09:01:40:A7:6D:CA:F5:0C:D3:7D:D2:F6:56:25`。
- [ ] **独立备份上传密钥**：正式发布前，将密钥与密码保存到用户选定的安全备份位置；当前仅确认本机副本。
- [x] **核对 Play App Signing**：2026-09-28 Console 已确认由 Google Play 签名；上传证书与本机 SHA-256 一致，Play 提供的分发证书指纹已记入发布记录。后续版本沿用上传密钥并递增版本号。
- [x] **创建并启用咖啡商品**：2026-09-28 `jp.jacky.kana.coffee` 已启用，购买选项 `coffee` 为 Buy、向后兼容，覆盖 173 个地区；日本 ¥300，其他地区由 Play 换算。en-US / ja-JP / zh-CN / zh-TW / ko-KR 名称与说明已填写。代码确认购买后只确认交易、不消耗商品，提供永久去广告。

### 6.3 构建与发布前验证

- [x] **单元测试与静态检查**：2026-09-28 `:app:testDebugUnitTest`、`:app:lintDebug`（复用有效缓存）及 `:app:lintRelease` 通过；51 项单元测试零失败。
- [x] **模拟器自动化回归**：2026-09-28 版本 2 的 10 项 instrumented UI 用例通过，新增购买后隐私入口可见／可点击的回归测试；覆盖练习、菜单、五十音图、本地化与咖啡界面。购买、广告等服务使用替身，不替代真实服务验收。
- [x] **发布包手机和平板启动检查**：从最终 AAB 生成的 APK 在 API 36 专用模拟器上通过手机与平板尺寸的冷启动、进程重启检查；每次观察 10 秒，无崩溃，截图文字可读、测试横幅可见。平板使用显示尺寸覆盖，不代表实体平板验收。
- [x] **S22 Ultra 真机回归**：2026-09-28 通过 `jx` 的 USB ADB，在 SM-S9080／Android 16 上完成 9 项自动化用例；最终 AAB 生成的 Release APK 已侧载验收。答题、错题提示、统计持久化、后台／菜单暂停计时、横竖屏、系统深浅色、五十音图、离线冷启动和分享面板通过。未发现崩溃或 ANR。[真机记录](docs/releases/2026-09-28-android-s22.md)。
- [ ] **补充平板与音效验收**：实体平板完整交互仍待验证；S22 音效尚未人工聆听确认。现有平板验证仅覆盖模拟器显示尺寸。
- [x] **生成签名发布包**：`:app:bundleRelease`、`:app:assembleRelease` 通过；核对 `jp.jacky.kana`、`1.0.0 (2)`、minSdk 26、targetSdk 36、正式广告 ID、非调试标记与签名。bundletool、APK 签名及 16 KB 对齐检查通过；版本 2 AAB SHA-256 为 `9aa084343352072b897a5189ddbc4358b8a7a55d4ab2d6063afc2b1902828c56`。
- [x] **修复 Release 启动崩溃**：首个本地发布包因 R8 裁剪 WorkManager 的 Room 数据库构造器而崩溃，未上传。补充精确保留规则及 `scripts/check-android-release.py`，AAB 生成的 APK 验证旧包失败、修复包冷启动与进程重启各稳定 10 秒。
- [x] **归档发布信息**：最终 AAB、混淆映射、校验值、构建日志、启动截图及中日英测试说明保存在本机 `build/android-internal-20260928/`；首版源码提交为 `da91138`。版本 2 包、日志和验收证据另存 `build/android-production-20260928/`；密钥与密码未进入 Git 或附件。

### 6.4 发布内部测试并验收

- [x] **上传内部测试轨道**：2026-09-28 15:11（日本时间）发布 `1.0.0 (1) - First Android test`，状态 **Available to internal testers**。Console 确认 SDK 26+、target 36、4 种 ABI；混淆映射已附带。仅有第三方原生库缺少调试符号的非阻塞警告。
- [x] **交付测试链接并加入测试**：轨道 Active、测试名单已启用；[加入测试](https://play.google.com/apps/internaltest/4701215213082302872)已在 S22 上接受，账号与内部测试／许可测试名单一致。首次审核前名称为 `jp.jacky.kana (unreviewed)`。
- [x] **发布版本 2 候选**：2026-09-28 20:00（日本时间）发布 `1.0.0 (2) - Review candidate`，状态 **Available to internal testers**；新增永久隐私政策入口。
- [x] **Play 安装验收**：2026-09-28 晚间商店安装恢复可用，S22 已从 Play 安装版本 1，再通过 Play 更新为版本 2。核对安装器 `com.android.vending`、版本号、Play 签名证书，冷启动 222 ms；购买权益保留，隐私链接打开正常，未发现 Kana 崩溃。
- [x] **真实购买服务验收**：2026-09-28 在 S22 使用 Play 测试卡验证 ¥300 价格、空记录恢复、取消、拒付、待批准转成功；全程显示测试订单、不收费。购买状态在离线冷启动后保留；清除本次测试数据后，Play 自动恢复权益，联网重启仍有效。界面显示已去广告，已购冷启动没有 UMP 请求；真实横幅验证见下一项。
- [x] **模拟器真实广告／同意服务验收**：正式 AAB 生成的 APK 已显示标有 Test Ad 的横幅。另用正式 AdMob app ID、测试横幅和 EEA 调试地区验证实际 UMP 表单、拒绝后继续练习、重开隐私选项与接受；未点击广告，默认 Debug 配置已恢复。
- [ ] **真机广告服务复测**：S22 仍将 `fundingchoicesmessages.google.com` 解析到 `127.0.0.1`；在可访问该域名的测试设备／网络下补验同意流程及购买前后的横幅。未修改用户网络过滤配置。
- [x] **更新发布记录**：实际版本、状态、链接、已通过测试和剩余限制已写入此文件、Android README 与发布记录；同步 [PR #6](https://github.com/newbdez33/kana/pull/6)。

### 6.5 正式上架前完成

- [x] **应用内隐私入口**：版本 2 的「更多」菜单永久提供隐私政策链接；购买后仍可见，八种界面语言已翻译，按日／中／英打开对应政策页。
- [x] **商店素材**：五语名称、短说明、完整说明、512 × 512 图标、五张 1024 × 500 置顶大图与 40 张 Android 手机／平板截图已上传并保存。每种语言含四张手机、四张 7 英寸和四张 10 英寸截图；两种平板槽复用同组模拟器截图。[可复现流程](store/android/README.md)。
- [x] **基础应用申报**：已保存隐私 URL、含广告、无登录限制、非政府应用、无金融／健康功能、Advertising ID 用途；分类为 Education，支持邮箱与 HTTPS 网站已配置。
- [x] **目标年龄**：2026-09-29 主人确定首发面向 13 岁以上；Target audience 已保存 13–15、16–17、18+，与现有隐私政策一致。
- [x] **内容评级**：2026-09-29 主人授权接受 IARC 条款后，问卷与评级已完成并保存：北美 Everyone、欧洲 PEGI 3、德国／巴西全年龄、其他主要地区 3+，标注应用内购买。该内容评级不等于儿童目标受众声明。
- [x] **Data safety**：2026-09-29 完成并保存最终声明；披露广告 SDK 的大致位置、应用互动、诊断、设备标识符，另披露可选购买记录；传输加密、无应用账号，五类数据及预览已核验。
- [x] **正式轨道候选**：已保存 `1.0.0 (2) - First Android release`，复用内部测试的版本 2 AAB；五语更新说明、176 个国家／地区及 Rest of World 已配置，包验证仅有第三方原生调试符号警告。
- [x] **提交审核**：2026-09-29 00:10（日本时间）发送正式版及 15 项变更；[提交记录 1](https://play.google.com/console/u/0/developers/4896965748454075126/app/4975495341700861726/publishing/submission-activity/1/details)显示 **In review**。记录时快速检查仍在运行，通过后自动进入后续审核。Managed publishing 关闭，审核通过后自动全量发布。
- [ ] **跟进审核结果**：查看快速检查及正式审核结果；如有问题，按 Console 的具体反馈修正并重新提交。
- [ ] **上线核验**：确认商店版本、截图、链接与内购，关联 AdMob 商店页面，验证 app-ads.txt，并观察崩溃、ANR、广告与购买状态。

依据：[Google Play 内部测试说明](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en)允许在应用设置尚未全部完成时开展内部测试；[许可测试说明](https://support.google.com/googleplay/android-developer/answer/6062777?hl=en)要求配置许可测试账号及启用待测商品。完整商店素材与公开发布申报列在 6.5，不作为内部测试的预设阻塞项；实际阻塞以 Console 为准。

## 已定事项（2026-09-27）

1. 付款门槛不动。
2. Realm 删除，换 JSON 文件。
3. 咖啡：一次性买断（非消耗型），¥300 档。
4. 不保留崩溃收集。
5. 主页先出 preview（Tailscale URL）给主人确认，再部署。
6. 所有改动走 PR；首批改动见 https://github.com/newbdez33/kana/pull/1。
