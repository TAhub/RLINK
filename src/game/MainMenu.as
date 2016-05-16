package game 
{
	import flash.geom.Point;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.World;
	import flash.net.SharedObject;
	import net.flashpunk.FP;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	
	public class MainMenu extends World
	{
		public static const HALLSIZE:uint = 10;
		public static const FAME:String = "/record";
		
		private var hasSave:Boolean;
		private var opOn:uint;
		private var menuOn:uint;
		private var record:Array;
		
		//score screen stuff
		private var score:uint;
		private var name:String;
		private var mes:String;
		private var enc:String;
		
		public function MainMenu(oO:uint = 0, mO:uint = 0, sc:uint = 0, m:String = "", e:String = "") 
		{
			var s:SharedObject = SharedObject.getLocal(Map.SAVE);
			hasSave = s.data.contents != null;
			s.close();
			
			opOn = oO;
			menuOn = mO;
			score = sc;
			name = "";
			mes = m;
			enc = e;
			Input.keyString = "";
		}
		
		public function saveScore():void
		{
			var s:SharedObject = SharedObject.getLocal(MainMenu.FAME);
			if (!s.data.strings)
			{
				s.data.scores = new Vector.<uint>();
				s.data.strings = new Array();
			}
			var records:Array = s.data.strings;
			var scores:Vector.<uint> = s.data.scores;
			
			var beforeRecords:Vector.<String> = new Vector.<String>();
			var afterRecords:Vector.<String> = new Vector.<String>();
			var beforeScores:Vector.<uint> = new Vector.<uint>();
			var afterScores:Vector.<uint> = new Vector.<uint>();
			
			//find out the records that are higher than the score
			for (var i:uint = 0; i < scores.length; i++)
			{
				if (scores[i] >= score)
				{
					beforeRecords.push(records[i]);
					beforeScores.push(scores[i]);
				}
				else
				{
					afterRecords.push(records[i]);
					afterScores.push(scores[i]);
				}
			}
			
			scores = new Vector.<uint>();
			records = new Array();
			for (i = 0; i < beforeScores.length && scores.length < MainMenu.HALLSIZE; i++)
			{
				scores.push(beforeScores[i]);
				records.push(beforeRecords[i]);
			}
			if (scores.length < MainMenu.HALLSIZE)
			{
				scores.push(score);
				records.push(name + mes);
			}
			for (i = 0; i < afterScores.length && scores.length < MainMenu.HALLSIZE; i++)
			{
				scores.push(afterScores[i]);
				records.push(afterRecords[i]);
			}
			s.data.scores = scores;
			s.data.strings = records;
			
			trace(name + mes);
			trace(records);
			
			s.close();
		}
		
		public override function render():void
		{
			switch(menuOn)
			{
			case 0:
				renderT(0, 3, true, "New Game");
				renderT(1, 3, hasSave, "Continue");
				renderT(2, 3, true, "Hall of Fame");
				break;
			case 1:
				renderT(0, HALLSIZE + 1, true, "Hall of Fame:");
				for (var i:uint = 0; i < HALLSIZE; i++)
				{
					var s:String;
					if (i < record.length)
						s = record[i];
					else
						s = "";
					renderT(i + 1, 10, true, s);
				}
				break;
			case 2:
				renderT(0, 2, true, enc + "\nEnter your name: " + name);
				renderT(1, 2, name.length > 0, "Submit score?");
				break;
			}
		}
		
		private function renderT(i:uint, maxI:uint, valid:Boolean, text:String):void
		{
			var t:Text = new Text(text);
			if (i != opOn)
				t.color = Player.INTER_UNSELECTEDC;
			else if (!valid)
				t.color = Player.INTER_INVALIDC;
			else
				t.color = Player.INTER_SELECTEDC;
			t.render(FP.buffer, new Point(FP.halfWidth - t.width / 2, FP.height * (i + 0.5) / maxI - t.height / 2), FP.zero);
		}
		
		public override function update():void
		{
			switch(menuOn)
			{
			case 0:
				if (Input.pressed(Key.ENTER))
					switch(opOn)
					{
					case 0:
						if (hasSave)
						{
							//clear the save
							var s:SharedObject = SharedObject.getLocal(Map.SAVE);
							s.data.contents = null;
							s.close();
						}
						FP.world = new CharacterCreator();
						break;
					case 1:
						if (hasSave)
							FP.world = new Map(Database.NONE, 0);
						break;
					case 2:
						menuOn = 1;
						opOn = 0;
						
						s = SharedObject.getLocal(FAME);
						record = s.data.strings;
						if (!record)
							record = new Array();
						s.close();
						break;
					}
				else
				{
					var mA:int = 0;
					if (Input.pressed(Key.W))
						mA -= 1;
					if (Input.pressed(Key.S))
						mA += 1;
						
					opOn = (3 + opOn + mA) % 3;
				}
				break;
			case 1:
				if (Input.pressed(Key.ENTER))
				{
					record = null;
					menuOn = 0;
				}
				break;
			case 2:
				if (Input.pressed(Key.ENTER) && name.length > 0)
				{
					saveScore();
					menuOn = 0;
					opOn = 0;
				}
				else if (Input.pressed(Key.ESCAPE))
				{
					menuOn = 0;
					opOn = 0;
				}
				else
				{
					var n:String = "";
					for (var i:uint = 0; i < Input.keyString.length && n.length < 15; i++)
					{
						var cc:uint = Input.keyString.charCodeAt(i);
						if (cc == " ".charCodeAt(0) ||
							(cc >= "A".charCodeAt(0) && cc <= "Z".charCodeAt(0)) ||
							(cc >= "a".charCodeAt(0) && cc <= "z".charCodeAt(0)))
							n += Input.keyString.charAt(i);
					}
					name = Input.keyString;
				}
				break;
			}
		}
	}

}