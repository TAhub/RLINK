package game 
{
	import flash.net.SharedObject;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.World;
	import flash.geom.Rectangle;
	import net.flashpunk.FP;
	
	public class Map extends World
	{
		public static const SAVE:String = "/save";
		
		private var icons:Vector.<Icon>;
		private var dnums:Vector.<DNum>;
		private var rooms:Vector.<Room>;
		public var player:Player;
		public var pet:Creature;
		private var creatures:Vector.<Creature>;
		private var expReward:uint;
		public var mapType:uint;
		public var rumble:Number;
		public var blackoutEffect:Number;
		public var teleportEffect:Number;
		public var floorNum:uint;
		
		private static const MGEN_FINALMAP:uint = 25;
		private static const MGEN_LINEARCHANCE:Number = 0.35;
		private static const MGEN_MAXCONNECTIONS:uint = 4;
		private static const MGEN_DOORMARGIN:uint = 1;
		private static const MGEN_DOORSIDEMARGIN:uint = 1;
		private static const MGEN_ENCHANTCHANCE:Number = 0.05;
		
		private static const EFFECT_BLACKOUTLENGTH:Number = 0.7;
		private static const EFFECT_BLACKOUTFADESTART:Number = 0.3;
		private static const EFFECT_TELEPORTLENGTH:Number = 0.5;
		private static const EFFECT_TELEPORTSTART:Number = 0.15;
		
		public function Map(type:uint, num:uint, pl:Player = null, teleport:Boolean = false, pt:Creature = null) 
		{
			//set camera up for camera snap
				FP.camera.x = 0;
				FP.camera.y = 0;
			
			if (type == Database.NONE)
			{
				rumble = 0;
				blackoutEffect = 0;
				teleportEffect = -1;
				load();
			}
			else
			{
				rumble = 0;
				blackoutEffect = 0;
				if (teleport)
					teleportEffect = 0;
				else
					teleportEffect = -1;
				mapType = type;
				floorNum = num;
				
				mapGenerator(pl, pt);
			}
			
			dnums = new Vector.<DNum>();
			icons = new Vector.<Icon>();
		}
		
		public function get exploredPercent():Number
		{
			var eN:uint = 0;
			for (var i:uint = 0; i < rooms.length; i++)
				if (rooms[i].explored)
					eN += 1;
			return (eN / rooms.length);
		}
		public function get exitRoom():Room { return rooms[rooms.length - 1]; }
		
		public override function render():void
		{
			if (rumble > 0)
			{
				FP.camera.x += (Math.random() * 2 - 1) * Creature.ANIM_RUMBLESTRENGTH;
				FP.camera.y += (Math.random() * 2 - 1) * Creature.ANIM_RUMBLESTRENGTH;
			}
			player.playerRender();
			for (var i:uint = 0; i < dnums.length; i++)
				dnums[i].render();
			for (i = 0; i < icons.length; i++)
				icons[i].render();
				
			if (blackoutEffect != -1)
			{
				var bE:Number = 0;
				if (blackoutEffect > EFFECT_BLACKOUTFADESTART)
					bE = (blackoutEffect - EFFECT_BLACKOUTFADESTART) / (EFFECT_BLACKOUTLENGTH - EFFECT_BLACKOUTFADESTART);
				if (bE < 1)
					FP.buffer.colorTransform(FP.buffer.rect, new ColorTransform(bE, bE, bE));
			}
			if (teleportEffect > EFFECT_TELEPORTSTART)
				player.renderTeleport((teleportEffect - EFFECT_TELEPORTSTART) / (EFFECT_TELEPORTLENGTH - EFFECT_TELEPORTSTART));
		}
		
		public function newIcon(x:Number, y:Number, frame:uint):void
		{
			icons.push(new Icon(x - FP.camera.x, y - FP.camera.y, frame));
		}
		
		public function newDNum(x:Number, y:Number, s:String, c:uint):void
		{
			dnums.push(new DNum(x - FP.camera.x, y - FP.camera.y, s, c));
		}
		
		public override function update():void
		{
			if (rumble > 0)
				rumble -= FP.elapsed;
			for (var i:uint = 0; i < rooms.length; i++)
				rooms[i].update();
			for (i = 0; i < creatures.length; i++)
				creatures[i].update();
				
			if (blackoutEffect != -1)
			{
				blackoutEffect += FP.elapsed;
				if (blackoutEffect > EFFECT_BLACKOUTLENGTH)
					blackoutEffect = -1;
			}
			if (teleportEffect != -1)
			{
				teleportEffect += FP.elapsed;
				if (teleportEffect > EFFECT_TELEPORTLENGTH)
					teleportEffect = -1;
			}
			
			//handle damage numbers
			var anyGone:Boolean = false;
			for (i = 0; i < dnums.length; i++)
			{
				dnums[i].update();
				if (dnums[i].dead)
					anyGone = true;
			}
			if (anyGone)
			{
				var ndnums:Vector.<DNum> = new Vector.<DNum>();
				for (i = 0; i < dnums.length; i++)
					if (!dnums[i].dead)
						ndnums.push(dnums[i]);
				dnums = ndnums;
			}
			
			//handle icons
			anyGone = false;
			for (i = 0; i < icons.length; i++)
			{
				icons[i].update();
				if (icons[i].dead)
					anyGone = true;
			}
			if (anyGone)
			{
				var nIcons:Vector.<Icon> = new Vector.<Icon>();
				for (i = 0; i < icons.length; i++)
					if (!icons[i].dead)
						nIcons.push(icons[i]);
				icons = nIcons;
			}
			
			if (dnums.length > 0 || icons.length > 0 || blackoutEffect != -1 || teleportEffect != -1)
				return; //wait until all the dnums, effects, etc are gone to do anything
				
			//see if anyone is animating
			for (i = 0; i < creatures.length; i++)
				if (creatures[i].animating)
					return;
				
			//remove any dead people
			var anyDead:Boolean = false;
			for (i = 0; !anyDead && i < creatures.length; i++)
				if (creatures[i].dead)
					anyDead = true;
			if (anyDead)
			{
				var newC:Vector.<Creature> = new Vector.<Creature>();
				for (i = 0; i < creatures.length; i++)
				{
					if (!creatures[i].dead)
						newC.push(creatures[i]);
					else
					{
						if (creatures[i] == player)
						{
							//handle player death
							player.defeat();
							return;
						}
						else if (creatures[i] == pet)
						{
							creatures[i].die();
							pet = null;
						}
						else
							player.awardEXP(creatures[i].die());
					}
				}
				creatures = newC;
				
				if (finalMap)
				{
					//check for VICTORY!!!!
					var vic:Boolean = true;
					for (i = 0; vic && i < creatures.length; i++)
						if (creatures[i] != player && creatures[i] != pet)
							vic = false;
					if (vic)
					{
						FP.world = new MainMenu(1, 2, player.score, ", a " + player.classInfo + ", defeated the high priest and won!", "You won! Congratulations!"); 
						return;
					}
				}
			}
					
			//handle actual input
			var foundAny:Boolean = false;
			for (i = 0; !foundAny && i < creatures.length; i++)
				if (!creatures[i].turnOver)
				{
					creatures[i].input();
					if (!creatures[i].turnOver || creatures[i].animating)
						foundAny = true; //it only counts if they did SOMETHING their turn
				}
			if (!foundAny)
			{
				//restart everyone's move points
				for (i = 0; i < creatures.length; i++)
					creatures[i].turnStart();
			}
		}
		
		public function deactivateAll():void
		{
			for (var i:uint = 0; i < creatures.length; i++)
				creatures[i].deactivate();
		}
		
		public function roomInView(rm:Room):Boolean
		{
			return player.room == rm;
		}
		
		public function mapTransition(nextMap:Boolean, autoType:Boolean = true, manualType:uint = 0):void
		{
			if (nextMap)
			{
				//award this map's exp
				player.awardEXP(expReward);
				
				//increment depth
				floorNum += 1;
			}
			
			if (autoType)
				FP.world = new Map(Main.pickFromList(Main.data.maps[mapType][9]), floorNum, player, true, pet);
			else
				FP.world = new Map(manualType, floorNum, player, false, pet);
		}
		
		public function addPet(pt:Creature):Boolean
		{
			if (pt.cantPlace)
				return false;
			creatures.push(pt);
			pet = pt;
			return true;
		}
		
		private function load():void
		{
			var l:SharedObject = SharedObject.getLocal(SAVE);
			var c:Vector.<uint> = l.data.contents;
			var iOn:uint = 0;
			mapType = c[iOn++];
			floorNum = c[iOn++];
			var rN:uint = c[iOn++];
			rooms = new Vector.<Room>();
			for (var i:uint = 0; i < rN; i++)
			{
				var rm:Room = new Room(Database.NONE, 0);
				iOn = rm.load(c, iOn);
				for (var j:uint = 0; j < rm.connections.length; j++)
					rm.connections[j][0] = c[iOn++];
				rooms.push(rm);
			}
			//link connections
			for (i = 0; i < rooms.length; i++)
				for (j = 0; j < rooms[i].connections.length; j++)
					rooms[i].connections[j][0] = rooms[rooms[i].connections[j][0]];
			var cN:uint = c[iOn++];
			creatures = new Vector.<Creature>();
			for (i = 0; i < cN; i++)
			{
				//creature #0 is always player
				var p:Boolean = false;
				if (i != 0)
				{
					//creature #1 MIGHT be a pet
					p = c[iOn++] == 1;
				}
				
				var x:uint = c[iOn++];
				var y:uint = c[iOn++];
				var r:Room = rooms[c[iOn++]];
				
				if (i == 0)
				{
					player = new Player(null, 0);
					iOn = player.load(c, iOn);
					player.room = r;
					player.x = x;
					player.y = y;
					player.establishInRoom();
					creatures.push(player);
				}
				else
				{
					var en:Enemy = new Enemy(null, 0, 0);
					iOn = en.load(c, iOn);
					en.room = r;
					en.x = x;
					en.y = y;
					if (p)
						pet = en;
					en.establishInRoom();
					creatures.push(en);
				}
			}
			//link creatures
			for (i = 0; i < creatures.length; i++)
				creatures[i].linkTarget(creatures);
			
			l.data.contents = null;
			l.close();
		}
		
		public function get finalMap():Boolean
		{
			return floorNum == MGEN_FINALMAP;
		}
		
		private function roomNumber(rm:Room):uint
		{
			return rm.num;
			for (var i:uint = 0; i < rooms.length; i++)
				if (rooms[i] == rm)
					return i;
			return 0;
		}
		
		public function save():void
		{
			var s:SharedObject = SharedObject.getLocal(SAVE);
			var c:Vector.<uint> = new Vector.<uint>();
			c.push(mapType);
			c.push(floorNum);
			c.push(rooms.length);
			for (var i:uint = 0; i < rooms.length; i++)
			{
				rooms[i].save(c);
				for (var j:uint = 0; j < rooms[i].connections.length; j++)
					c.push(roomNumber(rooms[i].connections[j][0]));
			}
			c.push(creatures.length);
			for (i = 0; i < creatures.length; i++)
			{
				if (i != 0)
				{
					//is it a pet?
					if (creatures[i] == pet)
						c.push(1);
					else
						c.push(0);
				}
				
				c.push(creatures[i].x);
				c.push(creatures[i].y);
				c.push(roomNumber(creatures[i].room));
				creatures[i].save(c, creatures);
			}
			
			s.data.contents = c;
			s.close();
			FP.world = new MainMenu();
		}
		
		//level generator
		private function mapGenerator(pl:Player, pt:Creature):void
		{
			if (finalMap)
				while (!finalMapGen(pl, pt)) {}
			else
				while (!mapGeneratorOne(pl, pt)) {}
		}
		
		private function finalMapGen(pl:Player, pt:Creature):Boolean
		{
			rooms = new Vector.<Room>();
			rooms.push(new Room(0, 0));
			rooms.push(new Room(0, 1));
			rooms.push(new Room(1, 2));
			rooms[0].dimensions.x = 0;
			rooms[0].dimensions.y = 0;
			rooms[0].dimensions.width = 5;
			rooms[0].dimensions.height = 5;
			rooms[1].dimensions.x = 1;
			rooms[1].dimensions.y = 5;
			rooms[1].dimensions.width = 3;
			rooms[1].dimensions.height = 10;
			rooms[2].dimensions.x = -2;
			rooms[2].dimensions.y = 15;
			rooms[2].dimensions.width = 9;
			rooms[2].dimensions.height = 9;
			rooms[0].addConnection(rooms[1]);
			rooms[0].connections[0].push(new Point(2, 5));
			rooms[1].addConnection(rooms[0]);
			rooms[1].connections[0].push(new Point(1, -1));
			rooms[1].addConnection(rooms[2]);
			rooms[1].connections[1].push(new Point(1, 10));
			rooms[2].addConnection(rooms[1]);
			rooms[2].connections[0].push(new Point(4, -1));
			rooms[0].initializeContents(false);
			rooms[1].initializeContents(false);
			rooms[2].initializeContents(false);
			
			//add the player
			if (pl)
			{
				if (!pl.teleportToRoom(rooms[0]))
					return false; //unable to place player
				player = pl;
			}
			//add the pet
			if (pt)
			{
				if (!pt.teleportToRoom(rooms[0]))
					return false; //unable to place pet
				pet = pt;
				
				//level the pet up
				pt.petLevel();
			}
			else
				pet = null;
				
			
			//TODO: put some trash enemies in the hallway in room #1
			new Enemy(rooms[1], 6, floorNum);
			new Enemy(rooms[1], 6, floorNum);
			
			//TODO: put the final boss in room #2
			new Enemy(rooms[2], 6, floorNum);
			new Enemy(rooms[2], 6, floorNum);
			new Enemy(rooms[2], 7, floorNum, true);
			
				
			registerCreatures();
				
			return true;
		}
		
		private function registerCreatures():void
		{
			creatures = new Vector.<Creature>();
			creatures.push(player);
			if (pet)
				creatures.push(pet);
			for (var i:uint = 1; i < rooms.length; i++)
				rooms[i].registerCreatures(creatures);
		}
		
		private function mapGeneratorOne(pl:Player, pt:Creature):Boolean
		{
			//variables based on map type
			var numRoomsMin:uint = Main.data.maps[mapType][4];
			var numRoomsMax:uint = Main.data.maps[mapType][5];
			var numRooms:uint = (numRoomsMax - numRoomsMin + 1) * Math.random() + numRoomsMin;
			var numEnemies:uint = numRooms * Main.data.maps[mapType][6] * 0.01;
			var numItems:uint = numRooms * Main.data.maps[mapType][7] * 0.01;
			var mainEnemyList:uint = Main.pickFromList(Main.data.maps[mapType][8]);
			expReward = Player.EXP_SKILLSPERFLOOR * Player.EXP_BASE * (1 + Player.EXP_SCALE * (floorNum + 1));
			
			rooms = new Vector.<Room>();
			//place the start room
			rooms.push(new Room(Main.data.maps[mapType][1], 0));
			
			while (rooms.length < numRooms)
			{
				//pick what room to branch off of
				var roomFrom:Room;
				if (rooms.length == 1)
					roomFrom = rooms[0]; //the first new room branches off of the start room
				else
				{
					//every other new room branches off of a room that ISNT the start room
					if (Math.random() < MGEN_LINEARCHANCE)
						roomFrom = rooms[rooms.length - 1]; //so that it isn't too weighted to the beginning
					else
					{
						var r:uint = Math.random() * (rooms.length - 1) + 1;
						roomFrom = rooms[r];
					}
				}
			
				if (roomFrom.connections.length < MGEN_MAXCONNECTIONS)
					mapGeneratorAddRoom(roomFrom, Database.NONE);
			}
			
			//place the end room onto the final room
			mapGeneratorAddRoom(rooms[rooms.length - 1], Main.data.maps[mapType][2]);
			
			//first, pick the room type for all non-leaf rooms
			for (var i:uint = 0; i < rooms.length; i++)
				if (rooms[i].type == Database.NONE && !rooms[i].leaf)
					rooms[i].type = Main.pickFromList(Main.data.maps[mapType][3]);
					
			//next, pick the room type for all leaf rooms
			for (i = 0; i < rooms.length; i++)
				if (rooms[i].type == Database.NONE && rooms[i].leaf)
					rooms[i].type = Main.pickFromList(Main.data.rooms[rooms[i].connections[0][0].type][1]);
					
			//set the dimensions of the rooms
			for (i = 0; i < rooms.length; i++)
				mapGeneratorSetRoomDimensions(rooms[i]);
				
			//set the exit points
			for (i = 0; i < rooms.length; i++)
				if (!mapGeneratorSetConnectionPoints(rooms[i]))
					return false;
					
			//initialize the rooms
			for (i = 0; i < rooms.length; i++)
				rooms[i].initializeContents(i == rooms.length - 1);
					
					
			//add the player
			if (pl)
			{
				if (!pl.teleportToRoom(rooms[0]))
					return false; //unable to place player
				player = pl;
			}
			//add the pet
			if (pt)
			{
				if (!pt.teleportToRoom(rooms[0]))
					return false; //unable to place pet
				pet = pt;
				
				//level the pet up
				pt.petLevel();
			}
			else
				pet = null;
			
			//set up tickets
			var enTickets:Vector.<uint> = new Vector.<uint>();
			var itTickets:Vector.<uint> = new Vector.<uint>();
			for (i = 0; i < rooms.length; i++)
			{
				enTickets.push(Main.data.rooms[rooms[i].type][4]);
				itTickets.push(Main.data.rooms[rooms[i].type][6]);
			}
			
			//handle item tickets
			//do this BEFORE enemies, so that it can place enemies on top of items
			for (i = 0; i < numItems; i++)
			{
				var itemR:Room = ticketHandle(itTickets);
				if (!itemR)
					break; //out of tickets
				else
				{
					//pick an item
					var itemList:uint = Main.data.rooms[itemR.type][7];
					
					if (Math.random() < Main.data.itemLists[itemList][3] * 0.01)
					{
						//equipment
						var eqL:uint = Main.data.itemLists[itemList][2];
						var pick:uint = Math.random() * (Main.data.lists[eqL].length - 1) / 2;
						var eq:Equipment = new Equipment(Main.data.lists[eqL][pick * 2 + 1]);
						if (Main.data.lists[eqL][pick * 2 + 2])
						{
							//its a weapon
							eq.weaponPickMaterial(floorNum);
							if (Math.random() < MGEN_ENCHANTCHANCE)
								eq.weaponPickEnchant();
							eq.weaponSetDamage();
							itemR.dropItemRandom(eq, 1, Player.INVENTORY_WEAPON);
						}
						else
						{
							//it's armor
							eq.armorPickMaterial(floorNum);
							if (Math.random() < MGEN_ENCHANTCHANCE)
								eq.armorPickEnchant();
							eq.armorSetDamage();
							itemR.dropItemRandom(eq, 1, Player.INVENTORY_ARMOR);
						}
					}
					else
					{
						//item
						var itL:uint = Main.data.itemLists[itemList][1];
						pick = Math.random() * (Main.data.lists[itL].length - 1) / 3;
						var minN:uint = Main.data.lists[itL][pick * 3 + 2];
						var maxN:uint = Main.data.lists[itL][pick * 3 + 3];
						var n:uint = (maxN - minN + 1) * Math.random() + minN;
						itemR.dropItemRandom(Main.data.lists[itL][pick * 3 + 1], n, Player.INVENTORY_ITEM);
					}
				}
			}
			
			//handle enemy tickets
			for (i = 0; i < numEnemies; i++)
			{
				var enemyR:Room = ticketHandle(enTickets);
				if (!enemyR)
					break; //out of tickets
				else
				{
					var enemyList:uint = Main.data.rooms[enemyR.type][5];
					if (enemyList == Database.NONE)
						enemyList = mainEnemyList;
					var en:Creature = new Enemy(enemyR, Main.pickFromList(enemyList), floorNum);
					if (en.cantPlace)
						return false; //unable to place enemy
				}
			}
			
			//place a boss
			enemyR = rooms[rooms.length - 1];
			enemyList = Main.data.rooms[enemyR.type][5];
			if (enemyList == Database.NONE)
				enemyList = mainEnemyList;
			enemyList += 1;
			en = new Enemy(enemyR, Main.pickFromList(enemyList), floorNum, true);
			if (en.cantPlace)
				return false; //unable to place enemy
			
			registerCreatures();
				
			//divide exp among enemies
			expReward /= 2;
			for (i = 1; i < creatures.length; i++)
				creatures[i].awardEXP(Math.ceil(expReward / (creatures.length - 1)));
					
			//it was successful
			return true;
		}
		
		private function ticketHandle(tickets:Vector.<uint>):Room
		{
			var totalTickets:uint = 0;
			for (var i:uint = 0; i < tickets.length; i++)
				totalTickets += tickets[i];
				
			if (totalTickets == 0)
				return null;
				
			var pick:int = totalTickets * Math.random();
			for (i = 0; i < tickets.length; i++)
			{
				pick -= tickets[i];
				if (pick < 0)
				{
					tickets[i] -= 1;
					return rooms[i];
				}
			}
			return null;
		}
		
		private function mapGeneratorSetConnectionPoints(rm:Room):Boolean
		{
			for (var i:uint = 0; i < rm.connections.length; i++)
				if (rm.connections[i].length == 1)
				{
					//find a rectangle that expresses the door
					//the rectangle should have an area of 2, and one half of it should be in one room
					//and the other half in the other room
					//this is used to get the positions for the doors links on both ends
					
					var o:Room = rm.connections[i][0];
					var door:Rectangle = rm.dimensions.clone();
					var doorO:Rectangle = o.dimensions.clone();
					door.x -= 1;
					door.y -= 1;
					door.width += 2;
					door.height += 2;
					doorO.x -= 1;
					doorO.y -= 1;
					doorO.width += 2;
					doorO.height += 2;
					door = door.intersection(doorO);
					
					var rawDoorPossibilities:Vector.<Rectangle> = new Vector.<Rectangle>();
					if (door.width > door.height)
						for (var x:uint = door.x + MGEN_DOORSIDEMARGIN; x < door.x + door.width - MGEN_DOORSIDEMARGIN; x++)
							rawDoorPossibilities.push(new Rectangle(x, door.y, 1, door.height));
					else
						for (var y:uint = door.y + MGEN_DOORSIDEMARGIN; y < door.y + door.height - MGEN_DOORSIDEMARGIN; y++)
							rawDoorPossibilities.push(new Rectangle(door.x, y, door.width, 1));
					
					//remove doors that are adjacent to current doors
					var doorPossibilities:Vector.<Rectangle> = new Vector.<Rectangle>();
					for (var j:uint = 0; j < rawDoorPossibilities.length; j++)
					{
						var collide:Boolean = false;
						var dE:Rectangle = rawDoorPossibilities[j].clone();
						dE.x -= MGEN_DOORMARGIN;
						dE.y -= MGEN_DOORMARGIN;
						dE.width += 2 * MGEN_DOORMARGIN;
						dE.height += 2 * MGEN_DOORMARGIN;
						for (var k:uint = 0; !collide && k < rm.connections.length; k++)
							if (rm.connections[k].length > 1 && dE.containsPoint(rm.absoluteConnection(k)))
								collide = true;
						for (k = 0; !collide && k < o.connections.length; k++)
							if (o.connections[k].length > 1 && dE.containsPoint(o.absoluteConnection(k)))
								collide = true;
						if (!collide)
							doorPossibilities.push(rawDoorPossibilities[j]);
					}
							
					if (doorPossibilities.length == 0)
					{
						//trace("Failed to place door.");
						return false; //this map is invalid
					}
						
					var pick:uint = doorPossibilities.length * Math.random();
								
					var d1:Rectangle = rm.dimensions.intersection(doorPossibilities[pick]);
					var d2:Rectangle = o.dimensions.intersection(doorPossibilities[pick]);
					
					rm.connections[i].push(new Point(d2.x - rm.dimensions.x, d2.y - rm.dimensions.y));
					for (j = 0; j < o.connections.length; j++)
						if (o.connections[j][0] == rm)
						{
							o.connections[j].push(new Point(d1.x - o.dimensions.x, d1.y - o.dimensions.y));
							break;
						}
				}
			return true;
		}
		
		private function mapGeneratorSetRoomDimensions(rm:Room):void
		{
			var w:uint = Math.random() * (Main.data.rooms[rm.type][3] - Main.data.rooms[rm.type][2] + 1) + Main.data.rooms[rm.type][2];
			var h:uint = Math.random() * (Main.data.rooms[rm.type][3] - Main.data.rooms[rm.type][2] + 1) + Main.data.rooms[rm.type][2];
			rm.dimensions.width = w;
			rm.dimensions.height = h;
			if (rm == rooms[0])
			{
				//it's at 0, 0
				rm.dimensions.x = 0;
				rm.dimensions.y = 0;
			}
			else
			{
				//it's relative to its first link
				var fr:Room = rm.connections[0][0];
				var x:int = fr.dimensions.x;
				var y:int = fr.dimensions.y;
				if (rm.dimensions.x == -1)
					x -= rm.dimensions.width;
				else if (rm.dimensions.y == -1)
					y -= rm.dimensions.height;
				else if (rm.dimensions.x == 1)
					x += fr.dimensions.width;
				else
					y += fr.dimensions.height;
				rm.dimensions.x = x;
				rm.dimensions.y = y;
			}
		}
		
		private function mapGeneratorAddRoom(addTo:Room, type:uint):void
		{
			var rm:Room = new Room(type, rooms.length);
				
			//now pick a direction
			//for now this is stored in the position variable of the dimension
			var r:uint = Math.random() * 4;
			rm.dimensions.x = 0;
			rm.dimensions.y = 0;
			switch(r)
			{
			case 0:
				rm.dimensions.x = -1;
				break;
			case 1:
				rm.dimensions.x = 1;
				break;
			case 2:
				rm.dimensions.y = -1;
				break;
			case 3:
				rm.dimensions.y = 1;
				break;
			}
			
			//add connections
			rm.addConnection(addTo);
			addTo.addConnection(rm);
			
			rooms.push(rm);
		}
	}

}