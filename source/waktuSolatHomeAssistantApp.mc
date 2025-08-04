import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Background;
import Toybox.Time;

class waktuSolatHomeAssistantApp extends Application.AppBase {
    private var _view as waktuSolatHomeAssistantView or Null;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        System.println("App started");
        
        // Register background service for periodic prayer times updates
        registerBackgroundService();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        _view = new waktuSolatHomeAssistantView();
        return [ _view, new waktuSolatHomeAssistantDelegate(_view) ];
    }
    
    // Return the glance view
    function getGlanceView() as [GlanceView] or [GlanceView, GlanceViewDelegate] or Null {
        // Note: Due to ConnectIQ platform limitations, we cannot reliably trigger API calls
        // from glance view context. The glance view will display cached data.
        // Fresh data fetching happens when the main app is opened.
        
        System.println("Glance view requested - displaying cached prayer times");
        return [ new waktuSolatGlanceView() ];
    }
    
    // Register background service for periodic updates
    function registerBackgroundService() as Void {
        try {
            // Check if background service is already registered
            var lastServiceTime = Background.getLastTemporalEventTime();
            if (lastServiceTime != null) {
                System.println("Background service already registered, last run: " + lastServiceTime.value());
                return;
            }
            
            // Register temporal event every 6 hours
            var time = new Time.Duration(6 * 60 * 60); // 6 hours in seconds
            Background.registerForTemporalEvent(time);
            System.println("Background service registered for 6-hour intervals");
        } catch (e) {
            System.println("Failed to register background service: " + e.getErrorMessage());
        }
    }
    
    // Get background service delegate
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new PrayerBackgroundService()];
    }
    
    // Handle background data when it returns
    function onBackgroundData(data as Application.PersistableType) as Void {
        try {
            if (data != null) {
                System.println("Background data received - prayer times updated");
                // Data is already processed and stored by the background service
                // Main app and glance view will automatically use the fresh data
            } else {
                System.println("Background service completed without new data");
            }
        } catch (e) {
            System.println("Background data handling error: " + e.getErrorMessage());
        }
    }

}

function getApp() as waktuSolatHomeAssistantApp {
    return Application.getApp() as waktuSolatHomeAssistantApp;
}