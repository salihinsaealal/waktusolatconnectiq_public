import Toybox.Application.Storage;
import Toybox.Time;
import Toybox.Timer;
import Toybox.Lang;
import Toybox.Communications;
import Toybox.Position;
import Toybox.System;
import Toybox.WatchUi;

// Proper ConnectIQ callback handler class for API responses
class PrayerAPICallback {
    function initialize() {}
    
    function invoke(responseCode as Number, data as Dictionary or Null) as Void {
        try {
            System.println("API Start");
            System.println("Response Code: " + responseCode);
            System.println("Data is null: " + (data == null));
            
            if (responseCode == 200 && data != null) {
                System.println("Success response received");
                System.println("Raw API Response: " + data.toString());
                
                // Process the actual API data
                PrayerDataManager.processAPIData(data);
                // Clear loading state on success
                PrayerDataManager.setLoadingState(false);
                // API success - indicator circle shows status, no need for toast
            } else {
                System.println("API failed with code: " + responseCode);
                // Clear loading state immediately - keep app responsive
                PrayerDataManager.setLoadingState(false);
                // Force UI update to show changes immediately
                WatchUi.requestUpdate();
                // No error shoutout - silent fallback to cached data with visual indicator
            }
            
            System.println("Data Loaded");
        } catch (ex) {
            System.println("CRITICAL ERROR in API response handler: " + ex.toString());
            WatchUi.showToast("Error", null);
        }
    }
}

// Shared data manager for prayer times using Toybox.Storage
class PrayerDataManager {
    
    // Storage keys
    private static const PRAYER_TIMES_KEY = "prayer_times";
    private static const LOCATION_KEY = "location";
    private static const LAST_FETCH_KEY = "last_fetch_time";
    private static const LOADING_STATE_KEY = "loading_state";
    
    // Loading state management
    private static var isLoadingNewLocation = false;
    
    // Loading state functions
    static function setLoadingState(loading as Boolean) as Void {
        isLoadingNewLocation = loading;
        Storage.setValue(LOADING_STATE_KEY, loading);
    }
    
    static function isLoading() as Boolean {
        return isLoadingNewLocation;
    }
    
    private static const MANUAL_LAT_KEY = "manual_latitude";
    private static const MANUAL_LON_KEY = "manual_longitude";
    private static const USE_MANUAL_KEY = "use_manual_coordinates";
    private static const RECENT_COORDS_KEY = "recent_coordinates";
    private static const MAX_RECENT_COORDS = 5;
    private static const FETCH_INTERVAL_MINUTES = 2; // Reduced from 15 to 2 minutes
    private static const LAST_COORDS_KEY = "last_fetch_coordinates"; // Track coordinates used in last fetch
    
    // Initialize - only set mock data if no data exists
    static function initialize() {
        // Only set mock data if we have never stored any prayer times before
        var existingData = Storage.getValue(PRAYER_TIMES_KEY);
        if (existingData == null) {
            setMockData();
        }
    }
    
    // Set mock data as fallback (using real API data for July 19, 2025 - Jasin)
    static function setMockData() as Void {
        var mockPrayerTimes = {
            "Subuh" => "05:58",   // Corrected based on actual data
            "Syuruk" => "07:11",  // Corrected based on actual data
            "Isyraq" => "07:23",  // Syuruk + 12 minutes
            "Dhuha" => "07:26",   // Syuruk + 15 minutes
            "Zohor" => "13:20",   // Confirmed correct
            "Asar" => "16:44",    // Confirmed correct
            "Maghrib" => "19:26",  // Confirmed correct
            "Isyak" => "20:40"    // Corrected based on actual data
        };
        
        Storage.setValue(PRAYER_TIMES_KEY, mockPrayerTimes);
        Storage.setValue(LOCATION_KEY, "Jasin"); // Real location from API
        Storage.setValue(LAST_FETCH_KEY, 0); // Never fetched from API
    }
    
    // Get current prayer times from storage (preserves real data, only uses mock as last resort)
    static function getPrayerTimes() as Dictionary<String, String> {
        var prayerTimes = Storage.getValue(PRAYER_TIMES_KEY);
        
        // If no data exists at all, use mock data as fallback
        if (prayerTimes == null) {
            setMockData();
            prayerTimes = Storage.getValue(PRAYER_TIMES_KEY);
        }
        
        return prayerTimes as Dictionary<String, String>;
    }
    
    // Get current location from storage (returns mock location only if no data ever stored)
    static function getLocation() as String {
        var location = Storage.getValue(LOCATION_KEY);
        if (location == null) {
            // Only use mock location if we've never stored any data before
            var lastFetch = Storage.getValue(LAST_FETCH_KEY);
            if (lastFetch == null) {
                setMockData();
                location = Storage.getValue(LOCATION_KEY);
            } else {
                // We have fetched before, but location is missing - return default
                return "Jasin, Malaysia";
            }
        }
        return location as String;
    }
    
    // Check if we need to fetch new data from API
    static function shouldFetchFromAPI() as Boolean {
        var lastFetch = Storage.getValue(LAST_FETCH_KEY);
        if (lastFetch == null || lastFetch == 0) {
            return true; // Never fetched before
        }
        
        // Check if coordinates have changed since last fetch
        var lastCoords = Storage.getValue(LAST_COORDS_KEY);
        var currentCoords = getCurrentCoordinates();
        
        if (lastCoords == null || coordinatesChanged(lastCoords, currentCoords)) {
            return true; // Coordinates changed - fetch immediately
        }
        
        // If coordinates unchanged, check time interval (reduced to 2 minutes)
        var now = Time.now();
        var timeDiff = now.value() - (lastFetch as Number);
        var minutesDiff = timeDiff / 60;
        
        return minutesDiff >= FETCH_INTERVAL_MINUTES;
    }
    
    // Force fetch from API (bypasses 15-min limit for mode changes and API test)
    static function forceFetchFromAPI() as Boolean {
        return true; // Always allow fetch when explicitly requested
    }
    
    // Fetch prayer times from API using GPS coordinates or manual coordinates
    static function fetchPrayerTimesFromAPI() as Void {
        // Set loading state when starting API fetch
        setLoadingState(true);
        
        var lat = null;
        var lon = null;
        
        // Check if using manual coordinates
        if (isUsingManualCoordinates()) {
            lat = getManualLatitude();
            lon = getManualLongitude();
        } else {
            // Try GPS coordinates with more permissive quality check
            if (Position has :getInfo) {
                var positionInfo = Position.getInfo();
                if (positionInfo != null && positionInfo.position != null) {
                    // Accept any GPS quality (not just QUALITY_GOOD)
                    var degrees = positionInfo.position.toDegrees();
                    if (degrees != null && degrees.size() >= 2) {
                        lat = degrees[0];
                        lon = degrees[1];
                        System.println("GPS coordinates found: " + lat + ", " + lon);
                    }
                } else {
                    System.println("GPS position info is null - permissions may not be granted");
                    // Auto-switch to manual mode when GPS fails
                    autoSwitchToManualMode();
                }
            } else {
                System.println("Position.getInfo not available");
            }
        }
        
        // If GPS failed and no manual coordinates, use default coordinates as fallback
        if (lat == null || lon == null || lat == 180.0 || lon == 180.0) {
            System.println("No coordinates available or invalid GPS, using default Jasin coordinates");
            lat = 2.317564;
            lon = 102.434082;
        } else {
            // Check if coordinates are outside Malaysia (rough boundaries)
            // Malaysia bounds: lat 0.8-7.5, lon 99.5-119.5
            if (lat < 0.8 || lat > 7.5 || lon < 99.5 || lon > 119.5) {
                System.println("Location outside Malaysia detected, using default Jasin coordinates");
                WatchUi.requestUpdate();
                lat = 2.317564;
                lon = 102.434082;
            }
        }
        
        // Make API call with available coordinates
        if (lat != null && lon != null) {
            var url = "https://mpt.i906.my/api/prayer/" + lat.format("%.6f") + "," + lon.format("%.6f");
            
            var options = {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };
            
            System.println("Making API call to: " + url);
            var callback = new PrayerAPICallback();
            Communications.makeWebRequest(url, null, options, new Lang.Method(callback, :invoke));
            
            // Force UI update to show loading state immediately
            WatchUi.requestUpdate();
        } else {
            System.println("No coordinates available for API call - check permissions or enable manual mode");
        }
    }
    

    
    // Test API processing with sample data (for simulator testing)
    static function testAPIProcessing() as Void {
        System.println("=== TESTING API DATA PROCESSING ===");
        
        // Create a sample API response similar to what the real API returns
        var sampleResponse = {
            "data" => {
                "place" => "Jasin, Melaka, Malaysia",
                "times" => [
                    // Sample Unix timestamps for today (these would be real timestamps from API)
                    [1721434800, 1721456400, 1721478000, 1721485200, 1721506800, 1721514000], // Day 1
                    [1721521200, 1721542800, 1721564400, 1721571600, 1721593200, 1721600400]  // Day 2
                ]
            }
        };
        
        // Process the sample data
        processAPIData(sampleResponse);
        System.println("=== API PROCESSING TEST COMPLETE ===");
    }
    
    // Process API data manually (for testing without web request)
    static function processAPIData(apiResponse as Dictionary) as Void {
        try {
            System.println("Processing API response: " + apiResponse.toString());
            
            // Check if response has expected structure
            if (!apiResponse.hasKey("data")) {
                System.println("Error: API response missing 'data' key");
                return;
            }
            
            var apiData = apiResponse["data"];
            if (apiData == null) {
                System.println("Error: API data is null");
                return;
            }
            
            // Safely extract location and times
            var location = "Unknown";
            var times = null;
            
            if (apiData has :hasKey && apiData.hasKey("place")) {
                location = apiData["place"];
            }
            
            if (apiData has :hasKey && apiData.hasKey("times")) {
                times = apiData["times"];
            }
            
            if (times == null || times.size() == 0) {
                System.println("Error: No times data in API response");
                return;
            }
            
            // Get current day (1-based index for day of month)
            var now = Time.now();
            var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
            var currentDay = info.day - 1; // Convert to 0-based index
            
            System.println("Current day index: " + currentDay + ", times array size: " + times.size());
            
            if (currentDay >= 0 && currentDay < times.size()) {
                var todayTimes = times[currentDay];
                
                if (todayTimes == null || todayTimes.size() < 6) {
                    System.println("Error: Today's times array invalid or too small: " + (todayTimes != null ? todayTimes.size() : "null"));
                    return;
                }
                
                // Convert Unix timestamps to HH:MM format and map to our prayer names
                // API provides: [Subuh, Syuruk, Zohor, Asar, Maghrib, Isyak]
                var prayerTimes = {
                    "Subuh" => convertUnixToTimeString(todayTimes[0]),
                    "Syuruk" => convertUnixToTimeString(todayTimes[1]),
                    "Isyraq" => calculateIsyraqTime(todayTimes[1]), // Syuruk + 12 minutes
                    "Dhuha" => calculateDhuhaTime(todayTimes[1]),   // Syuruk + 15 minutes
                    "Zohor" => convertUnixToTimeString(todayTimes[2]),
                    "Asar" => convertUnixToTimeString(todayTimes[3]),
                    "Maghrib" => convertUnixToTimeString(todayTimes[4]),
                    "Isyak" => convertUnixToTimeString(todayTimes[5])
                };
                    
                    // Update storage with API data
                    Storage.setValue(PRAYER_TIMES_KEY, prayerTimes);
                    Storage.setValue(LOCATION_KEY, location);
                    Storage.setValue(LAST_FETCH_KEY, Time.now().value());
                    
                    // Save coordinates used for this fetch to track changes
                    var currentCoords = getCurrentCoordinates();
                    Storage.setValue(LAST_COORDS_KEY, currentCoords);
                }
            } catch (e) {
                // If API parsing fails, keep existing data
                System.println("API parsing error: " + e.getErrorMessage());
            }
    }
    
    // Convert Unix timestamp to HH:MM format with error handling
    static function convertUnixToTimeString(unixTimestamp) as String {
        try {
            // Ensure we have a valid number
            var timestamp = unixTimestamp;
            if (timestamp == null) {
                System.println("Error: Unix timestamp is null");
                return "00:00";
            }
            
            // Convert to number if it's not already
            if (!(timestamp instanceof Number)) {
                if (timestamp instanceof Long) {
                    timestamp = timestamp.toNumber();
                } else {
                    System.println("Error: Invalid timestamp type: " + timestamp.toString());
                    return "00:00";
                }
            }
            
            var moment = new Time.Moment(timestamp);
            var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
            return Lang.format("$1$:$2$", [info.hour.format("%02d"), info.min.format("%02d")]);
        } catch (ex) {
            System.println("Error converting timestamp: " + ex.getErrorMessage());
            return "00:00";
        }
    }
    
    // Calculate Isyraq time (Syuruk + 12 minutes)
    static function calculateIsyraqTime(syurukUnix) as String {
        try {
            var timestamp = syurukUnix;
            if (timestamp == null) {
                return "00:00";
            }
            
            if (!(timestamp instanceof Number)) {
                if (timestamp instanceof Long) {
                    timestamp = timestamp.toNumber();
                } else {
                    return "00:00";
                }
            }
            
            var isyraqUnix = timestamp + (12 * 60); // Add 12 minutes
            return convertUnixToTimeString(isyraqUnix);
        } catch (ex) {
            System.println("Error calculating Isyraq time: " + ex.getErrorMessage());
            return "00:00";
        }
    }
    
    // Calculate Dhuha time (Syuruk + 15 minutes)
    static function calculateDhuhaTime(syurukUnix) as String {
        try {
            var timestamp = syurukUnix;
            if (timestamp == null) {
                return "00:00";
            }
            
            if (!(timestamp instanceof Number)) {
                if (timestamp instanceof Long) {
                    timestamp = timestamp.toNumber();
                } else {
                    return "00:00";
                }
            }
            
            var dhuhaUnix = timestamp + (15 * 60); // Add 15 minutes
            return convertUnixToTimeString(dhuhaUnix);
        } catch (ex) {
            System.println("Error calculating Dhuha time: " + ex.getErrorMessage());
            return "00:00";
        }
    }
    
    // Update prayer times from API response (legacy function for compatibility)
    static function updateFromAPI(prayerTimes as Dictionary<String, String>, location as String) as Void {
        Storage.setValue(PRAYER_TIMES_KEY, prayerTimes);
        Storage.setValue(LOCATION_KEY, location);
        Storage.setValue(LAST_FETCH_KEY, Time.now().value());
    }
    
    // Manual coordinates management functions
    static function setManualLatitude(latitude as Float) as Void {
        Storage.setValue(MANUAL_LAT_KEY, latitude);
    }
    
    static function setManualLongitude(longitude as Float) as Void {
        Storage.setValue(MANUAL_LON_KEY, longitude);
    }
    
    static function getManualLatitude() as Float or Null {
        return Storage.getValue(MANUAL_LAT_KEY) as Float or Null;
    }
    
    static function getManualLongitude() as Float or Null {
        return Storage.getValue(MANUAL_LON_KEY) as Float or Null;
    }
    
    static function setUseManualCoordinates(useManual as Boolean) as Void {
        Storage.setValue(USE_MANUAL_KEY, useManual);
        // Force fetch when mode changes (bypass 15-min limit)
        if (forceFetchFromAPI()) {
            fetchPrayerTimesFromAPI();
        }
    }
    
    static function isUsingManualCoordinates() as Boolean {
        var useManual = Storage.getValue(USE_MANUAL_KEY);
        return useManual != null ? useManual as Boolean : false; // Default to GPS mode
    }
    
    // Auto-switch to manual mode when GPS fails
    static function autoSwitchToManualMode() as Void {
        System.println("GPS failed, auto-switching to manual mode");
        Storage.setValue(USE_MANUAL_KEY, true);
        WatchUi.showToast("GPS→Manual", null);
    }
    
    // Save coordinates to recent list
    static function saveRecentCoordinates(lat as Float, lon as Float, name as String) as Void {
        var recentCoords = Storage.getValue(RECENT_COORDS_KEY);
        if (recentCoords == null) {
            recentCoords = [] as Array;
        } else {
            recentCoords = recentCoords as Array;
        }
        
        var newCoord = {
            "lat" => lat,
            "lon" => lon,
            "name" => name
        };
        
        // Add to beginning of list
        var newList = [newCoord];
        for (var i = 0; i < recentCoords.size() && i < MAX_RECENT_COORDS - 1; i++) {
            newList.add(recentCoords[i]);
        }
        
        Storage.setValue(RECENT_COORDS_KEY, newList);
    }
    
    // Get recent coordinates list
    static function getRecentCoordinates() as Array {
        var recentCoords = Storage.getValue(RECENT_COORDS_KEY);
        return recentCoords != null ? recentCoords as Array : [];
    }
    
    // Alias for saveRecentCoordinates for consistency
    static function addToRecentCoordinates(lat as Float, lon as Float, name as String) as Void {
        saveRecentCoordinates(lat, lon, name);
    }
    
    // Get current data source type for visual indicator
    static function getDataSourceType() as String {
        // First check if currently loading new location data
        if (isLoading()) {
            return "loading"; // Red - Loading new location data
        }
        
        // Check if using manual coordinates (highest priority)
        if (isUsingManualCoordinates()) {
            var manualLat = getManualLatitude();
            var manualLon = getManualLongitude();
            if (manualLat != null && manualLon != null) {
                return "manual"; // Blue - Manual coordinates set
            }
        }
        
        // Check API data freshness
        var lastFetch = Storage.getValue(LAST_FETCH_KEY);
        if (lastFetch != null && lastFetch > 0) {
            var timeDiff = Time.now().value() - lastFetch;
            var hoursDiff = timeDiff / (60 * 60);
            
            if (hoursDiff < 2) {
                return "api"; // Green - Fresh API data (within 2 hours)
            } else if (hoursDiff < 24) {
                return "cached"; // Yellow - Cached API data (2-24 hours old)
            }
        }
        
        return "mock"; // Gray - Using mock/fallback data
    }
    
    // Get prayer names in order
    static function getPrayerNames() as Array<String> {
        return ["Subuh", "Syuruk", "Isyraq", "Dhuha", "Zohor", "Asar", "Maghrib", "Isyak"];
    }
    
    // Generic function to convert time string (HH:MM) to minutes from midnight
    static function convertTimeStringToMinutes(timeString as String or Null) as Number {
        if (timeString == null) {
            return 0; // Handle null input
        }
        
        var colonIndex = timeString.find(":");
        if (colonIndex == null) {
            return 0; // Invalid format, return 0
        }
        
        try {
            var hourStr = timeString.substring(0, colonIndex);
            var minStr = timeString.substring(colonIndex + 1, timeString.length());
            
            var hour = hourStr.toNumber();
            var min = minStr.toNumber();
            
            return hour * 60 + min;
        } catch (e) {
            return 0; // Return 0 if conversion fails
        }
    }
    
    // Convert 24-hour time string to 12-hour format
    static function convertTo12HourFormat(timeString as String or Null) as String {
        if (timeString == null) {
            return "--:--"; // Handle null input
        }
        
        var colonIndex = timeString.find(":");
        if (colonIndex == null) {
            return timeString; // Invalid format, return as-is
        }
        
        try {
            var hourStr = timeString.substring(0, colonIndex);
            var minStr = timeString.substring(colonIndex + 1, timeString.length());
            
            var hour = hourStr.toNumber();
            var min = minStr.toNumber();
            
            var period = "AM";
            var displayHour = hour;
            
            if (hour == 0) {
                displayHour = 12;
            } else if (hour > 12) {
                displayHour = hour - 12;
                period = "PM";
            } else if (hour == 12) {
                period = "PM";
            }
            
            return Lang.format("$1$:$2$ $3$", [displayHour.format("%d"), min.format("%02d"), period]);
        } catch (e) {
            return timeString; // Return original string if conversion fails
        }
    }
    
    // Format minutes into readable time duration with proper pluralization
    static function formatTimeDuration(totalMinutes as Number) as String {
        if (totalMinutes < 60) {
            // Less than 1 hour - show only minutes
            if (totalMinutes == 1) {
                return "1 minute";
            } else {
                return totalMinutes.toString() + " minutes";
            }
        } else {
            // 1 hour or more - show hours and minutes
            var hours = totalMinutes / 60;
            var minutes = totalMinutes % 60;
            
            var result = "";
            
            // Add hours part
            if (hours == 1) {
                result = "1 hour";
            } else {
                result = hours.toString() + " hours";
            }
            
            // Add minutes part if there are any
            if (minutes > 0) {
                if (minutes == 1) {
                    result = result + " 1 minute";
                } else {
                    result = result + " " + minutes.toString() + " minutes";
                }
            }
            
            return result;
        }
    }
    
    // Format minutes into shorter readable time duration for glance view
    static function formatTimeDurationShort(totalMinutes as Number) as String {
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
    
    // Get current coordinates (GPS or manual) for comparison
    static function getCurrentCoordinates() as Dictionary {
        var coords = {};
        
        if (isUsingManualCoordinates()) {
            coords["lat"] = getManualLatitude();
            coords["lon"] = getManualLongitude();
            coords["type"] = "manual";
        } else {
            // Try to get GPS coordinates
            if (Position has :getInfo) {
                var positionInfo = Position.getInfo();
                if (positionInfo != null && positionInfo.position != null) {
                    var degrees = positionInfo.position.toDegrees();
                    coords["lat"] = degrees[0];
                    coords["lon"] = degrees[1];
                    coords["type"] = "gps";
                } else {
                    // GPS not available, use default coordinates
                    coords["lat"] = 2.317564;
                    coords["lon"] = 102.434082;
                    coords["type"] = "default";
                }
            } else {
                coords["lat"] = 2.317564;
                coords["lon"] = 102.434082;
                coords["type"] = "default";
            }
        }
        
        return coords;
    }
    
    // Check if coordinates have changed significantly
    static function coordinatesChanged(lastCoords as Dictionary, currentCoords as Dictionary) as Boolean {
        if (lastCoords == null || currentCoords == null) {
            return true;
        }
        
        // Check if coordinate type changed (GPS <-> Manual)
        if (lastCoords["type"] != currentCoords["type"]) {
            return true;
        }
        
        var lastLat = lastCoords["lat"];
        var lastLon = lastCoords["lon"];
        var currentLat = currentCoords["lat"];
        var currentLon = currentCoords["lon"];
        
        if (lastLat == null || lastLon == null || currentLat == null || currentLon == null) {
            return true;
        }
        
        // Check for significant coordinate change (more than 0.001 degrees ~ 100m)
        var latDiff = (lastLat as Float) - (currentLat as Float);
        var lonDiff = (lastLon as Float) - (currentLon as Float);
        
        if (latDiff < 0) { latDiff = -latDiff; }
        if (lonDiff < 0) { lonDiff = -lonDiff; }
        
        return (latDiff > 0.001 || lonDiff > 0.001);
    }
}
