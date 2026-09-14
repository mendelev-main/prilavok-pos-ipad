// Prilavok POS shared constants.
// This module is intentionally side-effect free.
// Runtime wiring into pos.html is performed incrementally and must be tested on a physical iPad.

(function (global) {
  'use strict';

  const root = global.PrilavokCore = global.PrilavokCore || {};

  root.Constants = Object.freeze({
    appVersion: '130.14',
    sourceOfTruth: 'local-pos',
    syncMode: 'manual-only'
  });
})(window);
