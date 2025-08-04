import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class waktuSolatHomeAssistantMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :settings) {
            WatchUi.pushView(
                new waktuSolatSettingsView(),
                new waktuSolatSettingsDelegate(),
                WatchUi.SLIDE_LEFT
            );
        } else if (id == :refresh) {
            // Force refresh prayer times from API
            if (PrayerDataManager.shouldFetchFromAPI()) {
                PrayerDataManager.fetchPrayerTimesFromAPI();
                WatchUi.showToast("Refresh", null);
            } else {
                WatchUi.showToast("Recent data", null);
            }
        }
    }

}