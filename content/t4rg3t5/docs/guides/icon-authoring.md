---
title: Custom Marker Icons
description: Create and package custom T4rg3t5 lock-on marker textures.
weight: 10
extra:
  api_docs: true
  kind: guide
---

T4rg3t5 discovers marker textures from the OpenMW VFS directory `textures/s3/crosshair/`. Add a DDS file there and select its filename stem through the `TargetLockIcon` setting.

## Prepare the image

Use GIMP or another image editor to create a 128×128 marker with a transparent background. A clean black-and-white source works best because T4rg3t5 applies the configured health colors to the marker.

1. Flatten the source to black and white. In GIMP, use **Colors → Threshold** and adjust the cutoff until the shape reads cleanly.
2. Remove or lighten the black pixels. **Colors → Levels** can raise the black input level so the recoloring produces a useful result.
3. Scale the image to 128×128 pixels.
4. Export it as an uncompressed DDS without mipmaps.

## Package and select it

Place the DDS in `textures/s3/crosshair/`. The filename stem becomes the setting value. The included marker uses the stem `Starburst`, so select it with `TargetLockIcon = 'Starburst'`; replace `Starburst` with the stem of your own file.

The settings menu enumerates VFS-visible DDS files in that directory. If the icon does not appear, check the package path, filename case, and DDS extension first.
