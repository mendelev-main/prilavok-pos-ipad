// Prilavok POS v130.12
// Background synchronization layer placeholder.
// Rules:
// 1. POS must continue operating without internet.
// 2. Local POS data is authoritative.
// 3. Remote systems must not overwrite newer local POS state.
// 4. Sync runs only after local persistence succeeds.
// This file is intentionally not connected to pos.html yet.
