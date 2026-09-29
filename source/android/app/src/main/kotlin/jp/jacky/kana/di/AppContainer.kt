package jp.jacky.kana.di

import jp.jacky.kana.ads.AdsManager
import jp.jacky.kana.practice.Clock
import jp.jacky.kana.share.ShareActions
import jp.jacky.kana.sound.SoundPlayer
import jp.jacky.kana.stats.StatStore
import jp.jacky.kana.store.CoffeeStore
import kotlin.random.Random

interface AppContainer {
    val random: Random
    val clock: Clock
    /** Per-question time limit; UI tests raise it so a slow emulator does not time out. */
    val timeLimitMillis: Long
    val statStore: StatStore
    val coffeeStore: CoffeeStore
    val adsManager: AdsManager
    val soundPlayer: SoundPlayer
    val shareActions: ShareActions
}
