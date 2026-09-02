/// Short, patient-facing order reference — the confirmation screen and the
/// order detail screen must render the exact same id for the exact same
/// order, so both call this instead of each picking their own truncation
/// (a full UUID vs. a differently-truncated one used to read as two
/// different order numbers for the same order).
String shortOrderId(String orderId) =>
    orderId.length <= 8 ? orderId : orderId.substring(0, 8);
