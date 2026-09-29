# Kana Android 版设计

日期：2026-09-27。状态：待主人审阅。对应 TODO.md 第 6 节前两项（实现 Android 版；接入广告与咖啡支持）。第三项（商店素材与 Google Play 上架）另出一份 spec。

## 1. 目标与范围

把 iOS 1.1.0 (17) 的 Kana 做成 Android 版，功能与视觉对齐，代码可上架 Google Play。

范围内：

- 五秒四选一练习、连对挑战、设备内统计。
- 五十音图（平假名 / 片假名切换）。
- 「请作者喝咖啡」一次性内购去广告，含恢复。
- AdMob 横幅（仅答错或超时后）、UMP 同意流程、广告隐私选项入口。
- 分享、反馈邮件。
- 8 种界面语言：英、日、简中、繁中、韩、德、法、西。
- 单元测试与模拟器 UI 测试。

范围外（本 spec 不做）：

- Play 商店截图、商店文案、隐私申报、上架流程。
- Firebase（Analytics 与崩溃收集都不接，已定）。
- 浊音、拗音练习（iOS 也没有）。
- 深色模式（与 iOS 一致，固定浅色）。
- iOS 的下拉展开菜单手势。

## 2. 已定决策

| 项目 | 决定 |
| --- | --- |
| 技术栈 | Kotlin + Jetpack Compose（Material 3 组件 + 自定义主题），单模块 `app` |
| applicationId / namespace | `jp.jacky.kana`（与 menkyo 的 `jp.jacky.menkyo` 同一命名空间） |
| Play 商品 ID | `jp.jacky.kana.coffee`，一次性商品，购买后 acknowledge，永不消耗 |
| 视觉 | 复刻 iOS 现有设计，固定浅色 |
| 位置 | `source/android/`，与 `source/kana` 并列 |
| SDK | minSdk 26，targetSdk 36，compileSdk 37.0（Compose 1.12 要求 compileSdk 37；`platforms;android-37.0` 已安装） |
| 工具链 | Gradle 9.6.0（wrapper 首次运行下载）、AGP 9.4.1（内置 Kotlin，不再应用 `org.jetbrains.kotlin.android`）、Kotlin 2.4.20、JDK 21（`/opt/homebrew/opt/openjdk@21`） |
| 依赖版本 | 实施时取各库最新稳定版，统一记录在 `gradle/libs.versions.toml` |
| 版本号 | versionName `1.0.0`，versionCode `1` |
| 依赖注入 | 手写 `AppContainer`，不用 Hilt；不用 Navigation 库；不用 kotlinx.serialization（统计 JSON 用 Android 自带的 `org.json`） |
| 流程 | 所有改动在 `newbdez33/android-app` 分支上走 PR |

## 3. 工程结构

```
source/android/
  settings.gradle.kts            # 仅 :app
  build.gradle.kts
  gradle.properties              # AndroidX、JVM 参数、AdMob 正式 ID 常量
  gradle/wrapper/                # Gradle 9.3.1
  gradle/libs.versions.toml
  gradlew, gradlew.bat
  README.md                      # 构建、测试、模拟器说明
  app/
    build.gradle.kts
    proguard-rules.pro
    src/main/AndroidManifest.xml
    src/main/kotlin/jp/jacky/kana/...
    src/main/res/values/strings.xml            # 英文（默认）
    src/main/res/values-ja/strings.xml
    src/main/res/values-b+zh+Hans/strings.xml
    src/main/res/values-b+zh+Hant/strings.xml
    src/main/res/values-ko/strings.xml
    src/main/res/values-de/strings.xml
    src/main/res/values-fr/strings.xml
    src/main/res/values-es/strings.xml
    src/main/res/xml/locales_config.xml
    src/main/res/font/hosohuwa.ttf
    src/main/res/raw/correct.wav, incorrect.wav
    src/main/res/mipmap-*/ic_launcher*.png + mipmap-anydpi-v26/ic_launcher.xml
    src/test/kotlin/jp/jacky/kana/...          # JVM 单元测试
    src/androidTest/kotlin/jp/jacky/kana/...   # 模拟器 UI 测试
```

Gradle 要点：

- 插件：`com.android.application`（AGP 9 内置 Kotlin）、`org.jetbrains.kotlin.plugin.compose`；根构建脚本用 `buildscript.classpath` 把 Kotlin Gradle 插件钉在与 Compose 编译器插件相同的版本。
- `buildFeatures { compose = true; buildConfig = true }`。
- 依赖：Compose BOM（material3、ui-tooling-preview、material-icons-extended）、activity-compose、lifecycle-viewmodel-compose、lifecycle-runtime-compose、kotlinx-coroutines-android、play-services-ads（25.x）、user-messaging-platform（4.x）、billing-ktx（9.x）。测试：junit4、kotlinx-coroutines-test、org.json（JVM 单元测试用）、androidx.test（core、runner、rules、ext.junit）、compose ui-test-junit4、ui-test-manifest。假实现放在 `src/sharedTest/kotlin`，同时进入 `test` 与 `androidTest` 源集。
- Release：`isMinifyEnabled = true`、`isShrinkResources = true`，签名从仓库外的 `key.properties` 读取（keyAlias / keyPassword / storeFile / storePassword），与 menkyo 相同；`preReleaseBuild` 前检查四个值齐全且 keystore 文件存在。
- 广告 ID：
  - debug 固定用 Google 测试 ID：App ID `ca-app-pub-3940256099942544~3347511713`，自适应横幅 `ca-app-pub-3940256099942544/9214589741`。
  - release 从 `gradle.properties` 的 `kana.admob.appId`、`kana.admob.bannerId` 读取，AdMob Android App 建好后填入并提交（ID 不是机密，iOS 也直接写在代码里）。两个值为空或仍含测试发布商号 `3940256099942544` 时，release 构建失败并给出提示。
  - App ID 通过 manifestPlaceholder 写入 `com.google.android.gms.ads.APPLICATION_ID` meta-data；横幅 ID 和商品 ID 进 `BuildConfig`。
- 根 `.gitignore` 追加：`source/android/.gradle/`、`source/android/local.properties`、`source/android/key.properties`、`*.jks`、`*.keystore`、`.kotlin/`、`.idea/`、`*.iml`（`build/` 已有）。

## 4. 架构

单 Activity + Compose。ViewModel 持有状态，纯 Kotlin 类承载规则，Android 依赖都藏在接口后面。

包结构（`jp.jacky.kana`）：

| 包 | 内容 | 职责 |
| --- | --- | --- |
| （根） | `KanaApplication`、`MainActivity`、`KanaApp` composable | 建 `AppContainer`；edge-to-edge；把 Activity 生命周期转给广告和同意流程；根据状态显示练习页和面板 |
| `di` | `AppContainer` 接口、`DefaultAppContainer` | 持有单例：`statStore`、`coffeeStore`、`adsManager`、`soundPlayer`、`random`、`clock`、`timeLimitMillis`（UI 测试放宽限时）、`shareActions` |
| `practice` | `Kana`、`KanaForm`、`KanaTable`、`Question`、`QuestionEngine`、`PracticeViewModel`、`PracticeUiState`、`PracticeScreen` 及子组件 | 出题、计时、答题、统计栏、菜单、横幅槽位 |
| `stats` | `StatSummary`、`StatStore` | 统计持久化 |
| `ads` | `AdsManager` 接口、`GoogleAdsManager`、`BannerAd` composable | 同意流程、SDK 初始化、隐私选项、横幅视图 |
| `store` | `CoffeeStore` 接口、`PlayCoffeeStore`、`PurchaseOutcome`、`StoreException` | Play Billing |
| `coffee` | `CoffeeViewModel`、`CoffeeUiState`、`CoffeeSheet` | 咖啡面板 |
| `chart` | `KanaChartSheet` | 五十音图 |
| `share` | `ShareActions` 接口、`AndroidShareActions` | 分享、反馈邮件 |
| `sound` | `SoundPlayer` 接口、`SoundPoolPlayer` | 音效 |
| `ui.theme` | `KanaColors`、`KanaTheme`、`KanaFonts` | 颜色、字体、主题 |

关键接口：

```kotlin
interface CoffeeStore {
    val adsRemoved: StateFlow<Boolean>
    val price: StateFlow<String?>            // 本地化价格文本，未取到为 null
    suspend fun loadProduct()                // 失败不抛，price 保持 null
    suspend fun purchase(activity: Activity): PurchaseOutcome   // PURCHASED / CANCELLED / PENDING
    suspend fun restore(): Boolean           // true = 找到既有购买
}

interface AdsManager {
    val isReady: StateFlow<Boolean>          // MobileAds 已初始化且允许请求广告
    val privacyOptionsRequired: StateFlow<Boolean>
    fun gatherConsent(activity: Activity)    // 每次启动调用一次
    fun showPrivacyOptions(activity: Activity)
}

interface SoundPlayer { fun playCorrect(); fun playIncorrect() }

interface ShareActions { fun share(activity: Activity); fun canSendFeedback(): Boolean; fun sendFeedback(activity: Activity) }
```

数据流：

- `PracticeViewModel` 组合 `QuestionEngine`、`StatStore`、`SoundPlayer`，并观察 `CoffeeStore.adsRemoved` 与 `AdsManager.isReady`、`privacyOptionsRequired`。对外暴露 `StateFlow<PracticeUiState>` 和事件方法：`answer(index)`、`toggleMenu()`、`openChart()`、`openCoffee()`、`closeSheet()`、`setInBackground(Boolean)`、`bannerFailed()`。
- `CoffeeViewModel` 只依赖 `CoffeeStore`，把 iOS `CoffeeViewController` 的状态机搬过来。
- `MainActivity` 在 `onStart` 调 `adsManager.gatherConsent(this)`（未购买时），在 `onStart` / `onStop` 调 `practiceViewModel.setInBackground(false / true)`。
- 测试通过替换 `KanaApplication.container` 注入假实现（见第 12 节）。

## 5. 练习规则

与 iOS 一致，另有三处明确修正（下文标 **修正**）。

数据：`KanaTable.rows` 是五十音图的 11 行，每格 `Kana(romaji, hiragana, katakana)`，空位用 `null` 占位以保持对齐（や行、わ行）；`KanaTable.practicePool` 为 46 个非空音。数据从 iOS `AppConfig.monographs` 逐项移植；浊音、拗音表暂不移植。

出题（`QuestionEngine.next()`，`Random` 可注入）：

1. 从 `practicePool` 随机取题目音。
2. 题目写法从罗马音 / 平假名 / 片假名三种中随机取一种。
3. 正确答案的写法从其余两种中随机取一种。
4. 三个干扰项：从 `practicePool` 中随机取与题目音不同、且彼此不同的三个音（**修正一**：iOS 允许干扰项重复），每个的写法三选一随机。
5. 正确项位置在 0..3 随机。

产出 `Question(prompt: String, answers: List<Answer>, correctIndex: Int)`，`Answer(kana, label)`。

计时：每题 5.0 秒，用注入的单调 `TimeSource` 计时。`PracticeViewModel` 在出题时记录开始时刻并启动协程 `delay(剩余时间)`，到期触发超时。

暂停：`paused = menuExpanded || activeSheet != null || inBackground`。进入暂停时取消计时协程并记录暂停时刻；解除暂停时把开始时刻后移暂停时长，再按剩余时间重启计时（已在展示正确答案时不重启）。**修正二**：App 退到后台也暂停（iOS 不处理）。

作答（`answer(index)`）：

- 若菜单展开，先收起。
- 未处于展示正确答案状态：
  - 取 `cost` = 当前时刻 − 开始时刻（秒）。
  - 答对：播放 correct 音效；`currentStreak + 1`，超过 `bestStreak` 则更新；若 `cost ≤ 5` 记入统计；出下一题。
  - 答错：播放 incorrect 音效；`currentStreak = 0`；若 `cost ≤ 5` 记入统计；进入展示正确答案状态（正确项高亮）；请求横幅。
- 超时：播放 incorrect 音效；`currentStreak = 0`；不记入统计；进入展示正确答案状态；请求横幅。
- 已处于展示正确答案状态（**修正三**）：点正确项播放 correct 音效并直接出下一题，不改连对、不记统计；点错误项只播放 incorrect 音效，状态不变。（iOS 在此情况下会把连对加一并可能记一次统计，属于无意行为。）

统计（`StatStore`）：

- `StatSummary(totalCount, totalCost, recentCosts[≤10], currentStreak, bestStreak)`，JSON 存于 `filesDir/stats.json`，用 Android 自带的 `org.json` 读写，写入先写临时文件再原子重命名。
- `add(cost)` 只接受 `0 < cost ≤ 5`：计数加一、累加耗时、追加到最近列表并裁到 10 个。
- 派生值：`averageSeconds = totalCost / totalCount`，`recentSeconds = recentCosts 平均`；`totalCount == 0` 时两者为 `null`，界面显示「—」。
- 文件损坏或缺失时从零开始，不提示。

## 6. 界面规格

### 6.1 主题

| 名称 | 值 | 来源 |
| --- | --- | --- |
| `accent` | `#C93332` | kanaAccentColor（最高连对、咖啡按钮、图标） |
| `secondary` | `#6E6963` | kanaSecondaryColor（说明文字） |
| `paper` | `#FCFAF5` | kanaPaperColor（咖啡面板底） |
| `keyRed` | `#D0141B` | kanaKeyRedColor（五十音图选中圆钮） |
| `keyGray` | `#F7F7F7` | kanaKeyGrayColor（练习页底、图表交替行） |
| `ink` | `#171412` | kanaBlackColor（正文、未选中圆钮） |
| `incorrect` | `#F08F8F` | 答错时正确项底色 |
| `divider` | `ink` 9% | 统计栏分隔线 |

- 固定浅色：`KanaTheme` 始终用上述颜色，不读系统深色设置；状态栏、导航栏图标为深色。
- 字体：假名与罗马音用 `hosohuwa.ttf`（iOS 同一文件）；其余用系统默认字体。iOS 的 pt 按 1:1 换算为 dp；假名字号用不随系统缩放的 dp 换算值（`155.dp.toSp()` 这类写法），界面文字用 sp。
- 图标（Material Icons）：菜单 `Menu` / 收起 `ExpandLess`、五十音图 `GridView`、咖啡 `LocalCafe`、已支持 `FavoriteBorder`、更多 `MoreHoriz`、分享 `Share`、反馈 `MailOutline`、广告隐私 `PrivacyTip`、关闭 `Close`、权益 `CheckCircle`（outlined）、感谢徽章 `Favorite`。
- edge-to-edge：根布局按 `WindowInsets.safeDrawing` 留边；横幅与答案格延伸到屏幕两侧。
- 内容宽度上限：统计栏、菜单行 560dp；咖啡面板内容 380dp；居中。

### 6.2 练习页（`PracticeScreen`）

自上而下：

1. **菜单行**（展开时高 80dp，收起时 0，动画 250ms）：左「五十音图」（网格图标 + 文字，14sp medium，`ink`）；右「请作者喝咖啡」（咖啡杯图标，`accent`；已购买后图标换心形）和「更多」按钮（44dp）。更多弹出 `DropdownMenu`：分享、反馈（仅当设备能处理 mailto）、广告隐私选项（仅当 `privacyOptionsRequired && !adsRemoved`）。
2. **统计栏**：标题「YOUR PRACTICE」（11sp semibold 大写，`secondary`）与菜单按钮（44dp，展开时图标变为向上箭头）；四列等宽指标：答题数、平均用时、最近 10 次平均、最高连对（数值 25sp 等宽数字 medium；秒数后缀 12sp `secondary`；最高连对数值 `accent`；说明 11sp `secondary`）；底部 1px 分隔线。
3. **题目区**：底色 `keyGray`；题目居中，字号 155（换算 dp），宽度不超过 240dp、高度不超过题目区 85%，超出时缩小。
4. **横幅槽位**：仅在请求横幅且 `isReady && !adsRemoved` 时出现，高度 = 广告高度 + 5dp；下一题收起。
5. **答案格**：白底 2×2，占剩余高度；每格文字 80（换算 dp）居中，`ink`；格间 1px `keyGray` 分隔。展示正确答案时正确项底色 `incorrect`、文字白色。

横屏与平板：同一布局，题目区按剩余高度缩放；答案格始终 2×2。

### 6.3 五十音图（`KanaChartSheet`）

- `ModalBottomSheet`，`skipPartiallyExpanded = true`，下滑或返回键关闭；关闭后练习页恢复计时。
- 顶部 140dp 头部：两个 64dp 圆钮「あ」「ア」（30 号 hosohuwa，白字），选中 `keyRed`，未选中 `ink`；默认平假名。
- 网格 5 列，11 行；每格高 60dp：假名 32 号 hosohuwa 居中，下方罗马音 18 号 `secondary`；空位留白；行背景白与 `keyGray` 交替；行内边距 10dp。ん单独一行靠左。

### 6.4 咖啡面板（`CoffeeSheet`）

- `ModalBottomSheet` 全高，底色 `paper`，右上 44dp 圆形关闭钮（`ink` 5% 底）。购买或恢复进行中时禁止关闭和下滑。
- 内容居中竖排：96dp 圆形插图（`accent` 7% 底，咖啡杯图标 44dp `accent`，右下 28dp 心形徽章）→ 标题（28sp semibold）→ 说明（15sp `secondary`）→ 分隔线 + 权益行（勾选图标 18dp + 文字）+ 分隔线 → 主按钮（最小高 56dp，圆角 14dp，`accent` 底白字）→ 条款（caption）→ 状态（footnote）→ 「恢复」文字按钮（44dp）→ 底部「五 十 音」（17sp 衬线，`secondary` 45%）。
- 状态与 iOS 一致：

| 状态 | 主按钮 | 其他 |
| --- | --- | --- |
| 读取价格中 | 「Loading price」+ 转圈，禁用 | |
| 价格可用 | 「Buy me a coffee · ¥300」 | |
| 价格不可用 | 「Try again」（点击重新读取） | 状态文字 CoffeeUnavailable |
| 购买中 / 恢复中 | 「Confirming purchase」/「Restoring purchase」+ 转圈，禁用 | 关闭钮禁用 |
| 等待批准 | 「Awaiting approval」，禁用 | 状态文字 CoffeePendingMessage；广告不移除 |
| 已购买 | 「Back to practice」（关闭面板） | 标题 CoffeeThanks、说明 ThanksMessage、权益 CoffeeSupported、插图心形；隐藏条款和恢复 |

- 弹窗（`AlertDialog`，单个「OK」）：恢复无结果 → RestoreNoneTitle / RestoreNoneMessage；购买或恢复失败 → PurchaseFailedTitle + 错误说明。

## 7. 广告与同意

Google 已把 `play-services-ads` 标为维护模式并推荐 Next-Gen SDK；本版沿用 `play-services-ads` 25.x，与 iOS 使用的 GMA SDK 13 对应，后续再评估迁移。

- 启动（`MainActivity.onStart`）且未购买时调用 `gatherConsent(activity)`，每次进程只执行一次：
  1. `ConsentInformation.requestConsentInfoUpdate`（`setTagForUnderAgeOfConsent(false)`）。
  2. 成功后 `UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity)`。
  3. 表单关闭后若 `canRequestAds()` 为真且尚未初始化，则在后台线程 `MobileAds.initialize`，完成后 `isReady = true`。
  4. 与 iOS 相同，调用 `requestConsentInfoUpdate` 的同时立即检查一次 `canRequestAds()`，上次启动已同意的用户不必等网络。
  5. 请求失败时不做重试，`isReady` 保持原值；App 其余功能正常。
- `privacyOptionsRequired` 取自 `privacyOptionsRequirementStatus == REQUIRED`，同意流程结束后更新；`showPrivacyOptions` 调用 `UserMessagingPlatform.showPrivacyOptionsForm`。
- debug 构建可通过 `gradle.properties` 的 `kana.ads.debugGeography=eea` 打开 `ConsentDebugSettings`（EEA + 当前设备 hash），用于手动检查同意表单；默认关闭。
- 横幅（`BannerAd`）：`AdView` 在 Activity 作用域创建一次，`adUnitId = BuildConfig.ADMOB_BANNER_ID`，尺寸 `AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(context, 窗口宽度 dp)`（SDK 25 起标记弃用，但替代的 large 版本最高占屏 20%，与 iOS 的横幅高度不符，故沿用）；`PracticeUiState.bannerRequested` 变为 true 且允许时 `loadAd(AdRequest)`；`onAdFailedToLoad` 回调 `bannerFailed()` 收起槽位；随 Activity 生命周期 `pause / resume / destroy`。
- Manifest：`APPLICATION_ID` meta-data；`INTERNET`、`ACCESS_NETWORK_STATE` 权限由 SDK 合并；`AD_ID` 权限由 SDK 自动声明，不额外处理。

## 8. 咖啡内购（`PlayCoffeeStore`）

- `BillingClient`：`setListener`、`enablePendingPurchases(PendingPurchasesParams.enableOneTimeProducts())`、`enableAutoServiceReconnection()`。App 启动即 `startConnection`。
- 连接就绪后：`queryPurchasesAsync(INAPP)` 刷新权益；`queryProductDetailsAsync` 取 `jp.jacky.kana.coffee` 的 `oneTimePurchaseOfferDetails.formattedPrice` 作为 `price`。
- 处理购买记录：产品包含 `jp.jacky.kana.coffee` 且 `purchaseState == PURCHASED` → 未 acknowledge 则 acknowledge → `adsRemoved = true`；`PENDING` → 不改 `adsRemoved`。每次启动的查询结果决定 `adsRemoved`（退款后查询不再返回该购买，权益自动收回，对应 iOS 的 `revocationDate`）。
- `purchase(activity)`：无产品先 `loadProduct`，仍无则抛 `StoreException.ProductUnavailable`；`launchBillingFlow`，等待 `PurchasesUpdatedListener`：`OK` 且状态 `PURCHASED` → `PURCHASED`；`PENDING` → `PENDING`；`USER_CANCELED` → `CANCELLED`；`ITEM_ALREADY_OWNED` → 重新查询后返回 `PURCHASED`；其他响应码 → 抛 `StoreException.Billing(code, debugMessage)`。
- `restore()`：`queryPurchasesAsync` 后返回 `adsRemoved.value`。
- `adsRemoved` 持久化在 SharedPreferences `kana`，键 `user.purchase.adsRemoved`；启动时先读缓存值，查询完成后覆盖。
- Billing 回调线程不定，用 `suspendCancellableCoroutine` 包装成挂起函数，状态更新切回主线程。
- Play 未发布或商品未建时，`loadProduct` 取不到价格，界面停在「价格不可用」并可重试，不崩溃。

## 9. 分享与反馈（`AndroidShareActions`）

- 分享：`ACTION_SEND` + `text/plain`，内容为 IntroText 换行后接 `https://play.google.com/store/apps/details?id=jp.jacky.kana`，用系统选择器。
- 反馈：`ACTION_SENDTO` `mailto:newbdez33+kana.feedback@gmail.com`，主题 Feedback。Manifest 声明 `<queries>` 以便 `resolveActivity` 在 Android 11+ 可用；无法处理时不显示菜单项。

## 10. 本地化与资源

- 字符串键与 iOS `Localizable.strings` 一一对应（39 个）：IntroText、Feedback、Coffee、CoffeeThanks、Restore、AdPrivacy、ThanksTitle、ThanksMessage、RestoreNoneTitle、RestoreNoneMessage、PurchaseFailedTitle、OK、Chart、Practice、StatAnswers、StatAverage、StatRecent、StatBest、StatSeconds、Menu、CloseMenu、Close、More、Share、Support、CoffeeMessage、CoffeeBenefit、CoffeeSupported、CoffeePrice、CoffeeTerms、CoffeeLoading、CoffeeUnavailable、CoffeePending、CoffeePendingMessage、CoffeePurchasing、CoffeeRestoring、ContinuePractice、Retry、PurchaseUnverified；另加 `app_name`（Kana）。键名转 snake_case。
- 格式参数改为 Android 位置参数：`stat_recent` = `Last %1$d avg.`，`stat_seconds` = `%1$ss`，`coffee_price` = `Buy me a coffee · %1$s`。
- 文案改动：`restore_none_message` 把「Apple Account」改为「Google account」（8 种语言各自改）；`purchase_unverified` 在 Android 不使用，仍保留以便对照。
- 语言目录：`values`（en）、`values-ja`、`values-b+zh+Hans`、`values-b+zh+Hant`、`values-ko`、`values-de`、`values-fr`、`values-es`。`locales_config.xml` 列出 8 种语言，Manifest 引用，支持 Android 13+ 的应用内语言设置。
- 音效：`correct.wav`、`incorrect.wav` 原样放 `res/raw`，`SoundPool`（`USAGE_GAME`、`CONTENT_TYPE_SONIFICATION`）预加载，不申请音频焦点，与 iOS 的「混音」一致。
- 字体：`Hosohuwafont.ttf` 复制为 `res/font/hosohuwa.ttf`。
- 图标：原图 `source/kana/kana/Assets.xcassets/AppIcon.appiconset/Icon-1024.png` 是白底、右侧竖排手写「五十音」。Android 自适应图标会被裁成圆形或圆角，所以背景层用纯白，前景层把三个字裁出后居中缩放到 108dp 画布中央的 66dp 安全区；导出 mdpi 到 xxxhdpi 的 `ic_launcher` 与 `ic_launcher_round`。

## 11. 错误处理

| 场景 | 行为 |
| --- | --- |
| 统计文件读写失败 | 忽略；内存中的值照常显示 |
| 同意信息请求失败 | 不重试，`isReady` 不变；练习正常 |
| 广告加载失败 | 收起槽位；下次答错再请求 |
| Billing 连接失败 / 无价格 | 面板显示「价格不可用」+ 重试；不弹窗 |
| 购买或恢复抛错 | 弹「Purchase not completed」+ 错误说明 |
| 购买 pending | 面板显示等待批准；下次启动查询到 PURCHASED 后才去广告 |
| 无邮件应用 | 不显示反馈项 |
| 设备无 Play 服务 | Billing 报 `BILLING_UNAVAILABLE`，走「价格不可用」；广告 SDK 自行处理 |

## 12. 测试

JVM 单元测试（`src/test`，JUnit4 + kotlinx-coroutines-test）：

- `QuestionEngineTest`：正确项恰有一个且在 0..3；四个音互不相同；正确项标签与题目写法不同；题目和答案文本都来自 46 个音；固定种子结果可复现。
- `StatStoreTest`：空状态平均为 null；`add` 只接受 (0, 5]；最近列表裁到 10；重启后从文件恢复；文件损坏时从零开始。
- `PracticeViewModelTest`（虚拟时间 + 假 `TimeSource`）：答对更新连对与统计并出新题；答错进入展示状态、请求横幅、连对归零；5 秒超时等同答错但不记统计；展示状态下点正确项出新题且连对不变；暂停期间不超时且暂停时长不计入耗时；`adsRemoved` 变为 true 时横幅收起；后台暂停。
- `CoffeeViewModelTest`（假 `CoffeeStore`）：六种状态的按钮文字与可用性；恢复无结果弹窗；抛错弹窗；pending 不去广告。
- `PlayCoffeeStoreTest`：用可注入的 `BillingClient` 包装接口的假实现，覆盖 PURCHASED / PENDING / 取消 / 已拥有 / 错误码，以及启动查询更新 `adsRemoved`。

模拟器 UI 测试（`src/androidTest`，Compose 测试规则）：

- `TestKanaApplication` + 自定义 `AndroidJUnitRunner` 注入 `FakeAppContainer`：固定种子 `Random`、`FakeCoffeeStore`、`FakeAdsManager`（`isReady = false`，不加载真实广告）、`FakeSoundPlayer`。
- 用例：练习页显示题目与四个答案，点正确项后答题数变化；点错误项后正确项高亮；打开五十音图并切换到片假名；打开咖啡面板，看到价格，购买后显示感谢状态；恢复无结果弹窗；日语 locale 下显示日文文案。
- 设备：新建 AVD `kana_api_36`（Pixel 7、API 36 google_apis arm64，复用本机镜像，不动 menkyo 的 AVD）。

验证命令（`source/android/` 下）：`./gradlew :app:testDebugUnitTest`、`./gradlew :app:lintDebug`、`./gradlew :app:assembleDebug`、`./gradlew :app:connectedDebugAndroidTest`。release 构建在填入正式广告 ID 和签名前预期失败，属于设计行为。

## 13. 主人需要做的事与后续

不阻塞开发，但上架前必须完成：

1. AdMob：新建 Android App（包名 `jp.jacky.kana`，未上架也可先建），新建一个横幅广告单元；把它加入现有 European / US 两条同意消息。把 App ID 和广告单元 ID 填入 `gradle.properties`。
2. Play Console：新建 App，创建一次性商品 `jp.jacky.kana.coffee`（以日本 ¥300 为基准价），添加许可测试账号；启用 Play App Signing，把上传密钥信息写到 `source/android/key.properties`。
3. 真机验证：同意弹窗、横幅、购买、恢复。

后续 spec：商店截图（模拟器按 5 种语言自动抓图）、商店文案（复用 `store/metadata.json`）、数据安全表单、广告声明、内部测试到正式发布。

## 14. 验收标准

- `testDebugUnitTest`、`lintDebug`、`assembleDebug`、`connectedDebugAndroidTest` 全部通过。
- 模拟器上手动检查 debug 构建：练习、答错高亮、超时、统计四个数字、菜单、五十音图切换、咖啡面板各状态、分享、8 种语言切换均可用；Google 测试横幅在答错后显示、下一题收起。
- 固定浅色，系统深色模式下界面不变。
- 根 README 增加 Android 构建说明；TODO.md 第 6 节前两项打勾并记录日期。
