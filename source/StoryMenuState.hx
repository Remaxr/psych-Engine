package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.addons.display.FlxGridOverlay;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
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

	private static var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;

	var weekThing:FlxSprite;
	var difficultyText:FlxSprite;
	var weekTitle:FlxSprite;
	var backspace:FlxSprite;

	private static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficultyGroup:FlxTypedGroup<FlxSprite>;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var sprDifficulty:FlxSprite;

	override function create()
	{
		#if MODS_ALLOWED
		Paths.destroyLoadedImages();
		#end
		WeekData.reloadWeekFiles(true);
		if(curWeek >= WeekData.weeksList.length) curWeek = 0;
		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		bgSprite = new FlxSprite(0, 0);
		bgSprite.antialiasing = ClientPrefs.globalAntialiasing;
		add(bgSprite);

		weekThing = new FlxSprite(0, 0);
		weekThing.antialiasing = ClientPrefs.globalAntialiasing;
		add(weekThing);

		weekTitle = new FlxSprite(30, 0);
		weekTitle.antialiasing = ClientPrefs.globalAntialiasing;
		add(weekTitle);

		backspace = new FlxSprite(-90, -15).loadGraphic(Paths.image('menuUI/backspace'));
		backspace.setGraphicSize(Std.int(backspace.width * 0.5));
		backspace.antialiasing = ClientPrefs.globalAntialiasing;
		add(backspace);

		difficultyText = new FlxSprite(-65, 440).loadGraphic(Paths.image('menuUI/difficultyText'));
		difficultyText.setGraphicSize(Std.int(difficultyText.width * 0.6));
		difficultyText.antialiasing = ClientPrefs.globalAntialiasing;
		add(difficultyText);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Storymode Menu", null);
		#end

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

		leftArrow = new FlxSprite(70, 575);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.setGraphicSize(Std.int(leftArrow.width * 1.25));
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(leftArrow);

		sprDifficultyGroup = new FlxTypedGroup<FlxSprite>();
		add(sprDifficultyGroup);

		
		for (i in 0...CoolUtil.difficultyStuff.length) {
			sprDifficulty = new FlxSprite(leftArrow.x + 115, leftArrow.y + 190).loadGraphic(Paths.image('menudifficulties/' + CoolUtil.difficultyStuff[i][0].toLowerCase()));
			sprDifficulty.x += (308 - sprDifficulty.width) / 2;
			sprDifficulty.setGraphicSize(Std.int(sprDifficulty.width * 0.5));
			sprDifficulty.ID = i;
			sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
			sprDifficultyGroup.add(sprDifficulty);
		}
		changeDifficulty();

		difficultySelectors.add(sprDifficultyGroup);

		rightArrow = new FlxSprite(leftArrow.x + 500, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.setGraphicSize(Std.int(rightArrow.width * 1.25));
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(rightArrow);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 425).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.globalAntialiasing;

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;

		changeWeek();

                #if android
                addVirtualPad(FULL, A_B_C);
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
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

		scoreText.text = "WEEK SCORE:" + lerpScore;

		difficultySelectors.visible = !weekIsLocked(curWeek);

		if (!movedBack && !selectedWeek)
		{
			if (controls.UI_UP_P)
			{
				changeWeek(-1);
				//FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (controls.UI_DOWN_P)
			{
				changeWeek(1);
				//FlxG.sound.play(Paths.sound('scrollMenu'));
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
			if (controls.UI_LEFT_P)
				changeDifficulty(-1);

			if (controls.ACCEPT)
			{
				selectWeek();
			}
			else if(controls.RESET #if android || _virtualpad.buttonC.justPressed #end)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				//FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);
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
				FlxG.sound.play(Paths.sound('confirmMenuBell'));

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

			var diffic = CoolUtil.difficultyStuff[curDifficulty][1];
			if(diffic == null) diffic = '';

			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
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

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficultyStuff.length-1;
		if (curDifficulty >= CoolUtil.difficultyStuff.length)
			curDifficulty = 0;

		sprDifficultyGroup.forEach(function(spr:FlxSprite) {
			spr.visible = false;
			if(curDifficulty == spr.ID) {
				spr.visible = true;
				spr.alpha = 0;
				spr.y = leftArrow.y - 100;
				FlxTween.tween(spr, {y: leftArrow.y - 80, alpha: 1}, 0.07);
			}
		});

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
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		bgSprite.visible = true;
		weekThing.visible = true;
		weekTitle.visible = true;
		//difficultyText.visible = true;
		//leftArrow.visible = true;
		//rightArrow.visible = true;
		//sprDifficulty.visible = true;
		//backspace.visible = true;
		var assetName:String = leWeek.weekBackground;
		var titleName:String = leWeek.weekName;
		var poop:String = '';
		if (titleName == 'trololoweek')
			poop = 'mrtrololo';
		else if (titleName == 'monstersweek')
			poop = 'monsters';
		if(assetName == null || assetName.length < 1) {
			bgSprite.visible = false;
			weekThing.visible = false;
			weekTitle.visible = false;
			//difficultyText.visible = false;
			//leftArrow.visible = false;
			//rightArrow.visible = false;
			//sprDifficulty.visible = false;
			//backspace.visible = false;
		} else {
			bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
			weekThing.loadGraphic(Paths.image('menuUI/' + poop));
			weekTitle.loadGraphic(Paths.image('menuUI/' + titleName));
			bgSprite.alpha = 0;
			weekThing.alpha = 0;
			weekTitle.alpha = 0;
			//difficultyText.alpha = 0;
			//leftArrow.alpha = 0;
			//rightArrow.alpha = 0;
			//sprDifficulty.alpha = 0;
			//backspace.alpha = 0;
			bgSprite.y = -100;
			weekThing.y = -100;
			weekTitle.y = -100;
			//difficultyText.y = -100;
			//leftArrow.y = -100;
			//rightArrow.y = -100;
			//sprDifficulty.y = -100;
			//backspace.y = -100;
			FlxTween.tween(bgSprite, {y: 0, alpha: 1}, 0.2);
			FlxTween.tween(weekThing, {y: 0, alpha: 1}, 0.2);
			FlxTween.tween(weekTitle, {y: 0, alpha: 1}, 0.2);
			//FlxTween.tween(difficultyText, {y: 0, alpha: 1}, 0.2);
			//FlxTween.tween(leftArrow, {y: 0, alpha: 1}, 0.2);
			//FlxTween.tween(rightArrow, {y: 0, alpha: 1}, 0.2);
			//FlxTween.tween(sprDifficulty, {y: 0, alpha: 1}, 0.2);
			//FlxTween.tween(backspace, {y: 0, alpha: 1}, 0.2);
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
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], curDifficulty);
		#end
	}
}
