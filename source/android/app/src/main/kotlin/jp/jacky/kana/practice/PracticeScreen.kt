package jp.jacky.kana.practice

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.GridView
import androidx.compose.material.icons.outlined.KeyboardArrowUp
import androidx.compose.material.icons.outlined.LocalCafe
import androidx.compose.material.icons.outlined.MailOutline
import androidx.compose.material.icons.outlined.Menu
import androidx.compose.material.icons.outlined.MoreHoriz
import androidx.compose.material.icons.outlined.PrivacyTip
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import jp.jacky.kana.R
import jp.jacky.kana.ads.BannerAd
import jp.jacky.kana.stats.StatSummary
import jp.jacky.kana.ui.theme.KanaColors
import jp.jacky.kana.ui.theme.KanaFonts
import java.text.NumberFormat

private val ContentMaxWidth = 560.dp

@Composable
fun PracticeScreen(
    state: PracticeUiState,
    bannerAdUnitId: String,
    canSendFeedback: Boolean,
    onAnswer: (Int) -> Unit,
    onToggleMenu: () -> Unit,
    onOpenChart: () -> Unit,
    onOpenCoffee: () -> Unit,
    onShare: () -> Unit,
    onFeedback: () -> Unit,
    onPrivacyPolicy: () -> Unit,
    onPrivacyOptions: () -> Unit,
    onBannerFailed: () -> Unit,
) {
    Column(
        Modifier
            .fillMaxSize()
            .background(KanaColors.keyGray)
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal))
    ) {
        AnimatedVisibility(visible = state.menuExpanded) {
            MenuRow(
                adsRemoved = state.adsRemoved,
                privacyOptionsAvailable = state.privacyOptionsAvailable,
                canSendFeedback = canSendFeedback,
                onOpenChart = onOpenChart,
                onOpenCoffee = onOpenCoffee,
                onShare = onShare,
                onFeedback = onFeedback,
                onPrivacyPolicy = onPrivacyPolicy,
                onPrivacyOptions = onPrivacyOptions,
            )
        }
        StatisticsBar(stats = state.stats, menuExpanded = state.menuExpanded, onToggleMenu = onToggleMenu)
        Column(Modifier.weight(1f).fillMaxWidth()) {
            QuestionArea(prompt = state.question.prompt, modifier = Modifier.weight(1f))
            if (state.showBanner) {
                BannerAd(adUnitId = bannerAdUnitId, onFailed = onBannerFailed, modifier = Modifier.padding(bottom = 5.dp))
            }
        }
        AnswerGrid(
            question = state.question,
            revealCorrect = state.revealCorrect,
            onAnswer = onAnswer,
            modifier = Modifier.weight(1f).windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Bottom)),
        )
    }
}

@Composable
private fun MenuRow(
    adsRemoved: Boolean,
    privacyOptionsAvailable: Boolean,
    canSendFeedback: Boolean,
    onOpenChart: () -> Unit,
    onOpenCoffee: () -> Unit,
    onShare: () -> Unit,
    onFeedback: () -> Unit,
    onPrivacyPolicy: () -> Unit,
    onPrivacyOptions: () -> Unit,
) {
    Box(Modifier.fillMaxWidth().height(80.dp), contentAlignment = Alignment.BottomCenter) {
        Row(
            Modifier.widthIn(max = ContentMaxWidth).fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 6.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            TextButton(onClick = onOpenChart, modifier = Modifier.heightIn(min = 44.dp).testTag("chartMenu")) {
                Icon(Icons.Outlined.GridView, contentDescription = null, tint = KanaColors.ink)
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.chart), color = KanaColors.ink, fontSize = 14.sp, fontWeight = FontWeight.Medium)
            }
            Spacer(Modifier.weight(1f))
            TextButton(onClick = onOpenCoffee, modifier = Modifier.heightIn(min = 44.dp).testTag("coffeeMenu")) {
                Icon(
                    if (adsRemoved) Icons.Outlined.FavoriteBorder else Icons.Outlined.LocalCafe,
                    contentDescription = null,
                    tint = KanaColors.accent,
                )
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.support), color = KanaColors.accent, fontSize = 14.sp, fontWeight = FontWeight.Medium)
            }
            Box {
                var expanded by remember { mutableStateOf(false) }
                IconButton(onClick = { expanded = true }, modifier = Modifier.size(44.dp).testTag("moreMenu")) {
                    Icon(Icons.Outlined.MoreHoriz, contentDescription = stringResource(R.string.more), tint = KanaColors.secondary)
                }
                DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.share)) },
                        leadingIcon = { Icon(Icons.Outlined.Share, contentDescription = null) },
                        onClick = { expanded = false; onShare() },
                    )
                    if (canSendFeedback) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.feedback)) },
                            leadingIcon = { Icon(Icons.Outlined.MailOutline, contentDescription = null) },
                            onClick = { expanded = false; onFeedback() },
                        )
                    }
                    if (privacyOptionsAvailable) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.ad_privacy)) },
                            leadingIcon = { Icon(Icons.Outlined.PrivacyTip, contentDescription = null) },
                            onClick = { expanded = false; onPrivacyOptions() },
                        )
                    }
                    DropdownMenuItem(
                        text = { Text(stringResource(R.string.privacy_policy)) },
                        leadingIcon = { Icon(Icons.Outlined.PrivacyTip, contentDescription = null) },
                        onClick = { expanded = false; onPrivacyPolicy() },
                        modifier = Modifier.testTag("privacyPolicyMenu"),
                    )
                }
            }
        }
    }
}

@Composable
private fun StatisticsBar(stats: StatSummary, menuExpanded: Boolean, onToggleMenu: () -> Unit) {
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
        Column(Modifier.widthIn(max = ContentMaxWidth).fillMaxWidth().padding(horizontal = 20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    stringResource(R.string.practice).uppercase(),
                    color = KanaColors.secondary,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.SemiBold,
                )
                Spacer(Modifier.weight(1f))
                IconButton(onClick = onToggleMenu, modifier = Modifier.size(44.dp).testTag("menuToggle")) {
                    Icon(
                        if (menuExpanded) Icons.Outlined.KeyboardArrowUp else Icons.Outlined.Menu,
                        contentDescription = stringResource(if (menuExpanded) R.string.close_menu else R.string.menu),
                        tint = KanaColors.ink,
                    )
                }
            }
            Spacer(Modifier.height(8.dp))
            val hasAnswers = stats.totalCount > 0
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
                Metric(
                    value = AnnotatedString(NumberFormat.getIntegerInstance().format(stats.totalCount)),
                    caption = stringResource(R.string.stat_answers),
                    tag = "statTotal",
                    modifier = Modifier.weight(1f),
                )
                Metric(
                    value = secondsText(stats.averageSeconds, hasAnswers),
                    caption = stringResource(R.string.stat_average),
                    tag = "statAverage",
                    modifier = Modifier.weight(1f),
                )
                Metric(
                    value = secondsText(stats.recentSeconds, hasAnswers),
                    caption = stringResource(R.string.stat_recent, StatSummary.RECENT_LIMIT),
                    tag = "statRecent",
                    modifier = Modifier.weight(1f),
                )
                Metric(
                    value = AnnotatedString(NumberFormat.getIntegerInstance().format(stats.bestStreak)),
                    caption = stringResource(R.string.stat_best),
                    tag = "statBest",
                    accent = true,
                    modifier = Modifier.weight(1f),
                )
            }
            Spacer(Modifier.height(20.dp))
            HorizontalDivider(color = KanaColors.divider, thickness = 1.dp)
        }
    }
}

@Composable
private fun secondsText(value: Double?, hasAnswers: Boolean): AnnotatedString {
    if (!hasAnswers || value == null) return AnnotatedString("—")
    val number = NumberFormat.getNumberInstance().apply {
        minimumFractionDigits = 2
        maximumFractionDigits = 2
    }.format(value)
    val text = stringResource(R.string.stat_seconds, number)
    val start = text.indexOf(number)
    return buildAnnotatedString {
        append(text)
        addStyle(SpanStyle(fontSize = 12.sp, color = KanaColors.secondary), 0, text.length)
        if (start >= 0) addStyle(SpanStyle(fontSize = 25.sp, color = KanaColors.ink), start, start + number.length)
    }
}

@Composable
private fun Metric(value: AnnotatedString, caption: String, tag: String, modifier: Modifier = Modifier, accent: Boolean = false) {
    Column(modifier.semantics(mergeDescendants = true) {}.testTag(tag)) {
        BasicText(
            text = value,
            style = TextStyle(
                fontSize = 25.sp,
                fontWeight = FontWeight.Medium,
                color = if (accent) KanaColors.accent else KanaColors.ink,
                fontFamily = FontFamily.Default,
            ),
            maxLines = 1,
            autoSize = TextAutoSize.StepBased(minFontSize = 15.sp, maxFontSize = 25.sp, stepSize = 1.sp),
        )
        Spacer(Modifier.height(5.dp))
        Text(caption, color = KanaColors.secondary, fontSize = 11.sp, fontWeight = FontWeight.Medium, maxLines = 2)
    }
}

@Composable
private fun QuestionArea(prompt: String, modifier: Modifier = Modifier) {
    BoxWithConstraints(modifier.fillMaxWidth().background(KanaColors.keyGray), contentAlignment = Alignment.Center) {
        val maxFont = with(LocalDensity.current) { 155.dp.toSp() }
        BasicText(
            text = prompt,
            modifier = Modifier.widthIn(max = 240.dp).heightIn(max = maxHeight * 0.85f).testTag("questionLabel"),
            style = TextStyle(fontFamily = KanaFonts.hosohuwa, color = KanaColors.ink, textAlign = TextAlign.Center),
            maxLines = 1,
            autoSize = TextAutoSize.StepBased(minFontSize = 40.sp, maxFontSize = maxFont, stepSize = 4.sp),
        )
    }
}

@Composable
private fun AnswerGrid(question: Question, revealCorrect: Boolean, onAnswer: (Int) -> Unit, modifier: Modifier = Modifier) {
    val maxFont = with(LocalDensity.current) { 80.dp.toSp() }
    Column(modifier.fillMaxWidth().background(Color.White)) {
        for (row in 0 until 2) {
            Row(Modifier.weight(1f).fillMaxWidth()) {
                for (column in 0 until 2) {
                    val index = row * 2 + column
                    val highlight = revealCorrect && index == question.correctIndex
                    Box(
                        Modifier
                            .weight(1f)
                            .fillMaxHeight()
                            .background(if (highlight) KanaColors.incorrect else Color.Transparent)
                            .clickable { onAnswer(index) }
                            .semantics { if (highlight) stateDescription = "correct" }
                            .testTag("answer$index"),
                        contentAlignment = Alignment.Center,
                    ) {
                        BasicText(
                            text = question.answers[index].label,
                            style = TextStyle(
                                fontFamily = KanaFonts.hosohuwa,
                                color = if (highlight) Color.White else KanaColors.ink,
                                textAlign = TextAlign.Center,
                            ),
                            maxLines = 1,
                            autoSize = TextAutoSize.StepBased(minFontSize = 24.sp, maxFontSize = maxFont, stepSize = 2.sp),
                        )
                    }
                    if (column == 0) VerticalDivider(color = KanaColors.keyGray, thickness = 1.dp)
                }
            }
            if (row == 0) HorizontalDivider(color = KanaColors.keyGray, thickness = 1.dp)
        }
    }
}
