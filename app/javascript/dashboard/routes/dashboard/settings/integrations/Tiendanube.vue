<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import Integration from './Integration.vue';
import Spinner from 'shared/components/Spinner.vue';
import tiendanubeAPI from 'dashboard/api/integrations/tiendanube';

const store = useStore();
const integrationLoaded = ref(false);
const isConnecting = ref(false);

const integration = computed(() =>
  store.getters['integrations/getIntegration']('tiendanube')
);

const uiFlags = computed(() => store.getters['integrations/getUIFlags']);

const integrationAction = computed(() => {
  if (integration.value?.enabled) {
    return 'disconnect';
  }
  return 'connect';
});

const connectTiendanube = async () => {
  try {
    isConnecting.value = true;
    const { data } = await tiendanubeAPI.connectTiendanube();
    window.location.href = data.redirect_url;
  } catch (error) {
    useAlert(
      'Error connecting to Tienda Nube. Please try again.'
    );
  } finally {
    isConnecting.value = false;
  }
};

const initializeIntegration = async () => {
  await store.dispatch('integrations/get', 'tiendanube');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeIntegration();
});
</script>

<template>
  <div
    v-if="integrationLoaded && !uiFlags.isFetching"
    class="flex flex-col flex-1 overflow-auto gap-5 pt-1 pb-10"
  >
    <Integration
      :integration-id="integration.id"
      :integration-logo="integration.logo"
      :integration-name="integration.name"
      :integration-description="integration.description"
      :integration-enabled="integration.enabled"
      :integration-action="integrationAction"
    >
      <template #action>
        <woot-button
          v-if="!integration.enabled"
          color-scheme="success"
          variant="smooth"
          :is-loading="isConnecting"
          @click="connectTiendanube"
        >
          {{ $t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT') }}
        </woot-button>
      </template>
    </Integration>
  </div>

  <div v-else class="flex items-center justify-center flex-1">
    <Spinner size="" color-scheme="primary" />
  </div>
</template>
