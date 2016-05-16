package game {
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.Sfx;
	public class Database 
	{
		//sprites
		[Embed(source = "sprites/player.png")] private static const SPR1:Class;
		[Embed(source = "sprites/tile.png")] private static const SPR2:Class;
		[Embed(source = "sprites/weapon.png")] private static const SPR3:Class;
		[Embed(source = "sprites/item.png")] private static const SPR4:Class;
		[Embed(source = "sprites/teleportAnim.png")] private static const SPR5:Class;
		[Embed(source = "sprites/projectile.png")] private static const SPR6:Class;
		[Embed(source = "sprites/icon.png")] private static const SPR7:Class;
		
		//sound effects
		//[Embed(source = "sounds/215025_taira-komori_swing1.mp3")] private static const SND1:Class;
		
		//files
		[Embed(source = "data/data.txt", mimeType = "application/octet-stream")] private static const DATA:Class;
		[Embed(source = "data/lines.txt", mimeType = "application/octet-stream")] private static const LINES:Class;
		
		public static const NONE:uint = 999999999;
		public var lines:Array = new Array();
		public var spriteSheets:Array = new Array();
		public var soundEffects:Array = new Array();
		private var sheets:Vector.<Array> = new Vector.<Array>();
		private var sounds:Vector.<Array> = new Vector.<Array>();
		
		//other lists
		public var maps:Vector.<Array> = new Vector.<Array>();
		public var rooms:Vector.<Array> = new Vector.<Array>();
		public var lists:Vector.<Array> = new Vector.<Array>();
		public var weapons:Vector.<Array> = new Vector.<Array>();
		public var armors:Vector.<Array> = new Vector.<Array>();
		public var materials:Vector.<Array> = new Vector.<Array>();
		public var skills:Vector.<Array> = new Vector.<Array>();
		public var creatures:Vector.<Array> = new Vector.<Array>();
		public var races:Vector.<Array> = new Vector.<Array>();
		public var colors:Vector.<Array> = new Vector.<Array>();
		public var hairs:Vector.<Array> = new Vector.<Array>();
		public var factions:Vector.<Array> = new Vector.<Array>();
		public var tilesets:Vector.<Array> = new Vector.<Array>();
		public var specials:Vector.<Array> = new Vector.<Array>();
		public var ais:Vector.<Array> = new Vector.<Array>();
		public var items:Vector.<Array> = new Vector.<Array>();
		public var itemLists:Vector.<Array> = new Vector.<Array>();
		public var statuses:Vector.<Array> = new Vector.<Array>();
		public var playerPackages:Vector.<Array> = new Vector.<Array>();
		public var relics:Vector.<Array> = new Vector.<Array>();
		public var boots:Vector.<Array> = new Vector.<Array>();
		public var attackAnims:Vector.<Array> = new Vector.<Array>();
		public var enchantments:Vector.<Array> = new Vector.<Array>();
		
		public function Database() 
		{
			//read lines
			var lineNames:Array = new Array();
			var data:Array = new LINES().toString().split("\n");
			for (var i:uint = 0; i < data.length - 1; i++)
			{
				var line:String = data[i];
				if (line.charAt(0) != "/")
				{
					var lineName:String = "";
					var lineContent:String = "";
					var onName:Boolean = true;
					for (var j:uint = 0; j < line.length - 1; j++)
					{
						if (onName && line.charAt(j) == " ")
							onName = false;
						else if (onName)
							lineName += line.charAt(j);
						else
							lineContent += line.charAt(j);
					}
					lineNames.push(lineName);
					lines.push(lineContent);
				}
			}
			
			//read data
			
			data = new DATA().toString().split("\n");
			
			//analyze data
			var allArrays:Vector.<Vector.<Array>> = new Vector.<Vector.<Array>>();
			//remember to push each data array into allarrays
			//if you don't put something into allArrays, it won't be linked with anything
			
			allArrays.push(sheets);
			allArrays.push(sounds);
			//other lists
			allArrays.push(maps);
			allArrays.push(rooms);
			allArrays.push(lists);
			allArrays.push(weapons);
			allArrays.push(armors);
			allArrays.push(materials);
			allArrays.push(skills);
			allArrays.push(creatures);
			allArrays.push(races);
			allArrays.push(relics);
			allArrays.push(colors);
			allArrays.push(hairs);
			allArrays.push(factions);
			allArrays.push(boots);
			allArrays.push(tilesets);
			allArrays.push(specials);
			allArrays.push(ais);
			allArrays.push(items);
			allArrays.push(itemLists);
			allArrays.push(statuses);
			allArrays.push(playerPackages);
			allArrays.push(attackAnims);
			allArrays.push(enchantments);
			
			var arrayOn:Vector.<Array>;
			for (i = 0; i < data.length; i++)
			{
				line = data[i];
				line = line.substr(0, line.length - 1);
				if (line.charAt(0) != "/")
				{
					switch(line)
					{
						//other lists
					case "MAP:":
						arrayOn = maps;
						break;
					case "ROOM:":
						arrayOn = rooms;
						break;
					case "LIST:":
						arrayOn = lists;
						break;
					case "WEAPON:":
						arrayOn = weapons;
						break;
					case "ARMOR:":
						arrayOn = armors;
						break;
					case "STATUS:":
						arrayOn = statuses;
						break;
					case "ITEMLIST:":
						arrayOn = itemLists;
						break;
					case "SKILL:":
						arrayOn = skills;
						break;
					case "MATERIAL:":
						arrayOn = materials;
						break;
					case "RELIC:":
						arrayOn = relics;
						break;
					case "CREATURE:":
						arrayOn = creatures;
						break;
					case "RACE:":
						arrayOn = races;
						break;
					case "BOOT:":
						arrayOn = boots;
						break;
					case "COLOR:":
						arrayOn = colors;
						break;
					case "HAIR:":
						arrayOn = hairs;
						break;
					case "FACTION:":
						arrayOn = factions;
						break;
					case "TILESET:":
						arrayOn = tilesets;
						break;
					case "SPECIAL:":
						arrayOn = specials;
						break;
					case "PLAYERPACKAGE:":
						arrayOn = playerPackages;
						break;
					case "AI:":
						arrayOn = ais;
						break;
					case "ITEM:":
						arrayOn = items;
						break;
					case "ATTACKANIM:":
						arrayOn = attackAnims;
						break;
					case "ENCHANTMENT:":
						arrayOn = enchantments;
						break;
						
						//core lists
					case "SHEET:":
						arrayOn = sheets;
						break;
					case "SOUND:":
						arrayOn = sounds;
						break;
					case "FILLERDATA:":
						arrayOn = new Vector.<Array>();
						break;
					default:
						//tbis is a data line
						var ar:Array = line.split(" ");
						var newEntry:Array = new Array();
						for (j = 0; j < ar.length; j++)
						{
							//see if it's a string or a number
							if (j == 0)
								newEntry.push(ar[j]); //it's the name
							else if (ar[j] == "none") //it's an empty reference
								newEntry.push(NONE);
							else if (ar[j] == "true")
								newEntry.push(true);
							else if (ar[j] == "false")
								newEntry.push(false);
							else if (isNaN(ar[j]))
							{
								var st:String = ar[j] as String;
								if (st.charAt(0) == "@") //it's a line!
								{
									if (ar[j] == "@none") //it's an empty line
										newEntry.push(NONE);
									else
									{
										//find the line
										var foundLine:Boolean = false;
										for (var k:uint = 0; k < lineNames.length; k++)
											if ("@" + lineNames[k] == ar[j])
											{
												foundLine = true;
												newEntry.push(k);
												break;
											}
										if (!foundLine)
										{
											trace("Unable to find line " + ar[j]);
											newEntry.push(NONE);
										}
									}
								}
								else
									newEntry.push(st);
							}
							else
								newEntry.push((int) (ar[j]));
						}
						//push the finished list
						arrayOn.push(newEntry);
						break;
					}
				}
			}
			
			//link them
			link(allArrays);
			
			//link up sound effects
			for (i = 0; i < sounds.length; i++)
			{
				var SRC:Class;
				switch(i)
				{
				//case 0:
				//	SRC = SND1;
				//	break;
				}
				
				var snd:Sfx = new Sfx(SRC);
				soundEffects.push(snd);
			}
			
			//load up spritesheets
			for (i = 0; i < sheets.length; i++)
			{
				switch(i)
				{
				case 0:
					SRC = SPR1;
					break;
				case 1:
					SRC = SPR2;
					break;
				case 2:
					SRC = SPR3;
					break;
				case 3:
					SRC = SPR4;
					break;
				case 4:
					SRC = SPR5;
					break;
				case 5:
					SRC = SPR6;
					break;
				case 6:
					SRC = SPR7;
					break;
				}
				
				var spr:Spritemap = new Spritemap(SRC, sheets[i][1], sheets[i][2]);
				spr.originX = sheets[i][3];
				spr.originY = sheets[i][4];
				spriteSheets.push(spr);
			}
			
			//unload excess data
			sheets = null;
			sounds = null;
		}
		
		private function link(allArrays:Vector.<Vector.<Array>>):void
		{
			for (var i:uint = 0; i < allArrays.length; i++)
			{
				var arrayOn:Vector.<Array> = allArrays[i];
				
				for (var j:uint = 0; j < arrayOn.length; j++)
				{
					var entry:Array = arrayOn[j];
					
					for (var k:uint = 1; k < entry.length; k++)
					{
						if (isNaN(entry[k]))
						{
							var st:String = entry[k] as String;
							if (st.charAt(0) == "#") //it's a literal word
							{
								var newSt:String = "";
								for (var l:uint = 1; l < st.length; l++)
								{
									if (st.charAt(l) == "#")
										newSt += " ";
									else
										newSt += st.charAt(l);
								}
								entry[k] = newSt;
							}
							else
							{
								//link it somewhere
								
								var found:Boolean = false;
								for (l = 0; l < allArrays.length && !found; l++)
								{
									var arrayCheck:Vector.<Array> = allArrays[l];
									
									for (var m:uint = 0; m < arrayCheck.length; m++)
									{
										if (arrayCheck[m][0] == st)
										{
											entry[k] = m;
											found = true;
											break;
										}
									}
								}
								
								if (!found)
									trace("Unable to find " + entry[k]);
							}
						}
					}
				}
			}
		}
	}

}