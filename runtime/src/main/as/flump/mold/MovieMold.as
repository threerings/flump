//
// Flump - Copyright 2013 Flump Authors

package flump.mold {

import flump.display.Movie;

public class MovieMold
{
    public var id :String;
    public var layers :Vector.<LayerMold> = new <LayerMold>[];
    public var labels :Vector.<Vector.<String>>;
    
    public var baseClass : String;

    public static function fromJSON (o :Object) :MovieMold {
        const mold :MovieMold = new MovieMold();
        mold.id = require(o, "id");
        mold.baseClass = o["baseClass"];
        for each (var layer :Object in require(o, "layers")) mold.layers.push(LayerMold.fromJSON(layer));
        return mold;
    }

    public function get frames () :int {
        var frames :int = 0;
        for each (var layer :LayerMold in layers) frames = Math.max(frames, layer.frames);
        return frames;
    }

    public function get flipbook () :Boolean {
        return (layers.length > 0 && layers[0].flipbook);
    }

    public function fillLabels () :void {
        labels = new Vector.<Vector.<String>>(frames, true);
        if (labels.length == 0) {
            return;
        }
        labels[0] = new <String>[];
        labels[0].push(Movie.FIRST_FRAME);
        if (labels.length > 1) {
            // If we only have 1 frame, don't overwrite labels[0]
            labels[frames - 1] = new <String>[];
        }
        labels[frames - 1].push(Movie.LAST_FRAME);
        for each (var layer :LayerMold in layers) {
            for each (var kf :KeyframeMold in layer.keyframes) {
                if (kf.label == null) continue;
                if (labels[kf.index] == null) labels[kf.index] = new <String>[];
                labels[kf.index].push(kf.label);
            }

        }
    }

    public function scale (scale :Number) :MovieMold {
        const clone :MovieMold = fromJSON(JSON.parse(JSON.stringify(this)));
        for each (var layer :LayerMold in clone.layers) {
            for each (var kf :KeyframeMold in layer.keyframes) {
                kf.x *= scale;
                kf.y *= scale;
                kf.pivotX *= scale;
                kf.pivotY *= scale;
            }
        }
        return clone;
    }

    public function toJSON (_:*) :Object {
        const json :Object = {
            id: id,
            layers: layers
        };
        
        if (baseClass != null) json.baseClass = baseClass;
        
        return json;
    }

    public function toXML () :XML {
        var xml :XML = baseClass == null ? <movie name={id}/> : <movie name={id} baseClass={baseClass}/>;
        for each (var layer :LayerMold in layers) xml.appendChild(layer.toXML());
        return xml;
    }

}
}
