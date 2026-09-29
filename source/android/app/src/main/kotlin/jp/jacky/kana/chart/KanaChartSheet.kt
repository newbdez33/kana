package jp.jacky.kana.chart

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsBottomHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import jp.jacky.kana.practice.Kana
import jp.jacky.kana.practice.KanaForm
import jp.jacky.kana.practice.KanaTable
import jp.jacky.kana.ui.theme.KanaColors
import jp.jacky.kana.ui.theme.KanaFonts

/** The gojūon chart as a full-height sheet; swipe down or press back to close. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun KanaChartSheet(onDismiss: () -> Unit) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    var form by rememberSaveable { mutableStateOf(KanaForm.HIRAGANA) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = Color.White,
        modifier = Modifier.testTag("kanaChart"),
    ) {
        LazyColumn(Modifier.fillMaxWidth().fillMaxHeight()) {
            item { ChartHeader(selected = form, onSelect = { form = it }) }
            itemsIndexed(KanaTable.rows) { index, row ->
                ChartRow(row = row, form = form, background = if (index % 2 == 0) Color.White else KanaColors.keyGray)
            }
            item { Spacer(Modifier.windowInsetsBottomHeight(WindowInsets.navigationBars)) }
        }
    }
}

@Composable
private fun ChartHeader(selected: KanaForm, onSelect: (KanaForm) -> Unit) {
    Row(
        Modifier.fillMaxWidth().height(140.dp),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        FormButton(label = "あ", selected = selected == KanaForm.HIRAGANA, tag = "chartHiragana") { onSelect(KanaForm.HIRAGANA) }
        FormButton(label = "ア", selected = selected == KanaForm.KATAKANA, tag = "chartKatakana") { onSelect(KanaForm.KATAKANA) }
    }
}

@Composable
private fun FormButton(label: String, selected: Boolean, tag: String, onClick: () -> Unit) {
    val fontSize = with(LocalDensity.current) { 30.dp.toSp() }
    Box(
        Modifier
            .size(64.dp)
            .clip(CircleShape)
            .background(if (selected) KanaColors.keyRed else KanaColors.ink)
            .clickable(onClick = onClick)
            .testTag(tag),
        contentAlignment = Alignment.Center,
    ) {
        BasicText(label, style = TextStyle(fontFamily = KanaFonts.hosohuwa, fontSize = fontSize, color = Color.White))
    }
}

@Composable
private fun ChartRow(row: List<Kana?>, form: KanaForm, background: Color) {
    Row(Modifier.fillMaxWidth().background(background).padding(horizontal = 10.dp, vertical = 10.dp)) {
        for (column in 0 until 5) {
            val kana = row.getOrNull(column)
            Box(Modifier.weight(1f).height(60.dp), contentAlignment = Alignment.Center) {
                if (kana != null) ChartCell(kana, form)
            }
        }
    }
}

@Composable
private fun ChartCell(kana: Kana, form: KanaForm) {
    val density = LocalDensity.current
    val kanaSize = with(density) { 32.dp.toSp() }
    val romajiSize = with(density) { 18.dp.toSp() }
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        BasicText(
            kana.text(form),
            style = TextStyle(fontFamily = KanaFonts.hosohuwa, fontSize = kanaSize, color = KanaColors.ink, textAlign = TextAlign.Center),
        )
        BasicText(
            kana.romaji,
            style = TextStyle(fontFamily = KanaFonts.hosohuwa, fontSize = romajiSize, color = KanaColors.secondary, textAlign = TextAlign.Center),
        )
    }
}
