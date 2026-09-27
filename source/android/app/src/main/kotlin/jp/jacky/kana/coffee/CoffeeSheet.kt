package jp.jacky.kana.coffee

import androidx.activity.compose.LocalActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsBottomHeight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material.icons.outlined.LocalCafe
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.ModalBottomSheetProperties
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import jp.jacky.kana.R
import jp.jacky.kana.ui.theme.KanaColors

/** "Buy me a coffee" sheet with the same states as the iOS CoffeeViewController. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CoffeeSheet(viewModel: CoffeeViewModel, onDismiss: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val activity = LocalActivity.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true, confirmValueChange = { !state.busy })

    ModalBottomSheet(
        onDismissRequest = { if (!state.busy) onDismiss() },
        sheetState = sheetState,
        containerColor = KanaColors.paper,
        properties = ModalBottomSheetProperties(shouldDismissOnBackPress = !state.busy),
        modifier = Modifier.testTag("coffeeSheet"),
    ) {
        Box(Modifier.fillMaxWidth().fillMaxHeight()) {
            IconButton(
                onClick = onDismiss,
                enabled = !state.busy,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(end = 16.dp)
                    .size(44.dp)
                    .clip(CircleShape)
                    .background(KanaColors.ink.copy(alpha = 0.05f))
                    .testTag("coffeeClose"),
            ) {
                Icon(Icons.Outlined.Close, contentDescription = stringResource(R.string.close), tint = KanaColors.secondary)
            }
            CoffeeContent(
                state = state,
                onPurchase = { activity?.let(viewModel::purchase) },
                onRestore = viewModel::restore,
                onClose = onDismiss,
                modifier = Modifier.align(Alignment.TopCenter).padding(top = 52.dp),
            )
        }
    }

    state.alert?.let { alert ->
        AlertDialog(
            onDismissRequest = viewModel::dismissAlert,
            confirmButton = { TextButton(onClick = viewModel::dismissAlert) { Text(stringResource(R.string.ok)) } },
            title = {
                Text(stringResource(if (alert is CoffeeAlert.RestoreNone) R.string.restore_none_title else R.string.purchase_failed_title))
            },
            text = {
                Text(
                    when (alert) {
                        CoffeeAlert.RestoreNone -> stringResource(R.string.restore_none_message)
                        is CoffeeAlert.Failed -> alert.detail ?: stringResource(R.string.coffee_unavailable)
                    }
                )
            },
        )
    }
}

@Composable
private fun CoffeeContent(
    state: CoffeeUiState,
    onPurchase: () -> Unit,
    onRestore: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val purchased = state.purchased
    BoxWithConstraints(modifier.fillMaxWidth().fillMaxHeight()) {
        val viewportHeight = maxHeight
        Column(Modifier.fillMaxWidth().verticalScroll(rememberScrollState())) {
            // At least one viewport tall: the footer sits at the bottom on tall screens and the
            // whole sheet scrolls on short ones.
            Box(Modifier.fillMaxWidth().heightIn(min = viewportHeight)) {
                Column(
                    Modifier
                        .align(Alignment.TopCenter)
                        .widthIn(max = 380.dp)
                        .fillMaxWidth()
                        .padding(horizontal = 28.dp)
                        .padding(bottom = 64.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Box(
                        Modifier.size(96.dp).clip(CircleShape).background(KanaColors.accent.copy(alpha = 0.07f)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            if (purchased) Icons.Outlined.FavoriteBorder else Icons.Outlined.LocalCafe,
                            contentDescription = null,
                            tint = KanaColors.accent,
                            modifier = Modifier.size(44.dp),
                        )
                        Box(
                            Modifier
                                .align(Alignment.BottomEnd)
                                .size(28.dp)
                                .clip(CircleShape)
                                .background(KanaColors.paper)
                                .padding(4.dp)
                                .clip(CircleShape)
                                .background(KanaColors.accent),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Filled.Favorite, contentDescription = null, tint = Color.White, modifier = Modifier.size(11.dp))
                        }
                    }
                    Spacer(Modifier.height(24.dp))
                    Text(
                        stringResource(if (purchased) R.string.coffee_thanks else R.string.coffee),
                        color = KanaColors.ink,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.SemiBold,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.testTag("coffeeTitle"),
                    )
                    Spacer(Modifier.height(12.dp))
                    Text(
                        stringResource(if (purchased) R.string.thanks_message else R.string.coffee_message),
                        color = KanaColors.secondary,
                        fontSize = 15.sp,
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(28.dp))
                    HorizontalDivider(color = KanaColors.ink.copy(alpha = 0.1f), thickness = 1.dp)
                    Row(
                        Modifier.padding(vertical = 16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.Center,
                    ) {
                        Icon(Icons.Outlined.CheckCircle, contentDescription = null, tint = KanaColors.accent, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        Text(
                            stringResource(if (purchased) R.string.coffee_supported else R.string.coffee_benefit),
                            color = KanaColors.secondary,
                            fontSize = 15.sp,
                        )
                    }
                    HorizontalDivider(color = KanaColors.ink.copy(alpha = 0.1f), thickness = 1.dp)
                    Spacer(Modifier.height(26.dp))

                    val busyLabel = when (state.operation) {
                        CoffeeOperation.PURCHASE -> stringResource(R.string.coffee_purchasing)
                        CoffeeOperation.RESTORE -> stringResource(R.string.coffee_restoring)
                        null -> null
                    }
                    val label = busyLabel
                        ?: if (purchased) stringResource(R.string.continue_practice)
                        else if (state.pending) stringResource(R.string.coffee_pending)
                        else if (state.loading) stringResource(R.string.coffee_loading)
                        else state.price?.let { stringResource(R.string.coffee_price, it) } ?: stringResource(R.string.retry)
                    val showSpinner = state.busy || (state.loading && !purchased)
                    Button(
                        onClick = { if (purchased) onClose() else onPurchase() },
                        enabled = !state.busy && (purchased || (!state.loading && !state.pending)),
                        colors = ButtonDefaults.buttonColors(containerColor = KanaColors.accent, contentColor = Color.White),
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier.fillMaxWidth().heightIn(min = 56.dp).testTag("coffeePurchase"),
                    ) {
                        if (showSpinner) {
                            CircularProgressIndicator(color = Color.White, strokeWidth = 2.dp, modifier = Modifier.size(18.dp))
                            Spacer(Modifier.width(10.dp))
                        }
                        Text(label, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
                    }
                    if (!purchased) {
                        Spacer(Modifier.height(4.dp))
                        Text(stringResource(R.string.coffee_terms), color = KanaColors.secondary, fontSize = 12.sp, textAlign = TextAlign.Center)
                    }
                    val status = when {
                        purchased -> null
                        state.pending -> stringResource(R.string.coffee_pending_message)
                        !state.loading && state.price == null -> stringResource(R.string.coffee_unavailable)
                        else -> null
                    }
                    if (status != null) {
                        Spacer(Modifier.height(12.dp))
                        Text(status, color = KanaColors.secondary, fontSize = 13.sp, textAlign = TextAlign.Center, modifier = Modifier.testTag("coffeeStatus"))
                    }
                    if (!purchased) {
                        Spacer(Modifier.height(12.dp))
                        TextButton(onClick = onRestore, enabled = !state.busy, modifier = Modifier.heightIn(min = 44.dp).testTag("coffeeRestore")) {
                            Text(stringResource(R.string.restore), color = KanaColors.secondary, fontSize = 15.sp)
                        }
                    }
                }
                Text(
                    "五 十 音",
                    color = KanaColors.secondary.copy(alpha = 0.45f),
                    fontSize = 17.sp,
                    fontFamily = FontFamily.Serif,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.align(Alignment.BottomCenter).padding(bottom = 24.dp),
                )
            }
            Spacer(Modifier.windowInsetsBottomHeight(WindowInsets.navigationBars))
        }
    }
}
