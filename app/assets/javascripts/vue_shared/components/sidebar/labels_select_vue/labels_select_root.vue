<script>
import $ from 'jquery';
import Vue from 'vue';
import Vuex, { mapState, mapActions, mapGetters } from 'vuex';
import { __ } from '~/locale';

import DropdownValueCollapsed from '~/vue_shared/components/sidebar/labels_select/dropdown_value_collapsed.vue';

import labelsSelectModule from './store';

import DropdownTitle from './dropdown_title.vue';
import DropdownValue from './dropdown_value.vue';
import DropdownButton from './dropdown_button.vue';
import DropdownContents from './dropdown_contents.vue';

import { DropdownVariant } from './constants';

Vue.use(Vuex);

export default {
  store: new Vuex.Store(labelsSelectModule()),
  components: {
    DropdownTitle,
    DropdownValue,
    DropdownButton,
    DropdownContents,
    DropdownValueCollapsed,
  },
  props: {
    allowLabelEdit: {
      type: Boolean,
      required: true,
    },
    allowLabelCreate: {
      type: Boolean,
      required: true,
    },
    allowMultiselect: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowScopedLabels: {
      type: Boolean,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: DropdownVariant.Sidebar,
    },
    selectedLabels: {
      type: Array,
      required: false,
      default: () => [],
    },
    labelsSelectInProgress: {
      type: Boolean,
      required: false,
      default: false,
    },
    labelsFetchPath: {
      type: String,
      required: false,
      default: '',
    },
    labelsManagePath: {
      type: String,
      required: false,
      default: '',
    },
    labelsFilterBasePath: {
      type: String,
      required: false,
      default: '',
    },
    dropdownButtonText: {
      type: String,
      required: false,
      default: __('Label'),
    },
    labelsListTitle: {
      type: String,
      required: false,
      default: __('Assign labels'),
    },
    labelsCreateTitle: {
      type: String,
      required: false,
      default: __('Create group label'),
    },
    footerCreateLabelTitle: {
      type: String,
      required: false,
      default: __('Create group label'),
    },
    footerManageLabelTitle: {
      type: String,
      required: false,
      default: __('Manage group labels'),
    },
  },
  computed: {
    ...mapState(['showDropdownButton', 'showDropdownContents']),
    ...mapGetters([
      'isDropdownVariantSidebar',
      'isDropdownVariantStandalone',
      'isDropdownVariantEmbedded',
    ]),
    dropdownButtonVisible() {
      return this.isDropdownVariantSidebar ? this.showDropdownButton : true;
    },
  },
  watch: {
    selectedLabels(selectedLabels) {
      this.setInitialState({
        selectedLabels,
      });
    },
  },
  mounted() {
    this.setInitialState({
      variant: this.variant,
      allowLabelEdit: this.allowLabelEdit,
      allowLabelCreate: this.allowLabelCreate,
      allowMultiselect: this.allowMultiselect,
      allowScopedLabels: this.allowScopedLabels,
      dropdownButtonText: this.dropdownButtonText,
      selectedLabels: this.selectedLabels,
      labelsFetchPath: this.labelsFetchPath,
      labelsManagePath: this.labelsManagePath,
      labelsFilterBasePath: this.labelsFilterBasePath,
      labelsListTitle: this.labelsListTitle,
      labelsCreateTitle: this.labelsCreateTitle,
      footerCreateLabelTitle: this.footerCreateLabelTitle,
      footerManageLabelTitle: this.footerManageLabelTitle,
    });

    this.$store.subscribeAction({
      after: this.handleVuexActionDispatch,
    });

    document.addEventListener('click', this.handleDocumentClick);
  },
  beforeDestroy() {
    document.removeEventListener('click', this.handleDocumentClick);
  },
  methods: {
    ...mapActions(['setInitialState', 'toggleDropdownContents']),
    /**
     * This method differentiates between
     * dispatched actions and calls necessary method.
     */
    handleVuexActionDispatch(action, state) {
      if (
        action.type === 'toggleDropdownContents' &&
        !state.showDropdownButton &&
        !state.showDropdownContents
      ) {
        this.handleDropdownClose(state.labels.filter(label => label.touched));
      }
    },
    /**
     * This method listens for document-wide click event
     * and toggle dropdown if user clicks anywhere outside
     * the dropdown while dropdown is visible.
     */
    handleDocumentClick({ target }) {
      // This approach of element detection is needed
      // as the dropdown wrapper is not using `GlDropdown` as
      // it will also require us to use `BDropdownForm`
      // which is yet to be implemented in GitLab UI.
      const hasExceptionClass = [
        'js-dropdown-button',
        'js-btn-cancel-create',
        'js-sidebar-dropdown-toggle',
      ].some(
        className =>
          target?.classList.contains(className) ||
          target?.parentElement.classList.contains(className),
      );

      const hadExceptionParent = ['.js-btn-back', '.js-labels-list'].some(
        className => $(target).parents(className).length,
      );

      if (
        this.showDropdownContents &&
        !hadExceptionParent &&
        !hasExceptionClass &&
        !this.$refs.dropdownButtonCollapsed?.$el.contains(target) &&
        !this.$refs.dropdownContents?.$el.contains(target)
      ) {
        this.toggleDropdownContents();
      }
    },
    handleDropdownClose(labels) {
      // Only emit label updates if there are any labels to update
      // on UI.
      if (labels.length) this.$emit('updateSelectedLabels', labels);
      this.$emit('onDropdownClose');
    },
    handleCollapsedValueClick() {
      this.$emit('toggleCollapse');
    },
  },
};
</script>

<template>
  <div
    class="labels-select-wrapper position-relative"
    :class="{
      'is-standalone': isDropdownVariantStandalone,
      'is-embedded': isDropdownVariantEmbedded,
    }"
  >
    <template v-if="isDropdownVariantSidebar">
      <dropdown-value-collapsed
        ref="dropdownButtonCollapsed"
        :labels="selectedLabels"
        @onValueClick="handleCollapsedValueClick"
      />
      <dropdown-title
        :allow-label-edit="allowLabelEdit"
        :labels-select-in-progress="labelsSelectInProgress"
      />
      <dropdown-value v-show="!showDropdownButton">
        <slot></slot>
      </dropdown-value>
      <dropdown-button v-show="dropdownButtonVisible" />
      <dropdown-contents
        v-if="dropdownButtonVisible && showDropdownContents"
        ref="dropdownContents"
      />
    </template>
    <template v-if="isDropdownVariantStandalone || isDropdownVariantEmbedded">
      <dropdown-button v-show="dropdownButtonVisible" />
      <dropdown-contents
        v-if="dropdownButtonVisible && showDropdownContents"
        ref="dropdownContents"
      />
    </template>
  </div>
</template>
