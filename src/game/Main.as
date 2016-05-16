package game
{
	import net.flashpunk.Engine;
	import net.flashpunk.FP;
	
	public class Main extends Engine
	{
		public static const data:Database = new Database();
		private static var mcCyle:Number;
		private static const MC_COLOR1:uint = 0x8682B7;
		private static const MC_COLOR2:uint = 0xA6A2D7;
		private static const MC_COLOR3:uint = 0x6662F7;
		private static const MC_CYCLESPEED:Number = 3.5;
		
		public function Main() 
		{
			super(800, 600);
			FP.screen.color = 0;
			mcCyle = 0;
			FP.world = new MainMenu();
		}
		
		public override function update():void
		{
			super.update();
			
			mcCyle += FP.elapsed * MC_CYCLESPEED;
			while (mcCyle > 3)
				mcCyle -= 3;
		}
		
		public static function get magicColor():uint
		{
			if (mcCyle < 1)
				return FP.colorLerp(MC_COLOR1, MC_COLOR2, mcCyle);
			else if (mcCyle < 2)
				return FP.colorLerp(MC_COLOR2, MC_COLOR3, mcCyle - 1);
			else
				return FP.colorLerp(MC_COLOR3, MC_COLOR1, mcCyle - 2);
		}
		
		public static function pickFromList(list:uint):uint
		{
			if (list == Database.NONE)
				return Database.NONE;
			var p:uint = Math.random() * (data.lists[list].length - 1) + 1;
			return data.lists[list][p];
		}
	}
	
}