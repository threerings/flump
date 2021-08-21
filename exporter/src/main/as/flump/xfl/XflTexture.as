//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

import aspire.util.XmlUtil;

import flump.SwfTexture;
import flump.executor.load.LoadedSwf;

public class XflTexture
{
    public var symbol :String;
    public var baseClass :String;

    public function XflTexture (lib :XflLibrary, location :String, xml :XML) {
        symbol = XmlUtil.getStringAttr(xml, "linkageClassName");
        
        // base Class
        var lBaseClass:String = XmlUtil.getStringAttr(xml, "linkageBaseClass", null);
        if (lBaseClass != "flash.display.Sprite") baseClass = lBaseClass;
        
        lib.createId(this, XmlUtil.getStringAttr(xml, "name"), symbol);
    }

    public function isValid (lib :XflLibrary) :Boolean {
        var swfTex :SwfTexture = SwfTexture.fromTexture(lib, this);
        return (swfTex.w > 0 && swfTex.h > 0);
    }
}
}
