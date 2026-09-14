/*
 Prilavok POS - Local Storage Layer
 v130.9 preparation

 RULE:
 Local iPad POS data is the primary source of truth.
 This file is a preparation layer only.
 Business logic should not access storage directly.

 Future responsibilities:
 - products
 - categories
 - orders
 - receipts
 - shifts
 - settings
 - employees
*/

const POSStorage = {
    get(key) {
        const value = localStorage.getItem(key);
        return value ? JSON.parse(value) : null;
    },

    set(key, value) {
        localStorage.setItem(key, JSON.stringify(value));
    },

    remove(key) {
        localStorage.removeItem(key);
    }
};
