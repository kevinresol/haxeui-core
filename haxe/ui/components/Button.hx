package haxe.ui.components;

import haxe.ui.core.Behaviour;
import haxe.ui.core.IClonable;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.core.MouseEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.layouts.DefaultLayout;
import haxe.ui.styles.Style;
import haxe.ui.util.Timer;
import haxe.ui.util.Variant;

/**
 General purpose push button that supports both text and icon as well as repeat event dispatching
**/
@:dox(icon="/icons/ui-button.png")
class Button extends InteractiveComponent implements IClonable<Button> {
    private var _label:Label;
    private var _icon:Image;
    private var _repeatTimer:Timer;

    public function new() {
        super();
        #if openfl
        //mouseChildren = false;
        #end
    }

    //***********************************************************************************************************
    // Internals
    //***********************************************************************************************************
    private override function createDefaults():Void {
        _defaultBehaviours = [
            "text" => new ButtonDefaultTextBehaviour(this),
            "icon" => new ButtonDefaultIconBehaviour(this)
        ];
        _defaultLayout = new ButtonLayout();
    }

    private override function create():Void {
        super.create();
        behaviourSet("text", _text);
        behaviourSet("icon", _iconResource);
    }

    private override function createChildren():Void {
        registerEvent(MouseEvent.MOUSE_OVER, _onMouseOver);
        registerEvent(MouseEvent.MOUSE_OUT, _onMouseOut);
        registerEvent(MouseEvent.MOUSE_DOWN, _onMouseDown);
    }

    private override function destroyChildren():Void {
        super.destroyChildren();

        unregisterEvent(MouseEvent.MOUSE_OVER, _onMouseOver);
        unregisterEvent(MouseEvent.MOUSE_OUT, _onMouseOut);
        unregisterEvent(MouseEvent.MOUSE_DOWN, _onMouseDown);

        if (_label != null) {
            removeComponent(_label);
            _label = null;
        }
        if (_icon != null) {
            removeComponent(_icon);
            _icon = null;
        }
    }

    //***********************************************************************************************************
    // Overrides
    //***********************************************************************************************************
    private override function set_text(value:String):String {
        value = super.set_text(value);
        behaviourSet("text", value);
        return value;
    }

    private override function applyStyle(style:Style):Void {
        super.applyStyle(style);
        if (style.icon != null) {
            icon = style.icon;
        }
        if (_label != null) {
            _label.customStyle.color = style.color;
            _label.customStyle.fontName = style.fontName;
            _label.customStyle.fontSize = style.fontSize;
            _label.customStyle.cursor = style.cursor;
            _label.invalidateStyle();
        }
        if (_icon != null) {
            _icon.customStyle.cursor = style.cursor;
            _icon.invalidateStyle();
        }
    }

    //***********************************************************************************************************
    // Public API
    //***********************************************************************************************************
    /**
     Whether the buttons state should remain pressed even when the mouse has left its bounds
    **/
    @:clonable public var remainPressed(default, default):Bool = false;

    /**
     Whether this button will dispatch multiple click events while the the mouse is pressed within it
    **/
    @:dox(group="Repeater related properties")
    @:clonable public var repeater(default, default):Bool = false;

    /**
     How often this button will dispatch multiple click events while the the mouse is pressed within it
    **/
    @:dox(group="Repeater related properties")
    @:clonable public var repeatInterval(default, default):Int = 50;

    private var _iconResource:String;
    /**
     The image resource to use as the buttons icon
    **/
    @:clonable public var icon(get, set):String;
    private function get_icon():String {
        return _iconResource; // TODO: temp
    }

    private function set_icon(value:String):String {
        if (_iconResource == value) {
            return value;
        }

        _iconResource = value;
        behaviourSet("icon", value);
        return value;
    }

    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private var _down:Bool = false;
    private function _onMouseOver(event:MouseEvent):Void {
        if (event.buttonDown == false || _down == false) {
            addClass(":hover");
        } else {
            addClass(":down");
        }
    }

    private function _onMouseOut(event:MouseEvent):Void {
        if (remainPressed == false) {
            removeClass(":down");
        }
        removeClass(":hover");
    }

    private function _onMouseDown(event:MouseEvent):Void {
        if (FocusManager.instance.focusInfo != null && FocusManager.instance.focusInfo.currentFocus != null) {
            FocusManager.instance.focusInfo.currentFocus.focus = false;
        }
        _down = true;
        addClass(":down");
        screen.registerEvent(MouseEvent.MOUSE_UP, _onMouseUp);

        if (repeater == true) {
            _repeatTimer = new Timer(repeatInterval, _onRepeatTimer);
        }
    }

    private function _onRepeatTimer() {
        if (hasClass(":hover") && _down == true) {
            var event:MouseEvent = new MouseEvent(MouseEvent.CLICK);
            dispatch(event);
        }
    }

    private function _onMouseUp(event:MouseEvent):Void {
        _down = false;
        removeClass(":down");
        if (hitTest(event.screenX, event.screenY)) {
            addClass(":hover");
        }

        if (_repeatTimer != null) {
            #if !(cpp || neko)
            _repeatTimer.stop();
            _repeatTimer = null;
            #end
        }

        screen.unregisterEvent(MouseEvent.MOUSE_UP, _onMouseUp);
    }
}

//***********************************************************************************************************
// Default behaviours
//***********************************************************************************************************
@:dox(hide)
@:access(haxe.ui.components.Button)
class ButtonDefaultTextBehaviour extends Behaviour {
    public override function set(value:Variant) {
        if (value.isNull) {
            return;
        }

        var button:Button = cast _component;
        if (button._label == null) {
            button._label = new Label();
            button._label.id = "button-label";
            button._label.scriptAccess = false;
            button.addComponent(button._label);
        }
        button._label.text = value;
    }
}

@:dox(hide)
@:access(haxe.ui.components.Button)
class ButtonDefaultIconBehaviour extends Behaviour {
    public override function get():Variant {
        var button:Button = cast _component;
        if (button._icon == null) {
            return null;
        }

        return button._icon.resource;
    }

    public override function set(value:Variant) {
        if (value.isNull) {
            return;
        }

        var button:Button = cast _component;
        if (button._icon == null) {
            button._icon = new Image();
            button._icon.addClass("icon");
            button._icon.id = "button-icon";
            button._icon.scriptAccess = false;
            button.addComponent(button._icon);
        }

        button._icon.resource = value.toString();
    }
}

@:dox(hide)
class ButtonLayout extends DefaultLayout {
    public function new() {
        super();
    }

    private var iconPosition(get, null):String;
    private function get_iconPosition():String {
        if (component.style.iconPosition == null) {
            return "left";
        }
        return component.style.iconPosition;
    }

    private override function repositionChildren():Void {
        super.repositionChildren();

        var label:Label = component.findComponent("button-label");
        var icon:Image = component.findComponent("button-icon");

        switch (iconPosition) {
            case "left" | "right":
                if (label != null && icon != null) {
                    var cx:Float = label.componentWidth + icon.componentWidth + horizontalSpacing;
                    var x:Float = Std.int((component.componentWidth / 2) - (cx / 2));

                    if (iconPosition == "right") {
                        label.left = x + marginLeft(label) - marginRight(label);
                        x += horizontalSpacing + label.componentWidth;
                        icon.left = x + marginLeft(icon) - marginRight(icon);
                    } else {
                        icon.left = x + marginLeft(icon) - marginRight(icon);
                        x += horizontalSpacing + icon.componentWidth;
                        label.left = x + marginLeft(label) - marginRight(label);
                    }

                    label.top = Std.int((component.componentHeight / 2) - (label.componentHeight / 2)) + marginTop(label) - marginBottom(label);
                    icon.top = Std.int((component.componentHeight / 2) - (icon.componentHeight / 2)) + marginTop(icon) - marginBottom(icon);
                } else if (label != null) {
                    label.left = Std.int((component.componentWidth / 2) - (label.componentWidth / 2)) + marginLeft(label) - marginRight(label);
                    label.top = Std.int((component.componentHeight / 2) - (label.componentHeight / 2)) + marginTop(label) - marginBottom(label);
                } else if (icon != null) {
                    icon.left = Std.int((component.componentWidth / 2) - (icon.componentWidth / 2));// + marginLeft(icon) - marginRight(icon);
                    icon.top = Std.int((component.componentHeight / 2) - (icon.componentHeight / 2)) + marginTop(icon) - marginBottom(icon);
                }
            case "top" | "bottom":
                if (label != null && icon != null) {
                    var cy:Float = label.componentHeight + icon.componentHeight + verticalSpacing;
                    var y:Float = Std.int((component.componentHeight / 2) - (cy / 2));

                    if (iconPosition == "bottom") {
                        label.top = y + marginTop(label) - marginBottom(label);
                        y += verticalSpacing + label.componentHeight;
                        icon.top = y + marginTop(icon) - marginBottom(icon);
                    } else {
                        icon.top = y + marginTop(icon) - marginBottom(icon);
                        y += verticalSpacing + icon.componentHeight;
                        label.top = y + marginTop(label) - marginBottom(label);
                    }

                    label.left = Std.int((component.componentWidth / 2) - (label.componentWidth / 2)) + marginLeft(label) - marginRight(label);
                    icon.left = Std.int((component.componentWidth / 2) - (icon.componentWidth / 2)) + marginLeft(icon) - marginRight(icon);
                } else if (label != null) {
                    label.left = Std.int((component.componentWidth / 2) - (label.componentWidth / 2)) + marginLeft(label) - marginRight(label);
                    label.top = Std.int((component.componentHeight / 2) - (label.componentHeight / 2)) + marginTop(label) - marginBottom(label);
                } else if (icon != null) {
                    icon.left = Std.int((component.componentWidth / 2) - (icon.componentWidth / 2)) + marginLeft(icon) - marginRight(icon);
                    icon.top = Std.int((component.componentHeight / 2) - (icon.componentHeight / 2)) + marginTop(icon) - marginBottom(icon);
                }
        }
    }
}