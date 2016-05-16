package game 
{
	import flash.geom.Point;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Spritemap;
	public class Icon 
	{
		private var p:Point;
		private var d:Point;
		private var life:Number;
		private var frame:uint;
		
		private static const ICON_LIFE:Number = 0.6;
		private static const ICON_FADESTART:Number = 0.4;
		private static const ICON_SPEEDMIN:Number = 65;
		private static const ICON_SPEEDMAX:Number = 90;
		private static const ICON_GRAVITY:Number = -300;
		
		public function Icon(x:Number, y:Number, _frame:uint) 
		{
			p = new Point(x, y);
			d = Point.polar((ICON_SPEEDMAX - ICON_SPEEDMIN) * Math.random() + ICON_SPEEDMIN, Math.random() * Math.PI * 2);
			life = ICON_LIFE;
			frame = _frame;
		}
		
		public function update():void
		{
			life -= FP.elapsed;
			p.x += d.x * FP.elapsed;
			p.y += d.y * FP.elapsed;
			d.y += ICON_GRAVITY * FP.elapsed;
		}
		
		public function get dead():Boolean
		{
			return life <= 0;
		}
		
		public function render():void
		{
			var spr:Spritemap = Main.data.spriteSheets[6];
			spr.frame = frame;
			spr.color = Main.magicColor;
			var a:Number = (life - ICON_FADESTART) / (ICON_LIFE - ICON_FADESTART);
			if (a < 0)
				a = 0;
			a = 1 - a;
			if (a > 0)
			{
				spr.alpha = a;
				spr.render(FP.buffer, p, FP.zero);
			}
		}
	}

}