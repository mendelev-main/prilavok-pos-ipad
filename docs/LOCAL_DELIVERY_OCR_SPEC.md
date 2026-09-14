# Prilavok POS — Local Delivery OCR Specification

Status: Future implementation

## Goal

Add an optional assistant for goods receiving that can read a photographed supplier document on the iPad, prepare a draft list of received items, match them to the existing local POS catalog, and let the user verify everything before the delivery is committed.

The feature must remain fully local to the iPad. Photos and recognized document contents must not be sent to Railway, Supabase, OpenAI, or any other cloud service as part of recognition.

## Target device and platform constraint

Primary target device:

- iPad 10th generation;
- iPadOS 26.6.2;
- A14 Bionic.

Apple Intelligence / Foundation Models must NOT be a dependency of this feature. The target iPad 10 does not meet Apple's current Apple Intelligence hardware requirements.

The first implementation must therefore use local Apple platform capabilities that work without Apple Intelligence, primarily Vision text recognition plus deterministic local parsing and catalog matching.

## Core product rule

Recognition never commits inventory automatically.

The OCR subsystem only creates a delivery draft. The user must review the draft and explicitly confirm the receiving operation before stock quantities, costs, or other inventory state are changed.

Required flow:

1. User opens `Прием поставки`.
2. User selects `Сфотографировать накладную` or chooses an existing local photo.
3. The image is processed locally on the iPad.
4. OCR extracts text and layout information.
5. A local parser identifies candidate delivery rows.
6. The POS tries to match each recognized row to the local product catalog.
7. The application presents a review screen.
8. The user corrects quantities, units, purchase prices, and product matches where necessary.
9. Unknown items can be linked to an existing product, ignored, or handled through an explicitly designed new-product flow.
10. Only after the user presses `Принять поставку` may the existing delivery/inventory logic be executed.

## Proposed architecture

```text
Photo / Camera
      ↓
Apple Vision OCR
      ↓
Document row parser
      ↓
Text normalization
      ↓
Local product matcher
      ↓
Delivery draft
      ↓
Human review
      ↓
Existing goods-receiving logic
```

No network connection is required for this flow.

## OCR layer

Preferred technology: Apple Vision.

The implementation should use the current Vision text-recognition API available for the deployment target. `RecognizeTextRequest` / `VNRecognizeTextRequest` can provide:

- recognized text;
- confidence values;
- bounding boxes / text locations;
- language configuration;
- accuracy-oriented recognition mode where appropriate.

The OCR layer is responsible only for extracting observations. It must not directly modify POS business data.

## Document parsing layer

The parser converts OCR observations into candidate delivery rows.

Initial candidate model:

```text
recognizedName
quantity
unit
purchasePrice
lineTotal
sourceText
ocrConfidence
```

Not every value must be present. Missing or ambiguous fields must be shown to the user for correction rather than guessed silently.

The parser should use layout information where possible, because supplier documents are often tables and column position can be more reliable than whitespace in the recognized text.

The first version does not need to understand every supplier document format.

## Product matching layer

Matching must be local against the POS catalog.

The matching pipeline should be deterministic and explainable before any future ML approach is considered.

Recommended stages:

1. exact match by known supplier mapping;
2. exact match after normalization;
3. barcode or supplier code match when available;
4. token / fuzzy name similarity;
5. volume, weight, unit, brand or other extracted hints;
6. manual selection by the user if confidence is insufficient.

Example:

```text
Supplier text:
КОКА КОЛА ЗЕРО PET 0,5

Normalized:
кока кола зеро 0.5

Suggested POS product:
Coca-Cola Zero 0.5
```

## Confidence UX

Each draft row should have an explicit state.

Suggested states:

- `matched` — strong known/exact match;
- `suggested` — probable match requiring user attention;
- `unmatched` — no acceptable match;
- `invalid` — required delivery data is missing or contradictory.

The UI may present these states visually, but confidence must never bypass final user confirmation.

## Supplier mapping memory

The POS should eventually be able to remember user-confirmed supplier aliases locally.

Example:

```text
Supplier item text:
МОЛ 3.2 БРЕСТ 1Л

User selected:
Молоко Брест 3.2% 1 л
```

After confirmation, a local mapping can be stored so that the same supplier text is matched directly on future deliveries.

Possible stored fields:

```text
supplierIdentity (optional)
supplierItemCode (optional)
supplierItemName
normalizedSupplierItemName
productId
lastConfirmedAt
```

These mappings are local operational data and must follow the same offline-first principles as the rest of the POS.

## Photo lifecycle and privacy

Default requirement: recognition is local.

The product decision about photo retention should be explicit. Supported future modes may include:

- process and discard the image after the draft is created;
- retain the image locally as an attachment to the delivery.

The initial implementation should not upload delivery-document images as part of OCR processing.

If cloud recognition is ever proposed in the future, it must be treated as a separate feature and must not silently replace local processing.

## Offline-first requirements

This feature must follow `docs/OFFLINE_FIRST_ARCHITECTURE.md`.

Specifically:

- camera/photo recognition must work without internet access;
- OCR must not trigger synchronization;
- creating or editing the delivery draft must remain local;
- confirming the delivery must use the existing local goods-receiving persistence path;
- remote synchronization, if applicable to resulting inventory data, remains a separate manual action through the approved Network Settings synchronization control.

## Failure behavior

OCR failure must never block manual goods receiving.

Required fallback:

```text
OCR succeeds
    → review recognized draft

OCR partly succeeds
    → review and manually complete missing fields

OCR fails
    → continue with normal manual delivery entry
```

The user must always be able to abandon the recognition draft without changing inventory.

## Non-goals for version 1

The first version does not require:

- Apple Intelligence;
- Siri integration;
- Foundation Models;
- Railway processing;
- Supabase processing;
- OpenAI API;
- fully automatic receiving;
- understanding every document format;
- automatic creation of new catalog products;
- cloud storage of supplier documents.

## Recommended implementation phases

### Phase 1 — OCR proof of concept

- camera / photo picker;
- Vision text recognition;
- diagnostics screen showing recognized text, confidence, and bounding boxes;
- no connection to inventory mutation.

### Phase 2 — Delivery draft parser

- convert OCR observations into candidate rows;
- parse quantity, unit, purchase price, and line total where possible;
- allow complete manual correction.

### Phase 3 — Local catalog matching

- normalization;
- fuzzy matching;
- match confidence;
- manual product selection.

### Phase 4 — Supplier mapping memory

- save confirmed aliases;
- prioritize known mappings on later deliveries;
- provide a way to change an incorrect stored mapping.

### Phase 5 — Production integration

- integrate reviewed draft with the existing goods-receiving logic;
- regression-test stock, cost, history, cancellation, and persistence behavior;
- verify on the physical iPad 10 before release.

## Acceptance criteria for the first production version

1. The feature runs on the physical iPad 10 target device.
2. It works with internet disabled.
3. No image or recognized text leaves the iPad during recognition.
4. The user can take a photo or select a local photo.
5. Recognized rows are presented as an editable draft.
6. Existing catalog products can be suggested locally.
7. Ambiguous and unknown products are visibly flagged.
8. OCR errors can be corrected manually.
9. No inventory changes occur before explicit confirmation.
10. Cancelling the draft leaves inventory unchanged.
11. OCR failure falls back to the existing manual goods-receiving flow.
12. The feature does not introduce automatic/background synchronization.

## Future enhancement path

If the POS later targets Apple Intelligence-capable hardware, a future implementation may add an optional local Foundation Models layer to improve document interpretation and ambiguous row parsing.

That future enhancement must remain optional. The deterministic Vision + local parser path defined by this specification remains the compatibility baseline for iPad 10.
