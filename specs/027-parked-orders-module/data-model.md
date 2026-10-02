# Data Model: parked orders

The existing parked row and current-order session shapes are unchanged. This stage introduces no
field or migration. Deletion writes only the existing logical key `parked`; the existing critical
journal is temporary recovery metadata and is cleared after a completed commit.
