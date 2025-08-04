import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.System;

(:glance)
class waktuSolatGlanceView extends WatchUi.GlanceView {
    private var _currentPrayer as String = "";
    private var _nextPrayer as String = "";
    private var _minutesUntilNext as Number = 0;
    private var _progressPercent as Float = 0.0;


    function initialize() {
        GlanceView.initialize();
        System.println("*** GLANCE VIEW INITIALIZED ***");
        
        // Glance view uses cached data only due to ConnectIQ API restrictions
        // The main app handles API fetching when user opens it
        // This ensures battery efficiency and respects platform limitations
        
        // Ensure we have basic fallback data if nothing is cached
        try {
            var existingData = Storage.getValue("prayer_times");
            if (existingData == null) {
                // Set basic mock data if no data exists
                var mockData = {
                    "Subuh" => "05:58",
                    "Syuruk" => "07:11",
                    "Isyraq" => "07:23",
                    "Dhuha" => "07:26",
                    "Zohor" => "13:20",
                    "Asar" => "16:44",
                    "Maghrib" => "19:26",
                    "Isyak" => "20:40"
                };
                Storage.setValue("prayer_times", mockData);
                Storage.setValue("location", "Jasin, Malaysia");
            }
        } catch (e) {
            System.println("Glance initialization error: " + e.getErrorMessage());
        }
        
        updateGlanceData();
    }

    function onUpdate(dc as Dc) as Void {
        System.println("*** GLANCE VIEW onUpdate CALLED ***");
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        
        var width = dc.getWidth();
        var height = dc.getHeight();
        
        // Draw border lines for area visualization (Epix 2 analysis)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        // dc.drawRectangle(0, 0, width, height); // Outer border
        

        
        // Font sizing optimized for Epix 2, Venu 2S, and FR255
        var glanceFont = Graphics.FONT_XTINY;
        
        // Font-height-aware middle-referenced positioning
        // This uses the middle point as reference with font-aware spacing
        var middleY = (height / 2).toNumber(); // Middle point of glance area
        var fontHeight = dc.getFontHeight(glanceFont); // Get actual font height
        var margin = (height * 0.1).toNumber(); // 10% margin for consistent spacing
        
        var topRowY = middleY - margin - fontHeight; // Above middle with font clearance
        var calculatedBarHeight = (height * 0.058).toNumber(); // Bar height ratio: ~0.058 (6/103)
        var barHeight = calculatedBarHeight > 4 ? calculatedBarHeight : 4; // Minimum 4px height
        
        // Ensure bar height is always odd for perfect centering
        if (barHeight % 2 == 0) {
            barHeight = barHeight + 1;
        }
        
        var barY = middleY - (barHeight - 1) / 2; // Center bar around middle point
        var bottomRowY = middleY + margin; // Below middle with margin
        
        // Left margin and bar width ratios
        var barX = (width * 0.036).toNumber(); // Left margin ratio: 0.036
        var barWidth = (width * 0.927).toNumber(); // Bar width ratio: 0.927
        
        // First row: Current Prayer - left aligned
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(barX, topRowY, glanceFont, "Current Time - " + _currentPrayer, Graphics.TEXT_JUSTIFY_LEFT);
        
        // Progress bar between rows - using ratio-based positioning
        
        // Detect device type based on dimensions
        var deviceName = "Unknown";
        if (width == 274 && height == 103) {
            deviceName = "Epix 2";
        } else if (width == 176 && height == 93) {
            deviceName = "FR255";
        } else if (width == 249 && height == 115) {
            deviceName = "Venu 2S";
        } else if (width == 226 && height == 101) {
            deviceName = "Edge 1040";
        } else if (width == 218 && height == 103) {
            deviceName = "Fenix 6S";
        } else if (width == 260 && height == 103) {
            deviceName = "Fenix 6/6 Pro";
        } else {
            deviceName = "Generic (" + width + "x" + height + ")";
        }
        
        // Log detailed area dimensions and positioning for debugging
        System.println("=== GLANCE AREA ANALYSIS (" + deviceName + ") ===");
        System.println("Detected area dimensions: " + width + "x" + height);
        System.println("Font-height-aware middle-referenced positioning:");
        System.println("- Middle Y: " + middleY + " (height/2)");
        System.println("- Font height: " + fontHeight + " pixels");
        System.println("- Margin: " + margin + " pixels (10% of height)");
        System.println("Calculated positions (pixels):");
        System.println("- Top row Y: " + topRowY + " (middle - margin - fontHeight = " + middleY + " - " + margin + " - " + fontHeight + ")");
        System.println("- Bar Y: " + barY + " (middle point)");
        System.println("- Bottom row Y: " + bottomRowY + " (middle + margin = " + middleY + " + " + margin + ")");
        System.println("- Left margin (barX): " + barX + " (ratio: " + (barX.toFloat() / width.toFloat()).format("%.3f") + ")");
        System.println("- Bar width: " + barWidth + " (ratio: " + (barWidth.toFloat() / width.toFloat()).format("%.3f") + ")");
        System.println("- Bar height: " + barHeight + " pixels (ratio: " + (barHeight.toFloat() / height.toFloat()).format("%.3f") + ")");
        System.println("=== END ANALYSIS ===");
        
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, barWidth, barHeight);
        
        // Progress bar fill with color coding
        var fillWidth = (barWidth * _progressPercent).toNumber();
        
        // Determine progress bar color based on time remaining
        var progressColor = Graphics.COLOR_GREEN; // Default: plenty of time
        
        if (_minutesUntilNext < 10) {
            // Red: Less than 10 minutes remaining
            progressColor = Graphics.COLOR_RED;
        } else if (_progressPercent > 0.8) {
            // Yellow: Less than 20% time remaining (more than 80% progress)
            progressColor = Graphics.COLOR_YELLOW;
        }
        
        dc.setColor(progressColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, fillWidth, barHeight);
        
        // Second row: Next Prayer info - left aligned with formatted time
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var formattedTime = formatTimeDurationShort(_minutesUntilNext);
        dc.drawText(10, bottomRowY, glanceFont, _nextPrayer + " in " + formattedTime, Graphics.TEXT_JUSTIFY_LEFT);
    }
    
    // Local utility function for glance view
    private function convertTimeStringToMinutes(timeString as String) as Number {
        var colonIndex = timeString.find(":");
        if (colonIndex == null) {
            return 0; // Invalid format, return 0
        }
        
        var hourStr = timeString.substring(0, colonIndex);
        var minStr = timeString.substring(colonIndex + 1, timeString.length());
        
        var hour = hourStr.toNumber();
        var min = minStr.toNumber();
        
        return hour * 60 + min;
    }
    
    // Local utility function for formatting time duration (short version)
    private function formatTimeDurationShort(totalMinutes as Number) as String {
        if (totalMinutes < 60) {
            // Less than 1 hour - show only minutes
            if (totalMinutes == 1) {
                return "1 min";
            } else {
                return totalMinutes.toString() + " mins";
            }
        } else {
            // 1 hour or more - show hours and minutes
            var hours = totalMinutes / 60;
            var minutes = totalMinutes % 60;
            
            var result = "";
            
            // Add hours part
            if (hours == 1) {
                result = "1 hr";
            } else {
                result = hours.toString() + " hrs";
            }
            
            // Add minutes part if there are any
            if (minutes > 0) {
                if (minutes == 1) {
                    result = result + " 1 min";
                } else {
                    result = result + " " + minutes.toString() + " mins";
                }
            }
            
            return result;
        }
    }
    
    private function updateGlanceData() as Void {
        var now = Time.now();
        var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
        
        var currentHour = info.hour;
        var currentMin = info.min;
        var currentTimeInMin = currentHour * 60 + currentMin;
        
        // Get adaptive prayer names based on screen size (need a dummy DC for device detection)
        // For glance view, we'll use the full list and let the main view handle the adaptive display
        // This ensures glance view always works with the complete prayer data
        var prayers = ["Subuh", "Syuruk", "Isyraq", "Dhuha", "Zohor", "Asar", "Maghrib", "Isyak"];
        
        // Try to get cached prayer times from storage, fallback to mock data if needed
        var prayerTimes;
        try {
            // Attempt direct storage access (safer than PrayerDataManager in glance context)
            var storedTimes = Storage.getValue("prayer_times");
            if (storedTimes != null && storedTimes instanceof Dictionary && storedTimes.size() >= 8) {
                prayerTimes = storedTimes as Dictionary<String, String>;
            } else {
                throw new Lang.Exception();
            }
        } catch (e) {
            // Fallback to mock data if storage access fails
            prayerTimes = {
                "Subuh" => "05:58",
                "Syuruk" => "07:11",
                "Isyraq" => "07:23",
                "Dhuha" => "07:26",
                "Zohor" => "13:20",
                "Asar" => "16:44",
                "Maghrib" => "19:26",
                "Isyak" => "20:40"
            };
        }
        
        // Convert prayer time strings to minutes dynamically
        var prayerTimesInMin = new [prayers.size()];
        for (var i = 0; i < prayers.size(); i++) {
            var prayerName = prayers[i];
            if (prayerTimes.hasKey(prayerName)) {
                prayerTimesInMin[i] = convertTimeStringToMinutes(prayerTimes[prayerName]);
            } else {
                // Fallback time if prayer not found
                prayerTimesInMin[i] = 360; // 6:00 AM as fallback
            }
        }
        
        // Find current prayer period and next prayer
        _currentPrayer = "After Isyak";
        _nextPrayer = "Subuh"; // Default to next day Subuh
        var nextTimeInMin = prayerTimesInMin[0] + 1440; // Next day Subuh
        var currentPeriodStart = prayerTimesInMin[prayerTimesInMin.size()-1]; // After Isyak
        
        for (var i = 0; i < prayerTimesInMin.size(); i++) {
            if (currentTimeInMin < prayerTimesInMin[i]) {
                nextTimeInMin = prayerTimesInMin[i];
                _nextPrayer = prayers[i]; // Set the next prayer name
                
                // Determine current prayer period
                if (i == 0) {
                    _currentPrayer = "Before Subuh";
                    currentPeriodStart = 0;
                } else {
                    _currentPrayer = prayers[i-1];
                    currentPeriodStart = prayerTimesInMin[i-1];
                }
                break;
            }
        }
        
        // Calculate minutes until next prayer
        _minutesUntilNext = nextTimeInMin - currentTimeInMin;
        if (_minutesUntilNext < 0) {
            _minutesUntilNext = _minutesUntilNext + 1440; // Add 24 hours
        }
        
        // Calculate progress percentage
        var periodDuration = nextTimeInMin - currentPeriodStart;
        if (periodDuration <= 0) {
            periodDuration = 1440 - currentPeriodStart + nextTimeInMin; // Handle overnight period
        }
        var timeElapsed = currentTimeInMin - currentPeriodStart;
        if (timeElapsed < 0) {
            timeElapsed = timeElapsed + 1440; // Handle overnight
        }
        
        _progressPercent = timeElapsed.toFloat() / periodDuration.toFloat();
        if (_progressPercent > 1.0) {
            _progressPercent = 1.0;
        } else if (_progressPercent < 0.0) {
            _progressPercent = 0.0;
        }
    }
}
