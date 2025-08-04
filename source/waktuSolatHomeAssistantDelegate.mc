import Toybox.Lang;
import Toybox.WatchUi;

class waktuSolatHomeAssistantDelegate extends WatchUi.BehaviorDelegate {
    private var _view as waktuSolatHomeAssistantView;

    function initialize(view as waktuSolatHomeAssistantView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onMenu() as Boolean {
        // Create Menu2 for consistency with settings
        var menu = new WatchUi.Menu2({:title=>"Menu"});
        menu.addItem(new WatchUi.MenuItem("Settings", "App settings", :settings, null));
        menu.addItem(new WatchUi.MenuItem("Refresh", "Update prayer times", :refresh, null));
        
        WatchUi.pushView(menu, new waktuSolatHomeAssistantMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
    
    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        return _view.onKeyPressed(keyEvent);
    }
    
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        var direction = swipeEvent.getDirection();
        
        if (direction == WatchUi.SWIPE_UP) {
            return _view.scrollUp();
        } else if (direction == WatchUi.SWIPE_DOWN) {
            return _view.scrollDown();
        }
        
        return false;
    }

}