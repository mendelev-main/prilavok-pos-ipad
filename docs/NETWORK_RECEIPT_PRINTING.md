# Network Receipt Printing — Current Specification

## Status

Active implementation for Prilavok POS on iPad.

## Architecture

Receipt printing is direct from the native iPad application to a LAN receipt printer.

Flow:

```
pos.html / network-printer.js
        ↓ WKWebView message handler "printer"
PrilavokPOSApp.swift
        ↓
BluetoothPrinterManager.swift
        ↓ NWConnection TCP
printer IP : 9100
        ↓
ESC/POS
Xprinter XP-N160II
```

No desktop print service is part of the receipt-printing path. A Mac, Windows VM, browser print agent, or printer driver is not required during normal POS operation.

## Supported printer configuration

Primary tested printer: Xprinter XP-N160II (Wi-Fi + USB).

Current working network configuration:
- printer is in STA mode;
- iPad and printer must have IP connectivity on the same LAN or routed LAN;
- WPA2-PSK/AES is supported by the tested printer when connected through a compatible access point;
- printer receives an IPv4 address by DHCP;
- raw receipt printing uses TCP port 9100;
- payload is ESC/POS.

The POS stores printer IP/configuration locally. For operational stability, the printer should receive a stable address, preferably through a DHCP reservation on the router.

## Native bridge contract

JavaScript sends:

```js
window.webkit.messageHandlers.printer.postMessage({
  action: 'print',
  order: {
    ...order,
    __networkPrinterIp: '192.168.x.x',
    __networkPrinterPort: 9100
  }
})
```

For a physical test print:

```js
{
  action: 'print',
  order: {
    __networkPrinterIp: '192.168.x.x',
    __networkPrinterPort: 9100,
    __networkTest: true
  }
}
```

`PrilavokPOSApp.swift` forwards `action: print` to `BluetoothPrinterManager.print(order:)`.

When `__networkPrinterIp` is present, `BluetoothPrinterManager` uses `NWConnection` with TCP and sends the ESC/POS bytes directly to the printer. The network path must not fall back to Bluetooth.

## Required receipt flows

All receipt-printing entry points must use the same native TCP path:

1. printer test from Settings;
2. manual print/reprint from the Receipts screen;
3. print from the paid-receipt modal;
4. automatic receipt printing after payment;
5. every configured receipt printer in the multi-printer configuration.

`network-printer.js` is the multi-printer layer. It adds `__networkPrinterIp`, port 9100 and printer configuration before posting to the native bridge.

The legacy single-printer functions in `pos.html` remain a compatibility fallback and must also use the native TCP bridge. They must not implement a separate HTTP printing path.

## Error/status handling

Native printer events are returned to JavaScript through `window.__nativePrinterEvent`.

Expected states:
- successful send: `printed` / `network_connected`;
- invalid/unreachable printer: `printError` / `network_error`;
- connection timeout: show a clear network error to the operator.

A successful TCP send means the job was handed to the printer connection; it is not a paper/consumable sensor confirmation.

## Offline-first rule

Printing is a local function and must not depend on Railway, Supabase, internet access, cloud synchronization, or any external printing service. If the local LAN is available, receipt printing must continue while the internet is unavailable.

## Deprecated design

The previous design that routed receipt jobs through a local Print Bridge / HTTP bridge is retired. Do not add `bridgeUrl`, HTTP print forwarding, or a required desktop helper back into the receipt flow.

Historical references to that design should be treated as obsolete. The source of truth is the native iPad TCP/9100 implementation described above.

## Implementation note: state scope

The main POS state is a top-level lexical `const state` in `pos.html`; it must not be assumed to exist as `window.state`. External scripts such as `network-printer.js` must not use `window.state.orders` to resolve receipt history. The configured-printer layer passes its selected receipt printers into the legacy receipt function explicitly, so reprints use the same saved LAN printer configuration as the successful test-print flow.

## Graphic receipt mode

When `__printerConfig.printMode == "graphic"` (the default for the XP-N160II profile), the native iPad layer renders the receipt with UIKit fonts, converts it to a monochrome bitmap and sends it with the ESC/POS `GS v 0` raster command. Cyrillic is therefore rendered by iOS and does not depend on the printer code page. Paper width, requested print width and DPI are taken from printer configuration. Text mode remains available as a compatibility fallback.

## Receipt designer

Each configured receipt printer has its own locally stored receipt appearance profile. The printer editor exposes **Настроить внешний вид чека**. The profile is passed inside `__printerConfig` and applied by the native raster renderer.

Supported customization includes custom receipt title/subtitle, header and footer comments, payment-section and total labels, visibility of order label/type, items, item comments, payments, cash tender/change, order comment, currency, separators and footer; title/body/small/total font sizes; content padding, line spacing, section spacing and item spacing. These settings are per printer and offline-first. Printer connection settings and receipt appearance settings must remain independent so changing visual design cannot break TCP connectivity.

Future receipt-designer additions should extend the same `__printerConfig` profile rather than create a second print pipeline. Suitable extensions include logo/QR blocks, alignment controls, custom fields, duplicate copies, kitchen templates and a live on-screen preview.

## Printer roles and document architecture

Printer configuration is a full-page settings flow rather than a modal editor. Every printer has one primary role: **payment receipts** or **order tickets (kitchen/bar)**.

Payment receipt printers receive the complete paid order and render receipt identity metadata including a stable receipt number, payment timestamp and shift employee. Kitchen/order printers do not render financial totals; they render the order/ticket number, order label/type, time, employee/register and the routed item list with item comments.

Kitchen printers can be assigned product categories. Before a kitchen job is sent, POS filters the order items to the categories assigned to that printer. An empty category assignment means all categories. Item category is snapshotted into the completed order so later product/category edits do not change historical routing metadata.

The printer settings UI must keep connection, role/routing, receipt template, and technical ESC/POS settings as separate sections. The established native TCP/9100 raster pipeline remains unchanged.

## Automatic document routing

After a payment is finalized, the completed immutable order is routed once through the configured printer profiles. Receipt-role printers with automatic printing enabled receive the full payment receipt. Kitchen/bar-role printers with automatic printing enabled receive only items matching their assigned categories; an empty filtered ticket is never printed. Each printer may independently print 1–3 copies.

Payment receipt template controls include visibility of receipt number, date/time, employee, register, customer, order label/type, item comments, payment details and other existing visual fields. These controls affect the native raster renderer, not just the settings UI.
