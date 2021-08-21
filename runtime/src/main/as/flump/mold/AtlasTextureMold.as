//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

import flash.geom.Point;
import flash.geom.Rectangle;

/** @private */
public class AtlasTextureMold
{
    public var symbol :String;
    public var bounds :Rectangle;
    public var origin :Point;
    
    public var baseClass : String;

    public static function fromJSON (o :Object) :AtlasTextureMold {
        const mold :AtlasTextureMold = new AtlasTextureMold();
        mold.symbol = require(o, "symbol");
        const rect :Array = require(o, "rect");
        mold.bounds = new Rectangle(rect[0], rect[1], rect[2], rect[3]);
        const orig :Array = require(o, "origin");
        mold.origin = new Point(orig[0], orig[1]);
        return mold;
    }

    public function toJSON (_:*) :Object {
        var json :Object = {
            symbol: symbol,
            rect: [bounds.x, bounds.y, bounds.width, bounds.height],
            origin: [origin.x, origin.y]
        };
        
        if (baseClass != null) json.baseClass = baseClass;
        
        return json;
    }

    public function toXML () :XML {
        const json :Object = toJSON(null);
        return baseClass==null ? <texture name={symbol} rect={json.rect} origin={json.origin}/> : <texture name={symbol} rect={json.rect} origin={json.origin} baseClass={json.baseClass}/>;
    }

}
}
