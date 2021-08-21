//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

import aspire.util.Set;
import aspire.util.Sets;
import aspire.util.XmlUtil;

import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import flump.mold.MovieMold;

public class XflMovie extends XflSymbol
{
    use namespace xflns;

    /** Returns true if the given movie symbol is marked for "Export for ActionScript" */
    public static function isExported (xml :XML) :Boolean {
        return XmlUtil.hasAttr(xml, EXPORT_CLASS_NAME);
    }

    /** Returns the library name of the given movie */
    public static function getName (xml :XML) :String {
        return XmlUtil.getStringAttr(xml, NAME);
    }

    /** Return a Set of all the symbols this movie references. */
    public static function getSymbolNames (mold :MovieMold) :Set {
        var names :Set = Sets.newSetOf(String);
        for each (var layer :LayerMold in mold.layers) {
            if (!layer.flipbook) {
                for each (var kf :KeyframeMold in layer.keyframes) {
                    if (kf.ref != null) names.add(kf.ref);
                }
            }
        }
        return names;
    }

    public static function parse (lib :XflLibrary, xml :XML) :MovieMold {
        const movie :MovieMold = new MovieMold();
        const name :String = getName(xml);
        const exportName :String = XmlUtil.getStringAttr(xml, EXPORT_CLASS_NAME, null);
        movie.id = lib.createId(movie, name, exportName);
        const location :String = XflLibrary.appendLocation(lib.location, movie.id);

        // base Class
        if (XmlUtil.getStringAttr(xml, "symbolType", null) == "button") movie.baseClass = "flash.display.SimpleButton";
        else {
            var baseClass:String = XmlUtil.getStringAttr(xml, "linkageBaseClass", null);
            if (baseClass != "flash.display.MovieClip") movie.baseClass = baseClass;
        }
        
        const layerEls :XMLList = xml.timeline.DOMTimeline[0].layers.DOMLayer;
        if (XmlUtil.getStringAttr(layerEls[0], XflLayer.NAME) == "flipbook") {
            movie.layers.push(XflLayer.parse(lib, location, layerEls[0], true));
            if (exportName == null) {
                lib.addError(location, ParseError.CRIT, "Flipbook movie '" + movie.id + "' not exported");
            }
            for each (var kf :KeyframeMold in movie.layers[0].keyframes) {
                kf.ref = movie.id + "_flipbook_" + kf.index;
            }
        } else {
            for each (var layerEl :XML in layerEls) {
                var layerType :String = XmlUtil.getStringAttr(layerEl, XflLayer.TYPE, "");
                if ((layerType != XflLayer.TYPE_GUIDE) && (layerType != XflLayer.TYPE_FOLDER)) {
                    movie.layers.unshift(XflLayer.parse(lib, location, layerEl, false));
                }
            }
        }
        movie.fillLabels();

        if (movie.layers.length == 0) {
            lib.addError(location, ParseError.CRIT, "Movies must have at least one layer");
        }

        return movie;
    }
}
}
