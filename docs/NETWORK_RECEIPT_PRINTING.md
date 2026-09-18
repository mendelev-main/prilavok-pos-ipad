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
