import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class waktuSolatSettingsView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Settings"});
        buildMenu();
    }
    
    // Build menu dynamically based on current mode
    function buildMenu() {
        // Clear existing menu items
        // Note: Menu2 doesn't have clear method, so we rebuild the menu
        
        var isManual = PrayerDataManager.isUsingManualCoordinates();
        var currentMode = isManual ? "Manual" : "GPS";
        
        // Always visible: Mode toggle
        Menu2.addItem(new WatchUi.MenuItem("Mode: " + currentMode, null, :toggle_mode, null));
        
        // Manual mode only: Location selection options
        if (isManual) {
            Menu2.addItem(new WatchUi.MenuItem("Select by State", null, :select_state, null));
            Menu2.addItem(new WatchUi.MenuItem("Quick Cities", null, :enter_coords, null));
            Menu2.addItem(new WatchUi.MenuItem("Recent Locations", null, :recent_coords, null));
        }
        
        // Always visible: Test API and Version
        // COMMENTED OUT: API Test menu item (can be re-enabled later if needed)
        // Menu2.addItem(new WatchUi.MenuItem("Test API", null, :test_api, null));
        Menu2.addItem(new WatchUi.MenuItem("Version: 2.0.6b", "Power by WakLeh Jasin", :version, null));
        Menu2.addItem(new WatchUi.MenuItem("Back", null, :back, null));
    }
}

class waktuSolatSettingsDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        
        if (id == :toggle_mode) {
            // Toggle between GPS and Manual mode
            try {
                var isManual = PrayerDataManager.isUsingManualCoordinates();
                PrayerDataManager.setUseManualCoordinates(!isManual);
                var newMode = !isManual ? "Manual" : "GPS";
                WatchUi.showToast(newMode, null);
                // Refresh menu to show/hide manual options dynamically
                WatchUi.popView(WatchUi.SLIDE_RIGHT);
                WatchUi.pushView(new waktuSolatSettingsView(), new waktuSolatSettingsDelegate(), WatchUi.SLIDE_LEFT);
            } catch (e) {
                WatchUi.showToast("Mode Error", null);
            }
        } else if (id == :select_state) {
            // Show state selection submenu
            showStateSelection();
        } else if (id == :enter_coords) {
            // Show coordinate entry submenu (quick cities)
            showCoordinateEntry();
        } else if (id == :recent_coords) {
            // Show recent coordinates submenu
            showRecentCoordinates();
        // COMMENTED OUT: API Test handler (can be re-enabled later if needed)
        // } else if (id == :test_api) {
        //     // Test API call with current coordinates
        //     testApiCall();
        } else if (id == :version) {
            // Show version info (no action needed, just display)
            WatchUi.showToast("Power by WakLeh", null);
        } else if (id == :back) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
    
    // Removed TextPicker methods to prevent crashes on real devices
    // Manual coordinates are now set to safe default values (Jasin, Malaysia)
    
    private function showCoordinateEntry() as Void {
        // Create submenu for coordinate entry with preset locations
        var coordMenu = new WatchUi.Menu2({:title=>"Enter Coordinates"});
        
        // Add major Malaysian cities as quick options
        coordMenu.addItem(new WatchUi.MenuItem("Kuala Lumpur", "3.139, 101.687", :kl, null));
        coordMenu.addItem(new WatchUi.MenuItem("Johor Bahru", "1.493, 103.741", :jb, null));
        coordMenu.addItem(new WatchUi.MenuItem("Penang", "5.416, 100.333", :penang, null));
        coordMenu.addItem(new WatchUi.MenuItem("Kota Kinabalu", "5.980, 116.074", :kk, null));
        coordMenu.addItem(new WatchUi.MenuItem("Kuching", "1.553, 110.359", :kuching, null));
        coordMenu.addItem(new WatchUi.MenuItem("Back", "Return to settings", :back, null));
        
        WatchUi.pushView(coordMenu, new CoordinateEntryDelegate(), WatchUi.SLIDE_LEFT);
    }
    
    private function showRecentCoordinates() as Void {
        var recentCoords = PrayerDataManager.getRecentCoordinates();
        var recentMenu = new WatchUi.Menu2({:title=>"Recent Locations"});
        
        if (recentCoords.size() == 0) {
            recentMenu.addItem(new WatchUi.MenuItem("No Recent", "No saved locations", :none, null));
        } else {
            for (var i = 0; i < recentCoords.size(); i++) {
                var coord = recentCoords[i];
                var name = coord["name"] as String;
                var lat = coord["lat"] as Float;
                var lon = coord["lon"] as Float;
                var subtitle = lat.format("%.3f") + ", " + lon.format("%.3f");
                recentMenu.addItem(new WatchUi.MenuItem(name, subtitle, i, coord));
            }
        }
        
        recentMenu.addItem(new WatchUi.MenuItem("Back", "Return to settings", :back, null));
        WatchUi.pushView(recentMenu, new RecentCoordsDelegate(), WatchUi.SLIDE_LEFT);
    }
    
    private function testApiCall() as Void {
        try {
            // Always fetch when API test is triggered (bypass 15-min limit)
            if (PrayerDataManager.forceFetchFromAPI()) {
                PrayerDataManager.fetchPrayerTimesFromAPI();
                WatchUi.showToast("Testing...", null);
            }
        } catch (e) {
            WatchUi.showToast("Test failed", null);
        }
    }
    
    // Show state selection menu
    private function showStateSelection() as Void {
        var states = MalaysianLocations.getStates();
        var menu = new WatchUi.Menu2({:title => "Select State"});
        
        for (var i = 0; i < states.size(); i++) {
            var state = states[i];
            menu.addItem(new WatchUi.MenuItem(state["name"], null, state["id"], null));
        }
        
        WatchUi.pushView(menu, new StateSelectionDelegate(), WatchUi.SLIDE_LEFT);
    }
}

// Coordinate Entry Delegate for preset Malaysian cities
class CoordinateEntryDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }
    
    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        
        if (id == :kl) {
            setCoordinates(3.139003, 101.686855, "Kuala Lumpur");
        } else if (id == :jb) {
            setCoordinates(1.4927, 103.7414, "Johor Bahru");
        } else if (id == :penang) {
            setCoordinates(5.4164, 100.3327, "Penang");
        } else if (id == :kk) {
            setCoordinates(5.9804, 116.0735, "Kota Kinabalu");
        } else if (id == :kuching) {
            setCoordinates(1.5533, 110.3592, "Kuching");
        } else if (id == :back) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
    
    private function setCoordinates(lat as Float, lon as Float, name as String) as Void {
        try {
            PrayerDataManager.setManualLatitude(lat);
            PrayerDataManager.setManualLongitude(lon);
            PrayerDataManager.setUseManualCoordinates(true);
            PrayerDataManager.saveRecentCoordinates(lat, lon, name);
            WatchUi.showToast(name, null);
            // Go back to main settings
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } catch (e) {
            WatchUi.showToast("Coord Error", null);
        }
    }
}

// Recent Coordinates Delegate
class RecentCoordsDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }
    
    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        
        if (id == :back) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        } else if (id == :none) {
            // No recent coordinates available
            WatchUi.showToast("No recent", null);
        } else {
            // Select from recent coordinates using index
            var recentCoords = PrayerDataManager.getRecentCoordinates();
            var index = id as Number;
            if (index >= 0 && index < recentCoords.size()) {
                var coord = recentCoords[index];
                var lat = coord["lat"] as Float;
                var lon = coord["lon"] as Float;
                var name = coord["name"] as String;
                
                try {
                    PrayerDataManager.setManualLatitude(lat);
                    PrayerDataManager.setManualLongitude(lon);
                    PrayerDataManager.setUseManualCoordinates(true);
                    WatchUi.showToast(name, null);
                    // Go back to main settings
                    WatchUi.popView(WatchUi.SLIDE_RIGHT);
                } catch (e) {
                    WatchUi.showToast("Coord Error", null);
                }
            }
        }
    }
}

// Delegate for state selection
class StateSelectionDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }
    
    function onSelect(item as WatchUi.MenuItem) as Void {
        var stateId = item.getId();
        showDistrictSelection(stateId);
    }
    
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
    
    // Show district selection for the selected state
    private function showDistrictSelection(stateId) as Void {
        var districts = MalaysianLocations.getDistricts(stateId);
        var menu = new WatchUi.Menu2({:title => "Select District"});
        
        for (var i = 0; i < districts.size(); i++) {
            var district = districts[i];
            menu.addItem(new WatchUi.MenuItem(district["name"], null, i, null));
        }
        
        WatchUi.pushView(menu, new DistrictSelectionDelegate(stateId), WatchUi.SLIDE_LEFT);
    }
}

// Delegate for district selection
class DistrictSelectionDelegate extends WatchUi.Menu2InputDelegate {
    private var _stateId;
    
    function initialize(stateId) {
        Menu2InputDelegate.initialize();
        _stateId = stateId;
    }
    
    function onSelect(item as WatchUi.MenuItem) as Void {
        var index = item.getId() as Number;
        var districts = MalaysianLocations.getDistricts(_stateId);
        
        if (index != null && index >= 0 && index < districts.size()) {
            var district = districts[index];
            var lat = district["lat"];
            var lon = district["lon"];
            var name = district["name"];
            
            try {
                PrayerDataManager.setManualLatitude(lat);
                PrayerDataManager.setManualLongitude(lon);
                PrayerDataManager.setUseManualCoordinates(true);
                
                // Add to recent coordinates
                PrayerDataManager.addToRecentCoordinates(lat, lon, name);
                
                WatchUi.showToast(name, null);
                
                // Go back to main settings (pop district menu and state menu)
                WatchUi.popView(WatchUi.SLIDE_RIGHT); // Pop district menu
                WatchUi.popView(WatchUi.SLIDE_RIGHT); // Pop state menu
            } catch (e) {
                WatchUi.showToast("Coord Error", null);
            }
        }
    }
    
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
