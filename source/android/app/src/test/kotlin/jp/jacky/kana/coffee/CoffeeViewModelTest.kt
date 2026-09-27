package jp.jacky.kana.coffee

import android.app.Activity
import jp.jacky.kana.store.PurchaseOutcome
import jp.jacky.kana.store.StoreException
import jp.jacky.kana.testing.FakeCoffeeStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CoffeeViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    private val activity = Activity()

    @Before
    fun setUp() = Dispatchers.setMain(dispatcher)

    @After
    fun tearDown() = Dispatchers.resetMain()

    @Test
    fun `loads the price on creation`() = runTest(dispatcher) {
        val store = FakeCoffeeStore()
        val vm = CoffeeViewModel(store)
        runCurrent()
        assertFalse(vm.state.value.loading)
        assertEquals("¥300", vm.state.value.price)
        assertEquals(1, store.loadCount)
    }

    @Test
    fun `does not load when already purchased`() = runTest(dispatcher) {
        val store = FakeCoffeeStore(initialAdsRemoved = true)
        val vm = CoffeeViewModel(store)
        runCurrent()
        assertTrue(vm.state.value.purchased)
        assertEquals(0, store.loadCount)
    }

    @Test
    fun `purchase completes and shows the thank you state`() = runTest(dispatcher) {
        val store = FakeCoffeeStore()
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.purchase(activity)
        runCurrent()
        assertNull(vm.state.value.operation)
        assertTrue(vm.state.value.purchased)
    }

    @Test
    fun `pending purchase keeps the offer with a pending note`() = runTest(dispatcher) {
        val store = FakeCoffeeStore().apply { purchaseOutcome = PurchaseOutcome.PENDING }
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.purchase(activity)
        runCurrent()
        assertTrue(vm.state.value.pending)
        assertFalse(vm.state.value.purchased)
        // A second tap while pending does nothing.
        vm.purchase(activity)
        assertNull(vm.state.value.operation)
    }

    @Test
    fun `purchase without a price reloads instead of purchasing`() = runTest(dispatcher) {
        val store = FakeCoffeeStore(productPrice = null)
        val vm = CoffeeViewModel(store)
        runCurrent()
        assertNull(vm.state.value.price)
        vm.purchase(activity)
        runCurrent()
        assertEquals(2, store.loadCount)
        assertFalse(vm.state.value.purchased)
    }

    @Test
    fun `restore without a purchase shows the nothing to restore alert`() = runTest(dispatcher) {
        val store = FakeCoffeeStore()
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.restore()
        runCurrent()
        assertEquals(CoffeeAlert.RestoreNone, vm.state.value.alert)
        vm.dismissAlert()
        runCurrent()
        assertNull(vm.state.value.alert)
    }

    @Test
    fun `restore with a purchase removes ads`() = runTest(dispatcher) {
        val store = FakeCoffeeStore().apply { restoreResult = true }
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.restore()
        runCurrent()
        assertTrue(vm.state.value.purchased)
        assertNull(vm.state.value.alert)
    }

    @Test
    fun `billing errors show the failure alert`() = runTest(dispatcher) {
        val store = FakeCoffeeStore().apply { purchaseError = StoreException.Billing(3, "unavailable") }
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.purchase(activity)
        runCurrent()
        assertEquals(CoffeeAlert.Failed("Billing error 3: unavailable"), vm.state.value.alert)
        assertNull(vm.state.value.operation)
    }

    @Test
    fun `unavailable product shows the failure alert without detail`() = runTest(dispatcher) {
        val store = FakeCoffeeStore().apply { purchaseError = StoreException.ProductUnavailable() }
        val vm = CoffeeViewModel(store)
        runCurrent()
        vm.purchase(activity)
        runCurrent()
        assertEquals(CoffeeAlert.Failed(null), vm.state.value.alert)
    }
}
