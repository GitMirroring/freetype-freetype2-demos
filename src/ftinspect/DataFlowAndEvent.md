# Data Flow and Event

This document describes how data such as settings and parameters flows between
components in `ftinspect`, and how events are wired between objects.

There's 2 major types of setting: "Active" and "Passive". When an active setting
is changed on the GUI, the event handler will actively push it to the engine.
When a passive setting is changed, it won't be immediately pushed all way down
to the underlying engine. They're passively applied to the engine on every
render event.

Below will list all settings and status values used in the project.

## Common Info and Settings

Most of these settings comes from the left panel. They're common across all
modes.

When they're modified, after internal processing of `SettingPanel`, the
`SettingPanel` will emit a signal, either `repaintNeeded` or `fontReloadNeeded`.
`MainGUI` is responsible to catch the signal. For the former one, it will just
notify the current active tab to repaint its view. For the latter one, it will
first reload the font in `Engine`, then notify the current tab that the font has
changed. During the process, active settings are already applied to the Engine
by `SettingPanel`, and passive settings will be applied when repainting.

Passive settings are applied to the engine via `SettingPanel::syncSettings`
function.

Notation: `->` single arrows means calling hierarchy, and `=>` double arrows
          means temporal sequence (i.e. one happens after another, but not one
          calls another).

Currently there's only one active setting here:

- Hinting Mode: `checkHintingMode` (map using model) -> engine setters -> `FT_Property_Set` => emit reload font

Passive common settings are:

- Hinting On/Off
  `checkHinting` (may change hinting mode!) -> emit repaint -> `syncSettings` => `Engine::update` -> load flags
- Hinting Debug Switches (hor. / vert. hinting etc...)
  repaint -> `syncSettings` => not implemented in Engine
- Auto Hinting On/Off
  `checkAutoHinting` -> emit repaint -> `syncSettings` => `Engine::update` -> load flags
- Anti Aliasing Mode
  `checkAntiAliasing` -> emit repaint -> `syncSettings` (map using model) => `Engine::update` -> load flags
- LCD Filter Mode
  repaint -> `syncSettings` (map using model) -> `Engine::setLcdFilter` -> `FT_Library_SetLcdFilter`
- Gamma Value
  repaint -> `syncSettings` => not implemented in Engine

Info:

- Font Glyph Count
  `loadFont` -> `FTC_Manager_LookupSize` => stored in `curNumGlyphs_`
- Font Type
  `loadFont` -> `FT_FACE_DRIVER_NAME` => stored in `fontType_`
- Available CharMaps (incl. Max index for each charmap)
  `loadFont` -> computed & stored in `curCharMaps_`
- Font Family Name & Style Name
  `loadFont` -> stored in `curFamilyName_` & `curStyleName_`

## Settings and Info in the Singular View

There's currently no active setting in the Singular View.

These parameters are used in the Sinuglar View:

- Current Glyph Index
  `GlyphIndexSelector::currentIndexChanged` -> `setGlyphIndex` (stored in `currentGlyphIndex_`) -> reprint -> `Engine::loadOutline` -> `FTC_ImageCache_LookupScaler`
- Font Size
  `FontSizeSelector::valueChanged` -> `repaintGlyph` -> `syncSettings` -> `FontSizeSelector::applyToEngine` => `Engine::update` -> scaler width/height
- Zoom Factor
  `zoom` -> glyph view transform => emit update grid
- Show Points
  `checkShowPoints` -> repaint (used in painting)
- Show Bitmap & Show Point Numbers & Show Outlines On/Off
  repaint (used in painting)

And these values are obtained from the engine in the Singular View:

- Current Glyph Count (a.k.a. Limit Index)
  (see above "Common Info") -> `reloadFont` (stored in `currentGlyphCount_`) -> `GlyphIndexSelector::setMinMax` -> min/mas for spin box

## Settings and Info in the Continuous View

Settings in the sub tabs are pulled using `updateFromCurrentSubTab` when
repainting. Info is pushed via `updateCurrentSubTab` when reloading font. 

### Common Settings and Info

- Font Size
  `FontSizeSelector::valueChanged` -> repaint -> `FontSizeSelector::applyToEngine`
  May also be alter via scrolling: `wheelResize` -> `FontSizeSelector::handleWheelResizeBySteps` -> spin box value
- Current Glyph Count
  (see above "Common Info") -> `reloadFont` (stored in `currentGlyphCount_`)
- Mode
  repaint -> `updateFromCurrentSubTab` (stored in canvas) => `GlyphContinuous::paintEvent`

### All Glyphs Mode

(all passive)

Settings:

- SubMode
  repaint -> `updateFromCurrentSubTab` (stored in canvas) => `GlyphContinuous::paintEvent`
- Current Glyph Index
  `GlyphIndexSelector::currentIndexChanged` -> repaint -> `updateFromCurrentSubTab` (stored in canvas) => `GlyphContinuous::paintEvent`
- Current CharMap
  repaint -> `updateFromCurrentSubTab` (stored in canvas) => `GlyphContinuous::paintEvent`
  May also be updated when setting available charmaps
- Limit Index (max index if charmap is used, otherwise glyph count)
  Triggered when current charmap or glyph count changes.
  `updateLimitIndex` -> stored in `glyphLimitIndex_` => `updateFromCurrentSubTab` (stored in canvas) => `GlyphContinuous::paintEvent`

Info:

- Available CharMaps
  (see above "Common Info", already stored in engine) -> `reloadFont` -> `updateCurrentSubTab` -> `ContinousAllGlyphsTab::setCharMaps`
- Current Glyph Count
  (see above "Common Info", already stored in engine) -> `reloadFont` -> `updateCurrentSubTab` -> `ContinousAllGlyphsTab::setGlyphCount` (stored in `currentGlyphCount_`)
- Displaying Count
  repaint -> `GlyphContinuous::paintEvent` -> `GlyphContinuous::displayingCountUpdated` -> `ContinousAllGlyphsTab::setDisplayingCount` -> `GlyphIndexSelector::setShowingCount`