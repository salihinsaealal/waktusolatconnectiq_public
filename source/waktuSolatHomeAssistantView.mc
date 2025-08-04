import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.System;
import Toybox.Lang;
import Toybox.Math;

class waktuSolatHomeAssistantView extends WatchUi.View {
    private var _currentTime as String = "";
    private var _nextPrayer as String = "";
    private var _scrollOffset as Number;
    private var _maxScroll as Number;
    
    // Responsive layout functions
    private function getDeviceInfo(dc as Dc) as Dictionary {
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Epix 2 as baseline (416x416)
        var scaleFactor = height / 416.0;
        var isSmallScreen = (height <= 240); // FR245 and similar
        
        return {
            "width" => width,
            "height" => height,
            "scaleFactor" => scaleFactor,
            "isSmallScreen" => isSmallScreen
        };
    }
    
    private function getScaledPositions(deviceInfo as Dictionary) as Dictionary {
        var height = deviceInfo["height"] as Number;
        var width = deviceInfo["width"] as Number;
        var scaleFactor = deviceInfo["scaleFactor"] as Float;
        
        return {
            "logoY" => (20.0 / 416.0 * height).toNumber(),
            "titleY" => (80.0 / 416.0 * height).toNumber(),
            "nextInfoY" => (120.0 / 416.0 * height).toNumber(),
            "listStartY" => (115.0 / 416.0 * height).toNumber(),
            "lineHeight" => (25.0 * scaleFactor).toNumber(),
            "locationY" => (340.0 / 416.0 * height).toNumber(),
            "loadingY" => (360.0 / 416.0 * height).toNumber(),
            "contentStartX" => (45.0 * scaleFactor).toNumber(),
            "contentWidth" => width - (75.0 * scaleFactor).toNumber(),
            "indicatorCenterX" => width / 2,
            "indicatorY" => (330.0 / 416.0 * height).toNumber()
        };
    }
    
    private function getAdaptivePrayerList(isSmallScreen as Boolean) as Array<String> {
        if (isSmallScreen) {
            // FR245: Remove Syuruk, Isyraq, Dhuha for readability
            return ["Subuh", "Zohor", "Asar", "Maghrib", "Isyak"] as Array<String>;
        } else {
            // All other devices: Full list
            return ["Subuh", "Syuruk", "Isyraq", "Dhuha", "Zohor", "Asar", "Maghrib", "Isyak"] as Array<String>;
        }
    }

    function initialize() {
        View.initialize();
        _scrollOffset = 0;
        _maxScroll = 0;
        
        // Initialize shared data manager and fetch API data if needed
        PrayerDataManager.initialize();
        if (PrayerDataManager.shouldFetchFromAPI()) {
            PrayerDataManager.fetchPrayerTimesFromAPI();
        }
        
        updateCurrentTimeAndNext();
    }

    function onLayout(dc as Dc) as Void {
        // Don't use XML layout, we'll draw everything custom
    }

    function onShow() as Void {
        updateCurrentTimeAndNext();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        // Get device info and scaled positions
        var deviceInfo = getDeviceInfo(dc);
        var positions = getScaledPositions(deviceInfo);
        var width = deviceInfo["width"] as Number;
        var height = deviceInfo["height"] as Number;
        
        // Logo above title - device-specific sizing
        var logo;
        
        // FR255-specific smaller logo - main app dimensions (260x260)
        if (height == 260 && width == 260) {
            // FR255 Main App - Use smaller logo
            logo = WatchUi.loadResource(Rez.Drawables.AppLogoXSmall) as WatchUi.BitmapResource;
        } else {
            // Default logo for Epix 2 and Venu 2S
            logo = WatchUi.loadResource(Rez.Drawables.AppLogo) as WatchUi.BitmapResource;
        }
        
        if (logo != null) {
            var isSmallScreen = deviceInfo["isSmallScreen"] as Boolean;
            
            if (!isSmallScreen) {
                // Show logo on supported devices (Epix 2, Venu 2S, FR255)
                var logoWidth = logo.getWidth();
                var logoY = positions["logoY"] as Number;
                dc.drawBitmap((width - logoWidth) / 2, logoY - _scrollOffset, logo);
            }
            // For very small screens, skip the logo to save space and prevent overlap
        }
        
        // Title - more compact
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        var titleY = positions["titleY"] as Number;
        dc.drawText(width/2, titleY - _scrollOffset, Graphics.FONT_TINY, "Waktu Solat", Graphics.TEXT_JUSTIFY_CENTER);
        
        // Next prayer time display in 12-hour format - centered
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var nextPrayerTime = getRemainingTimeToNextPrayer();
        var nextInfoY = positions["nextInfoY"] as Number;
        dc.drawText(width / 2, nextInfoY, Graphics.FONT_XTINY, "Next in " + nextPrayerTime, Graphics.TEXT_JUSTIFY_CENTER);
        
        // Data source status indicator circle above location
        var dataSourceType = PrayerDataManager.getDataSourceType();
        var indicatorColor = Graphics.COLOR_LT_GRAY; // Default gray for mock
        var isLoadingState = false; // Track if we're in loading state
        
        if (dataSourceType.equals("loading")) {
            indicatorColor = Graphics.COLOR_RED; // Red for loading state
            isLoadingState = true;
        } else if (dataSourceType.equals("api")) {
            indicatorColor = Graphics.COLOR_GREEN; // Green for fresh API data
        } else if (dataSourceType.equals("cached")) {
            indicatorColor = Graphics.COLOR_YELLOW; // Yellow for cached API data
        } else if (dataSourceType.equals("manual")) {
            indicatorColor = Graphics.COLOR_BLUE; // Blue for manual coordinates
        }
        
        // Draw small status circle above location (6px radius) - centered
        dc.setColor(indicatorColor, Graphics.COLOR_TRANSPARENT);
        var indicatorCenterX = positions["indicatorCenterX"] as Number;
        var indicatorY = positions["indicatorY"] as Number;
        dc.fillCircle(indicatorCenterX, indicatorY, 6);
        
        // Location display below status indicator - in green color
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        var locationY = positions["locationY"] as Number;
        dc.drawText(width / 2, locationY, Graphics.FONT_XTINY, PrayerDataManager.getLocation(), Graphics.TEXT_JUSTIFY_CENTER);
        
        // Show "Loading..." below location if in loading state (smaller font)
        if (isLoadingState) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var loadingY = positions["loadingY"] as Number;
            dc.drawText(width / 2, loadingY, Graphics.FONT_XTINY, "Loading...", Graphics.TEXT_JUSTIFY_CENTER);
        }
        
        // Calculate centered content area with responsive margins
        var contentWidth = positions["contentWidth"] as Number;
        var contentStartX = positions["contentStartX"] as Number;
        
        // Prayer times list - responsive layout with adaptive content
        var startY = positions["listStartY"] as Number;
        var lineHeight = positions["lineHeight"] as Number;
        var isSmallScreen = deviceInfo["isSmallScreen"] as Boolean;
        var prayers = getAdaptivePrayerList(isSmallScreen);
        var prayerTimes = PrayerDataManager.getPrayerTimes();
        
        for (var i = 0; i < prayers.size(); i++) {
            var prayer = prayers[i];
            var time = prayerTimes[prayer];
            var currentY = startY + (i * lineHeight) - _scrollOffset;
            
            // Skip if not visible
            if (currentY < -lineHeight || currentY > height + lineHeight) {
                continue;
            }
            
            // Determine prayer colors: Green for current period, Yellow for next prayer
            var prayerColor = Graphics.COLOR_LT_GRAY; // Default color
            var timeColor = Graphics.COLOR_WHITE; // Default time color
            
            // Check if loading - make prayer times gray during loading
            var isLoading = PrayerDataManager.isLoading();
            if (isLoading) {
                // COMMENTED OUT: Keep prayer times in normal colors during loading
                // prayerColor = Graphics.COLOR_LT_GRAY; // Gray prayer names during loading
                // timeColor = Graphics.COLOR_LT_GRAY; // Gray prayer times during loading
            }
            
            // Apply color coding (works both during loading and normal state)
            if (prayer.equals(_nextPrayer)) {
                prayerColor = Graphics.COLOR_YELLOW; // Next prayer in yellow
                timeColor = Graphics.COLOR_YELLOW;
            }
            
            // Check if this is the current prayer period
            var currentPrayerIndex = -1;
            var nextPrayerIndex = -1;
            
            // Find indices of current prayer and next prayer
            for (var j = 0; j < prayers.size(); j++) {
                if (prayers[j].equals(prayer)) {
                    currentPrayerIndex = j;
                }
                if (prayers[j].equals(_nextPrayer)) {
                    nextPrayerIndex = j;
                }
            }
            
            // Determine if this is the current prayer period
            var isCurrentPrayer = false;
            if (nextPrayerIndex == 0) {
                // Next prayer is Subuh (first prayer), so current period is Isyak (last prayer)
                isCurrentPrayer = (currentPrayerIndex == prayers.size() - 1);
            } else {
                // Normal case: current prayer is the one before next prayer
                isCurrentPrayer = (currentPrayerIndex == nextPrayerIndex - 1);
            }
            
            // Apply current prayer color regardless of loading state
            if (isCurrentPrayer) {
                prayerColor = Graphics.COLOR_GREEN; // Current period in green
                timeColor = Graphics.COLOR_GREEN;
            }
            
            // Font sizing optimized for Epix 2 and Venu 2S
            var prayerFont = Graphics.FONT_XTINY;
            var timeFont = Graphics.FONT_XTINY;
            
            // Prayer name - left aligned within centered content area
            dc.setColor(prayerColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(contentStartX + 5, currentY + 5, prayerFont, prayer, Graphics.TEXT_JUSTIFY_LEFT);
            
            // Prayer time - right aligned within centered content area (12-hour format)
            dc.setColor(timeColor, Graphics.COLOR_TRANSPARENT);
            var time12Hour = PrayerDataManager.convertTo12HourFormat(time);
            dc.drawText(contentStartX + contentWidth - 5, currentY + 5, timeFont, time12Hour, Graphics.TEXT_JUSTIFY_RIGHT);
        }
        
        // Calculate max scroll
        _maxScroll = (prayers.size() * lineHeight + 60) - height;
        if (_maxScroll < 0) {
            _maxScroll = 0;
        }
    }

    function onHide() as Void {
    }
    
    private function updateCurrentTimeAndNext() as Void {
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        _currentTime = Lang.format("$1$:$2$", [info.hour.format("%02d"), info.min.format("%02d")]);
        
        var currentHour = info.hour;
        var currentMin = info.min;
        var currentTimeInMin = currentHour * 60 + currentMin;
        
        // Get prayer names in order
        var prayers = ["Subuh", "Syuruk", "Isyraq", "Dhuha", "Zohor", "Asar", "Maghrib", "Isyak"];
        
        // Convert prayer time strings to minutes dynamically
        var prayerTimesInMin = new [prayers.size()];
        for (var i = 0; i < prayers.size(); i++) {
            prayerTimesInMin[i] = PrayerDataManager.convertTimeStringToMinutes(PrayerDataManager.getPrayerTimes()[prayers[i]]);
        }
        
        // Find next prayer dynamically
        _nextPrayer = "Subuh"; // Default to next day Subuh
        
        for (var i = 0; i < prayerTimesInMin.size(); i++) {
            if (currentTimeInMin < prayerTimesInMin[i]) {
                _nextPrayer = prayers[i];
                break;
            }
        }
    }
    
    // Calculate remaining time until next prayer in HH:MM format
    private function getRemainingTimeToNextPrayer() as String {
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        var currentTimeInMin = info.hour * 60 + info.min;
        
        // Get prayer names in order
        var prayers = ["Subuh", "Syuruk", "Isyraq", "Dhuha", "Zohor", "Asar", "Maghrib", "Isyak"];
        
        // Convert prayer time strings to minutes dynamically
        var prayerTimesInMin = new [prayers.size()];
        for (var i = 0; i < prayers.size(); i++) {
            prayerTimesInMin[i] = PrayerDataManager.convertTimeStringToMinutes(PrayerDataManager.getPrayerTimes()[prayers[i]]);
        }
        
        // Find next prayer time
        var nextTimeInMin = prayerTimesInMin[0] + 1440; // Default to next day Subuh
        
        for (var i = 0; i < prayerTimesInMin.size(); i++) {
            if (currentTimeInMin < prayerTimesInMin[i]) {
                nextTimeInMin = prayerTimesInMin[i];
                break;
            }
        }
        
        // Calculate remaining minutes
        var remainingMin = nextTimeInMin - currentTimeInMin;
        if (remainingMin < 0) {
            remainingMin = remainingMin + 1440; // Add 24 hours
        }
        
        // Convert remaining time to HH:MM format (24-hour duration)
        var hours = remainingMin / 60;
        var minutes = remainingMin % 60;
        
        return Lang.format("$1$:$2$", [hours.format("%02d"), minutes.format("%02d")]);
    }
    
    // Handle scrolling
    function onKeyPressed(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        
        if (key == WatchUi.KEY_UP) {
            return scrollUp();
        } else if (key == WatchUi.KEY_DOWN) {
            return scrollDown();
        }
        
        return false;
    }
    
    function scrollUp() as Boolean {
        _scrollOffset = _scrollOffset - 20;
        if (_scrollOffset < 0) {
            _scrollOffset = 0;
        }
        WatchUi.requestUpdate();
        return true;
    }
    
    function scrollDown() as Boolean {
        _scrollOffset = _scrollOffset + 20;
        if (_scrollOffset > _maxScroll) {
            _scrollOffset = _maxScroll;
        }
        WatchUi.requestUpdate();
        return true;
    }
    
    // Get data for glance view
    function getGlanceData() as Dictionary {
        updateCurrentTimeAndNext();
        var nextTime = PrayerDataManager.getPrayerTimes()[_nextPrayer];
        
        return {
            "current" => _currentTime,
            "next" => _nextPrayer,
            "nextTime" => nextTime,
            "reminder" => "15 min"
        };
    }
}
