package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;

import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.5.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;
    

	var menuItems:FlxTypedGroup<FlxSprite>;
 
    public var menuLSE:FlxSprite;
    var initX:Float;
    var initY:Float;
 
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'options',
		'credits'
	];

	var debugKeys:Array<FlxKey>;
    

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));


		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		// var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('mainmenu/menu_bg'));
     	bg.screenCenter();
		bg.antialiasing = false;
		add(bg);
        

        
		for (i in 0...optionShit.length)
		{
			var offset:Float = 20 - (Math.max(optionShit.length, 4) - 4) * 10;
			var menuItem:FlxSprite = new FlxSprite(640, (i * 140)  + offset);
            

            menuItem.loadGraphic(Paths.image('mainmenu/menu_ds_' + optionShit[i]));
			menuItem.loadGraphic(Paths.image('mainmenu/menu_' + optionShit[i]));
			menuItem.ID = i;
			// menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, 0);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
            
            menuItem.x = FlxG.width - menuItem.width + 40;

            // var menuPlacementX = 1260;
            // menuItem.x = menuPlacementX - (menuItem.width * 0.72);
            // trace(menuItem.width);
			// menuItem.updateHitbox();
            
            
             
		}

        
        
        
        // trace(menuItems.members[0]);

		var versionShit:FlxText = new FlxText(12, ClientPrefs.getResolution()[1] - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, ClientPrefs.getResolution()[1] - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
        
        
        
        

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();
        

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

                #if android
                addVirtualPad(UP_DOWN, A_B_E);
                #end

		super.create();
	}



	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}


		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
                menuLSE.animation.play('up');
                menuLSE.x = initX - 8;
                menuLSE.y = initY - 30;
                new FlxTimer().start(0.2, function(tmr:FlxTimer)
                {
                    menuLSE.animation.play('idle');
                    menuLSE.x = initX;
                    menuLSE.y = initY;
                });
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
                menuLSE.animation.play('down');
                // oh god manual offsets I'm sorry
                menuLSE.x = initX - 12;
                menuLSE.y = initY + 62;
                new FlxTimer().start(0.2, function(tmr:FlxTimer)
                {
                    menuLSE.animation.play('idle');
                    menuLSE.x = initX;
                    menuLSE.y = initY;
                });
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										MusicBeatState.switchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			// spr.screenCenter(X);
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
        

		menuItems.forEach(function(spr:FlxSprite)
		{
  
			if (spr.ID == curSelected)
			{
				spr.loadGraphic(Paths.image('mainmenu/menu_' + optionShit[spr.ID]));
                FlxTween.tween(spr, {x: FlxG.width - spr.width}, 0.1, {ease:FlxEase.quadInOut});
                
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
            } else {
                spr.loadGraphic(Paths.image('mainmenu/menu_ds_' + optionShit[spr.ID]));
                FlxTween.tween(spr, {x: FlxG.width - spr.width + 40}, 0.1, {ease:FlxEase.quadInOut});
            }
		});
	}
}
