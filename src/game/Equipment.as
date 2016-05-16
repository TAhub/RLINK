package game 
{
	import net.flashpunk.FP;
	
	public class Equipment 
	{
		private var enchantmentKnown:Boolean;
		public var id:uint;
		public var material:uint;
		public var damage:uint;
		public var enchantment:uint;
		private static const EQUIP_NOENCHANT:uint = 999;
		
		private static const EQUIP_MAXDAMAGE:Number = 0.05;
		private static const EQUIP_MAXDAMAGEENEMY:Number = 0.5;
		private static const EQUIP_FLOORPERTIER:uint = 4;
		private static const EQUIP_MAXTIER:uint = 4;
		private static const EQUIP_ENCHANTGLOW:Number = 0.35;
		public static const EQUIP_FACTIONBONUS:Number = 0.3;
		
		public function Equipment(_id:uint, _material:uint = 0, _enchantment:uint = EQUIP_NOENCHANT) 
		{
			id = _id;
			material = _material;
			damage = 0;
			enchantment = EQUIP_NOENCHANT;
			enchantmentKnown = false;
		}
		
		public function learnEnchantment():void { enchantmentKnown = true; }
		
		private function setDamage(max:Number, dura:uint):void
		{
			damage = max * Math.random() * dura;
		}
		
		public function weaponSetDamageEnemy():void
		{
			setDamage(EQUIP_MAXDAMAGEENEMY, weaponDurability);
		}
		
		public function weaponSetDamage():void
		{
			setDamage(EQUIP_MAXDAMAGE, weaponDurability);
		}
		
		public function armorSetDamageEnemy():void
		{
			setDamage(EQUIP_MAXDAMAGEENEMY, armorDurability);
		}
		
		public function armorPickEnchant():void
		{
			pickEnchant(false);
		}
		
		public function get enchanted():Boolean { return enchantment != EQUIP_NOENCHANT; }
		
		public function weaponPickEnchant():void
		{
			pickEnchant(true);
		}
		
		private function pickEnchant(w:Boolean):void
		{
			while (true)
			{
				enchantment = Main.data.enchantments.length * Math.random();
				if (Main.data.enchantments[enchantment][6] == w)
					return;
			}
		}
		
		public function armorSetDamage():void
		{
			setDamage(EQUIP_MAXDAMAGE, armorDurability);
		}
		
		public function weaponPickMaterial(floorNum:uint):void
		{
			pickMaterial(floorNum, weaponMaterialsList);
		}
		
		public function armorPickMaterial(floorNum:uint):void
		{
			pickMaterial(floorNum, armorMaterialsList);
		}
		
		private function pickMaterial(floorNum:uint, mL:uint):void
		{
			if (mL == Database.NONE)
				return; //it doesnt have a materials list, so just stay as material none
			
			var tier:uint = floorNum / EQUIP_FLOORPERTIER;
			if (tier > EQUIP_MAXTIER)
				tier = EQUIP_MAXTIER;
				
			while (true)
			{
				material = Main.pickFromList(mL);
				if (Main.data.materials[material][5] == tier)
					return; //found an appropriate material
			}
		}
		
		private function finishS(s:String):String
		{
			var sF:String = "";
			for (var i:uint = 0; i < s.length; i++)
			{
				if (s.charAt(i) != "*")
					sF += s.charAt(i);
				else if (Main.data.materials[material][6] != Database.NONE)
					sF += Main.data.lines[Main.data.materials[material][6]];
			}
			return sF;
		}
		
		private function finishDescription(line:uint, w:Boolean):String
		{
			var sF:String = finishS(Main.data.lines[line]);
			if (enchanted)
			{
				sF += "\n";
				if (enchantmentKnown)
				{
					if (Main.data.enchantments[enchantment][1] != Database.NONE)
						sF += Main.data.lines[Main.data.enchantments[enchantment][1] + 1];
					else
						sF += Main.data.lines[Main.data.enchantments[enchantment][2] + 1];
				}
				else
					sF += "This item has an unknown magical property.";
			}
			if (materialBonusFaction != Database.NONE)
			{
				if (w)
					sF += "\nThis weapon is the bane of ";
				else
					sF += "\nThis armor is an aegis against ";
				sF += Main.data.lines[Main.data.factions[materialBonusFaction][1]];
				sF += ".";
			}
			return sF;
		}
		
		private function finishName(line:uint):String
		{
			var sF:String = "";
			if (enchanted && Main.data.enchantments[enchantment][1] != Database.NONE && enchantmentKnown)
				sF += Main.data.lines[Main.data.enchantments[enchantment][1]] + " ";
			if (enchanted && !enchantmentKnown)
				sF += "magic ";
			sF += finishS(Main.data.lines[line]);
			if (enchanted && Main.data.enchantments[enchantment][2] != Database.NONE && enchantmentKnown)
				sF += " " + Main.data.lines[Main.data.enchantments[enchantment][2]];
			return sF;
		}
		
		public function get materialBonus():Number
		{
			return Main.data.materials[material][1] * 0.01;
		}
		
		public function get materialDuraBonus():Number
		{
			return Main.data.materials[material][2] * 0.01;
		}
		
		public function get materialBonusFaction():uint
		{
			return Main.data.materials[material][3];
		}
		
		public function get enchantmentCanRemove():Boolean
		{
			if (enchanted)
				return Main.data.enchantments[enchantment][5];
			else
				return true;
		}
		
		public function get enchantmentBonus():Number
		{
			if (enchanted)
				return Main.data.enchantments[enchantment][3] * 0.01;
			else
				return 0;
		}
		
		public function get enchantmentDuraMod():Number
		{
			if (enchanted)
				return Main.data.enchantments[enchantment][4] * 0.01;
			else
				return 1;
		}
		
		public function get materialSpecial():uint
		{
			return Main.data.materials[material][3];
		}
		
		private function get materialColorInner():uint
		{
			return Main.data.colors[Main.data.materials[material][4]][1];
		}
		
		public function get materialColor():uint
		{
			if (enchanted)
				return FP.colorLerp(materialColorInner, Main.magicColor, EQUIP_ENCHANTGLOW);
			else
				return materialColorInner;
		}
		
		public function get weaponDamage():uint
		{
			return Main.data.weapons[id][1];
		}
		
		public function get weaponHits():uint
		{
			return Main.data.weapons[id][2];
		}
		
		public function get weaponBaseDodge():Number
		{
			return Main.data.weapons[id][3] * 0.01;
		}
		
		public function get weaponUseDex():Boolean
		{
			return Main.data.weapons[id][4];
		}
		
		public function get weaponSkill():uint
		{
			return Main.data.weapons[id][5];
		}
		
		public function get weaponRange():uint
		{
			return Main.data.weapons[id][6];
		}
		
		public function get weaponName():String
		{
			return finishName(Main.data.weapons[id][11]);
		}
		
		public function get weaponDescription():String
		{
			return finishDescription(Main.data.weapons[id][11] + 1, true);
		}
		
		public function get weaponDurability():uint
		{
			return Main.data.weapons[id][7] * (1 + materialDuraBonus) * enchantmentDuraMod;
		}
		
		public function get weaponMaterialsList():uint
		{
			return Main.data.weapons[id][8];
		}
		
		public function get weaponFrame():uint
		{
			return Main.data.weapons[id][9];
		}
		
		public function get weaponItFrame():uint
		{
			return Main.data.weapons[id][10];
		}
		
		public function get weaponAnim():uint
		{
			return Main.data.weapons[id][12];
		}
		
		public function get weaponStatus():uint
		{
			if (enchanted)
				return Main.data.enchantments[enchantment][7];
			else
				return Database.NONE;
		}
		
		public function get weaponStatusLength():uint
		{
			if (enchanted)
				return Main.data.enchantments[enchantment][8];
			else
				return 0;
		}
		
		public function get weaponStatusChance():Number
		{
			if (enchanted)
				return Main.data.enchantments[enchantment][9] * 0.01;
			else
				return 0;
		}
		
		public function get armorDefense():uint
		{
			return Main.data.armors[id][1];
		}
		
		public function get armorMaxDodge():Number
		{
			return Main.data.armors[id][2] * 0.01;
		}
		
		public function get armorSpeedPenalty():uint
		{
			return Main.data.armors[id][3];
		}
		
		public function get armorDurability():uint
		{
			return Main.data.armors[id][4] * (1 + materialDuraBonus) * enchantmentDuraMod;
		}
		
		public function get armorMaterialsList():uint
		{
			return Main.data.armors[id][5];
		}
		
		public function get armorFrame():uint
		{
			return Main.data.armors[id][6];
		}
		
		public function get armorLegGender():Boolean
		{
			return Main.data.armors[id][7];
		}
		
		public function get armorArmFrame():uint
		{
			return Main.data.armors[id][8];
		}
		
		public function get armorItFrame():uint
		{
			return Main.data.armors[id][9];
		}
		
		public function get armorName():String
		{
			return finishName(Main.data.armors[id][10]);
		}
		
		public function get armorDescription():String
		{
			return finishDescription(Main.data.armors[id][10] + 1, false);
		}
		
		public function get armorMeleeResistance():Number
		{
			if (enchanted)
				return Main.data.enchantments[enchantment][7] * 0.01;
			else
				return 0;
		}
		
		public function get armorRangedResistance():Number
		{
			if (enchanted)
				return Main.data.enchantments[enchantment][8] * 0.01;
			else
				return 0;
		}
		
		public function get armorSpecialResistance():Number
		{
			if (enchanted)
				return Main.data.enchantments[enchantment][9] * 0.01;
			else
				return 0;
		}
	}

}