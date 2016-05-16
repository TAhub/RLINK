package game 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Spritemap;
	
	public class Room 
	{
		private static const MAP_EXPLOREDTILLGUIDE:Number = 0.5;
		public static const MAP_TILESIZE:uint = 40;
		private static const MAP_RANDM:uint = 16777216;
		private static const MAP_RANDA:uint = 1140671485;
		private static const MAP_RANDC:uint = 12820163;
		private static const MAP_OBSTACLETRIES:uint = 100;
		
		public var exitFlashE:uint;
		public var exitFlash:Number;
		private static const MAP_EXITFLASHLENGTH:Number = 1.2;
		
		public var explored:Boolean;
		public var exit:Point;
		public var num:uint;
		public var dimensions:Rectangle;
		public var obstacles:Vector.<uint>;
		public var type:uint;
		public var connections:Vector.<Array>;
		public var creatures:Vector.<Creature>;
		public var items:Vector.<Array>;
		
		public function save(c:Vector.<uint>):void
		{
			c.push(num);
			c.push(type);
			if (explored)
				c.push(1);
			else
				c.push(0);
			c.push(dimensions.x + Database.NONE);
			c.push(dimensions.y + Database.NONE);
			c.push(dimensions.width);
			c.push(dimensions.height);
			if (exit)
			{
				c.push(1);
				c.push(exit.x);
				c.push(exit.y);
			}
			else
				c.push(0);
			
			for (var i:uint = 0; i < dimensions.width * dimensions.height; i++)
			{
				c.push(obstacles[i]);
				
				if (!items[i])
					c.push(0);
				else
					inventorySave(items[i], c);
			}
			
			c.push(connections.length);
			for (i = 0; i < connections.length; i++)
			{
				c.push(connections[i][1].x + 10);
				c.push(connections[i][1].y + 10);
			}
		}
		
		public function load(c:Vector.<uint>, iOn:uint):uint
		{
			num = c[iOn++];
			type = c[iOn++];
			explored = c[iOn++] == 1;
			dimensions.x = c[iOn++] - Database.NONE;
			dimensions.y = c[iOn++] - Database.NONE;
			dimensions.width = c[iOn++];
			dimensions.height = c[iOn++];
			if (c[iOn++] == 1)
				exit = new Point(c[iOn++], c[iOn++]);
			
			obstacles = new Vector.<uint>();
			creatures = new Vector.<Creature>();
			items = new Vector.<Array>();
			for (var i:uint = 0; i < dimensions.width * dimensions.height; i++)
			{
				obstacles.push(c[iOn++]);
				creatures.push(null);
				
				var iA:Array = new Array();
				iOn = inventoryLoad(iA, c, iOn);
				if (iA.length == 0)
					items.push(null);
				else
					items.push(iA);
			}
			
			var nC:uint = c[iOn++];
			for (i = 0; i < nC; i++)
			{
				var cn:Array = new Array();
				cn.push(null);
				cn.push(new Point(c[iOn++] - 10, c[iOn++] - 10));
				connections.push(cn);
			}
			
			return iOn;
		}
		
		public static function inventorySave(inv:Array, c:Vector.<uint>):void
		{
			c.push(inv.length / 3);
			for (var j:uint = 0; j < inv.length / 3; j++)
			{
				c.push(inv[j * 3 + 2]);
				c.push(inv[j * 3 + 1]);
				
				switch(inv[j * 3 + 2])
				{
				case Player.INVENTORY_ITEM:
					c.push(inv[j * 3]);
					break;
				case Player.INVENTORY_WEAPON:
				case Player.INVENTORY_ARMOR:
					var e:Equipment = inv[j * 3];
					c.push(e.id);
					c.push(e.material);
					c.push(e.enchantment);
					c.push(e.damage);
					break;
				}
			}
		}
		
		public static function inventoryLoad(inv:Array, c:Vector.<uint>, iOn:uint):uint
		{
			var iL:uint = c[iOn++];
			for (var j:uint = 0; j < iL; j++)
			{
				var type:uint = c[iOn++];
				var num:uint = c[iOn++];
				
				switch(type)
				{
				case Player.INVENTORY_ITEM:
					inv.push(c[iOn++]);
					break;
				case Player.INVENTORY_WEAPON:
				case Player.INVENTORY_ARMOR:
					var e:Equipment = new Equipment(c[iOn++], c[iOn++], c[iOn++]);
					e.damage = c[iOn++];
					inv.push(e);
					break;
				}
				
				inv.push(num);
				inv.push(type);
			}
			return iOn;
		}
		
		public function Room(_type:uint, _num:uint) 
		{
			num = _num;
			type = _type;
			connections = new Vector.<Array>();
			dimensions = new Rectangle();
			exitFlash = 0;
			exitFlashE = Database.NONE;
			explored = false;
		}
		
		public function get containsBoss():Boolean
		{
			for (var i:uint = 0; i < creatures.length; i++)
				if (creatures[i] && creatures[i].boss)
					return true;
			return false;
		}
		
		public function get numRetreatAllies():uint
		{
			var n:uint = 0;
			for (var i:uint = 0; i < creatures.length; i++)
				if (creatures[i] && creatures[i].retreatAlly)
					n += 1;
			return n;
		}
		
		public function playerEnterRoom(ref:Creature):void
		{
			explored = true;
			exitFlash = MAP_EXITFLASHLENGTH;
			
			if (exitFlashE == Database.NONE && (FP.world as Map).exitRoom != this && ((ref as Player).relic == 0 || (FP.world as Map).exploredPercent >= MAP_EXPLOREDTILLGUIDE))
			{
				var path:Vector.<Room> = ref.pathToRoom((FP.world as Map).exitRoom);
				var nR:Room = path[path.length - 2];
				for (var i:uint = 0; i < connections.length; i++)
					if (connections[i][0] == nR)
					{
						exitFlashE = i;
						break;
					}
			}
		}
		
		public static function inventoryMergeAdd(inv:Array, id:*, num:uint, type:uint, maxSize:uint = 0):void
		{
			if (type == Player.INVENTORY_ITEM)
				for (var i:uint = 0; i < inv.length / 3; i++)
					if (inv[i * 3] == id)
					{
						inv[i * 3 + 1] += num;
						return;
					}
			if (maxSize != 0 && inv.length == maxSize * 3)
				return;
			inv.push(id);
			inv.push(num);
			inv.push(type);
		}
		
		public static function inventoryUseItem(inv:Array, i:uint):Array
		{
			if (inv[i * 3 + 1] > 1)
				inv[i * 3 + 1] -= 1;
			else
			{
				var nI:Array = new Array();
				for (var j:uint = 0; j < inv.length / 3; j++)
					if (i != j)
					{
						nI.push(inv[j * 3]);
						nI.push(inv[j * 3 + 1]);
						nI.push(inv[j * 3 + 2]);
					}
				return nI;
			}
			return inv;
		}
		
		public function dropItemRandom(id:*, num:uint, type:uint):void
		{
			while (true)
			{
				var x:uint = Math.random() * dimensions.width;
				var y:uint = Math.random() * dimensions.height;
				if (!solid(x, y))
				{
					dropItem(x, y, id, num, type);
					return;
				}
			}
		}
		
		public function dropItem(x:uint, y:uint, id:*, num:uint, type:uint):void
		{
			var i:uint = getI(x, y);
			if (!items[i])
				items[i] = new Array();
			inventoryMergeAdd(items[i], id, num, type);
		}
		
		public function initializeContents(placeExit:Boolean):void
		{
			creatures = new Vector.<Creature>();
			obstacles = new Vector.<uint>();
			items = new Vector.<Array>();
			for (var i:uint = 0; i < dimensions.width * dimensions.height; i++)
			{
				obstacles.push(Database.NONE);
				creatures.push(null);
				items.push(null);
			}
			
			if (placeExit)
			{
				//the exit just goes in the center
				exit = new Point(Math.floor(dimensions.width / 2), Math.floor(dimensions.height / 2));
				return;
			}
			
			exit = null;
				
			//place obstacles
			var minOb:uint = Main.data.rooms[type][12];
			var maxOb:uint = Main.data.rooms[type][13];
			var ob:uint = (maxOb - minOb + 1) * Math.random() + minOb;
			var tries:uint = 0;
			for (i = 0; i < ob && tries < MAP_OBSTACLETRIES; tries++)
			{
				//pick a spot
				var x:uint = Math.random() * dimensions.width;
				var y:uint = Math.random() * dimensions.height;
				
				//check the spot
				var valid:Boolean = true;
				var xS:uint = x;
				if (xS > 1)
					xS -= 1;
				var yS:uint = y;
				if (yS > 1)
					yS -= 1;
				for (var y2:uint = yS; valid && y2 <= y + 1 && y2 < dimensions.height; y2++)
					for (var x2:uint = xS; valid && x2 <= x + 1 && x2 < dimensions.width; x2++)
						if (solid(x2, y2))
							valid = false;
							
				if (valid)
				{
					//is it adjacent to an exit?
					for (var j:uint = 0; valid && j < connections.length; j++)
						if (Math.abs(connections[j][1].x - x) + Math.abs(connections[j][1].y - y) <= 1)
							valid = false;
					
					if (valid)
					{
						obstacles[getI(x, y)] = Main.pickFromList(Main.data.rooms[type][11]);
						i++;
					}
				}
			}
		}
		
		public function getI(x:uint, y:uint):uint { return x + dimensions.width * y; }
		public function getX(i:uint):uint { return i % dimensions.width; }
		public function getY(i:uint):uint { return i / dimensions.width; }
		
		public function addConnection(to:Room):void
		{
			var con:Array = new Array();
			con.push(to);
			connections.push(con);
		}
		
		public function absoluteConnection(i:uint):Point
		{
			return new Point(connections[i][1].x + dimensions.x, connections[i][1].y + dimensions.y);
		}
		
		public function connectionPointTo(r:Room):Point
		{
			for (var i:uint = 0; i < connections.length; i++)
				if (connections[i][0] == r)
					return connections[i][1];
			return null;
		}
		
		public function solid(x:uint, y:uint):Boolean
		{
			var i:uint = getI(x, y);
			if (creatures[i] || obstacles[i] != Database.NONE)
				return true;
			return false;
		}
		
		private function appearRNG(r:uint):uint
		{
			return (r * MAP_RANDA + MAP_RANDC) % MAP_RANDM;
		}
		
		private function appearFrame(r:uint, id:uint):uint
		{
			var tileset:uint = Main.data.rooms[type][8];
			var start:uint = Main.data.tilesets[tileset][id];
			var end:uint = Main.data.tilesets[tileset][id + 1];
			return (r % (end - start + 1) + start);
		}
		
		private function cornerRender(ang:uint, corner:Boolean, xFrom:int, yFrom:int, w:int, h:int, r:uint):uint
		{
			var spr:Spritemap = Main.data.spriteSheets[1];
			spr.angle = ang;
			for (var y:int = yFrom; y < yFrom + h; y++)
				for (var x:int = xFrom; x < xFrom + w; x++)
				{
					r = appearRNG(r);
					if (corner)
						spr.frame = appearFrame(r, 3);
					else
						spr.frame = appearFrame(r, 1);
					spr.render(FP.buffer, new Point((dimensions.x + x) * MAP_TILESIZE, (dimensions.y + y) * MAP_TILESIZE), FP.camera);
				}
			return r;
		}
		
		public function render():void
		{
			//seed custom RNG for the appearance
			var r:uint = dimensions.x + dimensions.y;
			
			//set tileset color
			var spr:Spritemap = Main.data.spriteSheets[1];
			spr.color = Main.data.colors[Main.data.rooms[type][9]][1];
			
			r = cornerRender(0, false, 0, -1, dimensions.width, 1, r);
			r = cornerRender(180, false, 1, dimensions.height + 1, dimensions.width, 1, r);
			r = cornerRender(90, false, -1, 1, 1, dimensions.height, r);
			r = cornerRender(270, false, dimensions.width + 1, 0, 1, dimensions.height, r);
			r = cornerRender(0, true, -1, -1, 1, 1, r);
			r = cornerRender(90, true, -1, dimensions.height + 1, 1, 1, r);
			r = cornerRender(180, true, dimensions.width + 1, dimensions.height + 1, 1, 1, r);
			r = cornerRender(270, true, dimensions.width + 1, -1, 1, 1, r);
			
			for (var y:uint = 0; y < dimensions.height; y++)
				for (var x:uint = 0; x < dimensions.width; x++)
				{
					var p:Point = new Point((dimensions.x + x) * MAP_TILESIZE, (dimensions.y + y) * MAP_TILESIZE);
					spr.angle = 0;
					r = appearRNG(r);
					spr.frame = appearFrame(r, 5);
					spr.render(FP.buffer, p, FP.camera);
					
					if (obstacles[getI(x, y)] != Database.NONE || (exit && exit.x == x && exit.y == y))
					{
						//render the obstacle or exit
						if (exit)
							spr.frame = 1;
						else
							spr.frame = obstacles[getI(x, y)];
						spr.render(FP.buffer, p, FP.camera);
					}
				}
			
			//draw doors
			for (var i:uint = 0; i < connections.length; i++)
			{
				p = new Point(connections[i][1].x + dimensions.x, connections[i][1].y + dimensions.y);
				var p2:Point = p.clone();
				if (p.x < dimensions.x)
				{
					spr.angle = 90;
					p.y += 1;
					p2.y += 1;
					p2.x += 1;
				}
				else if (p.y < dimensions.y)
				{
					spr.angle = 0;
					p2.y += 1;
				}
				else if (p.x >= dimensions.x + dimensions.width)
				{
					spr.angle = 270;
					p.x += 1;
				}
				else
				{
					spr.angle = 180;
					p.x += 1;
					p.y += 1;
					p2.x += 1;
				}
				p.x *= MAP_TILESIZE;
				p.y *= MAP_TILESIZE;
				p2.x *= MAP_TILESIZE;
				p2.y *= MAP_TILESIZE;
				var doorRT:uint;
				if (connections[i][0].leaf)
					doorRT = connections[i][0].type;
				else if (leaf)
					doorRT = type;
				else if (num > connections[i][0].num)
					doorRT = type;
				else
					doorRT = connections[i][0].type;
				spr.color = Main.data.colors[Main.data.rooms[doorRT][9]][1];
				if (exitFlash > 0 && i == exitFlashE)
					spr.color = FP.colorLerp(spr.color, 0xFFFFFF, exitFlash / MAP_EXITFLASHLENGTH);
				spr.frame = Main.data.rooms[doorRT][10];
				spr.render(FP.buffer, p, FP.camera);
				spr.frame = 0;
				spr.render(FP.buffer, p2, FP.camera);
			}
			
			for (i = 0; i < creatures.length; i++)
			{
				if (creatures[i])
					creatures[i].render();
				else if (items[i])
				{
					//render an item
					var sprI:Spritemap = Main.data.spriteSheets[3];
					switch(items[i][items[i].length - 1])
					{
					case Player.INVENTORY_ITEM:
						var ii:uint = items[i][items[i].length - 3];
						sprI.frame = Main.data.items[ii][5];
						sprI.color = Main.data.colors[Main.data.items[ii][6]][1];
						break;
					case Player.INVENTORY_WEAPON:
						var iW:Equipment = items[i][items[i].length - 3];
						sprI.frame = iW.weaponItFrame;
						sprI.color = iW.materialColor;
						break;
					case Player.INVENTORY_ARMOR:
						var iA:Equipment = items[i][items[i].length - 3];
						sprI.frame = iA.armorItFrame;
						sprI.color = iA.materialColor;
						break;
					}
					sprI.render(FP.buffer, new Point((getX(i) + dimensions.x + 0.5) * MAP_TILESIZE,
								(getY(i) + dimensions.y + 0.5) * MAP_TILESIZE), FP.camera);
				}
			}
			
			for (i = 0; i < creatures.length; i++)
				if (creatures[i])
					creatures[i].attackRender();
		}
		
		private function tileOnscreen(p:Point):Boolean
		{
			return new Rectangle(FP.camera.x, FP.camera.y, FP.width, FP.height).contains(
				(p.x + dimensions.x) * MAP_TILESIZE, (p.y + dimensions.y) * MAP_TILESIZE);
		}
		
		public function update():void
		{
			if (exitFlash > 0 && exitFlashE != Database.NONE && tileOnscreen(connections[exitFlashE][1]))
				exitFlash -= FP.elapsed;
		}
		
		public function registerCreatures(list:Vector.<Creature>):void
		{
			for (var i:uint = 0; i < creatures.length; i++)
				if (creatures[i])
					list.push(creatures[i]);
		}
		
		public function get leaf():Boolean { return connections.length == 1; }
	}

}