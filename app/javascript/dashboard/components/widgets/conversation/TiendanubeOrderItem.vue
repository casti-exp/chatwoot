<script setup>
import { computed } from 'vue';
import { format } from 'date-fns';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  order: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const formatDate = dateString => {
  if (!dateString) return '';
  try {
    return format(new Date(dateString), 'MMM d, yyyy');
  } catch {
    return dateString;
  }
};

const formatCurrency = (amount, currency) => {
  if (amount === undefined || amount === null) return '';
  try {
    return new Intl.NumberFormat('en', {
      style: 'currency',
      currency: currency || 'ARS',
    }).format(amount);
  } catch {
    return `${currency} ${amount}`;
  }
};

const getFinancialStatusClass = status => {
  const classes = {
    paid: 'bg-n-teal-5 text-n-teal-12',
    pending: 'bg-n-amber-5 text-n-amber-12',
    refunded: 'bg-n-ruby-5 text-n-ruby-12',
  };
  return classes[status] || 'bg-n-solid-3 text-n-slate-12';
};

const getFulfillmentStatusClass = status => {
  const classes = {
    fulfilled: 'text-n-teal-9',
    partial: 'text-n-amber-9',
    unfulfilled: 'text-n-ruby-9',
  };
  return classes[status] || 'text-n-slate-11';
};

const financialStatus = computed(() => {
  const status = props.order.financial_status;
  if (!status) return '';
  return t(`CONVERSATION_SIDEBAR.TIENDANUBE.FINANCIAL_STATUS.${status.toUpperCase()}`);
});

const fulfillmentStatus = computed(() => {
  const status = props.order.fulfillment_status;
  if (!status) return '';
  return t(`CONVERSATION_SIDEBAR.TIENDANUBE.FULFILLMENT_STATUS.${status.toUpperCase()}`);
});
</script>

<template>
  <div
    class="py-3 border-b border-n-weak last:border-b-0 flex flex-col gap-1.5"
  >
    <!-- Header with order ID and status -->
    <div class="flex justify-between items-center gap-2">
      <div class="font-medium flex min-w-0 flex-1">
        <a
          :href="order.admin_url"
          target="_blank"
          rel="noopener noreferrer"
          class="hover:underline text-n-slate-12 cursor-pointer truncate flex items-center gap-1"
        >
          <span>{{ $t('CONVERSATION_SIDEBAR.TIENDANUBE.ORDER_ID', { id: order.id }) }}</span>
          <i class="i-lucide-external-link text-xs" />
        </a>
      </div>

      <!-- Financial status badge -->
      <div
        :class="getFinancialStatusClass(order.financial_status)"
        class="text-xs px-2 py-1 rounded capitalize truncate whitespace-nowrap"
        :title="financialStatus"
      >
        {{ financialStatus }}
      </div>
    </div>

    <!-- Date and total -->
    <div class="text-sm text-n-slate-11 flex items-center gap-2">
      <span class="border-r border-n-weak pr-2">
        {{ formatDate(order.created_at) }}
      </span>
      <span class="font-medium text-n-slate-12">
        {{ formatCurrency(order.total_price, order.currency) }}
      </span>
    </div>

    <!-- Fulfillment status -->
    <div v-if="fulfillmentStatus" class="text-sm">
      <span
        :class="getFulfillmentStatusClass(order.fulfillment_status)"
        class="capitalize font-medium"
      >
        {{ fulfillmentStatus }}
      </span>
    </div>
  </div>
</template>
