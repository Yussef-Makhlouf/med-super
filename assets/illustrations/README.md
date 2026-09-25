# MedSuper illustrations

Original raster illustrations generated for the MedSuper patient app with the built-in OpenAI image-generation tool. The full-size images are 1254 × 1254 RGBA images; the new compact home assets are downsampled to 384 × 384. All have transparent backgrounds and use the app's blue (`#2452D9`) and teal (`#0F766E`) palette.

| File | Intended use | Generation brief |
|---|---|---|
| `care_overview.png` | Patient home care overview or next-care panel | Geometric healthcare cross, appointment calendar, shield, and capsule; calm, dimensional editorial illustration. |
| `doctor_discovery.png` | Doctor search or appointment discovery | Stethoscope framing an appointment calendar with a geometric clinician symbol. |
| `pharmacy_order.png` | Pharmacy orders or prescription flow | Blank prescription sheet, unbranded medicine bottle, and capsule. |
| `splash_orbit.png` | App launch splash artwork | Luminous connected-care form with orbit lines and frosted-glass accents, designed for the blue launch background. |
| `appointment_calendar.png` | Patient home appointments quick action | Compact calendar with a single check and clock accent; generated as a transparent image and downsampled to 192 × 192 for mobile-card use. |
| `wallet.png` | Patient home wallet quick action | Compact blank-card wallet with a teal clasp; contains no currency or payment claims and is downsampled to 192 × 192. |
| `lab_service.png` | Patient home lab-testing entry point | Microscope and three sample tubes in the existing soft 3D blue/teal illustration style; downsampled to 384 × 384. |
| `specialty_cardiology.png` | Cardiology specialty tile | Stethoscope and heart with a pulse detail; downsampled to 384 × 384. |
| `specialty_pediatrics.png` | Pediatrics specialty tile | Child-friendly teddy bear, stethoscope, and care kit; downsampled to 384 × 384. |
| `specialty_dermatology.png` | Dermatology specialty tile | Dermatoscope, skin sample, and teal droplet; downsampled to 384 × 384. |
| `specialty_dental.png` | Dental specialty tile | Tooth model, dental mirror, and sparkle; downsampled to 384 × 384. |
| `specialty_ophthalmology.png` | Ophthalmology specialty tile | Eye and optical lens; downsampled to 384 × 384. |

No embedded copy, patient photography, brand marks, or medical claims are included. Keep app labels and accessibility descriptions in the localized Flutter UI, not baked into these images.

Flutter bundles this directory through the `assets/illustrations/` entry in `pubspec.yaml`. Example:

```dart
Image.asset(
  'assets/illustrations/care_overview.png',
  semanticLabel: 'Care overview illustration',
)
```
