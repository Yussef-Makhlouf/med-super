# MedSuper brand assets

`medsuper_app_icon.svg` is the editable launcher source; the matching
`medsuper_app_icon.png` is the 1024px raster master used by the login hero and
platform outputs. The updated mark is a white care shield with a teal pulse on
a cobalt gradient, with no text.

Platform outputs:

- Android density-specific PNGs and adaptive launcher resources are in
  `android/app/src/main/res/mipmap-*` and `mipmap-anydpi-v*`.
- iPhone and iPad icon sizes are in
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.
- Web/PWA icon sizes and the favicon are in `web/icons/` and `web/`.
- The Windows multi-resolution icon is `windows/runner/resources/app_icon.ico`.
- The adaptive Android icon and native splash use vector marks so the shield
  and pulse remain crisp and fit launcher masks.

The SVG is the visual source of truth. When changing the mark, regenerate the
PNG master and platform sizes from this source to keep every launcher in sync.

The Flutter UI loads the master only for the branded login illustration; native
launch assets remain separate so platform startup stays fast and stable.
