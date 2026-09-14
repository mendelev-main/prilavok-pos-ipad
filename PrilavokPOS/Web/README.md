# Web Layer

Temporary architecture boundary for the POS web interface.

Current state:
- Existing production logic remains inside `pos.html`.
- No business logic has been moved yet.
- Future refactoring will extract CSS and JavaScript modules gradually.

Rule: every extraction must keep iPad POS behavior unchanged.
