# Installer artwork

- `make_icons.py` (needs `pillow`) cuts `app-icon-source.png` into `app-icon.png` (1024, product icon), `mac-icon.png` (512, osascript `with icon`), `wolfleader.ico` and `wizard-small.bmp` (110x110, Inno `WizardSmallImageFile`).
- `render.py` (needs `playwright` + `pillow`) reads `app-icon.png` and `icons/` and renders the rest; it never writes the four files above. Run `make_icons.py` first.
- `wizard-side.bmp` (328x628, 24-bit, 2x of 164x314): Inno `WizardImageFile`, app icon over the "Wolf Leader" wordmark. `render.py`.
- `whatsnew-cards.bmp` (834x474) for the Inno "What's new" page at 417x237, and `whatsnew-cards.png` (1668x948) for the Mac dialog and README. `render.py`.
- `dmg-background.png` (1280x800, 2x of 640x400): .dmg window background; put the setup app icon in the empty middle band, centred near (320, 235) in points, 112 or smaller. `render.py`.
