# Deferred / Out-of-Scope Items (Wave 2 executor view)

## Pre-existing failures observed at Wave 2 start

- `test/widgets/eden_detail_header_test.dart` + `test/widgets/_fixtures/eden_detail_page_scaffold_fixtures.dart` — compile errors referencing `EdenDetailPageScaffold` / `EdenDetailTab` symbols not yet exported. This is Wave 1 TRD-02's RED state (RED commit shipped, GREEN not yet landed). Owned by parallel Wave 1 executor; out of scope for Wave 2.

These are not regressions caused by Wave 2 changes.
