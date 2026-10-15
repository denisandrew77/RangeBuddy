#!/bin/sh
# Rebuild launcher assets from the original logo. Requires ImageMagick (magick).
set -eu
cd "$(dirname "$0")/.."
source_logo=assets/branding/denicar.jpg
for entry in mdpi:48:108 hdpi:72:162 xhdpi:96:216 xxhdpi:144:324 xxxhdpi:192:432; do
  density=${entry%%:*}
  sizes=${entry#*:}
  legacy=${sizes%%:*}
  adaptive=${sizes#*:}
  target="android/app/src/main/res/mipmap-$density"
  mkdir -p "$target"
  magick "$source_logo" -resize "$((legacy * 84 / 100))x$((legacy * 84 / 100))" -background white -gravity center -extent "${legacy}x${legacy}" "$target/ic_launcher.png"
  # Keep the entire wordmark within the central adaptive-icon safe region.
  magick "$source_logo" -resize "$((adaptive * 55 / 100))x$((adaptive * 55 / 100))" -background white -gravity center -extent "${adaptive}x${adaptive}" "$target/ic_launcher_foreground.png"
done
for size in 192 512; do
  magick "$source_logo" -resize "$((size * 84 / 100))x$((size * 84 / 100))" -background white -gravity center -extent "${size}x${size}" "web/icons/Icon-$size.png"
  magick "$source_logo" -resize "$((size * 60 / 100))x$((size * 60 / 100))" -background white -gravity center -extent "${size}x${size}" "web/icons/Icon-maskable-$size.png"
done
magick "$source_logo" -resize 54x54 -background white -gravity center -extent 64x64 web/favicon.png
