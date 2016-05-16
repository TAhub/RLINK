package game 
{
	import adobe.utils.CustomActions;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Spritemap;
	
	public class Creature 
	{
		private static const ANIM_MOVESPEED:Number = 7.5;
		private static const ANIM_ATTACKSPEED:Number = 4.5;
		private static const ANIM_CAMERASPEED:Number = 1000;
		private static const ANIM_BLENDFADE:Number = 1.5;
		private static const ANIM_FASTWEAPONBONUS:Number = 0.3;
		private static const ANIM_ATTACKMAXBLEND:Number = 0.3;
		private static const ANIM_HITRUMBLE:Number = 0.35;
		public static const ANIM_RUMBLESTRENGTH:uint = 2;
		private static const ANIM_SLIDINGBONUS:Number = 3;
		
		protected static const RULE_PETDEFAULTPEN:uint = 4;
		private static const RULE_RANDOMDAM:Number = 0.05;
		private static const RULE_STATDAM:Number = 0.02;
		private static const RULE_STATDODGE:Number = 0.05;
		private static const RULE_MAXDODGE:Number = 0.9;
		protected static const RULE_STATCRAFT:Number = 0.05;
		protected static const RULE_SKILLCRAFT:Number = 0.15;
		protected static const RULE_STATREPAIR:Number = 0.15;
		private static const RULE_SKILLDODGE:Number = 0.05;
		private static const RULE_SKILLDAM:Number = 0.04;
		private static const RULE_STATSPECIALDAM:Number = 0.015;
		private static const RULE_PLAYERSPECIALRESIST:Number = 0.6;
		private static const RULE_PLAYERARCHERYRESIST:Number = 0.8;
		private static const RULE_EQUIPDROPCHANCE:Number = 0.4;
		private static const RULE_PLAYERDODGEBONUS:Number = 0.15;
		private static const RULE_SOFTCAPMULT:Number = 0.65;
		
		//position
		public var x:uint;
		public var y:uint
		public var room:Room;
		
		//movement
		private var xFrom:uint;
		private var yFrom:uint;
		private var roomFrom:Room;
		private var xTo:uint;
		private var yTo:uint;
		private var roomTo:Room;
		private var movement:Number;
		private var sliding:Boolean;
		
		//attacking
		private var attacking:Number;
		private var special:uint;
		private var attackingTarget:Creature;
		
		//equipment
		protected var weapon:Equipment;
		protected var armor:Equipment;
		
		//stats
		protected var strength:uint;
		protected var dexterity:uint;
		protected var intelligence:uint;
		protected var speed:uint;
		protected var health:uint;
		protected var skills:Vector.<uint>;

		//status effects
		private var slowed:uint;
		private var poisoned:uint;
		private var snared:uint;
		private var speeded:uint;
		private var resistanced:uint;
		private var vanished:uint;
		
		//variables
		protected var currentHealth:uint;
		protected var movementPoints:uint;
		protected var experience:uint;
		
		//appearance and identity
		private var good:Boolean;
		public var boss:Boolean;
		private var race:uint;
		protected var gender:uint;
		protected var skinColor:uint;
		protected var hairColor:uint;
		protected var hair:uint;
		public var mir:Boolean;
		public var faction:uint;
		public var boots:uint;
		private var blendColor:uint;
		private var blend:Number;
		private var rumble:Number;
		
		public function save(c:Vector.<uint>, crs:Vector.<Creature>):void
		{
			//stats stuff
			c.push(experience);
			if (good)
				c.push(1);
			else
				c.push(0);
			if (boss)
				c.push(1);
			else
				c.push(0);
			c.push(strength);
			c.push(dexterity);
			c.push(intelligence);
			c.push(speed);
			c.push(health);
			c.push(faction);
			for (var i:uint = 0; i < skills.length; i++)
				c.push(skills[i]);
			
			//appearance stuff
			if (mir)
				c.push(1);
			else
				c.push(0);
			c.push(race);
			c.push(boots);
			c.push(gender);
			c.push(hair);
			c.push(hairColor);
			c.push(skinColor);
			
			//equipment
			if (weapon)
			{
				c.push(1);
				c.push(weapon.id);
				c.push(weapon.material);
				c.push(weapon.enchantment);
				c.push(weapon.damage);
			}
			else
				c.push(0);
			if (armor)
			{
				c.push(1);
				c.push(armor.id);
				c.push(armor.material);
				c.push(armor.enchantment);
				c.push(armor.damage);
			}
			else
				c.push(0);
			
			//status
			c.push(poisoned);
			c.push(snared);
			c.push(slowed);
			c.push(speeded);
			c.push(resistanced);
			c.push(vanished);
			c.push(currentHealth);
			c.push(movementPoints);
		}
		
		public function linkTarget(crs:Vector.<Creature>):void {}
		
		public function load(c:Vector.<uint>, iOn:uint):uint
		{
			//status stuff
			experience = c[iOn++];
			good = c[iOn++] == 1;
			boss = c[iOn++] == 1;
			strength = c[iOn++];
			dexterity = c[iOn++];
			intelligence = c[iOn++];
			speed = c[iOn++];
			health = c[iOn++];
			faction = c[iOn++];
			skills = new Vector.<uint>();
			for (var i:uint = 0; i < Main.data.skills.length; i++)
				skills.push(c[iOn++]);
				
			//appearance stuff
			mir = c[iOn++] == 1;
			race = c[iOn++];
			boots = c[iOn++];
			gender = c[iOn++];
			hair = c[iOn++];
			hairColor = c[iOn++];
			skinColor = c[iOn++];
			
			//equipment
			if (c[iOn++] == 1)
			{
				weapon = new Equipment(c[iOn++], c[iOn++], c[iOn++]);
				weapon.damage = c[iOn++];
			}
			if (c[iOn++] == 1)
			{
				armor = new Equipment(c[iOn++], c[iOn++], c[iOn++]);
				armor.damage = c[iOn++];
			}
			
			//status
			poisoned = c[iOn++];
			snared = c[iOn++];
			slowed = c[iOn++];
			speeded = c[iOn++];
			resistanced = c[iOn++];
			vanished = c[iOn++];
			currentHealth = c[iOn++];
			movementPoints = c[iOn++];
			
			return iOn;
		}
		
		public function Creature(rm:Room, type:uint, _good:Boolean, floorNum:uint, _boss:Boolean = false) 
		{
			//values everyone has
			experience = 0;
			movement = -1;
			attacking = -1;
			blend = 0;
			rumble = 0;
			
			if (!rm)
				return;
				
			mir = false;
			good = _good;
			boss = _boss;
			
			//pick an open spot in that room
			teleportToRoom(rm);
			
			//stats
			strength = Main.data.creatures[type][2];
			dexterity = Main.data.creatures[type][3];
			intelligence = Main.data.creatures[type][4];
			speed = Main.data.creatures[type][5];
			health = Main.data.creatures[type][1];
			skills = new Vector.<uint>();
			for (var i:uint = 0; i < Main.data.skills.length; i++)
				skills.push(0);
				
			//appearance
			faction = Main.data.creatures[type][7];
			race = Main.data.creatures[type][6];
			boots = Main.data.creatures[type][11];
			if (Main.data.races[race][4] && Math.random() > 0.5)
				gender = 1;
			else
				gender = 0;
			if (Main.data.races[race][7] != Database.NONE)
				hair = Main.pickFromList(Main.data.races[race][7] + gender);
			else
				hair = Database.NONE;
			skinColor = Main.pickFromList(Main.data.races[race][5]);
			if (skinColor != Database.NONE)
				skinColor = Main.data.colors[skinColor][1];
			hairColor = Main.pickFromList(Main.data.races[race][6]);
			if (hairColor != Database.NONE)
				hairColor = Main.data.colors[hairColor][1];
			
			//equipment
			if (Main.data.creatures[type][8] != Database.NONE)
			{
				weapon = new Equipment(Main.data.creatures[type][8]);
				weapon.weaponPickMaterial(floorNum);
				if (boss)
					weapon.weaponPickEnchant();
				if (!good)
					weapon.weaponSetDamageEnemy();
			}
			else
				weapon = null;
			if (Main.data.creatures[type][9] != Database.NONE)
			{
				armor = new Equipment(Main.data.creatures[type][9]);
				armor.armorPickMaterial(floorNum);
				if (boss)
					armor.armorPickEnchant();
				if (!good)
					armor.armorSetDamageEnemy();
			}
			else
				armor = null;
			
			resetStatus();
				
			//variables
			currentHealth = health;
			movementPoints = 0;
		}
		
		public function get retreatAlly():Boolean { return false; }
		
		private function resetStatus():void
		{
			slowed = 0;
			poisoned = 0;
			snared = 0;
			vanished = 0;
			speeded = 0;
			resistanced = 0;
		}
		
		public function get cantPlace():Boolean { return x == Database.NONE && y == Database.NONE; }
		
		protected function get inView():Boolean
		{
			return (FP.world as Map).roomInView(room);
		}
		
		public function petLevel():void
		{
			for (var i:uint = 0; i < skills.length; i++)
				skills[i] += 1;
			currentHealth = health;
		}
		
		public function establishInRoom():void
		{
			room.creatures[room.getI(x, y)] = this;
		}
		
		public function teleportToRoom(rm:Room):Boolean
		{
			resetStatus(); //reset your status
			room = rm;
			var startI:uint = startSpot;
			if (startI == Database.NONE)
			{
				x = Database.NONE;
				y = Database.NONE;
				return false;
			}
			x = room.getX(startI);
			y = room.getY(startI);
			establishInRoom();
			if (good)
				room.explored = true;
			return true;
		}
		
		private function get startSpot():uint
		{
			var validSpots:Vector.<uint> = new Vector.<uint>();
			for (var y:uint = 0; y < room.dimensions.height; y++)
				for (var x:uint = 0; x < room.dimensions.width; x++)
					if (!room.solid(x, y))
						validSpots.push(room.getI(x, y));
			if (validSpots.length == 0)
				return Database.NONE;
			var p:uint = validSpots.length * Math.random();
			return validSpots[p];
		}
		
		public function get dead():Boolean { return currentHealth == 0; }
		public function get turnOver():Boolean { return movementPoints == 0; }
		public function get invisible():Boolean { return vanished > 0; }
		public function turnStart():void
		{
			movementPoints = speed - effectiveArmor.armorSpeedPenalty;
			
			if (slowed > 0)
			{
				statusIcon(0, 1);
				slowed -= 1;
				movementPoints *= Main.data.statuses[0][1] * 0.01;
				if (movementPoints == 0)
					movementPoints = 1;
			}
			
			if (speeded > 0)
			{
				statusIcon(4, 1);
				speeded -= 1;
				movementPoints += Main.data.statuses[4][1];
			}
			
			if (snared > 0)
			{
				statusIcon(2, 1);
				snared -= 1;
				if (movementPoints > 1)
					movementPoints = 1;
			}
			
			if (resistanced > 0)
			{
				statusIcon(3, 1);
				resistanced -= 1;
			}
			
			if (vanished > 0)
			{
				statusIcon(5, 1);
				vanished -= 1;
			}
			
			if (poisoned > 0)
			{
				statusIcon(1, 1);
				poisoned -= 1;
				takeHitInner(Main.data.statuses[1][1]);
			}
		}
		
		public function cameraAdjust(focusC:Creature = null):void
		{
			var dCX:Number;
			var dCY:Number;
			
			//center the camera
			if (room.dimensions.width * Room.MAP_TILESIZE < FP.width)
				dCX = room.dimensions.x * Room.MAP_TILESIZE - (FP.width - room.dimensions.width * Room.MAP_TILESIZE) / 2;
			else
			{
				var cX:Number = drawP.x;
				if (focusC)
					cX = (cX + focusC.drawP.x) / 2;
				dCX = cX - FP.halfWidth;
				var minX:Number = (room.dimensions.x - 1) * Room.MAP_TILESIZE
				var maxX:Number = (room.dimensions.x + room.dimensions.width + 1) * Room.MAP_TILESIZE - FP.width;
				if (dCX < minX)
					dCX = minX;
				else if (dCX > maxX)
					dCX= maxX;
			}
			if (room.dimensions.height * Room.MAP_TILESIZE < FP.height)
				dCY = room.dimensions.y * Room.MAP_TILESIZE - (FP.height - room.dimensions.height * Room.MAP_TILESIZE) / 2;
			else
			{
				var cY:Number = drawP.y;
				if (focusC)
					cY = (cY + focusC.drawP.y) / 2;
				dCY = cY - FP.halfHeight;
				var minY:Number = (room.dimensions.y - 1) * Room.MAP_TILESIZE
				var maxY:Number = (room.dimensions.y + room.dimensions.height + 1) * Room.MAP_TILESIZE - FP.height;
				if (dCY < minY)
					dCY = minY;
				else if (dCY > maxY)
					dCY = maxY;
			}
			
			if (dCX == 0 && dCY == 0)
				dCX = -1; //make sure you don't camera snap by accident
			
			var camDif:Point = new Point(dCX - FP.camera.x, dCY - FP.camera.y);
			if (camDif.length <= ANIM_CAMERASPEED * FP.elapsed || (FP.camera.x == 0 && FP.camera.y == 0))
			{
				FP.camera.x = dCX;
				FP.camera.y = dCY;
			}
			else
			{
				camDif.normalize(ANIM_CAMERASPEED * FP.elapsed);
				FP.camera.x += camDif.x;
				FP.camera.y += camDif.y;
			}
		}
		
		public function playerRender():void
		{
			room.render();
		}
		
		private function get attackAnim():uint
		{
			if (special != Database.NONE)
				return Main.data.specials[special][6];
			else
				return effectiveWeapon.weaponAnim;
		}
		
		private function get hits():uint
		{
			if (special == Database.NONE)
				return effectiveWeapon.weaponHits;
			else
				return Main.data.specials[special][1];
		}
		
		private function get attackAnimSpeed():Number
		{
			if (Main.data.attackAnims[attackAnim][2] != Database.NONE)
			{
				//how far away are they?
				var d:Number = new Point(attackingTarget.drawP.x - drawP.x, attackingTarget.drawP.y - drawP.y).length;
				return Main.data.attackAnims[attackAnim][2] / d;
			}
			else
				return ANIM_ATTACKSPEED * (1 + (hits - 1) * ANIM_FASTWEAPONBONUS);
		}
		
		public function attackRender():void
		{
			if (attacking != -1)
			{
				var aa:Number = attacking;
				while (aa > 1)
					aa -= 1;
				
				var spr:Spritemap = Main.data.spriteSheets[5];
				if (special != Database.NONE)
					spr.color = Main.magicColor;
				else
					spr.color = FP.colorLerp(0xFFFFFF, effectiveWeapon.materialColor, 0.5);
				spr.frame = Main.data.attackAnims[attackAnim][1];
				
				if (special != Database.NONE && Main.data.specials[special][3])
					spr.scale = 1 + aa * aa * 2.5;
				else
					spr.scale = 1;
				
				var p:Point = new Point(attackingTarget.drawP.x - drawP.x, attackingTarget.drawP.y - drawP.y);
				spr.angle = Math.atan2(-p.y, p.x) * 180 / Math.PI;
				p.x *= aa;
				p.y *= aa;
				p.x += drawP.x;
				p.y += drawP.y - spr.height / 4;
				spr.render(FP.buffer, p, FP.camera);
			}
		}
		
		public function get drawP():Point
		{
			var p:Point = new Point(x + room.dimensions.x, y + room.dimensions.y);
			if (movement != -1)
			{
				p.x = (xTo + roomTo.dimensions.x) * movement + (xFrom + roomFrom.dimensions.x) * (1 - movement);
				p.y = (yTo + roomTo.dimensions.y) * movement + (yFrom + roomFrom.dimensions.y) * (1 - movement);
			}
			p.x = (p.x + 0.5) * Room.MAP_TILESIZE;
			p.y = (p.y + 0.5) * Room.MAP_TILESIZE;
			return p;
		}
		
		public function renderTeleport(progress:Number):void
		{
			var tS:uint = progress * 6;
			var spr:Spritemap = Main.data.spriteSheets[4];
			spr.flipped = mir;
			spr.frame = tS;
			spr.color = Main.magicColor;
			var p:Point = drawP;
			spr.render(FP.buffer, p, FP.camera);
			blend = 1;
			blendColor = Database.NONE;
			
			if (spr.frame < 3)
			{
				if (spr.frame == 2)
					spr.frame = 6;
				while (p.y > FP.camera.y)
				{
					p.y -= spr.height;
					spr.render(FP.buffer, p, FP.camera);
				}
			}
		}
		
		private function doBlend(base:uint):uint
		{
			if (blend <= 0)
				return base;
			else
			{
				var c:uint;
				if (blendColor == Database.NONE)
					c = Main.magicColor;
				else
					c = blendColor;
				return FP.colorLerp(base, c, blend);
			}
		}
		
		public function render(relicDraw:uint = 999):void
		{
			if (!good && invisible)
				return;
			
			var p:Point = drawP;
			if (rumble > 0)
			{
				p.x += (Math.random() * 2 - 1) * ANIM_RUMBLESTRENGTH;
				p.y += (Math.random() * 2 - 1) * ANIM_RUMBLESTRENGTH;
			}
			
			var legAdd:uint = 0;
			if (movement != -1 && (movement < 0.5 || sliding || Main.data.races[race][8]))
				legAdd += 1;
			
			var spr:Spritemap = Main.data.spriteSheets[0];
			spr.flipped = mir;
			
			if (invisible)
				spr.alpha = Main.data.statuses[5][1] * 0.01;
			
			if (hair != Database.NONE && Main.data.hairs[hair][3])
			{
				spr.color = doBlend(hairColor);
				spr.frame = Main.data.hairs[hair][1] + 1;
				if (Main.data.hairs[hair][2] && movement != -1)
					spr.frame += 2;
				spr.render(FP.buffer, p, FP.camera);
			}
			
			//legs
			if (Main.data.races[race][2] != Database.NONE)
			{
				spr.color = doBlend(skinColor);
				spr.frame = Main.data.races[race][2] + legAdd;
				spr.render(FP.buffer, p, FP.camera);
			}
			
			if (boots != Database.NONE)
			{
				spr.frame = Main.data.boots[boots][1] + legAdd;
				spr.color = doBlend(Main.data.colors[Main.data.boots[boots][2]][1]);
				spr.render(FP.buffer, p, FP.camera);
			}
			
			if (armor != null && effectiveArmor.armorFrame != Database.NONE)
			{
				spr.color = doBlend(effectiveArmor.materialColor);
				spr.frame = effectiveArmor.armorFrame + 2 + legAdd;
				if (effectiveArmor.armorLegGender)
					spr.frame += 2 * gender;
				spr.render(FP.buffer, p, FP.camera);
			}
			
			//front arm
			if (Main.data.races[race][3] != Database.NONE)
			{
				spr.color = doBlend(skinColor);
				spr.frame = Main.data.races[race][3];
				spr.render(FP.buffer, p, FP.camera);
			}
			
			if (armor != null && effectiveArmor.armorArmFrame != Database.NONE)
			{
				spr.color = doBlend(effectiveArmor.materialColor);
				spr.frame = effectiveArmor.armorArmFrame;
				spr.render(FP.buffer, p, FP.camera);
			}
			
			//body
			if (Main.data.races[race][1] != Database.NONE)
			{
				spr.color = doBlend(skinColor);
				spr.frame = Main.data.races[race][1] + gender
				spr.render(FP.buffer, p, FP.camera);
			}
			
			if (armor != null && effectiveArmor.armorFrame != Database.NONE)
			{
				spr.color = doBlend(effectiveArmor.materialColor);
				spr.frame = effectiveArmor.armorFrame + gender;
				spr.render(FP.buffer, p, FP.camera);
			}
			
			if (relicDraw != 999 && Main.data.relics[relicDraw][2] != Database.NONE)
			{
				spr.frame = Main.data.relics[relicDraw][2];
				spr.color = Main.data.colors[Main.data.relics[relicDraw][3]][1];
				spr.render(FP.buffer, p, FP.camera);
			}
				
			//back arm
			if (Main.data.races[race][3] != Database.NONE)
			{
				spr.color = doBlend(skinColor);
				spr.frame = Main.data.races[race][3] + 1;
				spr.render(FP.buffer, p, FP.camera);
			}
			
			if (armor != null && effectiveArmor.armorArmFrame != Database.NONE)
			{
				spr.color = doBlend(effectiveArmor.materialColor);
				spr.frame = effectiveArmor.armorArmFrame + 1;
				spr.render(FP.buffer, p, FP.camera);
			}
			
			if (hair != Database.NONE)
			{
				spr.color = doBlend(hairColor);
				spr.frame = Main.data.hairs[hair][1];
				if (Main.data.hairs[hair][2] && movement != -1)
				{
					spr.frame += 1;
					if (Main.data.hairs[hair][3])
						spr.frame += 1;
				}
				spr.render(FP.buffer, p, FP.camera);
			}
			
			//weapon
			if (weapon != null && weapon.weaponFrame != Database.NONE)
			{
				var spr2:Spritemap = Main.data.spriteSheets[2];
				spr2.alpha = spr.alpha;
				spr2.flipped = spr.flipped;
				spr2.color = doBlend(weapon.materialColor);
				spr2.frame = weapon.weaponFrame;
				spr2.render(FP.buffer, p, FP.camera);
			}
			
			if (invisible)
				spr.alpha = 1;
		}
		
		protected function get validSpecialTargets():Vector.<Creature>
		{
			return inRangeList(100);
		}
		
		protected function get validTargets():Vector.<Creature>
		{
			return inRangeList(effectiveWeapon.weaponRange);
		}
		
		protected function inRange(cr:Creature):Boolean
		{
			return (getDistanceTo(cr) <= effectiveWeapon.weaponRange);
		}
		
		protected function inRangeList(range:uint, allies:Boolean = false):Vector.<Creature>
		{
			var vt:Vector.<Creature> = new Vector.<Creature>();
			for (var i:uint = 0; i < room.creatures.length; i++)
				if (room.creatures[i])
				{
					if (onSameSide(room.creatures[i]) == allies && !room.creatures[i].invisible &&
						getDistanceTo(room.creatures[i]) <= range)
						vt.push(room.creatures[i]);
				}
			return vt;
		}
		
		private function onSameSide(cr:Creature):Boolean
		{
			return cr.faction == faction;
		}
		
		protected function clearActive():void
		{
			for (var i:uint = 0; i < room.creatures.length; i++)
				if (room.creatures[i] && room.creatures[i] != this)
				{
					//kill the enemy, and remove any reward it might have given you
					room.creatures[i].experience = 0;
					room.creatures[i].currentHealth = 0;
					room.creatures[i] = null;
				}
			(FP.world as Map).deactivateAll();
		}
		
		public function deactivate():void {}
		
		protected function getDistanceTo(cr:Creature):uint
		{
			if (cr.room != room)
				return Database.NONE; //they might as well be on the moon
			else
				return Math.abs(cr.x - x) + Math.abs(cr.y - y);
		}
		
		public function update():void
		{
			if (blend > 0)
				blend -= FP.elapsed * ANIM_BLENDFADE;
				
			if (rumble > 0)
				rumble -= FP.elapsed;
			
			if (attacking != -1)
			{
				blend = attacking;
				if (blend > 1)
					blend = 1;
				if (special != Database.NONE)
					blendColor = Database.NONE;
				else
				{
					blend *= ANIM_ATTACKMAXBLEND;
					blendColor = effectiveWeapon.materialColor;
				}
				
				var oldA:Number = attacking;
				if (!inView)
					attacking = Database.NONE;
				attacking += attackAnimSpeed * FP.elapsed;
				while (oldA < Math.floor(attacking))
				{
					if (Main.data.attackAnims[attackAnim][3])
						(FP.world as Map).rumble = ANIM_HITRUMBLE;
					
					if (special == Database.NONE)
					{
						attackingTarget.takeHit(this);
						oldA += 1;
						if (oldA > hits)
						{
							//break weapons and armor
							if (weapon && weapon.damage > weapon.weaponDurability)
								weapon = null;
							if (attackingTarget.armor && attackingTarget.armor.damage > attackingTarget.armor.armorDurability)
								attackingTarget.armor = null;
							
							//the attack is over
							vanished = 0;
							attacking = -1;
							attackingTarget = null;
							break;
						}
					}
					else
					{
						if (Main.data.specials[special][3])
						{
							//it's an AoE
							if (attackingTarget.y > 0 && room.creatures[room.getI(attackingTarget.x, attackingTarget.y - 1)])
								room.creatures[room.getI(attackingTarget.x, attackingTarget.y - 1)].takeSpecialHit(this);
							if (attackingTarget.x > 0 && room.creatures[room.getI(attackingTarget.x - 1, attackingTarget.y)])
								room.creatures[room.getI(attackingTarget.x - 1, attackingTarget.y)].takeSpecialHit(this);
							if (attackingTarget.y < room.dimensions.height - 1 && room.creatures[room.getI(attackingTarget.x, attackingTarget.y + 1)])
								room.creatures[room.getI(attackingTarget.x, attackingTarget.y + 1)].takeSpecialHit(this);
							if (attackingTarget.y < room.dimensions.width - 1 && room.creatures[room.getI(attackingTarget.x + 1, attackingTarget.y)])
								room.creatures[room.getI(attackingTarget.x + 1, attackingTarget.y)].takeSpecialHit(this);
						}
						attackingTarget.takeSpecialHit(this);
						oldA += 1;
						if (oldA > hits)
						{
							//the attack is over
							vanished = 0;
							attacking = -1;
							attackingTarget = null;
							break;
						}
					}
				}
			}
			if (movement != -1)
			{
				var oldM:Number = movement;
				if (!inView)
					movement = 1;
				var mA:Number = FP.elapsed * ANIM_MOVESPEED;
				if (sliding)
					mA *= ANIM_SLIDINGBONUS;
				movement += mA;
				if (movement > 0.5 && oldM <= 0.5)
				{
					var oR:Room = room;
					
					//be removed from your old room
					if (room.creatures[room.getI(x, y)] == this)
						room.creatures[room.getI(x, y)] = null;
					
					//transfer to the new room
					room = roomTo;
					x = xTo;
					y = yTo;
					
					//be added to your new room
					establishInRoom();
					if (this == (FP.world as Map).player && room != oR)
						room.playerEnterRoom(this);
				}
				if (movement > 1)
				{
					movement = -1;
					roomFrom = null;
					roomTo = null;
				}
			}
		}
		
		public function get healthName():String
		{
			var p:Number = currentHealth / health;
			if (p < 0.25)
				return "near death";
			else if (p < 0.5)
				return "badly injured";
			else if (p < 0.75)
				return "injured";
			else
				return "healthy";
		}
		
		public function input():void { movementPoints = 0; }
		
		private function get effectiveWeapon():Equipment
		{
			if (!weapon)
				return new Equipment(0, 0); //unarmed
			if (weapon.weaponRange > 1 && inRangeList(1).length > 0) //can't properly use a ranged weapon in melee
				return new Equipment(1, weapon.material, weapon.enchantment); //bashing
			return weapon;
		}
		
		private function get effectiveArmor():Equipment
		{
			if (!armor)
				return new Equipment(0, 0); //naked
			return armor;
		}
		
		protected function dnum(s:String):void
		{
			if (inView)
				(FP.world as Map).newDNum(drawP.x, drawP.y - Room.MAP_TILESIZE / 2, s, Player.INTER_SELECTEDC);
		}
		
		private function takeSpecialHit(from:Creature):void
		{
			var damage:Number = Main.data.specials[from.special][2];
			if (damage > 0)
			{
				damage *= (1 + (from.intelligence - intelligence) * RULE_STATSPECIALDAM);
				damage *= (1 + (Math.random() * 2 - 1) * RULE_RANDOMDAM);
				damage *= (1 - effectiveArmor.armorSpecialResistance);
				if (good)
					damage *= RULE_PLAYERSPECIALRESIST;
				if (damage < 1)
					damage = 1;
				var fDam:uint = damage;
				if (damage > fDam && Math.random() < damage - fDam)
					fDam += 1; //rounds randomly (ie so 1.5 ends up as 1 50% of the time, and 2 the other 50% of the time)
					
				takeHitInner(fDam, from);
			}
			
			//status effects, etc
			applyStatus(Main.data.specials[from.special][4], Main.data.specials[from.special][5]);
		}
		
		protected function applyStatus(effect:uint, length:uint):void
		{
			if (effect == Database.NONE)
				return;
			statusIcon(effect, 4);
			switch(effect)
			{
			case 0:
				if (movementPoints > 1)
				{
					movementPoints *= Main.data.statuses[0][1] * 0.01;
					if (movementPoints == 0)
						movementPoints = 1;
				}
				else
					slowed += 1;
				if (length > 1)
					slowed += length - 1;
				break;
			case 1:
				poisoned += length;
				break;
			case 2:
				if (movementPoints > 1)
					movementPoints = 1;
				else
					snared += 1;
				if (length > 1)
					snared += length - 1;
				break;
			case 3:
				resistanced += length;
				break;
			case 4:
				speeded += length;
				movementPoints += Main.data.statuses[4][1];
				break;
			case 5:
				vanished += length;
				break;
			}
		}
		
		public function dodgeChanceFrom(from:Creature):Number
		{
			if (from.invisible)
				return 0;
			var dodgeChance:Number = from.effectiveWeapon.weaponBaseDodge + (dexterity - from.dexterity) * RULE_STATDODGE;
			dodgeChance *= (1 + (skills[0] - from.skills[from.effectiveWeapon.weaponSkill]) * RULE_SKILLDODGE);
			if (good)
				dodgeChance += RULE_PLAYERDODGEBONUS;
			if (dodgeChance > effectiveArmor.armorMaxDodge)
				dodgeChance = effectiveArmor.armorMaxDodge + (dodgeChance - effectiveArmor.armorMaxDodge) * RULE_SOFTCAPMULT;
			if (dodgeChance > RULE_MAXDODGE)
				return RULE_MAXDODGE;
			else
				return dodgeChance;
		}
		
		private function takeHit(from:Creature):void
		{
			//see if you dodged the attack
			if (Math.random() < dodgeChanceFrom(from))
			{
				dnum("miss");
				return;
			}
			
			//how much damage did it do?
			var damage:Number = from.effectiveWeapon.weaponDamage - effectiveArmor.armorDefense;
			if (damage < 1)
				damage = 1; //minimum damage
			
			var dStat:uint;
			if (from.effectiveWeapon.weaponUseDex)
				dStat = from.dexterity;
			else
				dStat = from.strength;
			damage *= (1 + (dStat - strength) * RULE_STATDAM);
			damage *= (1 + from.effectiveWeapon.materialBonus - effectiveArmor.materialBonus);
			damage *= (1 + from.effectiveWeapon.enchantmentBonus - effectiveArmor.enchantmentBonus);
			damage *= (1 + (from.skills[from.effectiveWeapon.weaponSkill] - skills[1]) * RULE_SKILLDAM);
			damage *= (1 + (Math.random() * 2 - 1) * RULE_RANDOMDAM);
			if (from.faction == effectiveArmor.materialBonusFaction)
				damage *= (1 - Equipment.EQUIP_FACTIONBONUS);
			if (from.effectiveWeapon.materialBonusFaction == faction)
				damage *= (1 + Equipment.EQUIP_FACTIONBONUS);
			if (from.effectiveWeapon.weaponRange > 1)
				damage *= (1 - effectiveArmor.armorRangedResistance);
			else
				damage *= (1 - effectiveArmor.armorMeleeResistance);
			if (good && from.effectiveWeapon.weaponRange > 1)
				damage *= RULE_PLAYERARCHERYRESIST;
			
			//round and finalize damage
			if (damage < 1)
				damage = 1;
			var fDam:uint = damage;
			if (damage > fDam && Math.random() < damage - fDam)
				fDam += 1; //rounds randomly (ie so 1.5 ends up as 1 50% of the time, and 2 the other 50% of the time)
				
			//damage weapons and armor
			if (from.weapon && from.weapon.weaponDurability > 0)
				from.weapon.damage += fDam;
			if (armor && armor.armorDurability > 0)
				armor.damage += fDam;
			
			takeHitInner(fDam, from);
			
			//apply weapon status effects
			//this only happens on the first hit, so that fast weapons dont have a higher chance
			if (Math.random() < from.effectiveWeapon.weaponStatusChance / from.hits)
				applyStatus(from.effectiveWeapon.weaponStatus, from.effectiveWeapon.weaponStatusLength);
		}
		
		private function statusIcon(i:uint, num:uint):void
		{
			if (inView)
				for (var j:uint = 0; j < num; j++)
					(FP.world as Map).newIcon(drawP.x, drawP.y, Main.data.statuses[i][2]);
		}
		
		protected function defeatRegister(by:Creature):void {}
		
		protected function takeHitInner(dam:uint, from:Creature = null):void
		{
			//register who hit you, but ONLY if you aren't already dead
			if (currentHealth > 0 && from)
				defeatRegister(from);
			
			dnum("-" + dam);
			
			if (currentHealth > dam)
				currentHealth -= dam;
			else
				currentHealth = 0;
				
			rumble = ANIM_HITRUMBLE;
		}
		
		public function awardEXP(x:uint):void
		{
			if (good)
				x *= (1 + intelligence * Player.EXP_INTBONUS);
			experience += x;
		}
		
		public function die():uint
		{
			if (experience > 0)
			{
				//you only drop loot if you have experience
				//things with no item frame are presumably natural weapons or armor
				//enchanted items are always dropped as loot
				if (weapon && weapon.weaponItFrame != Database.NONE && (weapon.enchanted || Math.random() < RULE_EQUIPDROPCHANCE))
					room.dropItem(x, y, weapon, 1, Player.INVENTORY_WEAPON);
				if (armor && armor.armorItFrame != Database.NONE && (armor.enchanted || Math.random() < RULE_EQUIPDROPCHANCE))
					room.dropItem(x, y, armor, 1, Player.INVENTORY_ARMOR);
				room.dropItem(x, y, Main.data.races[race][9], 1, Player.INVENTORY_ITEM);
			}
			
			room.creatures[room.getI(x, y)] = null; //unregister yourself from the room
			
			//the return value is how much experience the player gets
			return experience;
		}
		
		protected function useSpecial(t:Creature, sp:uint):void
		{
			attack(t);
			special = sp;
		}
		
		protected function attack(t:Creature):void
		{
			attackingTarget = t;
			attacking = 0;
			special = Database.NONE;
			movementPoints = 0;
			
			if (t.x < x)
				mir = false;
			else if (t.x > x)
				mir = true;
		}
		
		public function pathToRoom(r:Room):Vector.<Room>
		{
			var roomPath:Vector.<Room> = new Vector.<Room>();
			if (r != room)
			{
				//find the path, starting at the destination and ending at the start
				pathToRoomRecurse(null, room, r, roomPath);
			}
			else
				roomPath.push(room);
			return roomPath;
		}
		
		private function pathToRoomRecurse(rF:Room, rO:Room, rT:Room, roomPath:Vector.<Room>):Boolean
		{
			//see if any of the immediate children are the destination
			for (var i:uint = 0; i < rO.connections.length; i++)
				if (rO.connections[i][0] == rT)
				{
					roomPath.push(rT);
					roomPath.push(rO);
					return true;
				}
				
			//otherwise, try every child
			for (i = 0; i < rO.connections.length; i++)
				if (rO.connections[i][0] != rF && pathToRoomRecurse(rO, rO.connections[i][0], rT, roomPath))
				{
					roomPath.push(rO);
					return true;
				}
				
			return false;
		}
		
		protected function moveToPerson(cr:Creature):Boolean
		{
			var desiredPoint:uint = Database.NONE;
			if (cr.room == room)
			{
				//find a path to them
				desiredPoint = room.getI(cr.x, cr.y);
			}
			else
			{
				var rP:Vector.<Room> = pathToRoom(cr.room);
				var p:Point = room.connectionPointTo(rP[rP.length - 2]);
				
				//get to exit point p
				if (moveToPersonEMT(p, -1, 0))
					desiredPoint = room.getI(p.x - 1, p.y);
				else if (moveToPersonEMT(p, 1, 0))
					desiredPoint = room.getI(p.x + 1, p.y);
				else if (moveToPersonEMT(p, 0, -1))
					desiredPoint = room.getI(p.x, p.y - 1);
				else if (moveToPersonEMT(p, 0, 1))
					desiredPoint = room.getI(p.x, p.y + 1);
				if (animating) //you did move!
					return true;
				if (desiredPoint == Database.NONE)
					return false; //you weren't moving already, so the doorway must have been blocked
			}
			
			//map out the entire room and figure out what single-point move to make
			var b:Vector.<uint> = new Vector.<uint>();
			var d:Vector.<uint> = new Vector.<uint>();
			var iQ:Vector.<uint> = new Vector.<uint>();
			for (var i:uint = 0; i < room.dimensions.width * room.dimensions.height; i++)
			{
				b.push(Database.NONE);
				d.push(Database.NONE);
			}
			
			d[room.getI(x, y)] = 0;
			iQ.push(room.getI(x, y));
			
			while (iQ.length > 0)
				moveToPersonME(b, d, iQ, desiredPoint);	
			
			var iOn:uint = desiredPoint;
			while (true)
			{
				var newIOn:uint = b[iOn];
				if (newIOn == Database.NONE)
					return false; //you can't get there
				else if (newIOn == room.getI(x, y))
				{
					//you found the path
					var xT:uint = room.getX(iOn);
					var yT:uint = room.getY(iOn);
					move(xT - x, yT - y);
					return true;
				}
				iOn = newIOn;
			}
			return false;
		}
		
		private function moveToPersonME(b:Vector.<uint>, d:Vector.<uint>, iQ:Vector.<uint>, dP:uint):void
		{
			var i:uint = iQ.pop();
			var x:uint = room.getX(i);
			var y:uint = room.getY(i);
			var dis:uint = d[i] + 1;
			
			//do the checks in a random order, to make the enemy a bit more unpredictable
			var jS:uint = Math.random() * 4;
			for (var j:uint = 0; j < 4; j++)
			{
				switch((j + jS) % 4)
				{
				case 0:
					if (x > 0)
						moveToPersonMEO(b, d, iQ, x - 1, y, dis, i, dP);
					break;
				case 1:
					if (x < room.dimensions.width - 1)
						moveToPersonMEO(b, d, iQ, x + 1, y, dis, i, dP);
					break;
				case 2:
					if (y > 0)
						moveToPersonMEO(b, d, iQ, x, y - 1, dis, i, dP);
					break;
				case 3:
					if (y < room.dimensions.height - 1)
						moveToPersonMEO(b, d, iQ, x, y + 1, dis, i, dP);
					break;
				}
			}
		}
		
		private function moveToPersonMEO(b:Vector.<uint>, d:Vector.<uint>, iQ:Vector.<uint>, x:uint, y:uint, dis:uint, fromI:uint, dP:uint):void
		{
			if (d[room.getI(x, y)] <= dis || (room.getI(x, y) != dP && room.solid(x, y)))
				return;
			d[room.getI(x, y)] = dis;
			b[room.getI(x, y)] = fromI;
			iQ.push(room.getI(x, y));
		}
		
		private function moveToPersonEMT(p:Point, xA:int, yA:int):Boolean
		{
			if (animating) //you moved earlier
				return false;
			
			if (!room.dimensions.contains(p.x + room.dimensions.x + xA, p.y + room.dimensions.y + yA))
				return false; //it was the wrong direction
				
			if (x == p.x + xA && y == p.y + yA)
			{
				//move that way yourself!
				move( -xA, -yA);
				return false;
			}
			else
				return true; //it's the right point, but you aren't quite there
		}
		
		protected function move(xA:int, yA:int, slide:Boolean = false):Boolean
		{
			//figure out exactly where you are going
			var absoluteXTo:int = x + room.dimensions.x + xA;
			var absoluteYTo:int = y + room.dimensions.y + yA;
			
			//are you moving to a door?
			roomTo = null;
			for (var i:uint = 0; i < room.connections.length; i++)
				if (absoluteXTo == room.absoluteConnection(i).x && absoluteYTo == room.absoluteConnection(i).y)
				{
					//you are moving to that room
					roomTo = room.connections[i][0];
					break;
				}
				
			if (!roomTo)
			{
				//its not an exit, so see if it's outside the room
				if (!room.dimensions.contains(absoluteXTo, absoluteYTo))
				{
					return false; //it's an invalid move
				}
					
				roomTo = room;
			}
			
			//set the position you are moving to
			xTo = absoluteXTo - roomTo.dimensions.x;
			yTo = absoluteYTo - roomTo.dimensions.y;
			
			//check for collisions
			if (roomTo.solid(xTo, yTo))
			{
				//see if you can move someone aside
				var movedAside:Boolean = false;
				var tMA:Creature = roomTo.creatures[roomTo.getI(xTo, yTo)];
				if (tMA && (roomTo != room || tMA.faction == faction) && !slide)
				{
					var ks:uint = Math.random() * 4;
					for (var k:uint = 0; !movedAside && k < 4; k++)
					{
						var xMA:int = 0;
						var yMA:int = 0;
						switch((k + ks) % 4)
						{
						case 0:
							xMA = 1;
							break;
						case 1:
							xMA = -1;
							break;
						case 2:
							yMA = 1;
							break;
						case 3:
							yMA = -1;
							break;
						}
						
						movedAside = tMA.move(xMA, yMA, true);
					}
					
					if (!movedAside)
					{
						//as a last resort, trade places with them
						room.creatures[room.getI(x, y)] = null;
						movedAside = tMA.move(-xA, -yA, true);
					}
				}
				
				if (!movedAside)
				{
					roomTo = null;
					return false;
				}
			}
			
			//remember the old position
			xFrom = x;
			yFrom = y;
			roomFrom = room;
			
			if (xA == -1)
				mir = false;
			else if (xA == 1)
				mir = true;
				
			sliding = slide;
			movement = 0;
			if (!slide)
				movementPoints -= 1;
			return true;
		}
		
		public function get animating():Boolean { return movement != -1 || attacking != -1; }
	}

}