// The lab-test catalog domain/data/presentation layer that used to live here
// has been removed: the booking flow no longer starts from a searchable
// catalog of selectable tests (see LAB_BOOKING_FLOW_TODO_AR.md). This file
// is kept as a placeholder so downstream providers (e.g. lab partner
// providers) that previously imported it can be migrated by their owning
// agents without this file disappearing outright.
//
// No providers remain here — once the screens/providers that still
// reference the old `selectedLabTestsProvider` / `selectedLabTestsTotalProvider`
// / `activeLabCategoryProvider` / `labSearchQueryProvider` symbols are
// migrated to the new upload-based flow, this file can be deleted entirely.
