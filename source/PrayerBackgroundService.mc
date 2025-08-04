import Toybox.Background;
import Toybox.Communications;
import Toybox.Application.Storage;
import Toybox.Position;
import Toybox.Time;
import Toybox.System;
import Toybox.Lang;

(:background)
class PrayerBackgroundService extends System.ServiceDelegate {
    
    function initialize() {
        ServiceDelegate.initialize();
        System.println("Prayer Background Service initialized");
    }

    function onTemporalEvent() as Void {
        System.println("Background service: Temporal event triggered");
        
        try {
            // Check if we should fetch new prayer times
            if (shouldFetchPrayerTimes()) {
                System.println("Background service: Fetching prayer times");
                fetchPrayerTimesBackground();
            } else {
                System.println("Background service: Using cached data (still fresh)");
                // Still return success to keep the service running
                Background.exit(null);
            }
        } catch (e) {
            System.println("Background service error: " + e.getErrorMessage());
            Background.exit(null);
        }
    }
    
    private function shouldFetchPrayerTimes() as Boolean {
        var lastFetch = Storage.getValue("last_fetch_time");
        if (lastFetch == null || lastFetch == 0) {
            return true; // Never fetched before
        }
        
        // Check if coordinates have changed since last fetch
        var lastCoords = Storage.getValue("last_fetch_coordinates");
        var currentCoords = getCurrentCoordinatesBackground();
        
        if (lastCoords == null || coordinatesChangedBackground(lastCoords, currentCoords)) {
            return true; // Coordinates changed - fetch immediately
        }
        
        // Check time interval (6 hours for background service to preserve battery)
        var now = Time.now();
        var timeDiff = now.value() - (lastFetch as Number);
        var minutesDiff = timeDiff / 60;
        
        return minutesDiff >= (6 * 60); // 6 hours interval for background
    }
    
    private function getCurrentCoordinatesBackground() as Dictionary {
        var coords = {};
        
        try {
            // Check if using manual coordinates
            var useManual = Storage.getValue("use_manual_coordinates");
            if (useManual != null && useManual as Boolean) {
                coords["lat"] = Storage.getValue("manual_latitude");
                coords["lon"] = Storage.getValue("manual_longitude");
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
        } catch (e) {
            // Fallback to default coordinates
            coords["lat"] = 2.317564;
            coords["lon"] = 102.434082;
            coords["type"] = "default";
        }
        
        return coords;
    }
    
    private function coordinatesChangedBackground(lastCoords as Dictionary, currentCoords as Dictionary) as Boolean {
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
        
        // Check for significant coordinate change (more than ~0.45 degrees ~ 50km)
        // 1 degree ≈ 111km, so 50km ≈ 0.45 degrees
        var latDiff = (lastLat as Float) - (currentLat as Float);
        var lonDiff = (lastLon as Float) - (currentLon as Float);
        
        if (latDiff < 0) { latDiff = -latDiff; }
        if (lonDiff < 0) { lonDiff = -lonDiff; }
        
        return (latDiff > 0.45 || lonDiff > 0.45);
    }
    
    private function fetchPrayerTimesBackground() as Void {
        try {
            var coords = getCurrentCoordinatesBackground();
            var lat = coords["lat"] as Float;
            var lon = coords["lon"] as Float;
            
            if (lat != null && lon != null) {
                var url = "https://mpt.i906.my/api/prayer/" + lat.format("%.6f") + "," + lon.format("%.6f");
                
                var options = {
                    :method => Communications.HTTP_REQUEST_METHOD_GET,
                    :headers => {
                        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
                    },
                    :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
                };
                
                System.println("Background service making API call to: " + url);
                var callback = new BackgroundPrayerAPICallback();
                Communications.makeWebRequest(url, null, options, new Lang.Method(callback, :invoke));
            } else {
                System.println("Background service: Invalid coordinates");
                Background.exit(null);
            }
        } catch (e) {
            System.println("Background API fetch error: " + e.getErrorMessage());
            Background.exit(null);
        }
    }
}

(:background)
class BackgroundPrayerAPICallback {
    function initialize() {}
    
    function invoke(responseCode as Number, data as Dictionary or Null) as Void {
        try {
            System.println("Background API Response Code: " + responseCode);
            
            if (responseCode == 200 && data != null) {
                System.println("Background API Success");
                processBackgroundAPIData(data);
                Background.exit(data); // Return data to main app/glance
            } else {
                System.println("Background API failed with code: " + responseCode);
                Background.exit(null);
            }
        } catch (ex) {
            System.println("Background API callback error: " + ex.toString());
            Background.exit(null);
        }
    }
    
    private function processBackgroundAPIData(apiResponse as Dictionary) as Void {
        try {
            if (!apiResponse.hasKey("data")) {
                return;
            }
            
            var apiData = apiResponse["data"];
            if (apiData == null) {
                return;
            }
            
            var location = "Unknown";
            var times = null;
            
            if (apiData has :hasKey && apiData.hasKey("place")) {
                location = apiData["place"] as String;
            }
            
            if (apiData has :hasKey && apiData.hasKey("times")) {
                times = apiData["times"];
            }
            
            if (times != null && times.size() > 0) {
                var now = Time.now();
                var info = Time.Gregorian.info(now, Time.FORMAT_SHORT);
                var currentDay = info.day - 1;
                
                if (currentDay >= 0 && currentDay < times.size()) {
                    var todayTimes = times[currentDay];
                    
                    if (todayTimes != null && todayTimes.size() >= 6) {
                        var prayerTimes = {
                            "Subuh" => convertUnixToTimeStringBackground(todayTimes[0]),
                            "Syuruk" => convertUnixToTimeStringBackground(todayTimes[1]),
                            "Isyraq" => calculateIsyraqTimeBackground(todayTimes[1]),
                            "Dhuha" => calculateDhuhaTimeBackground(todayTimes[1]),
                            "Zohor" => convertUnixToTimeStringBackground(todayTimes[2]),
                            "Asar" => convertUnixToTimeStringBackground(todayTimes[3]),
                            "Maghrib" => convertUnixToTimeStringBackground(todayTimes[4]),
                            "Isyak" => convertUnixToTimeStringBackground(todayTimes[5])
                        };
                        
                        // Store the data for main app and glance view to access
                        Storage.setValue("prayer_times", prayerTimes);
                        Storage.setValue("location", location);
                        Storage.setValue("last_fetch_time", Time.now().value());
                        
                        // Store current coordinates for change detection
                        var currentCoords = getCurrentCoordinatesBackground();
                        Storage.setValue("last_fetch_coordinates", currentCoords);
                        
                        System.println("Background service: Prayer times updated successfully");
                    }
                }
            }
        } catch (e) {
            System.println("Background API processing error: " + e.getErrorMessage());
        }
    }
    
    private function getCurrentCoordinatesBackground() as Dictionary {
        var coords = {};
        
        try {
            var useManual = Storage.getValue("use_manual_coordinates");
            if (useManual != null && useManual as Boolean) {
                coords["lat"] = Storage.getValue("manual_latitude");
                coords["lon"] = Storage.getValue("manual_longitude");
                coords["type"] = "manual";
            } else {
                coords["lat"] = 2.317564;
                coords["lon"] = 102.434082;
                coords["type"] = "gps";
            }
        } catch (e) {
            coords["lat"] = 2.317564;
            coords["lon"] = 102.434082;
            coords["type"] = "default";
        }
        
        return coords;
    }
    
    private function convertUnixToTimeStringBackground(unixTime) as String {
        try {
            var timestamp = unixTime;
            if (timestamp instanceof Long) {
                timestamp = timestamp.toNumber();
            }
            
            var moment = new Time.Moment(timestamp);
            var info = Time.Gregorian.info(moment, Time.FORMAT_SHORT);
            return Lang.format("$1$:$2$", [info.hour.format("%02d"), info.min.format("%02d")]);
        } catch (ex) {
            return "00:00";
        }
    }
    
    private function calculateIsyraqTimeBackground(syurukUnix) as String {
        try {
            var timestamp = syurukUnix;
            if (timestamp instanceof Long) {
                timestamp = timestamp.toNumber();
            }
            var isyraqUnix = timestamp + (12 * 60);
            return convertUnixToTimeStringBackground(isyraqUnix);
        } catch (ex) {
            return "00:00";
        }
    }
    
    private function calculateDhuhaTimeBackground(syurukUnix) as String {
        try {
            var timestamp = syurukUnix;
            if (timestamp instanceof Long) {
                timestamp = timestamp.toNumber();
            }
            var dhuhaUnix = timestamp + (15 * 60);
            return convertUnixToTimeStringBackground(dhuhaUnix);
        } catch (ex) {
            return "00:00";
        }
    }
}
