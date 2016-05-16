package game 
{
	import flash.geom.Point;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.FP;
	public class DNum 
	{
		private var t:Text;
		private var p:Point;
		private var life:Number;
		private static const DNUM_SPEED:Number = 25;
		private static const DNUM_LIFE:Number = 0.65;
		
		public function DNum(x:Number, y:Number, s:String, c:uint) 
		{
			t = new Text(s);
			t.color = c;
			t.centerOO();
			life = DNUM_LIFE;
			p = new Point(x, y);
		}
		
		public function update():void
		{
			p.y -= FP.elapsed * DNUM_SPEED;
			life -= FP.elapsed;
		}
		
		public function render():void
		{
			t.render(FP.buffer, p, FP.zero);
		}
		
		public function get dead():Boolean { return life <= 0; }
	}

}