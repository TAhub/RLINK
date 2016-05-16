package game 
{
	import flash.geom.Point;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.graphics.Text;
	import net.flashpunk.utils.Input;
	import net.flashpunk.utils.Key;
	import net.flashpunk.FP;
	import net.flashpunk.World;
	
	public class Player extends Creature
	{
		private static const INTER_MOVE:uint = 0;
		private static const INTER_TARGET:uint = 1;
		private static const INTER_IDOLTARGET:uint = 4;
		private static const INTER_LEVEL:uint = 2;
		private static const INTER_INVENTORY:uint = 3;
		private static const INTER_PICKUP:uint = 5;
		public static const INTER_TEXTSEP:uint = 13;
		public static const INTER_SELECTEDC:uint = 0xFFFFFF;
		public static const INTER_UNSELECTEDC:uint = 0x999999;
		public static const INTER_INVALIDC:uint = 0xFF9999;
		private static const INTER_CRITICALPOINT:Number = 0.15;
		private static const INTER_TARGETCIRCLEDOWN:uint = 5;
		private var menuOn:uint;
		private var menuI:uint;
		private var dR:Creature;
		private var itemI:uint;
		private var acted:Boolean;
		private var inventory:Array;
		private var hunger:uint;
		public var relic:uint;
		private var pack:uint;
		
		private static const HUNGER_BLOAT:uint = 200;
		private static const HUNGER_HUNGRY:uint = 30;
		private static const HUNGER_START:uint = 60;
		private static const HUNGER_MOVEPEN:uint = 1;
		
		public static const INVENTORY_ITEM:uint = 0;
		public static const INVENTORY_WEAPON:uint = 1;
		public static const INVENTORY_ARMOR:uint = 2;
		public static const INVENTORY_MAXSiZE:uint = 20;
		
		public static const EXP_SCALE:Number = 0.25;
		public static const EXP_BASE:uint = 100;
		public static const EXP_SKILLSPERFLOOR:uint = 5;
		public static const EXP_INTBONUS:Number = 0.04;
		
		public override function load(c:Vector.<uint>, iOn:uint):uint
		{
			iOn = super.load(c, iOn);
			hunger = c[iOn++];
			relic = c[iOn++];
			pack = c[iOn++];
			acted = c[iOn++] == 1;
			
			iOn = Room.inventoryLoad(inventory, c, iOn);
			
			return iOn;
		}
		
		public override function save(c:Vector.<uint>, crs:Vector.<Creature>):void
		{
			super.save(c, null);
			c.push(hunger);
			c.push(relic);
			c.push(pack);
			if (acted)
				c.push(1);
			else
				c.push(0);
			
			Room.inventorySave(inventory, c);
		}
		
		public function Player(rm:Room, type:uint) 
		{
			super(rm, type, true, 1, false);
			
			dR = null;
			menuOn = INTER_MOVE;
			inventory = new Array();
			
			if (!rm)
				return;
			
			hunger = HUNGER_START;
		}
			
		public function applyFeatures(features:Vector.<uint>):void
		{
			//stat build
			strength += features[1];
			dexterity += features[2];
			intelligence += features[3];
			
			//appearance stuff
			var race:Array = Main.data.races[Main.data.creatures[features[0]][6]];
			gender = features[4];
			skinColor = Main.data.colors[Main.data.lists[race[5]][features[5] + 1]][1];
			hair = Main.data.lists[race[7] + gender][features[6] + 1];
			hairColor = Main.data.colors[Main.data.lists[race[6]][features[7] + 1]][1];
			
			//starting skills
			pack = Main.data.creatures[features[0]][10];
			var pp:Array = Main.data.playerPackages[pack];
			skills[pp[2]] += 1;
			skills[pp[3]] += 1;
			
			//starting items
			inventory.push(pp[5]);
			inventory.push(pp[4]);
			inventory.push(INVENTORY_ITEM);
			inventory.push(pp[7]);
			inventory.push(pp[6]);
			inventory.push(INVENTORY_ITEM);
			inventory.push(pp[9]);
			inventory.push(pp[8]);
			inventory.push(INVENTORY_ITEM);
			relic = features[8];
		}
		
		public override function turnStart():void
		{
			super.turnStart();
			menuOn = INTER_MOVE;
			acted = false;
			
			if (hunger == 0) //take hunger damage
				takeHitInner(1, this); //you DO specify who it's from, so that if you die of hunger you won't get a death condition
			else
				hunger -= 1;
			if (hunger >= HUNGER_BLOAT || hunger <= HUNGER_HUNGRY)
			{
				//it's effectively slow, again
				if (movementPoints > HUNGER_MOVEPEN)
					movementPoints -= HUNGER_MOVEPEN;
				else
					movementPoints = 1;
			}
		}
		
		private function skillLevelCost(i:uint):uint
		{
			return EXP_BASE * (1 + EXP_SCALE * skills[i]);
		}
		
		public function defeat():void
		{
			if (dR && dR.dead)
				dR = null;
			if (dR && !(FP.world as Map).finalMap && !room.containsBoss) //can't have a special loss condition if there is a boss in the room
				switch(dR.faction)
				{
				case 0: //criminal
					if (weapon != null || armor != null || inventory.length > 0) //if you have anything of value
					{
						trace("YOU GOT BEAT UP");
						(FP.world as Map).blackoutEffect = 0;
						currentHealth = health / 2;
						clearActive();
						//remove all items from you and the room
						weapon = null;
						armor = null;
						inventory = new Array();
						for (var i:uint = 0; i < room.items.length; i++)
							room.items[i] = null;
						return;
					}
					break;
				case 1: //enforcer
					if ((FP.world as Map).mapType != 0) //if you aren't in jail already
					{
						//go to jail
						trace("YOU GOT THROWN IN JAIL");
						currentHealth = health / 2;
						(FP.world as Map).mapTransition(false, false, 0);
						weapon = null; //your weapon is confiscated too
						inventory = new Array(); //and your entire inventory
						//they dont take your clothes though
						return;
					}
					break;
				case 2: //animal
					break;
				case 3: //worshipper
					var hasSkill:Boolean = false;
					for (i = 0; !hasSkill && i < skills.length; i++)
						if (skills[i] > 0)
							hasSkill = true;
					if (hasSkill)
					{
						trace("YOU GOT MIND-DRAINED");
						(FP.world as Map).blackoutEffect = 0;
						currentHealth = health / 2;
						clearActive();
						while (true)
						{
							var p:uint = Math.random() * skills.length;
							if (skills[p] > 0)
							{
								skills[p] -= 1;
								break;
							}
						}
						return;
					}
					break;
				}
		
			dR = null;
			FP.world = new MainMenu(1, 2, score, ", a " + classInfo + ", died on floor number " + (FP.world as Map).floorNum + ".", "You died. But don't be discouraged!");
		}
		
		public function get classInfo():String
		{
			var i:String;
			if (gender == 0)
				i = "male ";
			else
				i = "female ";
				
			i += Main.data.lines[Main.data.playerPackages[pack][1]];
				
			return i;
		}
		
		public function get score():uint
		{
			var s:uint = (FP.world as Map).floorNum * 10;
			if (currentHealth > 0)
				s *= 2; //victory bonus
			return s;
		}
		
		protected override function defeatRegister(by:Creature):void { dR = by; }
		
		public override function update():void
		{
			super.update();
			
			if (menuOn == INTER_TARGET)
				cameraAdjust(validTargets[menuI]);
			else
				cameraAdjust();
		}
		
		private function itemName(it:* , itN:uint, type:uint):String
		{
			var s:String;
			switch(type)
			{
			case INVENTORY_ITEM:
				s = Main.data.lines[Main.data.items[it][7]];
				break;
			case INVENTORY_WEAPON:
				s = it.weaponName + damageForm(it.damage, it.weaponDurability);
				break;
			case INVENTORY_ARMOR:
				s = it.armorName + damageForm(it.damage, it.armorDurability);
				break;
			}
			if (itN > 1)
				s += " x" + itN;
			return s;
		}
		
		private function itemDescription(it:* , type:uint):String
		{
			var s:String;
			switch(type)
			{
			case INVENTORY_ITEM:
				s = Main.data.lines[Main.data.items[it][7] + 1];
				break;
			case INVENTORY_WEAPON:
				s = it.weaponDescription;
				s += "\nDamage = " + Math.floor(it.weaponDamage * (1 + it.materialBonus) * (1 + it.enchantmentBonus));
				break;
			case INVENTORY_ARMOR:
				s = it.armorDescription;
				s += "\nDefense = " + Math.floor(it.armorDefense * (1 + it.materialBonus) * (1 + it.enchantmentBonus));
				break;
			}
			return s;
		}
		
		private function get screenInvHeight():uint
		{
			return (FP.height / INTER_TEXTSEP) - 5;
		}
		
		private function itemValid(it:*, type:uint):Boolean
		{
			switch(type)
			{
			case INVENTORY_WEAPON:
				return (!weapon || weapon.enchantmentCanRemove);
			case INVENTORY_ARMOR:
				return (!armor || armor.enchantmentCanRemove);
			case INVENTORY_ITEM:
				switch(Main.data.items[it][1])
				{
				case 0:
					return currentHealth < health;
				case 1:
					return validSpecialTargets.length > 0;
				case 3:
					return ((weapon && weapon.damage > 0) || (armor && armor.damage > 0));
				case 4:
				case 5:
					return true;
				case Database.NONE:
					return false;
				}
				break;
			}
			return true;
		}
		
		public override function render(relicDraw:uint = 999):void
		{
			super.render(relic);
		}
		
		public override function playerRender():void
		{
			super.playerRender();
			
			var tI:uint = 1;
			var t:Text = new Text(currentHealth + "/" + health + " HP");
			if (currentHealth < health * INTER_CRITICALPOINT || currentHealth == 1)
				t.color = INTER_INVALIDC;
			else
				t.color = INTER_SELECTEDC;
			t.render(FP.buffer, new Point(FP.width - t.width, 0), FP.zero);
			if (movementPoints > 0)
			{
				t = new Text(movementPoints + "/" + speed + " MP");
				if (movementPoints == 1)
					t.color = INTER_INVALIDC;
				else
					t.color = INTER_SELECTEDC;
				t.render(FP.buffer, new Point(FP.width - t.width, (tI++) * INTER_TEXTSEP), FP.zero);
			}
			
			t = null;
			if (hunger == 0)
				t = new Text("Starving");
			else if (hunger <= HUNGER_HUNGRY)
				t = new Text("Hungry");
			else if (hunger >= HUNGER_BLOAT)
				t = new Text("Bloated");
			if (t)
			{
				t.color = INTER_INVALIDC;
				t.render(FP.buffer, new Point(FP.width - t.width, (tI++) * INTER_TEXTSEP), FP.zero);
			}
			
			if (weapon)
			{
				var wN:Text = new Text(itemName(weapon, 1, INVENTORY_WEAPON));
				wN.render(FP.buffer, new Point(FP.width - wN.width, (tI++) * INTER_TEXTSEP), FP.zero);
			}
			if (armor)
			{
				var aN:Text = new Text(itemName(armor, 1, INVENTORY_ARMOR));
				aN.render(FP.buffer, new Point(FP.width - aN.width, (tI++) * INTER_TEXTSEP), FP.zero);
			}
			
			//render UI
			switch(menuOn)
			{
			case INTER_LEVEL:
				for (var i:uint = 0; i < skills.length; i++)
				{
					s = Main.data.lines[Main.data.skills[i][1]] + ": " + skills[i];
					if (i == menuI)
						s += " (" + skillLevelCost(i) + " exp to level up)";
					t = new Text(s);
					if (i != menuI)
						t.color = INTER_UNSELECTEDC;
					else if (experience < skillLevelCost(i))
						t.color = INTER_INVALIDC;
					else
						t.color = INTER_SELECTEDC;
					t.render(FP.buffer, new Point(0, i * INTER_TEXTSEP), FP.zero);
				}
				t = new Text(experience + " exp");
				t.color = INTER_UNSELECTEDC;
				t.render(FP.buffer, new Point(0, skills.length * INTER_TEXTSEP), FP.zero);
				break;
			case INTER_INVENTORY:
			case INTER_PICKUP:
				var mW:uint = 0;
				var il:Array;
				if (menuOn == INTER_INVENTORY)
					il = inventory;
				else
					il = room.items[room.getI(x, y)];
				i = 0;
				var iS:int = 0;
				if (il.length / 3 >= screenInvHeight)
				{
					iS = itemI - screenInvHeight / 2;
					if (iS < 0)
						iS = 0;
					else if (iS + screenInvHeight > il.length / 3)
						iS = il.length / 3 - screenInvHeight;
				}
				for (i = iS; i < il.length / 3 && i < iS + screenInvHeight; i++)
				{
					t = new Text(itemName(il[i * 3], il[i * 3 + 1], il[i * 3 + 2]));
					if (i != itemI)
						t.color = INTER_UNSELECTEDC;
					else if ((menuOn == INTER_INVENTORY && (acted || !itemValid(il[i * 3], il[i * 3 + 2]))) ||
							(menuOn == INTER_PICKUP && inventory.length >= INVENTORY_MAXSiZE * 3))
						t.color = INTER_INVALIDC;
					else
						t.color = INTER_SELECTEDC;
					if (t.width > mW)
						mW = t.width;
					t.render(FP.buffer, new Point(0, (i - iS) * INTER_TEXTSEP), FP.zero);
				}
				var tW:uint = FP.width - mW;
				var tH:uint = FP.height - tI * INTER_TEXTSEP;
				t = new Text(itemDescription(il[itemI * 3], il[itemI * 3 + 2]),
							0, 0, {wordWrap:true, width:tW, height:tH});
				t.color = INTER_SELECTEDC;
				t.render(FP.buffer, new Point(mW, tI * INTER_TEXTSEP), FP.zero);
				break;
			case INTER_IDOLTARGET:
			case INTER_TARGET:
				//render a targeting reticle
				var vT:Creature;
				if (menuOn == INTER_TARGET)
					vT = validTargets[menuI];
				else
					vT = validSpecialTargets[menuI];
				var spr:Spritemap = Main.data.spriteSheets[0];
				spr.frame = 6;
				spr.color = INTER_INVALIDC;
				spr.flipped = vT.mir;
				var p:Point = vT.drawP;
				p.y += INTER_TARGETCIRCLEDOWN;
				spr.render(FP.buffer, p, FP.camera);
				
				var s:String;
				if (menuOn == INTER_TARGET)
				{
					s = "Attack with ";
					if (weapon == null)
						s += "your fists?";
					else
						s += weapon.weaponName + "?";
				}
				else
					s = "Use " + Main.data.lines[Main.data.specials[itemEffect][7]] + "?";
				t = new Text(s);
				t.color = INTER_SELECTEDC;
				t.render(FP.buffer, FP.zero, FP.zero);
				if (relic == 1)
					t = new Text("The target is " + vT.healthName + ".");
				else if (relic == 2 && menuOn == INTER_TARGET)
				{
					if (vT.dodgeChanceFrom(this) < 0.3)
						t = new Text("You have a very good chance to hit.");
					else if (vT.dodgeChanceFrom(this) < 0.6)
						t = new Text("You have a good chance to hit.");
					else
						t = new Text("You have a bad chance to hit.");
				}
				else
					t = null;
				if (t)
				{
					t.color = INTER_INVALIDC;
					t.render(FP.buffer, new Point(0, INTER_TEXTSEP), FP.zero);
				}
				break;
			}
		}
		
		private function damageForm(damage:uint, dura:uint):String
		{
			if (damage == 0)
				return "";
			else
			{
				var d:uint = 100 * (1 - (damage / dura));
				return " (" + d + "%)";
			}
		}
		
		private function get itemEffect():uint
		{
			return Main.data.items[inventory[itemI * 3]][2];
		}
		private function get itemEffect2():uint
		{
			return Main.data.items[inventory[itemI * 3]][3];
		}
		private function get itemEffect3():uint
		{
			return Main.data.items[inventory[itemI * 3]][4];
		}
		
		private function useItem():void
		{
			inventory = Room.inventoryUseItem(inventory, itemI);
		}
		
		public override function input():void
		{	
			var xA:int = 0;
			var yA:int = 0;
			var fT:Function;
			if (menuOn == INTER_MOVE)
				fT = Input.check;
			else
				fT = Input.pressed;
			if (fT(Key.W))
				yA -= 1;
			if (fT(Key.S))
				yA += 1;
			if (fT(Key.A))
				xA -= 1;
			if (fT(Key.D))
				xA += 1;
				
			if (xA != 0 && yA != 0)
				yA = 0;
				
			var eA:int = xA + yA;
				
			switch(menuOn)
			{
			case INTER_MOVE:
				if (xA != 0 || yA != 0)
					move(xA, yA);
				else if (Input.pressed(Key.SPACE) && !acted)
				{
					if (room.exit && room.exit.x == x && room.exit.y == y)
						(FP.world as Map).mapTransition(true);
					else if (validTargets.length > 0)
					{
						menuOn = INTER_TARGET;
						menuI = 0;
					}
				}
				else if (Input.pressed(Key.I) && inventory.length > 0)
				{
					menuOn = INTER_INVENTORY;
					itemI = 0;
				}
				else if (Input.pressed(Key.P) && room.items[room.getI(x, y)])
				{
					menuOn = INTER_PICKUP;
					itemI = 0;
				}
				else if (Input.pressed(Key.L))
				{
					menuOn = INTER_LEVEL;
					menuI = 0;
				}
				else if (Input.pressed(Key.ENTER))
					movementPoints = 0;
				else if (Input.pressed(Key.ESCAPE))
				{
					(FP.world as Map).save();
					return;
				}
				break;
			case INTER_IDOLTARGET:
			case INTER_TARGET:
				var vT:Vector.<Creature>;
				if (menuOn == INTER_TARGET)
					vT = validTargets;
				else
					vT = validSpecialTargets;
				if (eA == -1 && menuI == 0)
					menuI = vT.length - 1;
				else if (eA == 1 && menuI == vT.length - 1)
					menuI = 0;
				else
					menuI += eA;
				if (Input.pressed(Key.SPACE))
				{
					if (menuOn == INTER_TARGET)
						attack(vT[menuI]);
					else
					{
						useSpecial(vT[menuI], itemEffect);
						useItem();
					}
						
				}
				else if (Input.pressed(Key.ENTER))
					menuOn = INTER_MOVE;
				break;
			case INTER_LEVEL:
				if (eA == -1 && menuI == 0)
					menuI = skills.length - 1;
				else if (eA == 1 && menuI == skills.length - 1)
					menuI = 0;
				else
					menuI += eA;
				if (Input.pressed(Key.SPACE) && experience >= skillLevelCost(menuI))
				{
					experience -= skillLevelCost(menuI);
					skills[menuI] += 1;
				}
				else if (Input.pressed(Key.ENTER))
					menuOn = INTER_MOVE;
				break;
			case INTER_PICKUP:
				var l:Array = room.items[room.getI(x, y)];
				if (eA == -1 && itemI == 0)
					itemI = l.length / 3 - 1;
				else if (eA == 1 && itemI == l.length / 3 - 1)
					itemI = 0;
				else
					itemI += eA;
				if (Input.pressed(Key.SPACE))
				{
					Room.inventoryMergeAdd(inventory, l[itemI * 3], 1, l[itemI * 3 + 2], INVENTORY_MAXSiZE);
					room.items[room.getI(x, y)] = Room.inventoryUseItem(l, itemI);
					if (room.items[room.getI(x, y)].length == 0)
					{
						room.items[room.getI(x, y)] = null;
						menuOn = INTER_MOVE;
					}
					else if (itemI * 3 >= room.items[room.getI(x, y)].length)
						itemI -= 1;
				}
				else if (Input.pressed(Key.ENTER))
					menuOn = INTER_MOVE;
				break;
			case INTER_INVENTORY:
				if (eA == -1 && itemI == 0)
					itemI = inventory.length / 3 - 1;
				else if (eA == 1 && itemI == inventory.length / 3 - 1)
					itemI = 0;
				else
					itemI += eA;
				if (Input.pressed(Key.DELETE))
				{
					room.dropItem(x, y, inventory[itemI * 3], 1, inventory[itemI * 3 + 2]);
					useItem();
					if (inventory.length == 0)
						menuOn = INTER_MOVE;
					else if (itemI * 3 >= inventory.length)
						itemI -= 1;
				}
				else if (Input.pressed(Key.SPACE) && !acted && itemValid(inventory[itemI * 3], inventory[itemI * 3 + 2]))
				{
					switch(inventory[itemI * 3 + 2])
					{
					case INVENTORY_ITEM:
						switch(Main.data.items[inventory[itemI * 3]][1])
						{
						case 0: //healing items
							dnum("+" + itemEffect);
							currentHealth += itemEffect;
							if (currentHealth > health)
								currentHealth = health;
							menuOn = INTER_MOVE;
							useItem();
							acted = true;
							movementPoints -= 1;
							break;
						case 1: //idols
							menuOn = INTER_IDOLTARGET;
							menuI = 0;
							break;
						case 2: //craftables
							var craftRoll:Number = (skills[itemEffect3] * RULE_SKILLCRAFT + intelligence * RULE_STATCRAFT)
													* itemEffect2 * 0.01;
							var number:uint = 0;
							while (craftRoll > 1)
							{
								craftRoll -= 1;
								number += 1;
							}
							if (Math.random() < craftRoll)
								number += 1;
							if (number > Main.data.skills[itemEffect3][2])
								number = Main.data.skills[itemEffect3][2];
							if (number > 0)
								Room.inventoryMergeAdd(inventory, itemEffect, number, INVENTORY_ITEM);
							useItem();
							movementPoints = 0;
							break;
						case 3: //repair items
							var repairAmount:uint = itemEffect * (1 + RULE_STATREPAIR * intelligence);
							if (weapon)
							{
								if (weapon.damage > repairAmount)
								{
									weapon.damage -= repairAmount;
									repairAmount = 0;
								}
								else
								{
									repairAmount -= weapon.damage;
									weapon.damage = 0;
								}
							}
							if (armor && repairAmount > 0)
							{
								if (armor.damage > repairAmount)
									armor.damage -= repairAmount;
								else
									armor.damage = 0;
							}
								
							useItem();
							movementPoints = 0;
							break;
						case 4: //foods
							hunger += itemEffect;
							if (itemEffect2 > 0)
								applyStatus(1, itemEffect2);
							useItem();
							movementPoints = 0;
							break;
						case 5: //status potions
							applyStatus(itemEffect, itemEffect2);
							menuOn = INTER_MOVE;
							useItem();
							acted = true;
							movementPoints -= 1;
							break;
						case 6: //pet token
							var petLevel:int = (FP.world as Map).floorNum - RULE_PETDEFAULTPEN;
							if (petLevel < 0)
								petLevel = 0;
							if (skills[2] > petLevel)
								petLevel = skills[2];
							trace("generating pet of level " + petLevel);
							if ((FP.world as Map).addPet(new Enemy(room, itemEffect, petLevel)))
							{
								menuOn = INTER_MOVE;
								useItem();
								acted = true;
								movementPoints -= 1;
							}
							break;
							//NOTE: when adding new item types, any condition that would cause them to be unusable
							//should be put into the itemValid script, NOT here
						}
						break;
					case INVENTORY_WEAPON:
						var oW:Equipment = weapon;
						weapon = inventory[itemI * 3];
						weapon.learnEnchantment();
						if (oW)
							inventory[itemI * 3] = oW;
						else
							useItem();
						acted = true;
						movementPoints -= 1;
						break;
					case INVENTORY_ARMOR:
						var oA:Equipment = armor;
						armor = inventory[itemI * 3];
						armor.learnEnchantment();
						if (oA)
							inventory[itemI * 3] = oA;
						else
							useItem();
						movementPoints = 0;
						break;
					}
				}
				else if (Input.pressed(Key.ENTER))
					menuOn = INTER_MOVE;
				break;
			}
			
			if (turnOver)
				menuOn = INTER_MOVE;
		}
	}

}