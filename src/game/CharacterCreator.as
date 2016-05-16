package game 
{
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import flash.geom.Point;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.World;
	import net.flashpunk.FP;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	
	public class CharacterCreator extends World
	{
		private var displayRoom:Room;
		private var pl:Player;
		private var features:Vector.<uint>;
		private var iOn:uint;
		
		public static const SAVE:String = "/lastChar";
		
		public function CharacterCreator() 
		{
			//set up display
			displayRoom = new Room(0, 0);
			displayRoom.dimensions = new Rectangle(0, 0, 1, 1);
			displayRoom.initializeContents(true);
			
			iOn = 0;
			
			//initialize features
			features = new Vector.<uint>();
			
			var s:SharedObject = SharedObject.getLocal(SAVE);
			if (!s.data.features)
			{
				//default values
				features.push(0); //class
				features.push(0); //strength
				features.push(0); //dexterity
				features.push(0); //intelligence
				features.push(0); //gender
				features.push(0); //skin
				features.push(0); //hair
				features.push(0); //hair color
				features.push(0); //relic
				features.push(0); //pet
				features.push(000); //end
			}
			else
				for (var i:uint = 0; i < s.data.features.length; i++)
					features.push(s.data.features[i]); //load features
					
			s.close();
		}
		
		public override function begin():void
		{
			//camera changes before begin wont register
			generatePlayer();
		}
		
		private function generatePlayer():void
		{
			displayRoom.creatures[0] = null;
			pl = new Player(displayRoom, features[0]);
			FP.camera.x = 0;
			FP.camera.y = 0;
			pl.cameraAdjust(null);
			pl.applyFeatures(features);
		}
		
		private function get remainingPoints():int
		{
			return 12 - pointCost(1) - pointCost(2) - pointCost(3);
		}
		
		private function pointCost(i:uint):uint
		{
			var p:uint = 0;
			for (var j:uint = 0; j < features[i]; j++)
			{
				if (j < 6)
					p += 1;
				else
					p += 2;
			}
			return p;
		}
		
		private function get numPets():uint
		{
			for (var i:uint = 0; i < Main.data.creatures.length; i++)
				if (Main.data.creatures[Main.data.creatures.length - i - 1][7] != 4)
					return i;
			return 0;
		}
		
		private function get numClasses():uint
		{
			for (var i:uint = 0; i < Main.data.creatures.length; i++)
				if (Main.data.creatures[i][7] != 4)
					return i;
			return 0;
		}
		
		private function get playerPackage():Array
		{
			return Main.data.playerPackages[Main.data.creatures[features[0]][10]];
		}
		
		private function get playerRace():Array
		{
			return Main.data.races[Main.data.creatures[features[0]][6]];
		}
		
		public override function update():void
		{
			var xA:int = 0;
			var yA:int = 0;
			if (Input.pressed(Key.W))
				yA -= 1;
			if (Input.pressed(Key.S))
				yA += 1;
			if (Input.pressed(Key.A))
				xA -= 1;
			if (Input.pressed(Key.D) || Input.pressed(Key.ENTER))
				xA += 1;
				
			if (xA != 0)
			{
				var max:uint = Database.NONE;
				switch(iOn)
				{
				case 0:
					max = numClasses - 1;
					break;
				case 4:
					max = 1;
					break;
				case 5:
					max = Main.data.lists[playerRace[5]].length - 2;
					break;
				case 6:
					max = Main.data.lists[playerRace[7]].length - 2;
					break;
				case 7:
					max = Main.data.lists[playerRace[6]].length - 2;
					break;
				case 8:
					max = Main.data.relics.length - 1;
					break;
				case 9:
					max = numPets - 1;
					break;
				case 1:
				case 2:
				case 3:
					//stat builder
					var oldS:uint = features[iOn];
					if (features[iOn] > 0 || xA > 0)
						features[iOn] += xA;
					if (remainingPoints < 0)
						features[iOn] = oldS;
					break;
				default:
					if (xA == 1)
					{
						if (remainingPoints == 0)
						{
							var pet:Creature = new Enemy(displayRoom, petID, 1);
							FP.world = new Map(1, 1, pl, true, pet);
							
							//save the features
							var s:SharedObject = SharedObject.getLocal(SAVE);
							s.data.features = new Vector.<uint>();
							for (var i:uint = 0; i < features.length; i++)
								s.data.features.push(features[i]);
							s.close();
							return;
						}
						else if (remainingPoints == 12)
						{
							features[1] = 4;
							features[2] = 4;
							features[3] = 4;
						}
					}
					break;
				}
				if (max != Database.NONE)
				{
					if (xA == -1 && features[iOn] == 0)
						features[iOn] = max;
					else if (xA == 1 && features[iOn] == max)
						features[iOn] = 0;
					else
						features[iOn] += xA;
				}
				generatePlayer();
			}
			else if (yA != 0)
			{
				if (yA == -1 && iOn == 0)
					iOn = features.length - 1;
				else if (yA == 1 && iOn == features.length - 1)
					iOn = 0;
				else
					iOn += yA;
			}
		}
		
		private function renderFeature(i:uint):void
		{
			var s:String;
			var cr:Array = Main.data.creatures[features[0]];
			var inv:Boolean = false;
			switch(i)
			{
			case 0:
				s = "Class: " + Main.data.lines[playerPackage[1]];
				break;
			case 1:
				s = "Strength: " + (features[i] + cr[2]);
				break;
			case 2:
				s = "Dexterity: " + (features[i] + cr[3]);
				break;
			case 3:
				s = "Intelligence: " + (features[i] + cr[4]);
				break;
			case 4:
				s = "Gender: " + (features[i] == 0 ? "Male" : "Female");
				break;
			case 5:
				s = "Skin Color: " + (features[i] + 1);
				break;
			case 6:
				s = "Hair Style: " + (features[i] + 1);
				break;
			case 7:
				s = "Hair Color: " + (features[i] + 1);
				break;
			case 8:
				s = "Relic: " + Main.data.lines[Main.data.relics[features[i]][1]];
				break;
			case 9:
				s = "Pet: " + Main.data.lines[Main.data.ais[Main.data.creatures[petID][10]][11]];
				break;
			default:
				s = "Finish";
				inv = remainingPoints != 0;
				break;
			}
			
			var t:Text = new Text(s);
			if (i != iOn)
				t.color = Player.INTER_UNSELECTEDC;
			else if (inv)
				t.color = Player.INTER_INVALIDC;
			else
				t.color = Player.INTER_SELECTEDC;
			t.render(FP.buffer, new Point(0, Player.INTER_TEXTSEP * i), FP.zero);
		}
		
		private function get petID():uint
		{
			return Main.data.creatures.length - features[9] - 1;
		}
		
		public override function render():void
		{
			pl.render();
			
			//render the features
			for (var i:uint = 0; i < features.length; i++)
				renderFeature(i);
				
			var t:Text = new Text("Remaining stat points: " + remainingPoints);
			if (iOn == 1 || iOn == 2 || iOn == 3)
				t.color = Player.INTER_SELECTEDC;
			else
				t.color = Player.INTER_UNSELECTEDC;
			t.render(FP.buffer, new Point(FP.width - t.width, Player.INTER_TEXTSEP), FP.zero);
			
			var s:String = null;
			switch(iOn)
			{
			case 0:
				s = Main.data.lines[Main.data.playerPackages[Main.data.creatures[features[iOn]][10]][1] + 1];
				break;
			case 1:
				s = "Strength allows you to hit harder with most weapons, and take less damage from the attacks of others.";
				break;
			case 2:
				s = "Dexterity determines how accurate you are, and how good you are at dodging.";
				break;
			case 3:
				s = "Intelligence is used in crafting, magic, and makes you level up a little bit faster too.";
				break;
			case 8:
				s = Main.data.lines[Main.data.relics[features[iOn]][1] + 1];
				break;
			case 9:
				s = Main.data.lines[Main.data.ais[Main.data.creatures[petID][10]][11] + 1];
				break;
			default:
				break;
			}
			if (s)
			{
				t = new Text(s, 0, 0, { wordWrap:true, width:FP.halfWidth, height:FP.halfHeight, align:"center" } );
				t.color = Player.INTER_SELECTEDC;
				t.render(FP.buffer, new Point(FP.width / 4, 3 * Player.INTER_TEXTSEP), FP.zero);
			}
		}
	}

}