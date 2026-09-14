/*
 Prilavok POS - Synchronization Layer
 v130.9 preparation

 Architecture rule:
 POS LOCAL DATA > SERVER DATA

 Synchronization must never overwrite newer local POS state.
 This file contains only the future sync boundary.
*/

const POSSynchronization = {
    push() {
        // Future: send local changes to backend
    },

    pull() {
        // Future: receive remote data without replacing local truth
    },

    resolveConflict(localData, remoteData) {
        // Local POS always wins by design.
        return localData;
    }
};
