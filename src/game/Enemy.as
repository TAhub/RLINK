package game 
{
	import flash.geom.Point;
	import net.flashpunk.FP;
	
	public class Enemy extends Creature
	{
		private var active:Boolean;
		private var target:Creature;
		private var turnTime:Number;
		private var ai:uint;
		private var special:uint;
		private var heal:uint;
		private var savedTarget:uint;
		private static const AI_MAXTURNTIME:Number = 0.25;

		public override function load(c:Vector.<uint>, iOn:uint):uint
		{
			iOn = super.load(c, iOn);
			ai = c[iOn++];
			special = c[iOn++];
			heal = c[iOn++];
			active = c[iOn++] == 1;
			
			savedTarget = c[iOn++];
			
			return iOn;
		}
		
		public override function linkTarget(crs:Vector.<Creature>):void
		{
			if (savedTarget != Database.NONE)
				target = crs[savedTarget];
		}
		
		public override function save(c:Vector.<uint>, crs:Vector.<Creature>):void
		{
			super.save(c, null);
			c.push(ai);
			c.push(special);
			c.push(heal);
			if (active)
				c.push(1);
			else
				c.push(0);
				
			if (target)
			{
				for (var i:uint = 0; i < crs.length; i++)
				{
					if (crs[i] == target)
					{
						c.push(i);
						break;
					}
				}
			}
			else
				c.push(Database.NONE);
		}
		
		public function Enemy(rm:Room, type:uint, floorNum:uint, boss:Boolean = false, isMinion:Boolean = false) 
		{
			target = null;
			super(rm, type, aiFollowPlayer, floorNum, boss);
			
			if (!rm)
				return;
			
			ai = Main.data.creatures[type][10];
			special = Main.data.ais[ai][1];
			heal = Main.data.ais[ai][6];
			active = false;
			
			//place minions
			if (!isMinion)
				for (var i:uint = 0; i < Main.data.ais[ai][8]; i++)
					new Enemy(rm, Main.data.ais[ai][7], floorNum, false, true);
			
			//set skills based on floor number
			for (i = 0; i < skills.length; i++)
				skills[i] = floorNum;
				
			//set the fixed weapon enchantment
			if (Main.data.ais[ai][9] != Database.NONE && weapon)
				weapon.enchantment = Main.data.ais[ai][9];
		}
		
		public override function deactivate():void
		{
			active = false;
			target = null;
		}
		
		public override function turnStart():void
		{
			super.turnStart();
			turnTime = 0;
		}
		
		private function get aiFollowPlayer():Boolean
		{
			return Main.data.ais[ai][11] != Database.NONE;
		}
		
		private function get aiCanMove():Boolean
		{
			return Main.data.ais[ai][10];
		}
		
		private function get aiSpecialMaxHealth():uint
		{
			return Main.data.ais[ai][2] * 0.01 * health;
		}
		
		private function get aiSpecialChance():Number
		{
			return Main.data.ais[ai][3] * 0.01;
		}
		
		private function get aiRetreatMaxHealth():uint
		{
			return Main.data.ais[ai][4] * 0.01 * health;
		}
		
		private function get aiHealMaxHealth():uint
		{
			return Main.data.ais[ai][5] * 0.01 * health;
		}
		
		public override function get retreatAlly():Boolean { return currentHealth > aiRetreatMaxHealth; }
		
		private function doHeal():void
		{
			trace("AI USES A POTION");
			dnum("+" + heal);
			currentHealth += heal;
			if (currentHealth > health)
				currentHealth = health;
			heal = 0;
			movementPoints = 0;
		}
		
		public override function input():void
		{
			//turn timer, just in case
			turnTime += FP.elapsed;
			if (turnTime > AI_MAXTURNTIME)
			{
				trace("ENEMY AI TIMED OUT.");
				movementPoints = 0;
				return;
			}
			
			if (aiFollowPlayer)
				active = true;
				
			if (target && target.room != room && aiFollowPlayer)
				target = null; //ai followers dont chase targets into other rooms (probably won't come up much)
			
			//is there any enemy in your room?
			if (!active && inView)
				active = true; //get ready
				
			if (target && (target.dead || target.invisible))
				target = null;
			
			if (!active)
			{
				//just skip your turn
				movementPoints = 0;
				return;
			}
			
			var retreat:Boolean = currentHealth <= aiRetreatMaxHealth && room.numRetreatAllies > 0; // only retreat if you have a friend who ISNT retreating
			
			if (!retreat && special != Database.NONE && currentHealth <= aiSpecialMaxHealth &&
					Math.random() < aiSpecialChance && validSpecialTargets.length > 0)
			{
				//use your special on someone
				var vtP:uint = validSpecialTargets.length * Math.random();
				target = validSpecialTargets[vtP];
				useSpecial(target, special);
				special = Database.NONE;
				return;
			}
			else if (!retreat && validTargets.length > 0)
			{
				//attack someone who is in range
				vtP = validTargets.length * Math.random();
				target = validTargets[vtP]; //forget your old target, if you had one
				attack(target);
				return;
			}
			else if (!target)
			{
				//find a specific target to track down and attack
				var ts:Vector.<Creature> = validSpecialTargets;
				if (ts.length > 0)
				{
					//find the closest valid targets
					var lD:uint = Database.NONE;
					for (var i:uint = 0; i < ts.length; i++)
						if (getDistanceTo(ts[i]) < lD)
							lD = getDistanceTo(ts[i]);
					var tsF:Vector.<Creature> = new Vector.<Creature>();
					for (i = 0; i < ts.length; i++)
						if (getDistanceTo(ts[i]) == lD)
							tsF.push(ts[i]);
							
					//pick a random target among the closest targets
					var tsP:uint = tsF.length * Math.random();
					target = tsF[tsP];
				}
				else if (!aiFollowPlayer)
				{
					movementPoints = 0; //give up your turn
					return;
				}
			}
			
			if (!target && aiFollowPlayer)
			{
				//follow the player
				var pl:Creature = (FP.world as Map).player;
				if (getDistanceTo(pl) > 1)
					moveToPerson(pl);
				else
					movementPoints = 0;
			}
			
			if (target)
			{
				var shouldHeal:Boolean = heal > 0 && currentHealth <= aiHealMaxHealth;
				if (shouldHeal)
				{
					if (movementPoints > 1)
						retreat = true; //try retreating before you heal
					else
					{
						doHeal();
						return;
					}
				}
				
				if (retreat)
				{
					//try to flee
					var towards:Point;
					if (target.room != room)
					{
						//run a random direction
						var xA:int = 1;
						var yA:int = 1;
						if (Math.random() < 0.5)
							xA *= -1;
						else
							yA *= -1;
						towards = new Point(xA, yA);
					}
					else
						towards = new Point(target.x - x, target.y - y);;
					if (towards.x != 0 && towards.y != 0)
					{
						if (Math.random() > 0.5)
							towards.x = 0;
						else
							towards.y = 0;
					}
					if (towards.x != 0)
						towards.x /= Math.abs(towards.x);
					if (towards.y != 0)
						towards.y /= Math.abs(towards.y);
					
					if (!aiCanMove || !move( -towards.x, -towards.y))
						movementPoints -= 1; //lose a movement point anyway, so that you'll try again but not infinitely
				}
				else
				{
					//can you hit the target?
					if (inRange(target))
						attack(target); //just attack them
					else if (!aiCanMove || !moveToPerson(target)) //try to get in range of them
						movementPoints = 0; //..but if you can't, just stop here
				}
			}
		}
	}

}