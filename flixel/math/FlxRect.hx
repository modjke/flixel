package flixel.math;

import flash.geom.Rectangle;
import flixel.FlxG;
import flixel.util.FlxPool;
import flixel.util.FlxPool.IFlxPooled;
import flixel.util.FlxStringUtil;

/**
 * Stores a rectangle.
 */
class FlxRect implements IFlxPooled
{
	private static var _pool = new FlxPool<FlxRect>(FlxRect);
	
	/**
	 * Recycle or create new FlxRect.
	 * Be sure to put() them back into the pool after you're done with them!
	 */
	public static inline function get(X:Float = 0, Y:Float = 0, Width:Float = 0, Height:Float = 0):FlxRect
	{
		var rect = _pool.get().set(X, Y, Width, Height);
		rect._inPool = false;
		return rect;
	}
	
	/**
	 * Recycle or create a new FlxRect which will automatically be released 
	 * to the pool when passed into a flixel function.
	 */
	public static inline function weak(X:Float = 0, Y:Float = 0, Width:Float = 0, Height:Float = 0):FlxRect
	{
		var rect = _pool.get().set(X, Y, Width, Height);
		rect._weak = true;
		return rect;
	}
	
	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var height:Float;
	
	/**
	 * The x coordinate of the left side of the rectangle.
	 */
	public var left(get, set):Float;
	
	/**
	 * The x coordinate of the right side of the rectangle.
	 */
	public var right(get, set):Float;
	
	/**
	 * The x coordinate of the top of the rectangle.
	 */
	public var top(get, set):Float;
	
	/**
	 * The y coordinate of the bottom of the rectangle.
	 */
	public var bottom(get, set):Float;
	
	private var _weak:Bool = false;
	private var _inPool:Bool = false;
	
	public function new(X:Float = 0, Y:Float = 0, Width:Float = 0, Height:Float = 0)
	{
		set(X, Y, Width, Height);
	}
	
	/**
	 * Add this FlxRect to the recycling pool.
	 */
	public inline function put():Void
	{
		if (!_inPool)
		{
			_inPool = true;
			_pool.putUnsafe(this);
		}
	}
	
	/**
	 * Add this FlxPoint to the recycling pool if it's a weak reference (allocated via weak()).
	 */
	public inline function putWeak():Void
	{
		if (_weak)
		{
			_pool.put(this);
		}
	}
	
	/**
	 * Shortcut for setting both width and Height.
	 * 
	 * @param	Width	The new sprite width.
	 * @param	Height	The new sprite height.
	 */
	public inline function setSize(Width:Float, Height:Float):FlxRect
	{
		width = Width;
		height = Height;
		return this;
	}
	
	/**
	 * Fill this rectangle with the data provided.
	 * 
	 * @param	X		The X-coordinate of the point in space.
	 * @param	Y		The Y-coordinate of the point in space.
	 * @param	Width	Desired width of the rectangle.
	 * @param	Height	Desired height of the rectangle.
	 * @return	A reference to itself.
	 */
	public inline function set(X:Float = 0, Y:Float = 0, Width:Float = 0, Height:Float = 0):FlxRect
	{
		x = X;
		y = Y;
		width = Width;
		height = Height;
		return this;
	}

	/**
	 * Helper function, just copies the values from the specified rectangle.
	 * 
	 * @param	Rect	Any FlxRect.
	 * @return	A reference to itself.
	 */
	public inline function copyFrom(Rect:FlxRect):FlxRect
	{
		x = Rect.x;
		y = Rect.y;
		width = Rect.width;
		height = Rect.height;
		return this;
	}
	
	/**
	 * Helper function, just copies the values from this rectangle to the specified rectangle.
	 * 
	 * @param	Point	Any FlxRect.
	 * @return	A reference to the altered rectangle parameter.
	 */
	public inline function copyTo(Rect:FlxRect):FlxRect
	{
		Rect.x = x;
		Rect.y = y;
		Rect.width = width;
		Rect.height = height;
		return Rect;
	}
	
	/**
	 * Helper function, just copies the values from the specified Flash rectangle.
	 * 
	 * @param	FlashRect	Any Rectangle.
	 * @return	A reference to itself.
	 */
	public inline function copyFromFlash(FlashRect:Rectangle):FlxRect
	{
		x = FlashRect.x;
		y = FlashRect.y;
		width = FlashRect.width;
		height = FlashRect.height;
		return this;
	}
	
	/**
	 * Helper function, just copies the values from this rectangle to the specified Flash rectangle.
	 * 
	 * @param	Point	Any Rectangle.
	 * @return	A reference to the altered rectangle parameter.
	 */
	public inline function copyToFlash(FlashRect:Rectangle):Rectangle
	{
		FlashRect.x = x;
		FlashRect.y = y;
		FlashRect.width = width;
		FlashRect.height = height;
		return FlashRect;
	}
	
	/**
	 * Checks to see if some FlxRect object overlaps this FlxRect object.
	 * 
	 * @param	Rect	The rectangle being tested.
	 * @return	Whether or not the two rectangles overlap.
	 */
	public inline function overlaps(Rect:FlxRect):Bool
	{
		return (Rect.x + Rect.width > x) && (Rect.x < x + width) && (Rect.y + Rect.height > y) && (Rect.y < y + height);
	}
	
	/**
	 * Returns true if this FlxRect contains the FlxPoint
	 * 
	 * @param	Point	The FlxPoint to check
	 * @return	True if the FlxPoint is within this FlxRect, otherwise false
	 */
	public inline function containsFlxPoint(Point:FlxPoint):Bool
	{
		return FlxMath.pointInFlxRect(Point.x, Point.y, this);
	}
	
	/**
	 * Add another rectangle to this one by filling in the 
	 * horizontal and vertical space between the two rectangles.
	 * 
	 * @param	Rect	The second FlxRect to add to this one
	 * @return	The changed FlxRect
	 */
	public inline function union(Rect:FlxRect):FlxRect
	{
		var minX:Float = Math.min(x, Rect.x);
		var minY:Float = Math.min(y, Rect.y);
		var maxX:Float = Math.max(right, Rect.right);
		var maxY:Float = Math.max(bottom, Rect.bottom);
		
		return set(minX, minY, maxX - minX, maxY - minY);
	}
	
	/**
	 * Rounds x, y, width and height using Math.floor()
	 */
	public inline function floor():FlxRect
	{
		x = Math.floor(x);
		y = Math.floor(y);
		width = Math.floor(width);
		height = Math.floor(height);
		return this;
	}
	
	/**
	 * Rounds x, y, width and height using Math.ceil()
	 */
	public inline function ceil():FlxRect
	{
		x = Math.ceil(x);
		y = Math.ceil(y);
		width = Math.ceil(width);
		height = Math.ceil(height);
		return this;
	}
	
	/**
	 * Necessary for IFlxDestroyable.
	 */
	public function destroy() {}
	
	/**
	 * Convert object to readable string name. Useful for debugging, save games, etc.
	 */
	public inline function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("x", x),
			LabelValuePair.weak("y", y),
			LabelValuePair.weak("w", width),
			LabelValuePair.weak("h", height)]);
	}
	
	/**
	 * Checks if this rectangle's properties are equal to properties of provided rect.
	 * 
	 * @param	rect	Rectangle to check equality to.
	 * @return	Whether both rectangles are equal.
	 */
	public inline function equals(rect:FlxRect):Bool
	{
		return (this.x == rect.x && this.y == rect.y && this.width == rect.width && this.height == rect.height);
	}
	
	/**
	 * Returns the area of intersection with specified rectangle. 
	 * If the rectangles do not intersect, this method returns an empty rectangle.
	 * 
	 * @param	rect	Rectangle to check intersection againist.
	 * @return	The area of intersection of two rectangles.
	 */
	public function intersection(rect:FlxRect):FlxRect
	{
		var x0:Float = x < rect.x ? rect.x : x;
		var x1:Float = right > rect.right ? rect.right : right;
		if (x1 <= x0) 
		{	
			return new FlxRect();	
		}
		
		var y0:Float = y < rect.y ? rect.y : y;
		var y1:Float = bottom > rect.bottom ? rect.bottom : bottom;
		if (y1 <= y0) 
		{	
			return new FlxRect();	
		}
		
		return new FlxRect(x0, y0, x1 - x0, y1 - y0);
	}
	
	private inline function get_left():Float
	{
		return x;
	}
	
	private inline function set_left(Value:Float):Float
	{
		width -= Value - x;
		return x = Value;
	}
	
	private inline function get_right():Float
	{
		return x + width;
	}
	
	private inline function set_right(Value:Float):Float
	{
		width = Value - x;
		return Value;
	}
	
	private inline function get_top():Float
	{
		return y;
	}
	
	private inline function set_top(Value:Float):Float
	{
		height -= Value - y;
		return y = Value;
	}
	
	private inline function get_bottom():Float
	{
		return y + height;
	}
	
	private inline function set_bottom(Value:Float):Float
	{
		height = Value - y;
		return Value;
	}
}