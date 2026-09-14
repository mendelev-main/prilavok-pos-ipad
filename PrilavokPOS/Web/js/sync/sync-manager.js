// Prilavok POS v130.13
// Manual synchronization contract.
//
// Architectural requirements:
// 1. POS must continue operating without internet.
// 2. Local POS data is authoritative.
// 3. Remote systems must not overwrite newer local POS state.
// 4. Local persistence happens independently of synchronization.
// 5. Synchronization is NEVER started automatically.
// 6. The only approved standard sync trigger is the existing button in
//    Settings -> Network Settings (Настройки -> Сетевые настройки).
// 7. No sync on app launch, timer, reconnect, network-change event, or
//    immediately after a local mutation.
// 8. A failed sync must not modify or roll back authoritative local data.
//
// This module is still intentionally not connected to pos.html.
// It defines the contract we will implement when wiring the existing
// Network Settings synchronization button in a later safe migration step.

(function (global) {
  'use strict';

  const root = global.PrilavokCore = global.PrilavokCore || {};

  const SyncManager = {
    mode: 'manual-only',
    sourceOfTruth: 'local-pos',
    approvedTrigger: 'settings.network.manual-sync-button',
    automaticTriggersEnabled: false,

    canStartAutomatically() {
      return false;
    },

    describePolicy() {
      return {
        mode: this.mode,
        sourceOfTruth: this.sourceOfTruth,
        approvedTrigger: this.approvedTrigger,
        automaticTriggersEnabled: this.automaticTriggersEnabled
      };
    }
  };

  root.SyncManager = Object.freeze(SyncManager);
})(window);
