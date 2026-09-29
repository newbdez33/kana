package jp.jacky.kana.practice

enum class KanaForm { ROMAJI, HIRAGANA, KATAKANA }

data class Kana(val romaji: String, val hiragana: String, val katakana: String) {
    fun text(form: KanaForm): String = when (form) {
        KanaForm.ROMAJI -> romaji
        KanaForm.HIRAGANA -> hiragana
        KanaForm.KATAKANA -> katakana
    }
}

/** The 46 basic kana, laid out as the gojūon chart. Ported from the iOS AppConfig.monographs. */
object KanaTable {
    private fun k(romaji: String, hiragana: String, katakana: String) = Kana(romaji, hiragana, katakana)

    /** Chart rows; null keeps the column alignment for empty slots. */
    val rows: List<List<Kana?>> = listOf(
        listOf(k("a", "あ", "ア"), k("i", "い", "イ"), k("u", "う", "ウ"), k("e", "え", "エ"), k("o", "お", "オ")),
        listOf(k("ka", "か", "カ"), k("ki", "き", "キ"), k("ku", "く", "ク"), k("ke", "け", "ケ"), k("ko", "こ", "コ")),
        listOf(k("sa", "さ", "サ"), k("shi", "し", "シ"), k("su", "す", "ス"), k("se", "せ", "セ"), k("so", "そ", "ソ")),
        listOf(k("ta", "た", "タ"), k("chi", "ち", "チ"), k("tsu", "つ", "ツ"), k("te", "て", "テ"), k("to", "と", "ト")),
        listOf(k("na", "な", "ナ"), k("ni", "に", "ニ"), k("nu", "ぬ", "ヌ"), k("ne", "ね", "ネ"), k("no", "の", "ノ")),
        listOf(k("ha", "は", "ハ"), k("hi", "ひ", "ヒ"), k("fu", "ふ", "フ"), k("he", "へ", "ヘ"), k("ho", "ほ", "ホ")),
        listOf(k("ma", "ま", "マ"), k("mi", "み", "ミ"), k("mu", "む", "ム"), k("me", "め", "メ"), k("mo", "も", "モ")),
        listOf(k("ya", "や", "ヤ"), null, k("yu", "ゆ", "ユ"), null, k("yo", "よ", "ヨ")),
        listOf(k("ra", "ら", "ラ"), k("ri", "り", "リ"), k("ru", "る", "ル"), k("re", "れ", "レ"), k("ro", "ろ", "ロ")),
        listOf(k("wa", "わ", "ワ"), null, null, null, k("wo", "を", "ヲ")),
        listOf(k("n", "ん", "ン")),
    )

    val practicePool: List<Kana> = rows.flatten().filterNotNull()
}
