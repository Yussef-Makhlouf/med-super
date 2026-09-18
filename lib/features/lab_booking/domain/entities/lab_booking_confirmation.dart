/// Result of confirming a lab request — drives the success screen (step 3).
///
/// The lab request is only *submitted* here, not confirmed: the final price,
/// appointment time and any prep instructions (e.g. fasting) are only known
/// once lab staff reviews the request and submits a quote
/// (`clinic-reservations` `SubmitLabQuoteUseCase`) — there is no booking
/// code yet either (`ConfirmLabBookingUseCase` issues one later, after the
/// quote). [orderId] is the real `POST /v1/lab-orders` id, trackable via the
/// "My Lab Requests" list this screen links to — not a fabricated booking
/// number produced at submit time.
class LabBookingConfirmation {
  const LabBookingConfirmation({
    required this.orderId,
    required this.branchName,
    required this.branchAddress,
  });

  final String orderId;
  final String branchName;
  final String branchAddress;
}
