package jp.jacky.kana.practice

import kotlin.random.Random

data class Answer(val kana: Kana, val label: String)

data class Question(
    val kana: Kana,
    val prompt: String,
    val answers: List<Answer>,
    val correctIndex: Int,
)

/**
 * Builds one question at a time: a random kana shown in one form, the correct answer in a
 * different form, and distinct distractors in random forms.
 */
class QuestionEngine(
    private val random: Random,
    private val pool: List<Kana> = KanaTable.practicePool,
    private val answerCount: Int = 4,
) {
    fun next(): Question {
        val kana = pool.random(random)
        val forms = KanaForm.entries
        val promptForm = forms.random(random)
        val correctForm = forms.filter { it != promptForm }.random(random)
        val distractors = pool.filter { it != kana }.shuffled(random).take(answerCount - 1).iterator()
        val correctIndex = random.nextInt(answerCount)
        val answers = List(answerCount) { index ->
            if (index == correctIndex) {
                Answer(kana, kana.text(correctForm))
            } else {
                val other = distractors.next()
                Answer(other, other.text(forms.random(random)))
            }
        }
        return Question(kana, kana.text(promptForm), answers, correctIndex)
    }
}
