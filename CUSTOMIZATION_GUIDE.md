# Waktu Solat Malaysia Lite - Customization Guide

> **Complete customization reference for fonts, positions, colors, and layout for the lightweight prayer times app**

**Version 2.0.3** - Now with multi-device support and device-specific font sizing!

This guide shows you exactly where to modify the code to customize your Waktu Solat app. All line numbers are approximate and may shift as you make changes.

**Note**: With the new architecture using PrayerDataManager, most data customizations should be done in the PrayerDataManager.mc file rather than individual view files.

---

## Font Sizing and Device-Specific Adjustments

**Updated in v2.0.3**: Perfect font sizing and device-specific optimizations.

### Supported Devices
- **Epix 2 (416x416)**: Primary optimized layout with `Graphics.FONT_XTINY`
- **Forerunner 255 (260x260)**: Device-specific adjustments with `Graphics.FONT_XTINY`
- **Venu 2S (360x360)**: Fully optimized with `Graphics.FONT_XTINY`

### Main App Font Customization
**File**: `/source/waktuSolatHomeAssistantView.mc`
**Lines**: ~220-225

```monkey-c
// Font sizing optimized for Epix 2 and Venu 2S
var prayerFont = Graphics.FONT_XTINY;  // ← CHANGE THIS
var timeFont = Graphics.FONT_XTINY;    // ← CHANGE THIS
```

### Glance View Font Customization
**File**: `/source/waktuSolatGlanceView.mc`
**Lines**: ~30-32

```monkey-c
// Font sizing optimized for Epix 2 and Venu 2S
var glanceFont = Graphics.FONT_XTINY;  // ← CHANGE THIS
```

### Available Font Sizes (from largest to smallest)
1. `Graphics.FONT_SYSTEM_LARGE`
2. `Graphics.FONT_SYSTEM_MEDIUM`
3. `Graphics.FONT_SYSTEM_SMALL`
4. `Graphics.FONT_XTINY` ← Current setting for both devices
5. `Graphics.FONT_SYSTEM_XTINY`
6. `Graphics.FONT_SYSTEM_TINY`
7. `Graphics.FONT_SYSTEM_NUMBER_MILD`
8. `Graphics.FONT_SYSTEM_NUMBER_HOT`
9. `Graphics.FONT_NUMBER_MILD`
10. `Graphics.FONT_NUMBER_HOT`

**Note**: `Graphics.FONT_XTINY` provides perfect readability on all supported devices.

### FR255-Specific Device Adjustments

**Glance View Adjustments** (`waktuSolatGlanceView.mc` ~lines 30-36):
```monkey-c
// FR255-specific adjustments - glance view dimensions (176x93)
if (width == 176 && height == 93) {
    // FR255 Glance View - Move top row closer to top edge
    startY = (height - 80) / 2 - 15; // Move up significantly
    barHeight = 3; // Much thinner progress bar for small glance
}
```

**Main App Logo Adjustment** (`waktuSolatHomeAssistantView.mc` ~lines 96-103):
```monkey-c
// FR255-specific smaller logo - main app dimensions (260x260)
if (height == 260 && width == 260) {
    // FR255 Main App - Use smaller logo
    logo = WatchUi.loadResource(Rez.Drawables.AppLogoXSmall) as WatchUi.BitmapResource;
} else {
    // Default logo for Epix 2 and Venu 2S
    logo = WatchUi.loadResource(Rez.Drawables.AppLogo) as WatchUi.BitmapResource;
}
```

**What FR255 adjustments do:**
- **Glance View (176x93)**: Moves top row 15px higher, uses 3px thick progress bar (vs 7px default)
- **Main App (260x260)**: Uses smaller `AppLogoXSmall` resource to prevent logo overlap
- **Font Size**: Same `Graphics.FONT_XTINY` as other devices for consistency

---

## Data Source Customization
**File**: `/source/PrayerDataManager.mc`

### Default Mock Prayer Times (Lines 20-32)

```monkey-c
var mockPrayerTimes = {
    "Subuh" => "05:58",   // Fajr - Dawn prayer
    "Syuruk" => "07:11",  // Sunrise
    "Isyraq" => "07:23",  // Syuruk + 12 minutes
    "Dhuha" => "07:26",   // Syuruk + 15 minutes
    "Zohor" => "13:20",   // Dhuhr - Midday prayer
    "Asar" => "16:44",    // Asr - Afternoon prayer
    "Maghrib" => "19:26",  // Maghrib - Sunset prayer
    "Isyak" => "20:40"    // Isha - Night prayer
};
```

**What you can change:**
- All prayer times to match your local times
- Times are in 24-hour format (HH:MM)
- Isyraq and Dhuha are calculated from Syuruk automatically

### Default Location (Line 35)

```monkey-c
Storage.setValue(LOCATION_KEY, "Jasin"); // Real location from API
```

**What you can change:**
- Replace "Jasin" with your city name
- This is the fallback location when no API data is available

---

## Main View Customization
**File**: `/source/waktuSolatHomeAssistantView.mc`

### Logo Section (Lines 53-58)

```monkey-c
// Logo above title
var logo = WatchUi.loadResource(Rez.Drawables.AppLogo) as WatchUi.BitmapResource;
if (logo != null) {
    var logoWidth = logo.getWidth();
    dc.drawBitmap((width - logoWidth) / 2, 15 - _scrollOffset, logo);
}
```

**What you can change:**
- `15` = Logo Y position (higher number = lower on screen)
- `(width - logoWidth) / 2` = Horizontal centering formula
- Replace `Rez.Drawables.AppLogo` with different drawable resource

### Visual Status Indicator (Lines 59-75)

```monkey-c
// Data source status indicator circle above location
var dataSourceType = PrayerDataManager.getDataSourceType();
var indicatorColor = Graphics.COLOR_LT_GRAY; // Default gray for mock

if (dataSourceType.equals("api")) {
    indicatorColor = Graphics.COLOR_GREEN; // Green for API data
} else if (dataSourceType.equals("manual")) {
    indicatorColor = Graphics.COLOR_BLUE; // Blue for manual coordinates
}

// Draw small status circle above location (6px radius)
dc.setColor(indicatorColor, Graphics.COLOR_TRANSPARENT);
dc.fillCircle(width / 2, 325, 6);
```

**What you can change:**
- `Graphics.COLOR_GREEN` = API data indicator color
- `Graphics.COLOR_BLUE` = Manual coordinates indicator color
- `Graphics.COLOR_LT_GRAY` = Mock data indicator color
- `6` = Circle radius (size of indicator)
- `325` = Y position of status circle

### Header Section (Lines 55-58)

```monkey-c
// Next prayer countdown
var nextPrayerTime = getRemainingTimeToNextPrayer();
dc.drawText(width / 2, 120, Graphics.FONT_XTINY, "Next in " + nextPrayerTime, Graphics.TEXT_JUSTIFY_CENTER);

// Location display below status indicator
dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
dc.drawText(width / 2, 335, Graphics.FONT_XTINY, PrayerDataManager.getLocation(), Graphics.TEXT_JUSTIFY_CENTER);
```

**What you can change:**
- `120` = Next prayer countdown Y position
- `335` = Location text Y position
- `Graphics.FONT_XTINY` = Font sizes
- `"Next in "` = Text prefix for remaining time
- `Graphics.COLOR_GREEN` = Location text color

### Prayer List Layout (Lines 72-78)

```monkey-c
// Calculate centered content area with wider margins
var contentWidth = width - 80; // Leave 40px margin on each side
var contentStartX = 40; // Start 40px from left edge

// Prayer times list - centered overall layout with left-aligned text
var startY = 140; // Starting position for prayer list
var lineHeight = 30; // Space between each prayer line
```

**What you can change:**
- `80` = Total horizontal margin (smaller number = wider content)
- `40` = Left margin (adjust left/right position of content)
- `140` = Starting Y position for prayer list (higher = lower on screen)
- `30` = Space between each prayer line (bigger = more spacing)

### Prayer Text Positioning (Lines 95-100)

```monkey-c
// Prayer name - left aligned within centered content area
dc.drawText(contentStartX + 5, currentY + 5, Graphics.FONT_XTINY, prayer, Graphics.TEXT_JUSTIFY_LEFT);

// Prayer time - right aligned within centered content area  
dc.drawText(contentStartX + contentWidth - 5, currentY + 5, Graphics.FONT_XTINY, time, Graphics.TEXT_JUSTIFY_RIGHT);
```

**What you can change:**
- `+ 5` = Left padding for prayer names
- `- 5` = Right padding for prayer times
- `+ 5` = Vertical text position within each line
- `Graphics.FONT_XTINY` = Font size for prayers

### Color Settings (Lines 77-92)

```monkey-c
// Determine prayer colors: Green for current period, Yellow for next prayer
var prayerColor = Graphics.COLOR_LT_GRAY; // Default color
var timeColor = Graphics.COLOR_WHITE; // Default time color

if (prayer.equals(_nextPrayer)) {
    prayerColor = Graphics.COLOR_YELLOW; // Next prayer in yellow
    timeColor = Graphics.COLOR_YELLOW;
}

// Check if this is the current prayer period (previous prayer to next)
for (var j = 0; j < prayers.size(); j++) {
    if (prayers[j].equals(_nextPrayer) && j > 0 && prayers[j-1].equals(prayer)) {
        prayerColor = Graphics.COLOR_GREEN; // Current period in green
        timeColor = Graphics.COLOR_GREEN;
        break;
    }
}
```

**Color Logic:**
- **Green** = Current prayer period (the prayer time we're currently in)
- **Yellow** = Next upcoming prayer
- **Light Gray** = Other prayers

## Glance View Customization
**File**: `/source/waktuSolatGlanceView.mc`

### Glance Text Positioning (Lines 29, 48)

```monkey-c
// First row: Current Prayer - left aligned
dc.drawText(10, startY, Graphics.FONT_XTINY, "Current Prayer - " + _currentPrayer, Graphics.TEXT_JUSTIFY_LEFT);

// Second row: Next Prayer info - left aligned with formatted time
dc.drawText(10, barY + 10, Graphics.FONT_XTINY, "Next Prayer in " + formattedTime, Graphics.TEXT_JUSTIFY_LEFT);
```

**What you can change:**
- `10` = Left margin for text
- `startY` and `barY + 10` = Vertical positions
- `Graphics.FONT_XTINY` = Font size

### Progress Bar (Lines 32-43)

```monkey-c
// Progress bar between rows - with proper spacing
var barY = startY + 40; // Give more space after first row
var barWidth = width - 20;
var barHeight = 5;
var barX = 10;
```

**What you can change:**
- `40` = Space between first row and progress bar
- `20` = Progress bar margin (smaller = wider bar)
- `5` = Progress bar thickness
- `10` = Progress bar left position

## Available Font Sizes

```monkey-c
Graphics.FONT_XTINY    // Smallest - current prayer list size
Graphics.FONT_TINY     // Slightly bigger
Graphics.FONT_SMALL    // Medium size - current top section size
Graphics.FONT_MEDIUM   // Larger
Graphics.FONT_LARGE    // Largest
```

## Available Colors

```monkey-c
Graphics.COLOR_WHITE      // White
Graphics.COLOR_LT_GRAY    // Light Gray - default prayer text
Graphics.COLOR_DK_GRAY    // Dark Gray
Graphics.COLOR_GREEN      // Green - current prayer period
Graphics.COLOR_YELLOW     // Yellow - next prayer
Graphics.COLOR_RED        // Red
Graphics.COLOR_BLUE       // Blue
Graphics.COLOR_BLACK      // Black
Graphics.COLOR_TRANSPARENT // Transparent background
```

## 📐 Quick Layout Adjustments

### Make Content Wider
```monkey-c
var contentWidth = width - 10; // Change from 20 to 10
var contentStartX = 5;         // Change from 10 to 5
```

### Increase Prayer List Spacing
```monkey-c
var lineHeight = 35;           // Change from 30 to 35
```

### Move Prayer List Higher
```monkey-c
var startY = 45;              // Change from 55 to 45
```

### Make Prayer Text Bigger
```monkey-c
dc.drawText(..., Graphics.FONT_TINY, ...); // Change from FONT_XTINY to FONT_TINY
```

### Adjust Text Padding
```monkey-c
dc.drawText(contentStartX + 8, currentY + 8, ...); // Change from +5 to +8
```

## Common Customizations

### Scenario 1: "Text is too small"
- Change `Graphics.FONT_XTINY` to `Graphics.FONT_TINY` or `Graphics.FONT_SMALL` on lines 95-100

### Scenario 2: "Need more space between prayers"
- Increase `lineHeight` from `30` to `35` or `40` on line 64

### Scenario 3: "Content too narrow"
- Decrease `contentWidth = width - 20` to `width - 10` on line 59
- Decrease `contentStartX = 10` to `5` on line 60

### Scenario 4: "Prayer list too low"
- Decrease `startY = 55` to `45` or `50` on line 63

### Scenario 5: "Want different colors"
- Change color values in lines 77-92 using available colors above

## 💡 Tips

1. **Test incrementally**: Make one change at a time and test
2. **Build after changes**: Run `monkeyc -f monkey.jungle -d epix2 -o bin/test_epix2_waktuSolatHomeAssistant.prg -y developer_key`
3. **Backup first**: Keep a copy of working code before major changes
4. **Font hierarchy**: XTINY < TINY < SMALL < MEDIUM < LARGE
5. **Positioning**: Higher Y values = lower on screen, Higher X values = more to the right

## Device Considerations

- **epix2 screen**: 454x454 pixels
- **Safe margins**: Keep content at least 10px from edges
- **Readability**: FONT_XTINY is very small, consider FONT_TINY for better readability
- **Color contrast**: Ensure good contrast between text and background colors

---

*This guide covers the main customization points. For advanced modifications, refer to the Garmin ConnectIQ documentation.*
