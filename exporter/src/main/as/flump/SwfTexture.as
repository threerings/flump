//
// Flump - Copyright 2013 Flump Authors

package flump {

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.display.StageQuality;
import flash.filters.ColorMatrixFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

public class SwfTexture
{
    public var symbol :String;
    public var quality :String;
    public function get origin () :Point { return new Point(_origin.x * _scale, _origin.y * _scale); }
    public function get w () :int { return Math.ceil(_w * _scale); }
    public function get h () :int { return Math.ceil(_h * _scale); }
    public function get a () :int { return this.w * this.h; }

    public static function fromFlipbook (lib :XflLibrary, movie :MovieMold, frame :int,
            quality :String = StageQuality.BEST, scale :Number = 1,
            useNamespace :Boolean = false) :SwfTexture {
        const klass :Class = Class(lib.swf.getSymbol(movie.id));
        const clip :MovieClip = MovieClip(new klass());
        clip.gotoAndStop(frame + 1);
        const ns :String = useNamespace ? lib.location + "/" : "";
        const name :String = ns + movie.id + "_flipbook_" + frame;
        return new SwfTexture(name, clip, scale, quality);
    }

    public static function fromTexture (lib :XflLibrary, tex :XflTexture,
                                        quality :String = StageQuality.BEST, scale :Number = 1,
                                        useNamespace :Boolean = false) :SwfTexture {
        const klass :Class = Class(lib.swf.getSymbol(tex.symbol));
        const instance :Object = new klass();
        const ns :String = useNamespace ? lib.location + "/" : "";
        const disp :DisplayObject = (instance is BitmapData) ?
            new Bitmap(BitmapData(instance)) : DisplayObject(instance);
        return new SwfTexture(ns + tex.symbol, disp, scale, quality,tex.baseClass);
    }

    public function SwfTexture (symbol :String, disp :DisplayObject, scale :Number, quality :String, baseClass:String=null) {
        this.symbol = symbol;
        this.quality = quality;
        this.baseClass = baseClass;

        // wrap object twice for convenience
        const wrapper :Sprite = new Sprite();
        wrapper.addChild(disp);
        _disp = new Sprite();
        _disp.addChild(wrapper);

        // set the scale and size info
        _treatAsFiltered = hasPotentiallySizeAlteringFilters(disp);
        setScale(scale);
    }

    // scale can be changed after creation, if desired
    public function setScale (value :Number) :void {
        // To compensate for the fact that filters don't "scale", we do the following
        // if filtered:
        //    render at scale 1
        //    then scale bitmapData to target size
        // if not filtered:
        //    set the scale in the wrapper
        //    render directly at target size with vector renderer
        if (_treatAsFiltered) {
            // cache the scale to use later
            _scale = value;
            // only need to calculate size once, since _disp is not changing
            if (_visualBounds == null) {
                recalculateSizeInfo();
            }
        } else {
            // embed the scale in _disp
            var wrapper :DisplayObject = _disp.getChildAt(0);
            wrapper.scaleX = wrapper.scaleY = value;
            _scale = 1;
            // recalculate size since _disp has changed
            recalculateSizeInfo();
        }
    }

    public function toBitmapData (xPad :int, yPad :int) :BitmapData {
        // render with vector renderer
        var bmd :BitmapData = new BitmapData(_w, _h, true, 0x00);
        const m :Matrix = new Matrix();
        m.translate(_origin.x, _origin.y);
        bmd.drawWithQuality(_disp, m, null, null, null, true, this.quality);

        // scale bitmap to target size if necessary (only used if _disp contains filters)
        if (_scale != 1.0) {
            bmd = Util.renderToBitmapData(bmd, this.w, this.h, this.quality, _scale);
        }

        // add padding if necessary
        return (xPad > 0 || yPad > 0 ? Util.padBitmapBorder(bmd, xPad, yPad) : bmd);
    }

    public function toString () :String { return "a " + this.a + " w " + this.w + " h " + this.h; }

    private function recalculateSizeInfo () :void {
        // get normal bounds
        _strictBounds = _disp.getChildAt(0).getBounds(_disp);
        _visualBounds = _strictBounds;

        // possibly increase the visual bounds (due to filter action)
        if (_treatAsFiltered) {
            // render to bmd
            const topLeft:Point = new Point(
                _s_filteredBmd.width / 2 - _strictBounds.width / 2 - _strictBounds.x,
                _s_filteredBmd.height / 2 - _strictBounds.height / 2 - _strictBounds.y);
            const m :Matrix = new Matrix(1, 0, 0, 1, topLeft.x, topLeft.y);
            _s_filteredBmd.drawWithQuality(_disp, m, null, null, null, true, this.quality);

            // calculate visual bounds
            _visualBounds = _s_filteredBmd.getColorBoundsRect(0xff000000, 0x00000000, false);
            _s_filteredBmd.fillRect(_visualBounds, 0x0);

            // adjust registration point
            _visualBounds.x = -(topLeft.x - _visualBounds.x);
            _visualBounds.y = -(topLeft.y - _visualBounds.y);
        }

        // calculate derivative info
        _origin = new Point(-_visualBounds.x, -_visualBounds.y);
        _w = Math.ceil(_visualBounds.width);
        _h = Math.ceil(_visualBounds.height);
    }

    private function hasPotentiallySizeAlteringFilters (dObj :DisplayObject) :Boolean {
        return DisplayUtil.applyToHierarchy(dObj, function (disp :DisplayObject) :Boolean {
            for each (var filter :Object in disp.filters) {
                // all standard filters except ColorMatrixFilter can change the visual bounds
                if (!(filter is ColorMatrixFilter)) {
                    return true;
                }
            }
            return false;
        });
    }

    private var _disp :DisplayObjectContainer;
    private var _w :int, _h :int;
    private var _origin :Point;
    private var _strictBounds :Rectangle;
    private var _visualBounds :Rectangle;
    private var _scale :Number;
    private var _treatAsFiltered:Boolean;

    static private var _s_filteredBmd:BitmapData = new BitmapData(2048, 2048, true, 0x0);
    { _s_filteredBmd.lock(); }
}
}
