# MedSuper brand assets

`medsuper_app_icon.png` is the approved square launcher source. It is used on
the password-login hero and was generated with the built-in image generator
from this brief: an opaque cobalt square, a centered white medical cross, and
a teal pulse line; no text or watermark.

Platform outputs:

- Android density-specific PNGs and adaptive launcher resources are in
  `android/app/src/main/res/mipmap-*` and `mipmap-anydpi-v*`.
- iPhone and iPad icon sizes are in
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- The adaptive Android icon uses a native vector foreground so its cross and
  pulse remain crisp and safely inside launcher masks.

The Flutter UI loads the master only for the branded login illustration; native
launch assets remain separate so platform startup stays fast and stable.
