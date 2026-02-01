<script setup>
import { ref, watch, computed } from 'vue';
import { useFunctionGetter } from 'dashboard/composables/store';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import TiendanubeAPI from 'dashboard/api/integrations/tiendanube';
import TiendanubeOrderItem from './TiendanubeOrderItem.vue';

const props = defineProps({
  contactId: {
    type: [Number, String],
    required: true,
  },
});

const contact = useFunctionGetter('contacts/getContact', props.contactId);

const hasSearchableInfo = computed(
  () => !!contact.value?.email || !!contact.value?.phone_number
);

const orders = ref([]);
const loading = ref(true);
const error = ref('');

const fetchOrders = async () => {
  if (!hasSearchableInfo.value) {
    loading.value = false;
    return;
  }

  try {
    loading.value = true;
    error.value = '';
    const response = await TiendanubeAPI.getOrders(props.contactId);
    orders.value = response.data.orders || [];
  } catch (e) {
    console.error('Tiendanube orders error:', e);
    error.value = e.response?.data?.error || 'Failed to load orders';
  } finally {
    loading.value = false;
  }
};

watch(
  () => props.contactId,
  () => {
    if (hasSearchableInfo.value) {
      fetchOrders();
    }
  },
  { immediate: true }
);
</script>

<template>
  <div class="px-4 py-2 text-n-slate-12">
    <div v-if="!hasSearchableInfo" class="text-center text-n-slate-11 text-sm">
      {{ $t('CONVERSATION_SIDEBAR.TIENDANUBE.NO_DATA') }}
    </div>
    <div v-else-if="loading" class="flex justify-center items-center p-4">
      <Spinner size="32" class="text-n-brand" />
    </div>
    <div v-else-if="error" class="text-center text-n-ruby-11 text-sm">
      {{ error }}
    </div>
    <div v-else-if="!orders.length" class="text-center text-n-slate-11 text-sm">
      {{ $t('CONVERSATION_SIDEBAR.TIENDANUBE.NO_ORDERS') }}
    </div>
    <div v-else>
      <TiendanubeOrderItem
        v-for="order in orders"
        :key="order.external_id"
        :order="order"
      />
    </div>
  </div>
</template>
