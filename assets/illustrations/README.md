# MedSuper illustrations

Original raster illustrations generated for the MedSuper patient app with the built-in OpenAI image-generation tool. The PNG files are 1254 × 1254 RGBA images with transparent backgrounds and use the app's blue (`#2452D9`) and teal (`#0F766E`) palette.

| File | Intended use | Generation brief |
|---|---|---|
| `care_overview.png` | Patient home care overview or next-care panel | Geometric healthcare cross, appointment calendar, shield, and capsule; calm, dimensional editorial illustration. |
| `doctor_discovery.png` | Doctor search or appointment discovery | Stethoscope framing an appointment calendar with a geometric clinician symbol. |
| `pharmacy_order.png` | Pharmacy orders or prescription flow | Blank prescription sheet, unbranded medicine bottle, and capsule. |
| `splash_orbit.png` | App launch splash artwork | Luminous connected-care form with orbit lines and frosted-glass accents, designed for the blue launch background. |
| `appointment_calendar.png` | Patient home appointments quick action | Compact calendar with a single check and clock accent; generated as a transparent image and downsampled to 192 × 192 for mobile-card use. |
| `wallet.png` | Patient home wallet quick action | Compact blank-card wallet with a teal clasp; contains no currency or payment claims and is downsampled to 192 × 192. |

No embedded copy, patient photography, brand marks, or medical claims are included. Keep app labels and accessibility descriptions in the localized Flutter UI, not baked into these images.

Flutter bundles this directory through the `assets/illustrations/` entry in `pubspec.yaml`. Example:

```dart
Image.asset(
  'assets/illustrations/care_overview.png',
  semanticLabel: 'Care overview illustration',
)
```
