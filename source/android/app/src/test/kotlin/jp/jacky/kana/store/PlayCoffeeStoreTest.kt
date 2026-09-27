package jp.jacky.kana.store

import android.app.Activity
import com.android.billingclient.api.BillingClient.BillingResponseCode
import jp.jacky.kana.testing.FakeBillingGateway
import jp.jacky.kana.testing.InMemoryAdsRemovedStorage
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class PlayCoffeeStoreTest {
    private val gateway = FakeBillingGateway()
    private val storage = InMemoryAdsRemovedStorage()
    private val activity = Activity()

    private fun record(purchased: Boolean = true, pending: Boolean = false, acknowledged: Boolean = false) =
        PurchaseRecord(purchased = purchased, pending = pending, acknowledged = acknowledged, token = "token-1")

    @Test
    fun `start refreshes the entitlement and loads the price`() = runTest {
        storage.write(true) // stale cache from a refunded purchase
        gateway.purchases = emptyList()
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertTrue(store.adsRemoved.value)
        store.start()
        runCurrent()
        assertFalse(store.adsRemoved.value)
        assertFalse(storage.read())
        assertEquals("¥300", store.price.value)
    }

    @Test
    fun `purchase acknowledges and removes ads`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.OK, listOf(record()))) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.PURCHASED, store.purchase(activity))
        assertTrue(store.adsRemoved.value)
        assertTrue(storage.read())
        assertEquals(listOf("token-1"), gateway.acknowledged)
    }

    @Test
    fun `pending purchase keeps ads`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.OK, listOf(record(purchased = false, pending = true)))) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.PENDING, store.purchase(activity))
        assertFalse(store.adsRemoved.value)
    }

    @Test
    fun `user cancel returns CANCELLED`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.USER_CANCELED, emptyList())) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.CANCELLED, store.purchase(activity))
    }

    @Test
    fun `purchase returns CANCELLED when the update has no coffee record`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.OK, emptyList())) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.CANCELLED, store.purchase(activity))
        assertFalse(store.adsRemoved.value)
    }

    @Test
    fun `already owned refreshes the entitlement`() = runTest {
        gateway.purchases = listOf(record(acknowledged = true))
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.ITEM_ALREADY_OWNED, emptyList())) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertEquals(PurchaseOutcome.PURCHASED, store.purchase(activity))
        assertTrue(store.adsRemoved.value)
    }

    @Test
    fun `billing errors are reported`() = runTest {
        gateway.onLaunch = { gateway.purchaseUpdates.tryEmit(PurchaseUpdate(BillingResponseCode.SERVICE_DISCONNECTED, emptyList())) }
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        try {
            store.purchase(activity)
            fail("expected StoreException.Billing")
        } catch (e: StoreException.Billing) {
            assertEquals(BillingResponseCode.SERVICE_DISCONNECTED, e.responseCode)
        }
    }

    @Test
    fun `launch failure is reported without waiting`() = runTest {
        gateway.launchResult = BillingResponseCode.BILLING_UNAVAILABLE
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        try {
            store.purchase(activity)
            fail("expected StoreException.Billing")
        } catch (e: StoreException.Billing) {
            assertEquals(BillingResponseCode.BILLING_UNAVAILABLE, e.responseCode)
        }
    }

    @Test
    fun `missing product throws ProductUnavailable`() = runTest {
        gateway.product = null
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        store.loadProduct()
        assertEquals(null, store.price.value)
        try {
            store.purchase(activity)
            fail("expected ProductUnavailable")
        } catch (e: StoreException.ProductUnavailable) {
            // expected
        }
    }

    @Test
    fun `restore reports and applies an existing purchase`() = runTest {
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        assertFalse(store.restore())
        gateway.purchases = listOf(record())
        assertTrue(store.restore())
        assertTrue(store.adsRemoved.value)
        assertEquals(listOf("token-1"), gateway.acknowledged)
    }

    @Test
    fun `connection failure leaves the price unknown`() = runTest {
        gateway.connectResult = BillingResponseCode.BILLING_UNAVAILABLE
        val store = PlayCoffeeStore(gateway, storage, backgroundScope)
        store.loadProduct()
        assertEquals(null, store.price.value)
        assertFalse(store.restore())
    }
}
