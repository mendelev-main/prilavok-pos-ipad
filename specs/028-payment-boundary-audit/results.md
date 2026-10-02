# Results: аудит границы оплаты

**Baseline**: `1b3b291` · **Version**: 130.52 · **Date**: 2026-10-02

## Сохранённые гарантии

- Completed sale data is committed locally before receipt UI, printing and loyalty publication.
- Product stock, receipt, shift delivery movement and cleared current session share one recovery journal.
- Journal creation failure leaves live sale data unchanged; partial target writes recover at startup.
- The busy guard and empty-cart check prevent duplicate receipt creation in the tested paths.

## Найденные риски

- **P1 confirmed**: a paid split part is transient and is lost on Back, WebView restart or crash before
  the last part. This can cause duplicate collection or an accepted payment without a receipt.
- **P2 defensive**: the internal finalization boundary does not reject unknown methods or offsetting
  negative amounts, although the current UI cannot create them.

## Decision

Do not extract payment code yet. First implement durable split-payment draft and boundary validation
as a separate feature stage, then rerun payment, storage recovery and build checks.

## Verification

- Full Node suite: PASS, 231/231.
- Production runtime diff: none by design.
- Version remains 130.52; `project.pbxproj` remains untouched.
