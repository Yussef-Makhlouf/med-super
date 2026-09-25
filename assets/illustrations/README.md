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
| `specialty_general_medicine.png` | General medicine specialty tile | Medical bag and stethoscope. |
| `specialty_orthopedics.png` | Orthopedics specialty tile | Knee joint model. |
| `specialty_ent.png` | Ear, nose, and throat specialty tile | Ear model and tuning fork. |
| `specialty_neurology.png` | Neurology specialty tile | Brain model with neural detail. |
| `specialty_psychiatry.png` | Psychiatry specialty tile | Calm abstract profile and thought bubbles. |
| `specialty_gynecology.png` | Gynecology specialty tile | Non-graphic reproductive-system model. |
| `specialty_urology.png` | Urology specialty tile | Kidney pair model. |
| `specialty_endocrinology.png` | Endocrinology specialty tile | Thyroid model and molecule. |
| `specialty_gastroenterology.png` | Gastroenterology specialty tile | Stomach and intestine model. |
| `specialty_pulmonology.png` | Pulmonology specialty tile | Lungs with airflow detail. |
| `specialty_family_medicine.png` | Family medicine specialty tile | Three abstract figures and a care cross. |
| `specialty_rheumatology.png` | Rheumatology specialty tile | Hand joints and joint model. |
| `specialty_hematology.png` | Hematology specialty tile | Blood drop and microscope. |
| `specialty_nephrology.png` | Nephrology specialty tile | Kidneys and filtration droplet. |
| `specialty_allergy_immunology.png` | Allergy and immunology specialty tile | Immune shield and pollen. |
| `specialty_internal_medicine.png` | Internal medicine specialty tile | Clinical chart with organ symbols. |

No embedded copy, patient photography, brand marks, or medical claims are included. Keep app labels and accessibility descriptions in the localized Flutter UI, not baked into these images.

The 16 new specialty images were generated as a consistent 4×4 transparent illustration sheet and exported as individual 384 × 384 PNGs. Flutter bundles this directory through the `assets/illustrations/` entry in `pubspec.yaml`. Example:

```dart
Image.asset(
  'assets/illustrations/care_overview.png',
  semanticLabel: 'Care overview illustration',
)
```
