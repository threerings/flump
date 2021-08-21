package flump.export.texturepacker {

public class MaxRectPackerImpl {

    import flash.geom.Rectangle;

    /*
     Implements different bin packer algorithms that use the MAXRECTS data structure.
     See http://clb.demon.fi/projects/even-more-rectangle-bin-packing

     Author: Jukka Jylänki
     - Original

     Author: Claus Wahlers
     - Ported to ActionScript3

     Author: Tony DiPerna
     - Ported to HaXe, optimized

     Author: Shawn Skinner (treefortress)
     - Ported back to AS3

     */

        public var freeRectangles:Vector.<Rectangle>;

        protected var binWidth:Number;
        protected var binHeight:Number;

        public function MaxRectPackerImpl(width:Number, height:Number):void {
            init(width, height);
        }

        public function init(width:Number, height:Number):void {
            binWidth = width;
            binHeight = height;
            freeRectangles = new <Rectangle>[];
            freeRectangles.push(new Rectangle(0, 0, width, height));
        }

        public function quickInsert(width:Number, height:Number):Rectangle {
            var newNode:Rectangle = quickFindPositionForNewNodeBestAreaFit(width, height);

            if (newNode.height == 0) {
                return null;
            }

            var numRectanglesToProcess:int = freeRectangles.length;
            var i:int = 0;
            while (i < numRectanglesToProcess) {
                if (splitFreeNode(freeRectangles[i], newNode)) {
                    freeRectangles.splice(i, 1);
                    --numRectanglesToProcess;
                    --i;
                }
                i++;
            }

            pruneFreeList();
            return newNode;
        }

        [Inline]
        final protected function quickFindPositionForNewNodeBestAreaFit(width:Number, height:Number):Rectangle {
            var score:int = int.MAX_VALUE;
            var areaFit:Number;
            var r:Rectangle;
            var bestNode:Rectangle = new Rectangle();

            for(var i:int = 0, l:int = freeRectangles.length; i < l; i++) {
                r = freeRectangles[i];
                // Try to place the rectangle in upright (non-flipped) orientation.
                if (r.width >= width && r.height >= height) {
                    areaFit = r.width * r.height - width * height;
                    if (areaFit < score) {
                        bestNode.x = r.x;
                        bestNode.y = r.y;
                        bestNode.width = width;
                        bestNode.height = height;
                        score = areaFit;
                    }
                }
            }

            return bestNode;
        }

        protected function splitFreeNode(freeNode:Rectangle, usedNode:Rectangle):Boolean {
            var newNode:Rectangle;
            // Test with SAT if the rectangles even intersect.
            if (usedNode.x >= freeNode.x + freeNode.width ||
                    usedNode.x + usedNode.width <= freeNode.x ||
                    usedNode.y >= freeNode.y + freeNode.height ||
                    usedNode.y + usedNode.height <= freeNode.y) {
                return false;
            }
            if (usedNode.x < freeNode.x + freeNode.width && usedNode.x + usedNode.width > freeNode.x) {
                // New node at the top side of the used node.
                if (usedNode.y > freeNode.y && usedNode.y < freeNode.y + freeNode.height) {
                    newNode = freeNode.clone();
                    newNode.height = usedNode.y - newNode.y;
                    freeRectangles.push(newNode);
                }
                // New node at the bottom side of the used node.
                if (usedNode.y + usedNode.height < freeNode.y + freeNode.height) {
                    newNode = freeNode.clone();
                    newNode.y = usedNode.y + usedNode.height;
                    newNode.height = freeNode.y + freeNode.height - (usedNode.y + usedNode.height);
                    freeRectangles.push(newNode);
                }
            }
            if (usedNode.y < freeNode.y + freeNode.height && usedNode.y + usedNode.height > freeNode.y) {
                // New node at the left side of the used node.
                if (usedNode.x > freeNode.x && usedNode.x < freeNode.x + freeNode.width) {
                    newNode = freeNode.clone();
                    newNode.width = usedNode.x - newNode.x;
                    freeRectangles.push(newNode);
                }
                // New node at the right side of the used node.
                if (usedNode.x + usedNode.width < freeNode.x + freeNode.width) {
                    newNode = freeNode.clone();
                    newNode.x = usedNode.x + usedNode.width;
                    newNode.width = freeNode.x + freeNode.width - (usedNode.x + usedNode.width);
                    freeRectangles.push(newNode);
                }
            }
            return true;
        }

        protected function pruneFreeList():void  {
            // Go through each pair and remove any rectangle that is redundant.
            var i:int = 0;
            var j:int = 0;
            var len:int = freeRectangles.length;
            var tmpRect:Rectangle;
            var tmpRect2:Rectangle;
            while (i < len) {
                j = i + 1;
                tmpRect = freeRectangles[i];
                while (j < len) {
                    tmpRect2 = freeRectangles[j];
                    if (isContainedIn(tmpRect,tmpRect2)) {
                        freeRectangles.splice(i, 1);
                        --i;
                        --len;
                        break;
                    }
                    if (isContainedIn(tmpRect2,tmpRect)) {
                        freeRectangles.splice(j, 1);
                        --len;
                        --j;
                    }
                    j++;
                }
                i++;
            }
        }

        [Inline]
        final protected function isContainedIn(a:Rectangle, b:Rectangle):Boolean {
            return a.x >= b.x && a.y >= b.y    && a.x + a.width <= b.x + b.width && a.y + a.height <= b.y + b.height;
        }


}
}
