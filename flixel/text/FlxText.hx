package flixel.text;

import flash.display.BitmapData;
import flash.filters.BitmapFilter;
import flash.geom.ColorTransform;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText.FlxTextFormat;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;
import openfl.Assets;

/**
 * Extends FlxSprite to support rendering text. Can tint, fade, rotate and scale just like a sprite. Doesn't really animate 
 * though, as far as I know. Also does nice pixel-perfect centering on pixel fonts as long as they are only one liners.
 */
class FlxText extends FlxSprite
{
	/**
	 * The text being displayed.
	 */
	public var text(get, set):String;
	
	/**
	 * The size of the text being displayed in pixels.
	 */
	public var size(get, set):Float;
	
	/**
	 * The font used for this text (assuming that it's using embedded font).
	 */
	public var font(get, set):String;
	
	/**
	 * Whether this text field uses an embedded font (by default) or not. 
	 * Read-only - use systemFont to specify a system font to use, which then automatically sets this to false.
	 */
	public var embedded(get, never):Bool;
	
	/**
	 * The system font for this text (not embedded). Setting this sets embedded to false.
	 * Passing an invalid font name (like "" or null) causes a default font to be used. 
	 */
	public var systemFont(get, set):String;
	
	/**
	 * Whether to use bold text or not (false by default).
	 */
	public var bold(get, set):Bool;
	
	/**
	 * Whether to use italic text or not (false by default). It only works in Flash.
	 */
	public var italic(get, set):Bool;
	
	/**
	 * Whether to use word wrapping and multiline or not (true by default).
	 */
	public var wordWrap(get, set):Bool;
	
	/**
	 * The alignment of the font (LEFT, RIGHT, CENTER or JUSTIFY).
	 */
	public var alignment(get, set):FlxTextAlign;
	
	/**
	 * Use a border style
	 */	
	public var borderStyle(default, set):FlxTextBorderStyle = NONE;
	
	/**
	 * The color of the border in 0xRRGGBB format
	 */	
	public var borderColor(default, set):FlxColor = FlxColor.TRANSPARENT;
	
	/**
	 * The size of the border, in pixels.
	 */
	public var borderSize(default, set):Float = 1;
	
	/**
	 * How many iterations do use when drawing the border. 0: only 1 iteration, 1: one iteration for every pixel in borderSize
	 * A value of 1 will have the best quality for large border sizes, but might reduce performance when changing text. 
	 * NOTE: If the borderSize is 1, borderQuality of 0 or 1 will have the exact same effect (and performance).
	 */
	public var borderQuality(default, set):Float = 1;
	
	/**
	 * Internal reference to a Flash TextField object.
	 */
	public var textField(get, never):TextField;
	
	/**
	 * The width of the TextField object used for bitmap generation for this FlxText object.
	 * Use it when you want to change the visible width of text. Enables autoSize if <= 0.
	 */
	public var fieldWidth(get, set):Float;
	
	/**
	 * Whether the fieldWidth should be determined automatically. Requires wordWrap to be false.
	 */
	public var autoSize(get, set):Bool;
	
	/**
	 * Offset that is applied to the shadow border style, if active. 
	 * x and y are multiplied by borderSize. Default is (1, 1), or lower-right corner.
	 */
	public var shadowOffset(default, null):FlxPoint;
	
	/**
	 * Internal reference to a Flash TextField object.
	 */
	private var _textField:TextField;
	/**
	 * Internal reference to a Flash TextFormat object.
	 */
	private var _defaultFormat:TextFormat;
	/**
	 * Internal reference to another helper Flash TextFormat object.
	 */
	private var _formatAdjusted:TextFormat;
	/**
	 * Internal reference to an Array of FlxTextFormat
	 */
	private var _formats:Array<FlxTextFormat>;
	
	private var _font:String;
	
	/**
	 * Creates a new FlxText object at the specified position.
	 * 
	 * @param   X              The X position of the text.
	 * @param   Y              The Y position of the text.
	 * @param   FieldWidth     The width of the text object. Enables autoSize if <= 0.
	 *                         (height is determined automatically).
	 * @param   Text           The actual text you would like to display initially.
	 * @param   Size           The font size for this text object.
	 * @param   EmbeddedFont   Whether this text field uses embedded fonts or not.
	 */
	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Float = 8, EmbeddedFont:Bool = true)
	{
		super(X, Y);
		
		var setTextEmpty:Bool = false;
		if (Text == null || Text == "")
		{
			// empty texts have a textHeight of 0, need to
			// prevent initialiazing with "" before the first calcFrame() call
			#if flash
			Text = " ";
			#else
			Text = "";
			#end
			setTextEmpty = true;
		}
		
		_textField = new TextField();
		_textField.selectable = false;
		_textField.multiline = true;
		_textField.wordWrap = true;
		_defaultFormat = new TextFormat(null, Size, 0xffffff);
		_formats = new Array<FlxTextFormat>();
		font = FlxAssets.FONT_DEFAULT;
		_formatAdjusted = new TextFormat();
		_textField.defaultTextFormat = _defaultFormat;
		_textField.text = Text;
		fieldWidth = FieldWidth;
		_textField.embedFonts = EmbeddedFont;
		_textField.height = (Text.length <= 0) ? 1 : 10;
		#if flash
		_textField.sharpness = 100;
		#end
		
		allowCollisions = FlxObject.NONE;
		moves = false;
		
		var key:String = FlxG.bitmap.getUniqueKey("text");
		var graphicWidth:Int = (FieldWidth <= 0) ? 1 : Std.int(FieldWidth);
		makeGraphic(graphicWidth, 1, FlxColor.TRANSPARENT, false, key);
		
		#if FLX_RENDER_BLIT 
		calcFrame();
		if (setTextEmpty)
		{
			text = "";
		}
		#else
		if (Text != "")
		{
			calcFrame();
		}
		#end
		
		shadowOffset = FlxPoint.get(1, 1);
	}
	
	/**
	 * Clean up memory.
	 */
	override public function destroy():Void
	{
		shadowOffset = FlxDestroyUtil.put(shadowOffset);
		_textField = null;
		_font = null;
		_defaultFormat = null;
		_formatAdjusted = null;
		
		if (_formats != null)
		{
			for (format in _formats)
			{
				if (format != null)
				{
					format.destroy();
					format = null;
				}
			}
		}
		
		_formats = null;
		super.destroy();
	}
	
	/**
	 * Adds another format to this FlxText
	 * 
	 * @param	Format	The format to be added.
	 * @param	Start	(Default = -1) The start index of the string where the format will be applied. If greater than -1, this value will override the format.start value.
	 * @param	End		(Default = -1) The end index of the string where the format will be applied. If greater than -1, this value will override the format.start value.
	 */
	public function addFormat(Format:FlxTextFormat, Start:Int = -1, End:Int = -1):Void
	{
		Format.start = (Start > -1) ? Start : Format.start;
		Format.end = (End > -1) ? End : Format.end;
		_formats.push(Format);
		// sort the array using the start value of the format so we can skip formats that can't be applied to the textField
		_formats.sort(function(left:FlxTextFormat, right:FlxTextFormat) { return left.start < right.start ? -1 : 1; } );
		dirty = true;
	}
	
	/**
	 * Removes a specific FlxTextFormat from this text.
	 */
	public inline function removeFormat(Format:FlxTextFormat):Void
	{
		FlxArrayUtil.fastSplice(_formats, Format);
		dirty = true;
	}
	
	/**
	 * Clears all the formats applied.
	 */
	public function clearFormats():Void
	{
		for (format in _formats)
		{
			format = FlxDestroyUtil.destroy(format);
		}
		
		_formats = [];
		updateDefaultFormat();
	}
	
	
	/**
	 * You can use this if you have a lot of text parameters
	 * to set instead of the individual properties.
	 * 
	 * @param	Font			The name of the font face for the text display.
	 * @param	Size			The size of the font (in pixels essentially).
	 * @param	Color			The color of the text in traditional flash 0xRRGGBB format.
	 * @param	Alignment		The desired alignment
	 * @param	BorderStyle		NONE, SHADOW, OUTLINE, or OUTLINE_FAST (use setBorderFormat)
	 * @param	BorderColor 	Int, color for the border, 0xRRGGBB format
	 * @param	EmbeddedFont	Whether this text field uses embedded fonts or not
	 * @return	This FlxText instance (nice for chaining stuff together, if you're into that).
	 */
	public function setFormat(?Font:String, Size:Float = 8, Color:FlxColor = FlxColor.WHITE, ?Alignment:FlxTextAlign, 
		?BorderStyle:FlxTextBorderStyle, BorderColor:FlxColor = FlxColor.TRANSPARENT, Embedded:Bool = true):FlxText
	{
		BorderStyle = (BorderStyle == null) ? NONE : BorderStyle;
		
		if (Embedded)
		{
			font = Font;
		}
		else if (Font != null)
		{
			systemFont = Font;
		}
		
		size = Size;
		color = Color;
		alignment = Alignment;
		setBorderStyle(BorderStyle, BorderColor);
		
		updateDefaultFormat();
		
		return this;
	}
	
	/**
	 * Set border's style (shadow, outline, etc), color, and size all in one go!
	 * 
	 * @param	Style outline style
	 * @param	Color outline color in flash 0xRRGGBB format
	 * @param	Size outline size in pixels
	 * @param	Quality outline quality - # of iterations to use when drawing. 0:just 1, 1:equal number to BorderSize
	 */
	public inline function setBorderStyle(Style:FlxTextBorderStyle, Color:FlxColor = 0, Size:Float = 1, Quality:Float = 1):Void 
	{
		borderStyle = Style;
		borderColor = Color;
		borderSize = Size;
		borderQuality = Quality;
	}
	
	private function set_fieldWidth(value:Float):Float
	{
		if (_textField != null)
		{
			if (value <= 0)
			{
				wordWrap = false;
				autoSize = true;
			}
			else
			{
				_textField.width = value;
			}
			
			dirty = true;
		}
		
		return value;
	}
	
	private function get_fieldWidth():Float
	{
		return (_textField != null) ? _textField.width : 0;
	}
	
	private function set_autoSize(value:Bool):Bool
	{
		if (_textField != null)
		{
			_textField.autoSize = (value) ? TextFieldAutoSize.LEFT : TextFieldAutoSize.NONE;
			dirty = true;
		}
		
		return value;
	}
	
	private function get_autoSize():Bool
	{
		return (_textField != null) ? (_textField.autoSize != TextFieldAutoSize.NONE) : false;
	}
	
	private inline function get_text():String
	{
		return _textField.text;
	}
	
	private function set_text(Text:String):String
	{
		var ot:String = _textField.text;
		_textField.text = Text;
		dirty = (_textField.text != ot) || dirty;
		
		return _textField.text;
	}
	
	private inline function get_size():Float
	{
		return _defaultFormat.size;
	}
	
	private function set_size(Size:Float):Float
	{
		_defaultFormat.size = Size;
		updateDefaultFormat();
		return Size;
	}
	
	override private function set_color(Color:FlxColor):Int
	{
		if (_defaultFormat.color == Color.to24Bit())
		{
			return Color;
		}
		_defaultFormat.color = Color.to24Bit();
		color = Color;
		updateDefaultFormat();
		return Color;
	}
	
	private inline function get_font():String
	{
		return _font;
	}
	
	private function set_font(Font:String):String
	{
		_textField.embedFonts = true;
		
		if (Font != null)
		{
			var newFontName:String = Font;
			if (Assets.exists(Font, AssetType.FONT))
			{
				newFontName = Assets.getFont(Font).fontName;
			}
			
			_defaultFormat.font = newFontName;
		}
		else
		{
			_defaultFormat.font = FlxAssets.FONT_DEFAULT;
		}
		
		updateDefaultFormat();
		return _font = _defaultFormat.font;
	}
	
	private inline function get_embedded():Bool
	{
		return _textField.embedFonts = true;
	}
	
	private inline function get_systemFont():String
	{
		return _defaultFormat.font;
	}
	
	private function set_systemFont(Font:String):String
	{
		_textField.embedFonts = false;
		_defaultFormat.font = Font;
		updateDefaultFormat();
		return Font;
	}
	
	private inline function get_bold():Bool 
	{ 
		return _defaultFormat.bold; 
	}
	
	private function set_bold(value:Bool):Bool
	{
		if (_defaultFormat.bold != value)
		{
			_defaultFormat.bold = value;
			updateDefaultFormat();
		}
		return value;
	}
	
	private inline function get_italic():Bool 
	{ 
		return _defaultFormat.italic; 
	}
	
	private function set_italic(value:Bool):Bool
	{
		if (_defaultFormat.italic != value)
		{
			_defaultFormat.italic = value;
			updateDefaultFormat();
		}
		return value;
	}
	
	private inline function get_wordWrap():Bool 
	{ 
		return _textField.wordWrap; 
	}
	
	private function set_wordWrap(value:Bool):Bool
	{
		if (_textField.wordWrap != value)
		{
			_textField.wordWrap = value;
			dirty = true;
		}
		return value;
	}
	
	private inline function get_alignment():FlxTextAlign
	{
		return cast(_defaultFormat.align, String);
	}
	
	private function set_alignment(Alignment:FlxTextAlign):FlxTextAlign
	{
		_defaultFormat.align = convertTextAlignmentFromString(Alignment);
		updateDefaultFormat();
		return Alignment;
	}
	
	private function set_borderStyle(style:FlxTextBorderStyle):FlxTextBorderStyle
	{		
		if (style != borderStyle)
		{
			borderStyle = style;
			dirty = true;
		}
		
		return borderStyle;
	}
	
	private function set_borderColor(Color:FlxColor):FlxColor
	{
		if (borderColor.to24Bit() != Color.to24Bit() && borderStyle != NONE)
		{
			dirty = true;
		}
		borderColor = Color;
		return Color;
	}
	
	private function set_borderSize(Value:Float):Float
	{
		if (Value != borderSize && borderStyle != NONE)
		{			
			dirty = true;
		}
		borderSize = Value;
		
		return Value;
	}
	
	private function set_borderQuality(Value:Float):Float
	{
		Value = Math.min(1, Math.max(0, Value));
		
		if (Value != borderQuality && borderStyle != NONE)
		{
			dirty = true;
		}
		borderQuality = Value;
		
		return Value;
	}
	
	private function get_textField():TextField 
	{
		return _textField;
	}
	
	override private function set_graphic(Value:FlxGraphic):FlxGraphic 
	{
		var graph:FlxGraphic = super.set_graphic(Value);
		
		if (Value != null)
			Value.destroyOnNoUse = true;
		
		return graph;
	}
	
	override private function updateColorTransform():Void
	{
		if (alpha != 1)
		{
			if (colorTransform == null)
			{
				colorTransform = new ColorTransform(1, 1, 1, alpha);
			}
			else
			{
				colorTransform.alphaMultiplier = alpha;
			}
			useColorTransform = true;
		}
		else
		{
			if (colorTransform != null)
			{
				colorTransform.alphaMultiplier = 1;
			}
			
			useColorTransform = false;
		}
		
		dirty = true;
	}
	
	private function regenGraphics():Void
	{
		var oldWidth:Float = graphic.width;
		var oldHeight:Float = graphic.height;
		
		var newWidth:Float = _textField.width + _widthInc;
		// Account for 2px gutter on top and bottom (that's why there is "+ 4")
		var newHeight:Float = _textField.textHeight + _heightInc + 4;
		
		// prevent text height from shrinking on flash if text == ""
		if (_textField.textHeight == 0) 
		{
			newHeight = oldHeight;
		}
		
		if ((oldWidth != newWidth) || (oldHeight != newHeight))
		{
			// Need to generate a new buffer to store the text graphic
			height = newHeight - _heightInc;
			var key:String = graphic.key;
			FlxG.bitmap.remove(key);
			
			makeGraphic(Std.int(newWidth), Std.int(newHeight), FlxColor.TRANSPARENT, false, key);
			frameHeight = Std.int(height);
			_textField.height = height * 1.2;
			_flashRect.x = 0;
			_flashRect.y = 0;
			_flashRect.width = newWidth;
			_flashRect.height = newHeight;
		}
		// Else just clear the old buffer before redrawing the text
		else
		{
			graphic.bitmap.fillRect(_flashRect, FlxColor.TRANSPARENT);
		}
	}
	
	/**
	 * Internal function to update the current animation frame.
	 * 
	 * @param	RunOnCpp	Whether the frame should also be recalculated if we're on a non-flash target
	 */
	override private function calcFrame(RunOnCpp:Bool = false):Void
	{
		if (_textField == null)
		{
			return;
		}
		
		// TODO: override filters functionality here...
		if (_filters != null)
		{
			_textField.filters = _filters;
		}
		
		regenGraphics();
		
		if ((_textField != null) && (_textField.text != null) && (_textField.text.length > 0))
		{
			// Now that we've cleared a buffer, we need to actually render the text to it
			_formatAdjusted.font   = _defaultFormat.font;
			_formatAdjusted.size   = _defaultFormat.size;
			_formatAdjusted.bold   = _defaultFormat.bold;
			_formatAdjusted.italic = _defaultFormat.italic;
			_formatAdjusted.color  = _defaultFormat.color;
			_formatAdjusted.align  = _defaultFormat.align;
			_matrix.identity();
	
			_matrix.translate(Std.int(0.5 * _widthInc), Std.int(0.5 * _heightInc));
			
			// If it's a single, centered line of text, we center it ourselves so it doesn't blur to hell
			if ((_defaultFormat.align == TextFormatAlign.CENTER) && (_textField.numLines == 1))
			{
				_formatAdjusted.align = TextFormatAlign.LEFT;
				updateFormat(_formatAdjusted);
				
				#if flash
				_matrix.translate(Math.floor((width - _textField.getLineMetrics(0).width) / 2), 0);
				#else
				_matrix.translate(Math.floor((width - _textField.textWidth) / 2), 0);
				#end
			}
			
			applyBorderStyle();
			applyFormats(_formatAdjusted, false);

			//Actually draw the text onto the buffer
			graphic.bitmap.draw(_textField, _matrix);
		}
		
		#if FLX_RENDER_TILE
		if (!RunOnCpp)
		{
			return;
		}
		#end
		
		dirty = true;
		getFlxFrameBitmapData();
	}
	
	private function applyBorderStyle():Void
	{
		var iterations:Int = Std.int(borderSize * borderQuality);
		if (iterations <= 0) 
		{ 
			iterations = 1;
		}
		var delta:Float = borderSize / iterations;
		
		switch (borderStyle)
		{
			case SHADOW:
				//Render a shadow beneath the text
				//(do one lower-right offset draw call)
				applyFormats(_formatAdjusted, true);
				
				for (iter in 0...iterations)
				{
					_matrix.translate(delta, delta);
					graphic.bitmap.draw(_textField, _matrix);
				}
				
				_matrix.translate( -shadowOffset.x * borderSize, -shadowOffset.y * borderSize);
				
			case OUTLINE:
				//Render an outline around the text
				//(do 8 offset draw calls)
				applyFormats(_formatAdjusted, true);
				
				var itd:Float = delta;
				for (iter in 0...iterations)
				{
					_matrix.translate(-itd, -itd);		//upper-left
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(itd, 0);			//upper-middle
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(itd, 0);			//upper-right
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(0, itd);			//middle-right
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(0, itd);			//lower-right
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(-itd, 0);			//lower-middle
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(-itd, 0);			//lower-left
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(0, -itd);			//middle-left
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(itd, 0);			//return to center
					itd += delta;
				}
				
			case OUTLINE_FAST:
				//Render an outline around the text
				//(do 4 diagonal offset draw calls)
				//(this method might not work with certain narrow fonts)
				applyFormats(_formatAdjusted, true);
				
				var itd:Float = delta;
				for (iter in 0...iterations)
				{
					_matrix.translate(-itd, -itd);			//upper-left
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(itd * 2, 0);			//upper-right
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(0, itd * 2);			//lower-right
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate( -itd * 2, 0);			//lower-left
					graphic.bitmap.draw(_textField, _matrix);
					_matrix.translate(itd, -itd);			//return to center
					itd += delta;
				}
				
			case NONE:
		}
	}
	
	private inline function applyFormats(FormatAdjusted:TextFormat, UseBorderColor:Bool = false):Void
	{
		// Apply the default format
		FormatAdjusted.color = UseBorderColor ? borderColor.to24Bit() : _defaultFormat.color;
		updateFormat(FormatAdjusted);
		
		// Apply other formats
		for (format in _formats)
		{
			if (_textField.text.length - 1 < format.start) 
			{
				// we can break safely because the array is ordered by the format start value
				break;
			}
			else 
			{
				FormatAdjusted.font    = format.format.font;
				FormatAdjusted.bold    = format.format.bold;
				FormatAdjusted.italic  = format.format.italic;
				FormatAdjusted.size    = format.format.size;
				FormatAdjusted.color   = UseBorderColor ? format.borderColor.to24Bit() : format.format.color;
			}
			
			_textField.setTextFormat(FormatAdjusted, format.start, Std.int(Math.min(format.end, _textField.text.length)));
		}
	}
	
	/**
	 * A helper function for updating the TextField that we use for rendering.
	 * 
	 * @return	A writable copy of TextField.defaultTextFormat.
	 */
	private function dtfCopy():TextFormat
	{
		var dtf:TextFormat = _textField.defaultTextFormat;
		return new TextFormat(dtf.font, dtf.size, dtf.color, dtf.bold, dtf.italic, dtf.underline, dtf.url, dtf.target, dtf.align);
	}
	
	/**
	 * Method for converting string to TextFormatAlign
	 */
	#if (flash || js)
	private function convertTextAlignmentFromString(StrAlign:FlxTextAlign):TextFormatAlign
	#else
	private function convertTextAlignmentFromString(StrAlign:FlxTextAlign):String
	#end
	{
		return switch (StrAlign)
		{
			case LEFT:
				TextFormatAlign.LEFT;
			case CENTER:
				TextFormatAlign.CENTER;
			case RIGHT:
				TextFormatAlign.RIGHT;
			case JUSTIFY:
				TextFormatAlign.JUSTIFY;
		}
	}
	
	private inline function updateDefaultFormat():Void
	{
		_textField.defaultTextFormat = _defaultFormat;
		updateFormat(_defaultFormat);
		dirty = true;
	}
	
	private inline function updateFormat(Format:TextFormat):Void
	{
		#if !flash
		_textField.setTextFormat(Format, 0, _textField.text.length);
		#else
		_textField.setTextFormat(Format);
		#end
	}
}

class FlxTextFormat implements IFlxDestroyable
{
	/**
	 * The border color if FlxText has a shadow or a border
	 */
	public var borderColor:FlxColor;
	
	/**
	 * The start index of the string where the format will be applied
	 */
	public var start:Int = -1;
	/**
	 * The end index of the string where the format will be applied
	 */
	public var end:Int = -1;
	
	/**
	 * Internal TextFormat
	 */
	public var format(default, null):TextFormat;
	
	/**
	 * @param	FontColor	(Optional) Set the font  color. By default, inherits from the default format.
	 * @param	Bold		(Optional) Set the font to bold. The font must support bold. By default, false. 
	 * @param	Italic		(Optional) Set the font to italics. The font must support italics. Only works in Flash. By default, false.  
	 * @param	BorderColor	(Optional) Set the border color. By default, no border (null).
	 * @param	Start		(Default=-1) The start index of the string where the format will be applied. If not set, the format won't be applied.
	 * @param	End			(Default=-1) The end index of the string where the format will be applied.
	 */
	public function new(?FontColor:FlxColor, ?Bold:Bool, ?Italic:Bool, ?BorderColor:FlxColor, ?Start:Int = -1, ?End:Int = -1)
	{
		format = new TextFormat(null, null, FontColor, Bold, Italic);
		
		if (Start > -1)
		{
			start = Start;
		}
		if (End > -1)
		{
			end = End;
		}
		
		borderColor = BorderColor == null ? FlxColor.TRANSPARENT : BorderColor;
	}
	
	public function destroy():Void
	{
		format = null;
	}
}

enum FlxTextBorderStyle
{
	NONE;
	/**
	 * A simple shadow to the lower-right
	 */
	SHADOW;
	/**
	 * Outline on all 8 sides
	 */
	OUTLINE;
	/**
	 * Outline, optimized using only 4 draw calls. (Might not work for narrow and/or 1-pixel fonts)
	 */
	OUTLINE_FAST;
}

@:enum
abstract FlxTextAlign(String) from String
{
	var LEFT = "left";
	var CENTER = "center";
	var RIGHT = "right";
	var JUSTIFY = "justify";
}
