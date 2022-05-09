package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import flixel.graphics.FlxGraphic;
import WeekData;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	// Wether you have to beat the previous week for playing this one
	// Not recommended, as people usually download your mod for, you know,
	// playing just the modded week then delete it.
	// defaults to True
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;

	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;

	private static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
    
    var storyMenuBG:FlxSprite;
    var maniaMenuBG:FlxSprite;
    
    var remixArray:Array<String> = ['iFlicky'];
    var chartArray:Array<String> = ['FullCombro x Polarin'];
    public var txtRemix:FlxText;
    public var txtChart:FlxText;
    

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if(curWeek >= WeekData.weeksList.length) curWeek = 0;
		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(FlxG.width * 0.7, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat(Paths.font("Spartan-Light.ttf"), 32);

		txtWeekTitle = new FlxText(10, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("Spartan-Light.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = ClientPrefs.globalAntialiasing;

		grpWeekText = new FlxTypedGroup<MenuItem>();
        
                
        storyMenuBG = new FlxSprite();
        storyMenuBG.loadGraphic(Paths.image('storyMenuBG'));
        storyMenuBG.x = 350;
        add(storyMenuBG);
        
        maniaMenuBG = new FlxSprite();
        maniaMenuBG.loadGraphic(Paths.image('maniaMenuBG'));
        maniaMenuBG.x = 320;
        maniaMenuBG.alpha = 0;
        add(maniaMenuBG);
        
        var storyMenuOverlay:FlxSprite = new FlxSprite();
        storyMenuOverlay.loadGraphic(Paths.image('storyMenuOverlay'));
        storyMenuOverlay.x = 0;
        add(storyMenuOverlay);
        
        var txtTracks:FlxText = new FlxText(40, 320, 0, "", 18);
		txtTracks.setFormat(Paths.font("Spartan-Light.ttf"), 22, 0xFF747474, LEFT);
		txtTracks.alpha = 1;
        txtTracks.text="TRACK LIST";
        add(txtTracks);

		txtTracklist = new FlxText(40, txtTracks.y + 28, 0, "", 32);
		txtTracklist.setFormat(Paths.font("Spartan-Light.ttf"), 36, FlxColor.WHITE, LEFT);
		add(txtTracklist);
        
        trace(txtTracks);
        trace(txtTracklist);
        
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);
        
        txtRemix = new FlxText(40, txtTracks.y + 68, 0, "", 18);
		txtRemix.setFormat(Paths.font("Spartan-Light.ttf"), 22, 0xFF747474, LEFT);
		txtRemix.alpha = 0;
        txtRemix.text="REMIX BY";
        add(txtRemix);
        
        txtChart = new FlxText(40, txtTracks.y + 100, 0, "", 18);
		txtChart.setFormat(Paths.font("Spartan-Light.ttf"), 22, 0xFF747474, LEFT);
		txtChart.alpha = 0;
        txtChart.text="CHART BY";
        add(txtChart);
        
        
        
		add(grpWeekText);
        

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		// add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length)
		{
			WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
			var weekThing:MenuItem = new MenuItem(875, -500, WeekData.weeksList[i]);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
            weekThing.scrollFactor.set();
			grpWeekText.add(weekThing);

			// weekThing.screenCenter(X);
			weekThing.antialiasing = ClientPrefs.globalAntialiasing;
			// weekThing.updateHitbox();

			// Needs an offset thingie
			if (weekIsLocked(i))
			{
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = ClientPrefs.globalAntialiasing;
				grpLocks.add(lock);
			}
		}

		WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[0]));
		var charArray:Array<String> = WeekData.weeksLoaded.get(WeekData.weeksList[0]).weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(1080,680);
		leftArrow.loadGraphic(Paths.image("leftArrow"));
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(leftArrow);

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
		changeDifficulty();

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 168, leftArrow.y);
        rightArrow.loadGraphic(Paths.image("rightArrow"));
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(rightArrow);

		// add(bgYellow);
		// add(bgSprite);
		// add(grpWeekCharacters);
        
        /*
		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 425).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.globalAntialiasing;
		add(tracksSprite);
        */
        

		changeWeek();

    #if android
  	addVirtualPad(FULL, A_B);
    #end

		super.create();
	}

	override function closeSubState() {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

		scoreText.text = "WEEK SCORE:" + lerpScore;

		// FlxG.watch.addQuick('font', scoreText.font);

		difficultySelectors.visible = !weekIsLocked(curWeek);

		if (!movedBack && !selectedWeek)
		{
			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;
			if (upP)
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (downP)
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (controls.UI_RIGHT)
				rightArrow.animation.play('press')
			else
				rightArrow.animation.play('idle');

			if (controls.UI_LEFT)
				leftArrow.animation.play('press');
			else
				leftArrow.animation.play('idle');

			if (controls.UI_RIGHT_P)
				changeDifficulty(1);
			else if (controls.UI_LEFT_P)
				changeDifficulty(-1);
			else if (upP || downP)
				changeDifficulty();

			if(FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}
			else if(controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				//FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);

		grpLocks.forEach(function(lock:FlxSprite)
		{
			// lock.y = grpWeekText.members[lock.ID].y;
		});
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!weekIsLocked(curWeek))
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				if(grpWeekCharacters.members[1].character != '') grpWeekCharacters.members[1].animation.play('confirm');
				stopspamming = true;
			}

			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).songs;
			for (i in 0...leWeek.length) {
				songArray.push(leWeek[i][0]);
			}

			// Nevermind that's stupid lmao
			PlayState.storyPlaylist = songArray;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
			if(diffic == null) diffic = '';

			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});
		} else {
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}

	var tweenDifficulty:FlxTween;
	var lastImagePath:String;
	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;


		var image:Dynamic = Paths.image('menudifficulties/' + Paths.formatToSongPath(CoolUtil.difficulties[curDifficulty]));
		var newImagePath:String = '';
		if(Std.isOfType(image, FlxGraphic))
		{
			var graphic:FlxGraphic = image;
			newImagePath = graphic.assetsKey;
		}
		else
			newImagePath = image;
        
        trace("curDif = " + CoolUtil.difficulties[curDifficulty]);
        if (curWeek > 0) {
            if (maniaMenuBG.alpha != 1) {
                var tweenOffset = 100 * change;
                maniaMenuBG.x += tweenOffset;
                FlxTween.tween(maniaMenuBG, {x:maniaMenuBG.x - tweenOffset, y:maniaMenuBG.y, alpha:1},0.25, { type:FlxTween.ONESHOT, ease:FlxEase.quadInOut });
                FlxTween.tween(storyMenuBG, {alpha:0},0.25, { type:FlxTween.ONESHOT, ease:FlxEase.quadInOut });
            }
        } else {
            if (storyMenuBG.alpha != 1) {
                var tweenOffset = 100 * change;
                storyMenuBG.x += tweenOffset;
                FlxTween.tween(storyMenuBG, {x:storyMenuBG.x - tweenOffset, y:storyMenuBG.y, alpha:1},0.25, { type:FlxTween.ONESHOT, ease:FlxEase.quadInOut });
                FlxTween.tween(maniaMenuBG, {alpha:0},0.25, { type:FlxTween.ONESHOT, ease:FlxEase.quadInOut });
            }
        }

        
		if(newImagePath != lastImagePath)
		{
			sprDifficulty.loadGraphic(image);
			sprDifficulty.x = leftArrow.x + 20;
			sprDifficulty.x += (143 - sprDifficulty.width) / 2;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y;

			if(tweenDifficulty != null) tweenDifficulty.cancel();
			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y, alpha: 1}, 0.07, {onComplete: function(twn:FlxTween)
			{
				tweenDifficulty = null;
			}});
		}
		lastImagePath = newImagePath;
		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], curDifficulty);
		#end
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= WeekData.weeksList.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = WeekData.weeksList.length - 1;

		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);
		WeekData.setDirectoryFromWeek(leWeek);

		var leName:String = leWeek.storyName;
		txtWeekTitle.text = leName.toUpperCase();
		// txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var bullShit:Int = 0;
        
        for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && !weekIsLocked(curWeek))
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}
		
		PlayState.storyWeek = curWeek;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
	}

	function weekIsLocked(weekNum:Int) {
		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[weekNum]);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText()
	{
		var weekArray:Array<String> = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).weekCharacters;
		for (i in 0...grpWeekCharacters.length) {
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
		}

		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length) {
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
            var stringManiaStrip:String = stringThing[i];
            if (stringManiaStrip.toLowerCase().substr(stringManiaStrip.length - 5, 5) == "mania") {
                stringManiaStrip = stringManiaStrip.substr(0, stringManiaStrip.length - 6);   
            }
			txtTracklist.text += stringManiaStrip + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		// txtTracklist.screenCenter(X);
		// txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], curDifficulty);
		#end
	}
}
