package jp.jacky.kana.coffee

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import jp.jacky.kana.store.CoffeeStore
import jp.jacky.kana.store.PurchaseOutcome
import jp.jacky.kana.store.StoreException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

sealed interface CoffeeAlert {
    data object RestoreNone : CoffeeAlert
    /** detail null means the product is unavailable. */
    data class Failed(val detail: String?) : CoffeeAlert
}

enum class CoffeeOperation { PURCHASE, RESTORE }

data class CoffeeUiState(
    val purchased: Boolean = false,
    val price: String? = null,
    val loading: Boolean = false,
    val operation: CoffeeOperation? = null,
    val pending: Boolean = false,
    val alert: CoffeeAlert? = null,
) {
    val busy: Boolean get() = operation != null
}

class CoffeeViewModel(private val store: CoffeeStore) : ViewModel() {

    private data class Local(
        val loading: Boolean = false,
        val operation: CoffeeOperation? = null,
        val pending: Boolean = false,
        val alert: CoffeeAlert? = null,
    )

    private val local = MutableStateFlow(Local())

    val state: StateFlow<CoffeeUiState> = combine(store.adsRemoved, store.price, local) { purchased, price, local ->
        CoffeeUiState(
            purchased = purchased,
            price = price,
            loading = local.loading,
            operation = local.operation,
            pending = local.pending && !purchased,
            alert = local.alert,
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, CoffeeUiState(purchased = store.adsRemoved.value, price = store.price.value))

    init {
        if (!store.adsRemoved.value && store.price.value == null) loadProduct()
    }

    fun loadProduct() {
        if (local.value.loading) return
        local.update { it.copy(loading = true) }
        viewModelScope.launch {
            store.loadProduct()
            local.update { it.copy(loading = false) }
        }
    }

    fun purchase(activity: Activity) {
        val current = state.value
        if (current.busy || current.purchased || current.loading || current.pending) return
        if (current.price == null) {
            loadProduct()
            return
        }
        perform(CoffeeOperation.PURCHASE) {
            val outcome = store.purchase(activity)
            local.update { it.copy(pending = outcome == PurchaseOutcome.PENDING) }
        }
    }

    fun restore() {
        if (state.value.busy) return
        perform(CoffeeOperation.RESTORE) {
            if (!store.restore()) local.update { it.copy(alert = CoffeeAlert.RestoreNone) }
        }
    }

    fun dismissAlert() = local.update { it.copy(alert = null) }

    private fun perform(operation: CoffeeOperation, block: suspend () -> Unit) {
        local.update { it.copy(operation = operation) }
        viewModelScope.launch {
            try {
                block()
            } catch (e: StoreException.ProductUnavailable) {
                local.update { it.copy(alert = CoffeeAlert.Failed(null)) }
            } catch (e: StoreException) {
                local.update { it.copy(alert = CoffeeAlert.Failed(e.message)) }
            }
            local.update { it.copy(operation = null) }
        }
    }

    companion object {
        fun factory(store: CoffeeStore): ViewModelProvider.Factory = viewModelFactory {
            initializer { CoffeeViewModel(store) }
        }
    }
}
