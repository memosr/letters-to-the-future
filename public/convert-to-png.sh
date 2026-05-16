#!/bin/bash
# Convert SVG assets to PNG using rsvg-convert
# Install: brew install librsvg

set -e
cd "$(dirname "$0")"

if ! command -v rsvg-convert &> /dev/null; then
  echo "rsvg-convert not found. Install with: brew install librsvg"
  exit 1
fi

echo "Converting SVGs to PNG..."

rsvg-convert -w 1024 -h 1024 icon.svg -o icon.png
echo "  icon.png (1024x1024)"

rsvg-convert -w 200 -h 200 splash.svg -o splash.png
echo "  splash.png (200x200)"

rsvg-convert -w 1200 -h 630 hero.svg -o hero.png
echo "  hero.png (1200x630)"

rsvg-convert -w 1200 -h 630 og.svg -o og.png
echo "  og.png (1200x630)"

echo "Done."
