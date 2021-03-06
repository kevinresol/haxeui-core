package haxe.ui;

import haxe.ui.core.KeyboardEvent;
import haxe.ui.core.Screen;
import haxe.ui.focus.FocusManager;
import haxe.ui.macros.BackendMacros;
import haxe.ui.macros.ModuleMacros;
import haxe.ui.macros.NativeMacros;
import haxe.ui.styles.Engine;
import haxe.ui.themes.ThemeManager;
import haxe.ui.util.GenericConfig;
import haxe.ui.util.Properties;

class Toolkit {
    public static var styleSheet:Engine = new Engine();
    public static var theme:String = "default";

    public static var properties:Map<String, String> = new Map<String, String>();

    public static var backendProperties:Properties = new Properties();
    public static var nativeConfig:GenericConfig = new GenericConfig();

    private static var _built:Bool = false;
    public static function build() {
        if (_built == true) {
            return;
        }
        BackendMacros.processBackend();
        ModuleMacros.processModules();
        NativeMacros.processNative();
        _built = true;

        #if (haxeui_remoting && !haxeui_remoting_server)
        var client:haxe.ui.remoting.client.Client = new haxe.ui.remoting.client.Client();
        #end
    }

    public static function init(options:Dynamic = null) {
        build();
        ThemeManager.instance.applyTheme(theme);
        if (options != null) {
            screen.options = options;
            ToolkitAssets.instance.options = options;
        }
        screen.registerEvent(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    private static function onKeyDown(event:KeyboardEvent) {
        if (event.keyCode == KeyboardEvent.KEY_TAB) {
            if (event.shiftKey == false) {
                FocusManager.instance.focusNext();
            } else {
                FocusManager.instance.focusPrev();
            }
        }
    }

    public static var assets(get, null):ToolkitAssets;
    private static function get_assets():ToolkitAssets {
        return ToolkitAssets.instance;
    }

    public static var screen(get, null):Screen;
    private static function get_screen():Screen {
        return Screen.instance;
    }
}