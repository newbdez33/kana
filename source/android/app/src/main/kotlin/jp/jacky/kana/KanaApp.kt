package jp.jacky.kana

import androidx.activity.compose.LocalActivity
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import jp.jacky.kana.chart.KanaChartSheet
import jp.jacky.kana.coffee.CoffeeSheet
import jp.jacky.kana.coffee.CoffeeViewModel
import jp.jacky.kana.di.AppContainer
import jp.jacky.kana.practice.PracticeScreen
import jp.jacky.kana.practice.PracticeViewModel
import jp.jacky.kana.practice.Sheet

@Composable
fun KanaApp(container: AppContainer, viewModel: PracticeViewModel) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val activity = LocalActivity.current

    PracticeScreen(
        state = state,
        bannerAdUnitId = BuildConfig.ADMOB_BANNER_ID,
        canSendFeedback = container.shareActions.canSendFeedback(),
        onAnswer = viewModel::answer,
        onToggleMenu = viewModel::toggleMenu,
        onOpenChart = viewModel::openChart,
        onOpenCoffee = viewModel::openCoffee,
        onShare = { activity?.let(container.shareActions::share) },
        onFeedback = { activity?.let(container.shareActions::sendFeedback) },
        onPrivacyOptions = { activity?.let(container.adsManager::showPrivacyOptions) },
        onBannerFailed = viewModel::bannerFailed,
    )

    when (state.sheet) {
        Sheet.CHART -> KanaChartSheet(onDismiss = viewModel::closeSheet)
        Sheet.COFFEE -> {
            val coffeeViewModel: CoffeeViewModel = viewModel(factory = CoffeeViewModel.factory(container.coffeeStore))
            CoffeeSheet(viewModel = coffeeViewModel, onDismiss = viewModel::closeSheet)
        }
        null -> Unit
    }
}
