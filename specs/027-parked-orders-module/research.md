# Research: отложенные заказы

## Existing safe paths

`parkOrderNow` journals `parked` plus `currentOrderSession`; `resumeParked` journals the inverse.
Both update memory after durable completion and have interruption recovery tests.

## Confirmed defect

`deleteParked` filtered `state.parked` first and then called `saveKey`. The compatibility facade
swallows storage errors, so UI state could lose the row without a successful write.

## Decision

Use `commitCriticalStorage('delete-parked',{parked:nextParked})`, retain the existing busy guard
pattern, and update state/open the modal only after success.
