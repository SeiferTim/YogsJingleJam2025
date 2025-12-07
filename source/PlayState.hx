package;

import CharacterData.WeaponType;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class PlayState extends FlxState
{
	public static var current:PlayState;

	public var map:FlxTilemap;
	public var player:Player;
	var selectedCharacter:CharacterData; // Character selected in CharacterSelectState

	public var projectiles:FlxTypedGroup<Projectile>; // Made public for MagicBallProjectile lifespan detection
	public var bossProjectiles:FlxTypedGroup<Projectile>; // Made public for MagicBallProjectile lifespan detection

	var plasmas:FlxTypedGroup<Plasma>;

	public var mayflies:FlxTypedGroup<Mayfly>; // Made public for MagicBallProjectile.findNearestEnemy()
	public var ghosts:FlxTypedGroup<Ghost>; // Made public for MagicBallProjectile.findNearestEnemy()
	var whiteGhosts:FlxTypedGroup<FlxSprite>; // White sprite overlay for ghost spawn animation
	var hearts:FlxTypedGroup<HeartPickup>;
	var spiritOrbs:FlxTypedGroup<SpiritOrb>;
	var timePulseRocks:FlxTypedGroup<FlxSprite>; // Rocks spawned during boss2 Time Pulse attack

	public var hud:HUD;
	// Boss phases
	public var boss:BossPhase01Larva; // Made public for MagicBallProjectile.findNearestEnemy()
	var boss2:BossPhase02;
	var currentBossPhase:Int = 1;
	
	var cameraTarget:FlxObject;
	var cinematics:CinematicManager;

	// Mayfly spawning
	var mayflySpawnTimer:Float = 0;
	var mayflySpawnInterval:Float = 3.0; // Spawn attempt every 3 seconds

	public var shadowLayer:ShadowLayer;

	var introState:IntroState = FADE_IN;
	var introTimer:Float = 0;
	var fadeOverlay:FlxSprite;
	var eggSprite:FlxSprite;
	var cocoonSprite:FlxSprite;
	var playerActive:Bool = false;
	// Phase transition
	public var gameState:GameState = INTRO;
	var transitionTimer:Float = 0;

	public function new(?character:CharacterData)
	{
		super();
		current = this;
		selectedCharacter = character;
	}

	override public function create()
	{
		super.create();
		Actions.init();

		// Enable pixel-perfect rendering
		FlxG.camera.pixelPerfectRender = true;
		FlxG.camera.antialiasing = false;

		map = new FlxTilemap();
		map.loadMapFromCSV("assets/maps/base.csv", "assets/images/lofi_environment.png", 8, 8, FlxTilemapAutoTiling.OFF, 0, 0);
		add(map);

		FlxG.worldBounds.set(8, 8, map.width - 16, map.height - 16);
		// Shadow layer - renders above map but below entities
		// Creates a bitmap layer at 0.7 alpha so overlapping shadows don't compound
		shadowLayer = new ShadowLayer(Std.int(map.width), Std.int(map.height));
		add(shadowLayer);

		// Create projectile groups (but don't add yet - add after player/boss for proper layering)
		projectiles = new FlxTypedGroup<Projectile>();
		bossProjectiles = new FlxTypedGroup<Projectile>();
		plasmas = new FlxTypedGroup<Plasma>(5);
		mayflies = new FlxTypedGroup<Mayfly>(5);
		ghosts = new FlxTypedGroup<Ghost>(10);
		whiteGhosts = new FlxTypedGroup<FlxSprite>(10); // For spawn animation
		hearts = new FlxTypedGroup<HeartPickup>(10);
		spiritOrbs = new FlxTypedGroup<SpiritOrb>(10);
		timePulseRocks = new FlxTypedGroup<FlxSprite>(10);

		add(hearts);
		add(spiritOrbs);
		add(timePulseRocks); // Add rocks to scene (will be spawned by boss2)

		// Initialize plasma pool
		for (i in 0...plasmas.maxSize)
		{
			plasmas.add(new Plasma());
		}

		// Initialize spirit orb pool
		for (i in 0...spiritOrbs.maxSize)
		{
			spiritOrbs.add(new SpiritOrb());
		}
		eggSprite = new FlxSprite(0, 0);
		eggSprite.loadGraphic("assets/images/boss-phase-00-egg.png", true, 256, 100);
		eggSprite.animation.frameIndex = 0;
		eggSprite.visible = false;
		add(eggSprite);
		// Cocoon sprite (for phase transitions)
		cocoonSprite = new FlxSprite(0, 0);
		cocoonSprite.loadGraphic("assets/images/boss-phase-01-cocoon.png");
		cocoonSprite.visible = false;
		cocoonSprite.alpha = 0;
		add(cocoonSprite);

		player = new Player((map.width / 2) - 4, map.height - 32, projectiles);
		player.active = false;
		// Apply character stats if available
		if (selectedCharacter != null)
		{
			player.maxHP = selectedCharacter.maxHP;
			player.currentHP = selectedCharacter.maxHP;
			player.attackDamage = selectedCharacter.attackDamage;
			player.moveSpeed = selectedCharacter.moveSpeed;
			player.luck = selectedCharacter.luck;

			// Set the character sprite frame from the selected character
			player.animation.frameIndex = selectedCharacter.spriteFrame;

			// Set the weapon based on character's weapon type
			player.setWeapon(selectedCharacter.weaponType);
			// Add weapon hitboxes to scene (for melee weapons)
			if (Std.isOfType(player.weapon, Sword))
			{
				var sword:Sword = cast player.weapon;
				add(sword.getSlashHitbox());
				add(sword.getSpinHitbox());
			}
			else if (Std.isOfType(player.weapon, Halberd))
			{
				var halberd:Halberd = cast player.weapon;
				add(halberd.getJabHitbox());
			}
		}
		
		add(player);

		// Create player shadow
		// Width: 1.2x, Height: 0.25x, Anchor: center.x, y + height
		player.shadow = new Shadow(player, 1.2, 0.25, 0, player.height / 2);
		shadowLayer.add(player.shadow);

		// Add player reticle and dizzy sprite to scene
		add(player.reticle);
		add(player.dizzySprite);

		// Boss spawns at center of egg sprite
		// Egg is 100px tall with center.y at 57px
		var bossSpawnX = eggSprite.x + eggSprite.width / 2;
		var bossSpawnY = eggSprite.y + 57;
		boss = new BossPhase01Larva(bossSpawnX, bossSpawnY, player, null, bossProjectiles, plasmas);
		boss.visible = true; // Always visible, but starts at alpha 0
		boss.active = false;
		boss.currentHealth = 0;
		add(boss);

		// Create boss shadows for each segment
		boss.createShadows(shadowLayer);

		// Add mayflies and hearts before projectiles
		add(mayflies);
		add(ghosts);
		add(whiteGhosts); // White ghost spawn animation sprites

		// Add projectiles AFTER player and boss so they render on top
		add(projectiles);
		add(bossProjectiles);
		add(plasmas);
		// Create camera target for smooth camera control
		cameraTarget = new FlxObject(player.x, player.y, 1, 1);
		add(cameraTarget);

		FlxG.camera.follow(cameraTarget, LOCKON);
		FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);
		// Initialize cinematic manager
		cinematics = new CinematicManager(FlxG.camera, cameraTarget, player);

		var characterName = selectedCharacter != null ? selectedCharacter.name : null;
		hud = new HUD(player, boss, characterName);
		// HUD player elements always visible, only boss health is hidden initially
		hud.visible = true;
		hud.setBossHealthVisible(false);
		add(hud);
		fadeOverlay = new FlxSprite(0, 0);
		fadeOverlay.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		fadeOverlay.scrollFactor.set(0, 0);
		add(fadeOverlay);

		// No longer need to manually set camera scroll
		// FlxG.camera.scroll.set(player.x - FlxG.width / 2, player.y - FlxG.height / 2);

		startIntroSequence();
	}

	override public function update(elapsed:Float)
	{
		// DEBUG: Press T to test phase transition
		if (FlxG.keys.justPressed.T && gameState == PHASE_1_ACTIVE)
		{
			trace("DEBUG: Force Phase 1 death");
			boss.currentHealth = 0;
		}

		if (gameState == INTRO)
		{
			updateIntroSequence(elapsed);
		}
		else if (gameState == PHASE_0_5_GHOSTS)
		{
			// Phase 0.5: Staggered ghost spawning and fight BEFORE egg hatches
			updatePhase0_5Ghosts(elapsed);
			updateMayflySpawning(elapsed); // Allow healing during ghost fight
			checkProjectileCollisions();
			checkMeleeWeaponCollisions();
			checkGhostCollisions();
		}
		else if (gameState == PHASE_1_ACTIVE)
		{
			// Check if boss Phase 1 is defeated
			if (boss != null && boss.currentHealth <= 0)
			{
				startPhase1DeathSequence();
			}

			// Update Mayfly spawning
			updateMayflySpawning(elapsed);
			checkProjectileCollisions();
			checkMeleeWeaponCollisions(); // Check sword/halberd vs boss
			checkBossCollisions();
		}
		else if (gameState == PHASE_1_DEATH)
		{
			updatePhase1DeathSequence(elapsed);
		}
		else if (gameState == PHASE_1_5_ACTIVE)
		{
			updatePhase1_5(elapsed);
			// IMPORTANT: Spawn MORE mayflies during cocoon phase so player can heal!
			updateMayflySpawning(elapsed);
			
			checkProjectileCollisions();
			// No boss collisions during cocoon phase
		}
		else if (gameState == PHASE_2_5_ACTIVE)
		{
			updatePhase2_5(elapsed);
			// Allow healing and normal projectile checks while ghosts fight
			updateMayflySpawning(elapsed);
			checkProjectileCollisions();
			checkGhostCollisions();
		}
		else if (gameState == PHASE_2_ACTIVE)
		{
			// Check if boss Phase 2 is defeated
			if (boss2 != null && boss2.currentHealth <= 0)
			{
				trace("Phase 2 boss defeated!");
				// TODO: Implement Phase 2 death sequence similar to Phase 1
				// For now just go straight to game over
				gameState = PHASE_2_DEATH;
			}

			// Update Mayfly spawning
			updateMayflySpawning(elapsed);
			
			checkProjectileCollisions();
			checkMeleeWeaponCollisions(); // Check melee vs boss2
			checkPhase2Collisions();
		}
		
		super.update(elapsed);
	}
	function startIntroSequence():Void
	{
		introState = FADE_IN;
		introTimer = 0;

		// Make egg visible BEFORE fade starts
		eggSprite.visible = true;

		FlxTween.tween(fadeOverlay, {alpha: 0}, 1.0, {
			ease: FlxEase.quadOut,
			onComplete: function(t:FlxTween)
			{
				introState = SCROLL_TO_EGG;
				introTimer = 0;
			}
		});
	}

	function updateIntroSequence(elapsed:Float):Void
	{
		introTimer += elapsed;

		switch (introState)
		{
			case FADE_IN: // FlxTween handles, just wait

			case SCROLL_TO_EGG:
				if (introTimer > 0.8)
				{
					FlxTween.tween(cameraTarget, {y: eggSprite.y + eggSprite.height / 2}, 2.0, {
						ease: FlxEase.quadInOut,
						onComplete: _ -> 
						{
							introState = EGG_PAUSE_1;
							introTimer = 0;
							// Check for ghosts BEFORE egg hatches
							checkForGhostsOrStartHatch();
						}
					});
					introState = SCROLLING;
				}

			case SCROLLING: // FlxTween handles

			case EGG_PAUSE_1:
				if (introTimer > 0.4)
					advanceIntro(EGG_CRACK_1);

			case EGG_CRACK_1:
				eggSprite.animation.frameIndex = 1;
				if (introTimer > 0.05)
					advanceIntro(EGG_PAUSE_2);

			case EGG_PAUSE_2:
				if (introTimer > 0.4)
					advanceIntro(EGG_CRACK_2);

			case EGG_CRACK_2:
				eggSprite.animation.frameIndex = 2;
				if (introTimer > 0.05)
					advanceIntro(EGG_PAUSE_3);

			case EGG_PAUSE_3:
				if (introTimer > 0.4)
					advanceIntro(EGG_CRACK_REST);

			case EGG_CRACK_REST:
				eggSprite.animation.frameIndex = introTimer < 0.3 ? 2 + Math.floor((introTimer / 0.3) * 3) : 4;
				if (introTimer > 0.5)
					advanceIntro(EGG_PAUSE_4);

			case EGG_PAUSE_4:
				if (introTimer > 0.3)
				{
					boss.active = true;
					boss.visible = true; // Make sure boss is visible before fade-in
					advanceIntro(BOSS_FADE_IN);
				}

			case BOSS_FADE_IN:
				boss.fadeIn(Math.min(introTimer / 1.5, 1.0));
				if (introTimer >= 1.5)
					advanceIntro(BOSS_UNFURL);

			case BOSS_UNFURL:
				boss.unfurl(Math.min(introTimer / 1.5, 1.0));
				var headPos = boss.getHeadPosition();
				cameraTarget.setPosition(headPos.x, headPos.y);
				if (introTimer >= 1.5)
					advanceIntro(BOSS_DESCEND);

			case BOSS_DESCEND:
				boss.moveTo(map.width / 2, map.height - 64, 40, elapsed);
				var headPos = boss.getHeadPosition();
				cameraTarget.setPosition(headPos.x, headPos.y);
				if (boss.isAtPosition(map.width / 2, map.height - 64))
					advanceIntro(HEALTH_BAR_APPEAR);

			case HEALTH_BAR_APPEAR:
				// Show and fade in boss health bar only
				if (!hud.bossHealthBar.visible && introTimer > 0.05)
				{
					hud.setBossHealthVisible(true);
				}
				// Fade in just the boss health bar
				hud.bossHealthBar.setAlpha(Math.min(introTimer / 0.5, 1.0));
				if (introTimer > 0.8)
					advanceIntro(HEALTH_BAR_PAUSE);

			case HEALTH_BAR_PAUSE:
				if (introTimer > 0.4)
				{
					boss.currentHealth = 0;
					hud.revealBossName();
					advanceIntro(HEALTH_BAR_FILL);
				}

			case HEALTH_BAR_FILL:
				boss.currentHealth = introTimer < 1.0 ? FlxMath.lerp(0, boss.maxHealth, introTimer) : boss.maxHealth;
				if (introTimer > 1.2)
					advanceIntro(BOSS_ROAR);

			case BOSS_ROAR:
				if (introTimer < 0.05)
				{
					boss.roar();
					FlxG.camera.shake(0.02, 0.4);
				}
				if (introTimer < 0.8)
					eggSprite.alpha = 1.0 - (introTimer / 0.8);
				else if (eggSprite.visible)
					eggSprite.visible = false;

				if (introTimer > 1.0)
					boss.closeRoar();
				if (introTimer > 1.5)
				{
					FlxTween.tween(cameraTarget, {x: player.x, y: player.y}, 0.5, {
						ease: FlxEase.quadInOut,
						onComplete: _ ->
						{
							introState = COMPLETE;
							// Start the battle
							startBattle();
						}
					});
					introState = SCROLL_TO_PLAYER;
				}

			case SCROLL_TO_PLAYER: // FlxTween handles

			case COMPLETE:
		}
	}

	inline function advanceIntro(nextState:IntroState):Void
	{
		introState = nextState;
		introTimer = 0;
	}

	function checkForGhostsOrStartHatch():Void
	{
		// Filter ghosts: only spawn those who died in Phase 0 or Phase 1
		var allGhosts = GameData.getDeadCharacters();
		var phase0And1Ghosts = allGhosts.filter(function(char:CharacterData)
		{
			return char.deathPhase <= 1; // Phase 0 or Phase 1 deaths
		});

		if (phase0And1Ghosts.length > 0)
		{
			trace("Found " + phase0And1Ghosts.length + " Phase 0/1 ghosts - starting Phase 0.5");
			startPhase0_5Ghosts(phase0And1Ghosts);
		}
		else
		{
			trace("No Phase 0/1 ghosts - continuing with egg hatch");
			// Continue with the intro (egg will hatch)
			// Don't need to do anything - intro will continue naturally
		}
	}

	var ghostSpawnQueue:Array<CharacterData> = [];
	var ghostSpawnTimer:Float = 0;
	var ghostSpawnInterval:Float = 0.5; // Spawn one ghost every 0.5 seconds
	var ghostsSpawningComplete:Bool = false; // Track when all ghosts have spawned
	var ghostsDefeatedTimer:Float = 0; // Timer after all ghosts are defeated
	var ghostsAllDead:Bool = false; // Track when all ghosts are dead

	// Batched ghost spawning
	var ghostBatches:Array<Array<CharacterData>> = [];
	var currentBatchIndex:Int = 0;
	var currentBatchSpawned:Bool = false;
	var maxGhostsPerBatch:Int = 3;

	function startPhase0_5Ghosts(ghostsToSpawn:Array<CharacterData>):Void
	{
		gameState = PHASE_0_5_GHOSTS;
		player.active = false; // Player can't move during ghost spawning
		player.reticle.visible = false; // Hide reticle during cinematics
		ghostsSpawningComplete = false;
		ghostsAllDead = false;
		ghostsDefeatedTimer = 0;
		Ghost.resetSpawnCounter(); // Reset ghost spawn animation stagger

		// Hide boss during ghost fight - fade to 0
		boss.forEach(spr -> if (spr != null) spr.alpha = 0);
		boss.visible = false;

		// Sort ghosts by level (lowest to highest) and split into batches
		ghostsToSpawn.sort((a, b) -> a.level - b.level);
		ghostBatches = createGhostBatches(ghostsToSpawn, maxGhostsPerBatch);
		currentBatchIndex = 0;
		currentBatchSpawned = false;

		// Pan to player BEFORE spawning ghosts (so ghosts spawn around player in bottom half)
		cinematics.panTo(player.x, player.y, 1.0, 1.0, function()
		{
			trace("Phase 0.5: Camera on player, starting ghost spawns");
			
			// Queue up first batch for staggered spawning
			if (ghostBatches.length > 0)
			{
				ghostSpawnQueue = ghostBatches[0].copy();
				ghostSpawnTimer = 0;
			}
		});

		trace("Phase 0.5: Spawning "
			+ ghostsToSpawn.length
			+ " ghosts in "
			+ ghostBatches.length
			+ " batches (max "
			+ maxGhostsPerBatch
			+ " per batch)");
	}

	function updatePhase0_5Ghosts(elapsed:Float):Void
	{
		// Debug: Log state every 2 seconds
		if (Std.int(ghostsDefeatedTimer) % 2 == 0 && ghostsDefeatedTimer > 0 && ghostsDefeatedTimer < 0.1)
		{
			trace("Phase 0.5 Status - Ghosts alive: " + ghosts.countLiving() + ", Batch: " + (currentBatchIndex + 1) + "/" + ghostBatches.length
				+ ", Timer: " + ghostsDefeatedTimer + ", All dead flag: " + ghostsAllDead);
		}

		// Staggered ghost spawning for current batch
		if (ghostSpawnQueue.length > 0)
		{
			ghostSpawnTimer += elapsed;
			if (ghostSpawnTimer >= ghostSpawnInterval)
			{
				ghostSpawnTimer = 0;
				var charData = ghostSpawnQueue.shift();
				spawnSingleGhost(charData);
				trace("Spawned ghost: " + charData.name + " (Level " + charData.level + ") - Remaining in batch: " + ghostSpawnQueue.length);
			}
			return; // Don't check for victory yet
		}
		
		// Current batch spawned - check if all are dead before spawning next batch
		if (!currentBatchSpawned && ghostSpawnQueue.length == 0)
		{
			currentBatchSpawned = true;
			trace("Batch " + (currentBatchIndex + 1) + " fully spawned - waiting for white ghost animation");
			return;
		}

		// Wait for white ghost spawn animations to complete before starting fight
		if (currentBatchSpawned && whiteGhosts.countLiving() > 0)
		{
			// Still animating, wait...
			return;
		}

		// All white ghosts done animating - start fight immediately (no pan, already on player)
		if (currentBatchSpawned && whiteGhosts.countLiving() == 0 && !player.active)
		{
			trace("Phase 0.5 batch " + (currentBatchIndex + 1) + " fight started!");
			FlxG.camera.follow(player, LOCKON);
			player.active = true;
			player.reticle.visible = true;
			// Activate all ghosts now
			ghosts.forEachAlive(function(ghost:Ghost)
			{
				ghost.active = true;
			});
			return;
		}

		// Check if current batch is defeated
		var currentGhostCount = ghosts.countLiving();
		if (currentBatchSpawned && currentGhostCount == 0 && !ghostsAllDead)
		{
			// All ghosts in current batch defeated
			currentBatchIndex++;

			if (currentBatchIndex < ghostBatches.length)
			{
				// Spawn next batch
				trace("=== BATCH " + currentBatchIndex + " DEFEATED - SPAWNING NEXT BATCH ===");
				ghostSpawnQueue = ghostBatches[currentBatchIndex].copy();
				ghostSpawnTimer = 0;
				currentBatchSpawned = false;
				Ghost.resetSpawnCounter(); // Reset animation stagger for new batch
			}
			else
			{
				// All batches completed
				trace("=== ALL GHOST BATCHES DEFEATED! ===");
				trace("Starting 3-second timer before transition...");
				ghostsAllDead = true;
				ghostsDefeatedTimer = 0;
			}
			return;
		}

		// If waiting for all ghosts to be defeated
		if (ghostsAllDead)
		{
			// Increment timer
			ghostsDefeatedTimer += elapsed;

			// Trace every second
			var currentSecond = Std.int(ghostsDefeatedTimer);
			var lastSecond = Std.int(ghostsDefeatedTimer - elapsed);
			if (currentSecond > lastSecond)
			{
				trace("Phase 0.5 timer: " + currentSecond + " seconds (waiting for 3)");
			}

			// After 3 seconds, end Phase 0.5
			if (ghostsDefeatedTimer >= 3.0)
			{
				trace("=== 3 SECONDS ELAPSED - ENDING PHASE 0.5 ===");
				endPhase0_5Ghosts();
			}
			return;
		}

		// Occasional check - trace every 3 seconds while fighting
		if (currentGhostCount > 0 && ghostsDefeatedTimer == 0 && Std.int(elapsed * 60) % 180 == 0)
		{
			trace("Phase 0.5 - Still fighting: " + currentGhostCount + " ghost(s) alive");
		}
	}

	function createGhostBatches(ghosts:Array<CharacterData>, batchSize:Int):Array<Array<CharacterData>>
	{
		var batches:Array<Array<CharacterData>> = [];
		var currentBatch:Array<CharacterData> = [];

		for (ghost in ghosts)
		{
			currentBatch.push(ghost);
			if (currentBatch.length >= batchSize)
			{
				batches.push(currentBatch);
				currentBatch = [];
			}
		}

		// Add remaining ghosts as final batch
		if (currentBatch.length > 0)
		{
			batches.push(currentBatch);
		}
		return batches;
	}

	function endPhase0_5Ghosts():Void
	{
		trace("=== ENDING PHASE 0.5 GHOSTS ===");
		trace("Transitioning to egg hatch sequence...");

		// IMMEDIATELY switch to INTRO state to prevent updatePhase0_5Ghosts from running during transition
		gameState = INTRO;
		introState = EGG_PAUSE_1; // Will start egg hatch after cinematics complete
		introTimer = 0;

		// Stop player control and hide reticle
		player.active = false;
		player.velocity.set(0, 0);
		player.reticle.visible = false;

		// Calculate player destination
		var startX = (map.width / 2) - 4;
		var startY = map.height - 32;
		var moveTime = Math.sqrt(Math.pow(startX - player.x, 2) + Math.pow(startY - player.y, 2)) / (40 * player.moveSpeed);

		cameraTarget.setPosition(player.x + player.width / 2, player.y + player.height / 2);
		
		// Move player with 1 second start delay, then pan to egg with another 1 second delay
		cinematics.followTween(player, startX, startY, moveTime, 1.0, function()
		{
			trace("Player reached position, now panning to egg...");
			// Pan camera to egg (with 1 second delay after player arrives)
			cinematics.panToSprite(eggSprite, 1.0, 1.0, function()
			{
				trace("Pan to egg complete - egg hatch will now proceed");
				// introState is already EGG_PAUSE_1, just reset timer to trigger hatch
				introTimer = 0;
			});
		});
	}
	function spawnSingleGhost(charData:CharacterData):Void
	{
		// Get ghost spawn position first (but don't activate ghost yet)
		var eggCenterX = eggSprite.x + eggSprite.width / 2;
		var eggCenterY = eggSprite.y + 57;

		// Spawn in BOTTOM half of arena (below egg) with buffer around player
		var spawnX:Float;
		var spawnY:Float;
		var attempts = 0;
		var maxAttempts = 50;

		// Get player position for buffer check
		var playerCenterX = player.x + player.width / 2;
		var playerCenterY = player.y + player.height / 2;

		do
		{
			spawnX = FlxG.random.float(16, map.width - 24);
			spawnY = FlxG.random.float(map.height / 2 + 16, map.height - 24);
			attempts++;
		}
		while (attempts < maxAttempts && ( // Too close to egg
				Math.sqrt(Math.pow(spawnX - eggCenterX, 2) + Math.pow(spawnY - eggCenterY, 2)) < 64 // Too close to player (24px buffer)
				|| Math.sqrt(Math.pow(spawnX - playerCenterX, 2) + Math.pow(spawnY - playerCenterY, 2)) < 24));

			// Create white ghost sprite for spawn animation
		var whiteGhost:FlxSprite = whiteGhosts.getFirstAvailable();
		if (whiteGhost == null)
		{
			whiteGhost = new FlxSprite();
			whiteGhost.loadGraphic("assets/images/white-ghost.png", true, 8, 8); // Same 8x8 spritesheet format as players.png
			whiteGhosts.add(whiteGhost);
		}

		// Set the sprite frame to match the character
		whiteGhost.animation.frameIndex = charData.spriteFrame;

		// Position white ghost centered at spawn location
		// Center the sprite at the spawn point (spawnX, spawnY is top-left of 16x16 ghost)
		// We want white ghost centered at spawnX+8, spawnY+8
		whiteGhost.scale.set(0.5, 0.5);
		whiteGhost.updateHitbox(); // Update bounds after scaling
		whiteGhost.x = spawnX + 8 - whiteGhost.width / 2;
		whiteGhost.y = spawnY + 8 - whiteGhost.height / 2;
		whiteGhost.alpha = 0;
		whiteGhost.exists = true;
		whiteGhost.alive = true;

		// Get stagger delay based on how many ghosts have been spawned in this batch
		var ghostIndex = Ghost.getSpawnCounter();
		var staggerDelay = 0.4 * ghostIndex;
		Ghost.incrementSpawnCounter();

		// Tween alpha to 1 over 0.8s
		FlxTween.tween(whiteGhost, {alpha: 1}, 0.8, {startDelay: staggerDelay});

		// Tween scale to 1 over 0.8s, then spawn real ghost
		FlxTween.tween(whiteGhost.scale, {x: 1, y: 1}, 0.8, {
			startDelay: staggerDelay,
			onUpdate: function(_)
			{
				// Keep white ghost centered as it scales
				whiteGhost.updateHitbox();
				whiteGhost.x = spawnX + 8 - whiteGhost.width / 2;
				whiteGhost.y = spawnY + 8 - whiteGhost.height / 2;
			},
			onComplete: function(_)
			{
				// Spawn the real ghost
				var ghost:Ghost = ghosts.getFirstAvailable();
				if (ghost == null)
				{
					ghost = new Ghost();
					ghosts.add(ghost);
				}
				ghost.spawn(charData, player, bossProjectiles, eggCenterX, eggCenterY);
				// Override spawn position to match white ghost
				ghost.x = spawnX;
				ghost.y = spawnY;
				ghost.alpha = 0.95; // Slightly transparent

				// Make ghost inactive and face center until camera pans to player
				ghost.active = false;
				var centerX = map.width / 2;
				var centerY = map.height / 2;
				ghost.facingAngle = Math.atan2(centerY - ghost.y, centerX - ghost.x);

				// Set death callback to spawn spirit orb at ghost's shadow position
				ghost.onDeath = function(g:Ghost)
				{
					var orbX = g.x + g.width / 2;
					var orbY = g.y + g.height; // At the bottom (where shadow is)
					spawnSpiritOrb(orbX, orbY, g.characterData.level);
				};

				// Add ghost weapon hitboxes to scene (for melee weapons)
				if (Std.isOfType(ghost.weapon, Sword))
				{
					var sword:Sword = cast ghost.weapon;
					add(sword.getSlashHitbox());
					add(sword.getSpinHitbox());
				}
				else if (Std.isOfType(ghost.weapon, Halberd))
				{
					var halberd:Halberd = cast ghost.weapon;
					add(halberd.getJabHitbox());
				}
				// Fade out white ghost with scale increase
				FlxTween.tween(whiteGhost, {alpha: 0}, 0.8);
				FlxTween.tween(whiteGhost.scale, {x: 1.5, y: 1.5}, 0.8, {
					onComplete: function(_)
					{
						whiteGhost.kill();
					}
				});
			}
		});
	}
	function startEggHatching():Void
	{
		// Continue the intro sequence from EGG_PAUSE_1 (ready to crack the egg)
		gameState = INTRO;
		introState = EGG_PAUSE_1;
		introTimer = 0.0;

		trace("Egg hatching sequence started");
	}

	function startBattle():Void
	{
		playerActive = true;
		player.active = true;
		player.reticle.visible = true; // Show reticle when gameplay starts
		boss.active = true;
		boss.setReady();
		FlxG.camera.follow(player, LOCKON);
		// Set game state to Phase 1 active
		gameState = PHASE_1_ACTIVE;
		trace("Phase 1 battle started!");
	}

	function spawnSpiritOrb(X:Float, Y:Float, ghostLevel:Int = 1):Void
	{
		var orb:SpiritOrb = spiritOrbs.getFirstAvailable();
		if (orb == null)
		{
			orb = new SpiritOrb();
			spiritOrbs.add(orb);
		}
		orb.spawn(X, Y, player, ghostLevel);

		// Set callback for when orb is collected during Phase 0.5
		// No special callback needed for Phase 0.5 - we just wait 20 seconds after all ghosts are dead

		trace("Spirit orb spawned at (" + X + ", " + Y + ") with level " + ghostLevel);
	}

	function spawnGhosts():Void
	{
		var deadChars = GameData.getDeadCharacters();
		trace("Spawning " + deadChars.length + " ghosts...");

		// Pass egg center position to avoid spawning on egg
		var eggCenterX = eggSprite.x + eggSprite.width / 2;
		var eggCenterY = eggSprite.y + 57; // Egg center.y is at 57px

		for (charData in deadChars)
		{
			var ghost:Ghost = ghosts.getFirstAvailable();
			if (ghost == null)
			{
				ghost = new Ghost();
				ghosts.add(ghost);
			}
			ghost.spawn(charData, player, bossProjectiles, eggCenterX, eggCenterY);

			// Set death callback to spawn spirit orb
			ghost.onDeath = function(g:Ghost)
			{
				var orbX = g.x + g.width / 2;
				var orbY = g.y + g.height; // At the bottom (where shadow is)
				spawnSpiritOrb(orbX, orbY, g.characterData.level); // Pass ghost's level
			};

			// Add ghost weapon hitboxes to scene (for melee weapons)
			if (Std.isOfType(ghost.weapon, Sword))
			{
				var sword:Sword = cast ghost.weapon;
				add(sword.getSlashHitbox());
				add(sword.getSpinHitbox());
			}
			else if (Std.isOfType(ghost.weapon, Halberd))
			{
				var halberd:Halberd = cast ghost.weapon;
				add(halberd.getJabHitbox());
			}
		}
	}

	/**
	 * Generate a unique damage instance ID for tracking damage cooldowns.
	 * Uses the sprite's ID + current game ticks to create a unique ID per spawn/recycle.
	 * This handles the edge case where a projectile hits, gets recycled, and hits again.
	 */
	function getDamageInstanceId(sprite:FlxSprite):String
	{
		return sprite.ID + "_" + FlxG.game.ticks;
	}

	function checkProjectileCollisions():Void
	{
		projectiles.forEachAlive(function(proj:Projectile)
		{
			// Check world bounds
			if (proj.x < FlxG.worldBounds.left
				|| proj.x + proj.width > FlxG.worldBounds.right
				|| proj.y < FlxG.worldBounds.top
				|| proj.y + proj.height > FlxG.worldBounds.bottom)
			{
				proj.hitWall();
			}
		});

		bossProjectiles.forEachAlive(function(proj:Projectile)
		{
			if (proj.x < FlxG.worldBounds.left
				|| proj.x + proj.width > FlxG.worldBounds.right
				|| proj.y < FlxG.worldBounds.top
				|| proj.y + proj.height > FlxG.worldBounds.bottom)
			{
				proj.kill();
			}
		});
		// Update homing projectiles with targets
		updateHomingProjectiles();

		// Check player projectiles vs Mayflies
		FlxG.overlap(projectiles, mayflies, arrowHitMayfly);

		// Check player picking up hearts
		FlxG.overlap(player, hearts, playerPickupHeart);

		// Check melee weapon collisions
		checkMeleeWeaponCollisions();
	}

	function updateHomingProjectiles():Void
	{
		projectiles.forEachAlive(function(proj:Projectile)
		{
			// Check if this is a magic ball projectile with homing
			if (Std.isOfType(proj, Wand.MagicBallProjectile))
			{
				var magicBall:Wand.MagicBallProjectile = cast proj;

				if (magicBall.isHoming)
				{
					// Find nearest enemy target
					var nearestEnemy = findNearestEnemy(magicBall.x + magicBall.width / 2, magicBall.y + magicBall.height / 2);
					magicBall.targetEnemy = nearestEnemy;
				}
			}
		});
	}

	function findNearestEnemy(fromX:Float, fromY:Float):FlxSprite
	{
		var nearest:FlxSprite = null;
		var nearestDist:Float = Math.POSITIVE_INFINITY;

		// Check boss segments
		if (boss != null && boss.alive && boss.visible)
		{
			for (segment in boss.members)
			{
				if (segment != null && segment.alive)
				{
					var dx = (segment.x + segment.width / 2) - fromX;
					var dy = (segment.y + segment.height / 2) - fromY;
					var dist = dx * dx + dy * dy; // Use squared distance to avoid sqrt

					if (dist < nearestDist)
					{
						nearestDist = dist;
						nearest = segment;
					}
				}
			}
		}

		// Check mayflies
		mayflies.forEachAlive(function(mayfly:Mayfly)
		{
			var dx = (mayfly.x + mayfly.width / 2) - fromX;
			var dy = (mayfly.y + mayfly.height / 2) - fromY;
			var dist = dx * dx + dy * dy;

			if (dist < nearestDist)
			{
				nearestDist = dist;
				nearest = mayfly;
			}
		});

		return nearest;
	}

	function checkMeleeWeaponCollisions():Void
	{
		// Check if player is using a melee weapon
		if (Std.isOfType(player.weapon, Sword))
		{
			var sword:Sword = cast player.weapon;
			// Check spin attack first (has priority during spin)
			if (sword.isSpinActive())
			{
				var spinHitbox = sword.getSpinHitbox();
				if (spinHitbox.exists && spinHitbox.alpha > 0)
				{
					var hitSomething = false;

					// Check vs boss segments
					if (!hitSomething && boss != null && boss.alive && boss.visible)
					{
						// Use boss's checkOverlap with standard collision and pixel-perfect
						if (boss.checkOverlap(spinHitbox, false, true))
						{
							// Generate unique ID for this sword's spin hitbox at this moment
							boss.takeDamage(sword.baseDamage * player.attackDamage * 0.7, getDamageInstanceId(spinHitbox));
							hitSomething = true;
							// ALWAYS bounce
							var dx = player.x - boss.x;
							var dy = player.y - boss.y;
							var dist = Math.sqrt(dx * dx + dy * dy);
							if (dist > 0)
							{
								dx /= dist;
								dy /= dist;
								var bounceSpeed = 150;
								player.applySpinBounce(dx * bounceSpeed, dy * bounceSpeed);
							}
						}
					}

					// Check vs boss2 body parts
					if (!hitSomething && boss2 != null && boss2.alive && boss2.isActive)
					{
						// Pixel-perfect check for spin vs boss2 segments
						if ((spinHitbox.overlaps(boss2.thorax) && FlxG.pixelPerfectOverlap(spinHitbox, boss2.thorax))
							|| (spinHitbox.overlaps(boss2.head) && FlxG.pixelPerfectOverlap(spinHitbox, boss2.head))
							|| (spinHitbox.overlaps(boss2.abdomen) && FlxG.pixelPerfectOverlap(spinHitbox, boss2.abdomen)))
						{
							// Boss2 doesn't have damage source tracking yet, just damage normally
							boss2.takeDamage(sword.baseDamage * player.attackDamage * 0.7);
							hitSomething = true;
							// ALWAYS bounce
							var dx = player.x - boss2.x;
							var dy = player.y - boss2.y;
							var dist = Math.sqrt(dx * dx + dy * dy);
							if (dist > 0)
							{
								dx /= dist;
								dy /= dist;
								var bounceSpeed = 150;
								player.applySpinBounce(dx * bounceSpeed, dy * bounceSpeed);
							}
						}
					}

					// Check vs mayflies (only if didn't hit boss)
					if (!hitSomething)
					{
					FlxG.overlap(spinHitbox, mayflies, function(h:FlxSprite, m:Mayfly)
					{
							// Pixel-perfect for spin (has transparency)
							if (FlxG.pixelPerfectOverlap(h, m))
							{
								// Mayflies will take damage every hit (no cooldown tracking yet)
								m.takeDamage(sword.baseDamage * player.attackDamage * 0.7);
							hitSomething = true;
								// ALWAYS bounce
								var dx = player.x - m.x;
								var dy = player.y - m.y;
								var dist = Math.sqrt(dx * dx + dy * dy);
								if (dist > 0)
								{
									dx /= dist;
									dy /= dist;
									var bounceSpeed = 150;
									player.applySpinBounce(dx * bounceSpeed, dy * bounceSpeed);
								}
							}
					});
					}

					// Check vs ghosts (only if didn't hit anything else)
					if (!hitSomething)
					{
					FlxG.overlap(spinHitbox, ghosts, function(h:FlxSprite, g:Ghost)
					{
							// Pixel-perfect for spin (has transparency)
							if (FlxG.pixelPerfectOverlap(h, g))
							{
								// Ghosts will take damage every hit (no cooldown tracking yet)
								g.takeDamage(sword.baseDamage * player.attackDamage * 0.7);
							hitSomething = true;
								// ALWAYS bounce
								var dx = player.x - g.x;
								var dy = player.y - g.y;
								var dist = Math.sqrt(dx * dx + dy * dy);
								if (dist > 0)
								{
									dx /= dist;
									dy /= dist;
									var bounceSpeed = 150;
									player.applySpinBounce(dx * bounceSpeed, dy * bounceSpeed);
								}
							}
						});
					}
				}
			}
			else
			{
				// Normal slash attack
				var hitbox = sword.getSlashHitbox();

				if (hitbox.exists && hitbox.alpha > 0 && sword.canDealDamage())
				{
					var hitSomething = false;

					// Check vs boss segments
					if (!hitSomething && boss != null && boss.alive && boss.visible)
					{
						// Use boss's checkOverlap with rotated collision and pixel-perfect
						if (boss.checkOverlap(hitbox, true, true))
						{
							// Generate unique ID for this sword's slash hitbox at this moment
							boss.takeDamage(sword.baseDamage * player.attackDamage, getDamageInstanceId(hitbox));
							hitSomething = true;
						}
					}

					// Check vs boss2 body parts
					if (!hitSomething && boss2 != null && boss2.alive && boss2.isActive)
					{
						// Pixel-perfect check for slash vs boss2 segments
						// Boss2 doesn't have instance-based damage tracking yet
						if ((hitbox.overlaps(boss2.thorax) && FlxG.pixelPerfectOverlap(hitbox, boss2.thorax))
							|| (hitbox.overlaps(boss2.head) && FlxG.pixelPerfectOverlap(hitbox, boss2.head))
							|| (hitbox.overlaps(boss2.abdomen) && FlxG.pixelPerfectOverlap(hitbox, boss2.abdomen)))
						{
							boss2.takeDamage(sword.baseDamage * player.attackDamage, getDamageInstanceId(hitbox));
							hitSomething = true;
						}
					}

					// Check vs mayflies (only if didn't hit boss)
					if (!hitSomething)
					{
						mayflies.forEachAlive(function(m:Mayfly)
						{
							if (!hitSomething && hitbox.overlaps(m))
							{
								// Mayflies don't have cooldown tracking yet
								m.takeDamage(sword.baseDamage * player.attackDamage);
								hitSomething = true;
							}
						});
					}
					// Check vs ghosts (only if didn't hit anything else)
					if (!hitSomething)
					{
						ghosts.forEachAlive(function(g:Ghost)
						{
							if (!hitSomething && hitbox.overlaps(g))
							{
								// Ghosts don't have cooldown tracking yet
								g.takeDamage(sword.baseDamage * player.attackDamage);
								hitSomething = true;
							}
						});
					}
					// Mark that this swing has dealt damage
					if (hitSomething)
					{
						sword.markHit();
					}
				}
			}
		}
		else if (Std.isOfType(player.weapon, Halberd))
		{
			var halberd:Halberd = cast player.weapon;
			var hitbox = halberd.getJabHitbox();

			if (halberd.isJabActive() && hitbox.exists && halberd.canDealDamage())
			{
				var hitSomething = false;

				// Check vs boss segments
				if (boss != null && boss.alive && boss.visible)
				{
					FlxG.overlap(hitbox, boss, function(h:FlxSprite, b:FlxSprite)
					{
						if (!hitSomething)
						{
							boss.takeDamage(halberd.baseDamage * player.attackDamage);
							hitSomething = true;
						}
					});
				}
				// Check vs boss2 body parts
				if (!hitSomething && boss2 != null && boss2.alive && boss2.isActive)
				{
					if (hitbox.overlaps(boss2.thorax) || hitbox.overlaps(boss2.head) || hitbox.overlaps(boss2.abdomen))
					{
						boss2.takeDamage(halberd.baseDamage * player.attackDamage);
						hitSomething = true;
					}
				}

				// Check vs mayflies (only if didn't hit boss)
				if (!hitSomething)
				{
					FlxG.overlap(hitbox, mayflies, function(h:FlxSprite, m:Mayfly)
					{
						if (!hitSomething)
						{
							m.takeDamage(halberd.baseDamage * player.attackDamage);
							hitSomething = true;
						}
					});
				}
				// Check vs ghosts (only if didn't hit anything else)
				if (!hitSomething)
				{
					FlxG.overlap(hitbox, ghosts, function(h:FlxSprite, g:Ghost)
					{
						if (!hitSomething)
						{
							g.takeDamage(halberd.baseDamage * player.attackDamage);
							hitSomething = true;
						}
					});
				}
				// Mark that this jab has dealt damage
				if (hitSomething)
				{
					halberd.markHit();
				}
			}
		}
	}

	function checkGhostCollisions():Void
	{
		// Check player projectiles vs ghosts
		FlxG.overlap(projectiles, ghosts, projectileHitGhost);

		// Check ghost projectiles (they use bossProjectiles group) vs player
		FlxG.overlap(player, bossProjectiles, playerHitProjectile);

		// Check ghost melee weapon hitboxes vs player
		ghosts.forEachAlive(function(ghost:Ghost)
		{
			if (ghost.weapon == null)
				return;

			if (Std.isOfType(ghost.weapon, Sword))
			{
				var sword:Sword = cast ghost.weapon;

				// Check spin attack first
				if (sword.isSpinActive())
				{
					var spinHitbox = sword.getSpinHitbox();
					if (spinHitbox.exists && spinHitbox.alpha > 0)
					{
						FlxG.overlap(spinHitbox, player, function(h:FlxSprite, p:Player)
						{
							// Ghosts deal 0.7 damage per spin hit
							p.takeDamage(0.7, ghost.x + ghost.width / 2, ghost.y + ghost.height / 2);
						});
					}
				}
				else
				{
					// Normal slash attack
					var hitbox = sword.getSlashHitbox();
					if (hitbox.exists && hitbox.alpha > 0 && sword.canDealDamage())
					{
						FlxG.overlap(hitbox, player, function(h:FlxSprite, p:Player)
						{
							// Ghosts deal 1.0 damage (1 heart) per hit
							p.takeDamage(1.0, ghost.x + ghost.width / 2, ghost.y + ghost.height / 2);
							sword.markHit();
						});
					}
				}
			}
			else if (Std.isOfType(ghost.weapon, Halberd))
			{
				var halberd:Halberd = cast ghost.weapon;
				var hitbox = halberd.getJabHitbox();
				if (halberd.isJabActive() && hitbox.exists && halberd.canDealDamage())
				{
					FlxG.overlap(hitbox, player, function(h:FlxSprite, p:Player)
					{
						// Ghosts deal 1.0 damage (1 heart) per hit
						p.takeDamage(1.0, ghost.x + ghost.width / 2, ghost.y + ghost.height / 2);
						halberd.markHit();
					});
				}
			}
		});
	}

	function checkBossCollisions():Void
	{
		if (!boss.alive || !boss.visible)
			return;

		// FlxG.overlap can handle groups directly
		FlxG.overlap(projectiles, boss, projHitBossSegment);
		FlxG.overlap(player, boss, playerHitBossSegment);
		FlxG.overlap(player, bossProjectiles, playerHitProjectile);
		// Check plasma collisions
		FlxG.overlap(player, plasmas, playerHitPlasma);
	
		// Check ghosts vs player projectiles and melee
		FlxG.overlap(projectiles, ghosts, projectileHitGhost); // Check melee weapons vs ghosts
		if (Std.isOfType(player.weapon, Sword))
		{
			var sword:Sword = cast player.weapon;
			var hitbox = sword.getSlashHitbox();
			if (hitbox.exists && hitbox.alpha > 0)
			{
				FlxG.overlap(hitbox, ghosts, function(h:FlxSprite, g:Ghost)
				{
					g.takeDamage(sword.baseDamage * player.attackDamage);
				});
			}
		}
		else if (Std.isOfType(player.weapon, Halberd))
		{
			var halberd:Halberd = cast player.weapon;
			var hitbox = halberd.getJabHitbox();
			if (halberd.isJabActive() && hitbox.exists)
			{
				FlxG.overlap(hitbox, ghosts, function(h:FlxSprite, g:Ghost)
				{
					g.takeDamage(halberd.baseDamage * player.attackDamage);
				});
			}
		}
	}

	function projectileHitGhost(proj:Projectile, ghost:Ghost):Void
	{
		if (!proj.alive || !ghost.alive || ghost.currentHealth <= 0)
			return;

		ghost.takeDamage(proj.damage);
		proj.hitEnemy();
	}

	function projHitBossSegment(proj:Projectile, segment:FlxSprite):Void
	{
		if (!proj.alive)
			return;

		// For boss segments, do pixel-perfect collision check to avoid hitting transparent areas
		// AABB check already passed (by FlxG.overlap), now verify actual pixel overlap
		if (!FlxG.pixelPerfectOverlap(proj, segment))
			return;

		boss.takeDamage(proj.damage);
		proj.hitEnemy();
	}

	function playerHitBossSegment(player:Player, segment:FlxSprite):Void
	{
		if (!player.isInvincible)
		{
			// Pixel-perfect check for boss collision to avoid transparent areas
			if (!FlxG.pixelPerfectOverlap(player, segment))
				return;
				
			player.takeDamage(boss.contactDamage, boss.x + boss.width / 2, boss.y + boss.height / 2);
		}
	}

	function playerHitProjectile(player:Player, proj:Projectile):Void
	{
		if (!player.isInvincible)
		{
			player.takeDamage(proj.damage, proj.x + proj.width / 2, proj.y + proj.height / 2);
		}
		proj.kill();
	}
	function playerHitPlasma(player:Player, plasma:Plasma):Void
	{
		if (plasma.isExploding)
		{
			// Explosion damages and knocks back player (unless dodging)
			if (!player.isInvincible && !player.isDodging)
			{
				var centerX = plasma.x + plasma.width / 2;
				var centerY = plasma.y + plasma.height / 2;
				player.takeDamage(1.0, centerX, centerY);
			}
		}
		else
		{
			// Ball itself just triggers explosion (no damage)
			plasma.explode();
		}
	}

	function arrowHitMayfly(proj:Projectile, mayfly:Mayfly):Void
	{
		if (!proj.alive || !mayfly.alive)
			return;

		mayfly.takeDamage(proj.damage);

		proj.hitEnemy();
	}

	function playerPickupHeart(player:Player, heart:HeartPickup):Void
	{
		heart.collect(player);
	}
	
	// ===== PHASE TRANSITION SYSTEM =====

	function startPhase1DeathSequence():Void
	{
		trace("Phase 1 boss defeated! Starting death sequence...");
		gameState = PHASE_1_DEATH;
		transitionTimer = 0;

		// Stop player and boss
		player.active = false;
		player.velocity.set(0, 0);
		player.reticle.visible = false;
		boss.active = false;

		// Initialize cameraTarget to player position
		cameraTarget.setPosition(player.x + player.width / 2, player.y + player.height / 2);

		// Switch camera to following cameraTarget for cinematics
		FlxG.camera.follow(cameraTarget, LOCKON);

		// Pan camera to boss head using cameraTarget (smooth transition)
		var headPos = boss.getHeadPosition();
		FlxTween.tween(cameraTarget, {
			x: headPos.x,
			y: headPos.y
		}, 1.0, {ease: FlxEase.quadInOut});
	}

	function updatePhase1DeathSequence(elapsed:Float):Void
	{
		transitionTimer += elapsed;

		var cocoonCenterX = map.width / 2;
		var cocoonCenterY = 60;
		var bossTargetY = cocoonCenterY + cocoonSprite.height / 2;

		// Sequence: pan(1s) → roar(1.5s) → crawl(2.5s) → cocoon fade(1.5s) → pan back(1s)
		if (transitionTimer > 1.0 && transitionTimer <= 2.5)
		{
			if (transitionTimer - elapsed <= 1.0)
			{
				boss.roar();
				FlxG.camera.shake(0.01, 1.0);
			}
		}
		else if (transitionTimer > 2.5 && transitionTimer <= 5.0)
		{
			// Boss crawls to cocoon position, camera follows
			boss.moveTo(cocoonCenterX, bossTargetY, 40, elapsed);
			var headPos = boss.getHeadPosition();
			cameraTarget.setPosition(headPos.x, headPos.y);
			// Meanwhile, player walks to starting position
			var startX = (map.width / 2) - 4;
			var startY = map.height - 32;
			var walkSpeed = 50; // Slow walk speed during cinematic

			var dx = startX - player.x;
			var dy = startY - player.y;
			var dist = Math.sqrt(dx * dx + dy * dy);

			if (dist > 1)
			{
				var angle = Math.atan2(dy, dx);
				player.x += Math.cos(angle) * walkSpeed * elapsed;
				player.y += Math.sin(angle) * walkSpeed * elapsed;
			}
		}
		else if (transitionTimer > 5.0 && transitionTimer <= 6.5)
		{
			boss.headX = cocoonCenterX;
			boss.headY = bossTargetY;
			cameraTarget.setPosition(boss.headX, boss.headY);

			if (cocoonSprite.alpha == 0)
			{
				cocoonSprite.setPosition(cocoonCenterX - cocoonSprite.width / 2, cocoonCenterY - cocoonSprite.height / 2);
				cocoonSprite.visible = true;
				shadowLayer.add(new Shadow(cocoonSprite, 1.2, 1.0, 0, 4, true));
				hud.setBossHealthVisible(false);
			}

			var fadeProgress = (transitionTimer - 5.0) / 1.5;
			cocoonSprite.alpha = fadeProgress;
			var bossAlpha = 1.0 - fadeProgress;

			boss.forEach(spr -> if (spr != null) spr.alpha = bossAlpha);
			for (shadow in boss.shadows)
				if (shadow != null && shadow.exists)
				{
					shadow.alpha = bossAlpha;
					if (bossAlpha <= 0)
						shadow.kill();
				}
			}
		else if (transitionTimer > 6.5 && transitionTimer <= 7.5)
		{
			if (boss.visible)
			{
				boss.visible = false;
				boss.die();
				// Now explicitly cleanup the boss sprites
				boss.forEach(function(spr:FlxSprite)
				{
					if (spr != null)
						spr.kill();
				});
			}
			if (transitionTimer - elapsed <= 6.5)
				FlxTween.tween(cameraTarget, {x: player.x + player.width / 2, y: player.y + player.height / 2}, 1.0, {ease: FlxEase.quadInOut});
		}
		else if (transitionTimer > 7.5)
		{
			FlxG.camera.follow(player, LOCKON);
			startPhase1_5();
		}
	}

	function startPhase1_5():Void
	{
		trace("Starting Phase 1.5 - Cocoon intermission (ALWAYS 1 minute minimum)");
		gameState = PHASE_1_5_ACTIVE;
		transitionTimer = 0;
		ghostsAllDead = false;
		ghostsDefeatedTimer = 0;
		Ghost.resetSpawnCounter(); // Reset ghost spawn animation stagger

		// Player should already be at starting position from walking during death sequence
		player.velocity.set(0, 0);
		player.reticle.visible = false; // Hide during camera pan

		// Pan camera back to player
		FlxTween.tween(cameraTarget, {
			x: player.x,
			y: player.y
		}, 1.0, {
			ease: FlxEase.quadInOut,
			onComplete: function(t:FlxTween)
			{
				FlxG.camera.follow(player, LOCKON);
				player.active = true;
				player.reticle.visible = true;
			}
		});

		// Filter ghosts: only spawn those who died in Phase 1.5 (1) or Phase 2 (2)
		var allGhosts = GameData.getDeadCharacters();
		var phase1_5And2Ghosts = allGhosts.filter(function(char:CharacterData)
		{
			return char.deathPhase >= 1 && char.deathPhase <= 2;
		});

		if (phase1_5And2Ghosts.length > 0)
		{
			trace("Phase 1.5: Spawning " + phase1_5And2Ghosts.length + " Phase 1.5/2 ghosts");
			// Sort by level and create batches
			phase1_5And2Ghosts.sort((a, b) -> a.level - b.level);
			ghostBatches = createGhostBatches(phase1_5And2Ghosts, maxGhostsPerBatch);
			currentBatchIndex = 0;
			currentBatchSpawned = false;

			// Queue up first batch
			if (ghostBatches.length > 0)
			{
				ghostSpawnQueue = ghostBatches[0].copy();
			ghostSpawnTimer = 0;
		}
			trace("Split into " + ghostBatches.length + " batches of max " + maxGhostsPerBatch + " ghosts");
		}
		else
		{
			trace("Phase 1.5: No ghosts - player can farm healing for 1 minute");
		}
	}

	function updatePhase1_5(elapsed:Float):Void
	{
		transitionTimer += elapsed;

		// Staggered ghost spawning for current batch
		if (ghostSpawnQueue.length > 0)
		{
			ghostSpawnTimer += elapsed;
			if (ghostSpawnTimer >= ghostSpawnInterval)
			{
				ghostSpawnTimer = 0;
				var charData = ghostSpawnQueue.shift();
				spawnSingleGhost(charData);
				trace("Spawned Phase 1.5 ghost: " + charData.name + " (Level " + charData.level + ")");
			}
			return;
		}

		// Current batch spawned - check if all are dead before spawning next batch
		if (!currentBatchSpawned && ghostSpawnQueue.length == 0 && ghostBatches.length > 0)
		{
			currentBatchSpawned = true;
			trace("Phase 1.5 Batch " + (currentBatchIndex + 1) + " fully spawned");
			return;
		}

		// Check if current batch is defeated
		var currentGhostCount = ghosts.countLiving();
		if (currentBatchSpawned && currentGhostCount == 0 && ghostBatches.length > 0)
		{
			currentBatchIndex++;

			if (currentBatchIndex < ghostBatches.length)
			{
				// Spawn next batch
				trace("=== PHASE 1.5 BATCH " + currentBatchIndex + " DEFEATED - SPAWNING NEXT BATCH ===");
				ghostSpawnQueue = ghostBatches[currentBatchIndex].copy();
				ghostSpawnTimer = 0;
				currentBatchSpawned = false;
				Ghost.resetSpawnCounter();
			}
			else
			{
				// All batches completed
				if (!ghostsAllDead)
				{
					trace("All Phase 1.5 ghost batches defeated!");
					ghostsAllDead = true;
					ghostsDefeatedTimer = 0;
				}
			}
			return;
		}

		// Track when all ghosts are defeated (from batches)
		if (ghostsAllDead)
		{
			ghostsDefeatedTimer += elapsed;
			
			// Transition 3 seconds after all ghosts defeated
			if (ghostsDefeatedTimer >= 3.0)
			{
				trace("Phase 1.5 complete (all ghosts defeated) - starting Phase 2 hatch");
				startPhase2HatchSequence();
			}
			return;
		}

		// Check if all ghosts are dead (for cases with no batches)
		if (currentGhostCount == 0 && player.active && !ghostsAllDead && ghostBatches.length == 0)
		{
			trace("All Phase 1.5 ghosts defeated! Waiting 3 seconds before transition...");
			ghostsAllDead = true;
			ghostsDefeatedTimer = 0;
			return;
		}

		// If no ghosts to fight, wait 30 seconds as breather/healing time
		if (ghostBatches.length == 0 && transitionTimer >= 30.0)
		{
			trace("Phase 1.5 complete (30s breather, no ghosts) - starting Phase 2 hatch");
			startPhase2HatchSequence();
		}
	}

	function startPhase2HatchSequence():Void
	{
		trace("Boss hatching into Phase 2!");
		gameState = PHASE_2_HATCH;
		transitionTimer = 0;

		// Stop player
		player.active = false;
		player.velocity.set(0, 0);
		player.reticle.visible = false;

		// Move player back to starting position
		var startX = (map.width / 2) - 4;
		var startY = map.height - 32;
		player.x = startX;
		player.y = startY;

		// Pan to cocoon using cameraTarget
		FlxTween.tween(cameraTarget, {
			x: cocoonSprite.x + cocoonSprite.width / 2,
			y: cocoonSprite.y + cocoonSprite.height / 2
		}, 1.0, {
			ease: FlxEase.quadInOut,
			onComplete: function(t:FlxTween)
			{
				// Fade out cocoon
				FlxTween.tween(cocoonSprite, {alpha: 0}, 1.0, {
					onComplete: function(t:FlxTween)
					{
						cocoonSprite.visible = false;
						spawnPhase2Boss();
					}
				});
			}
		});
	}

	function spawnPhase2Boss():Void
	{
		trace("Spawning Phase 2 boss!");

		// Create Phase 2 boss at cocoon position
		boss2 = new BossPhase02(cocoonSprite.x, cocoonSprite.y, player, bossProjectiles, plasmas);
		boss2.alpha = 0;
		add(boss2);

		// Set up rock spawning callback
		boss2.onSpawnRock = function(rock:FlxSprite)
		{
			timePulseRocks.add(rock);
			trace("Added Time Pulse rock to scene");
		};

		// Set up fullscreen effect callback - add above most gameplay but below HUD
		boss2.onSpawnFullscreenEffect = function(effect:FlxSprite)
		{
			insert(members.indexOf(hud), effect); // Insert just before HUD
			trace("Added Time Pulse fullscreen effect to scene");
		};

		// Create shadows
		boss2.createShadows(shadowLayer);

		// Fade in
		FlxTween.tween(boss2, {alpha: 1}, 1.5, {
			onComplete: function(t:FlxTween)
			{
				// Activate Phase 2
				boss2.activate();
				gameState = PHASE_2_ACTIVE;

				// Tween camera back to player
				FlxTween.tween(cameraTarget, {x: player.x, y: player.y}, 1.0, {
					ease: FlxEase.quadInOut,
					onComplete: function(t:FlxTween)
					{
						// Reactivate player
						player.active = true;
						player.reticle.visible = true;
						trace("Phase 2 active!");
					}
				});
			}
		});
	}

	function checkPhase2Collisions():Void
	{
		if (boss2 == null || !boss2.exists || !boss2.isActive)
			return;

		// Check player projectiles hitting boss body parts
		projectiles.forEachAlive(function(p:Projectile)
		{
			// Check collision with main body parts (thorax, head, abdomen)
			if (p.overlaps(boss2.thorax) || p.overlaps(boss2.head) || p.overlaps(boss2.abdomen))
			{
				boss2.takeDamage(player.attackDamage);
				p.kill();
			}
		});

		// Check boss hitting player (when charging)
		if (boss2.attackState == CHARGE_ATTACKING)
		{
			// Check if any body part hits player
			if (player.overlaps(boss2.thorax) || player.overlaps(boss2.head) || player.overlaps(boss2.abdomen))
			{
				player.takeDamage(1);
				player.knockback(boss2.x + boss2.width / 2, boss2.y + boss2.height / 2, 150);
			}
		}
		// Check Time Pulse rocks hitting player or walls
		timePulseRocks.forEachAlive(function(rock:FlxSprite)
		{
			// Check if rock is moving (has velocity)
			if (rock.velocity.x != 0 || rock.velocity.y != 0)
			{
				// Check collision with player
				if (!player.isInvincible && rock.overlaps(player))
				{
					player.takeDamage(1.0, rock.x + rock.width / 2, rock.y + rock.height / 2);
					rock.kill();
				}

				// Check collision with world bounds
				if (rock.x < FlxG.worldBounds.left
					|| rock.x + rock.width > FlxG.worldBounds.right
					|| rock.y < FlxG.worldBounds.top
					|| rock.y + rock.height > FlxG.worldBounds.bottom)
				{
					rock.kill();
				}
			}
		});
	}

	function updateMayflySpawning(elapsed:Float):Void
	{
		mayflySpawnTimer += elapsed;
		
		var activeMayflies = mayflies.countLiving();
		var spawnRate = activeMayflies == 0 ? 1.0 : 3.0;

		if (mayflySpawnTimer >= spawnRate && activeMayflies < 4)
		{
			mayflySpawnTimer = FlxG.random.float(0, 0.5);

			var mayfly = mayflies.getFirstAvailable();
			if (mayfly == null)
			{
				mayfly = new Mayfly();
				mayflies.add(mayfly);
			}
			mayfly.spawn();
		}
	}

	public function spawnHeart(Pos:FlxPoint):Void
	{
		var heart:HeartPickup = hearts.getFirstAvailable();
		if (heart == null)
		{
			heart = new HeartPickup();
			hearts.add(heart);
		}
		heart.spawn(Pos);
	}
	public function onPlayerDeath():Void
	{
		trace("Player died!");

		// Stop all gameplay
		player.active = false;
		if (boss != null)
			boss.active = false;
		if (boss2 != null)
			boss2.isActive = false;
		
		ghosts.forEachAlive(function(ghost:Ghost)
		{
			ghost.active = false;
		});

		// Save death data
		saveDeathData();

		// Fade out HUD before showing death screen
		FlxTween.tween(hud, {alpha: 0}, 0.3, {
			onComplete: function(_)
			{
				// Show death screen after HUD fades
				openSubState(new DeathScreenSubState(selectedCharacter.name, getCurrentPhase()));
			}
		});
	}

	function saveDeathData():Void
	{
		// Determine weapon type
		var weaponType:WeaponType = BOW;
		if (Std.isOfType(player.weapon, Sword))
			weaponType = SWORD;
		else if (Std.isOfType(player.weapon, Wand))
			weaponType = WAND;
		else if (Std.isOfType(player.weapon, Halberd))
			weaponType = HALBERD;

		var currentPhase = getCurrentPhase();

		trace("Saving death: " + selectedCharacter.name + " phase " + currentPhase + " with weapon " + weaponType);

		// Create character data with death info
		var charData = selectedCharacter.clone();
		charData.deathPhase = currentPhase;
		charData.weaponType = weaponType;

		// Save to GameData
		GameData.addDeadCharacter(charData);
	}

	function getCurrentPhase():Int
	{
		switch (gameState)
		{
			case INTRO | PHASE_0_5_GHOSTS:
				return 0;
			case PHASE_1_ACTIVE | PHASE_1_DEATH | PHASE_1_5_ACTIVE:
				return 1;
			case PHASE_2_HATCH | PHASE_2_ACTIVE | PHASE_2_DEATH | PHASE_2_5_ACTIVE:
				return 2;
			default:
				return 0;
		}
	}

	function updatePhase2_5(elapsed:Float):Void
	{
		transitionTimer += elapsed;

		if (ghosts.countLiving() == 0)
		{
			trace("All Phase 2.5 ghosts defeated! Proceeding to Phase 2 hatch.");
			startPhase2HatchSequence();
			return;
		}

		// Safety timeout
		if (transitionTimer > 60.0)
		{
			trace("Phase 2.5 intermission timeout - forcing Phase 2 hatch");
			startPhase2HatchSequence();
		}
	}
}

enum GameState
{
	INTRO; // Phase 0: Fade in, pan to egg, pause - ends at egg pause
	PHASE_0_5_GHOSTS; // Phase 0.5: Ghost spawning/fighting (before egg hatches) - only if ghosts died in Phase 0/1
	PHASE_1_ACTIVE; // Phase 1: Egg hatches, boss emerges, fight until boss dies
	PHASE_1_DEATH; // Phase 1: Boss death sequence (moves up, cocoon forms)
	PHASE_1_5_ACTIVE; // Phase 1.5: ALWAYS happens - min 1 minute, ghosts if died in Phase 1.5/2
	PHASE_2_HATCH; // Phase 2: Boss emerges from cocoon
	PHASE_2_ACTIVE; // Phase 2: Boss fight
	PHASE_2_DEATH; // Phase 2 boss death
	PHASE_2_5_ACTIVE; // Phase 2.5: Husk intermission (if applicable)
	PHASE_3_HATCH; // Phase 3 boss emergence
	PHASE_3_ACTIVE; // Phase 3 boss fight
}

enum IntroState
{
	FADE_IN;
	SCROLL_TO_EGG;
	SCROLLING;
	EGG_PAUSE_1;
	EGG_CRACK_1;
	EGG_PAUSE_2;
	EGG_CRACK_2;
	EGG_PAUSE_3;
	EGG_CRACK_REST;
	EGG_PAUSE_4;
	BOSS_FADE_IN;
	BOSS_DESCEND;
	BOSS_UNFURL;
	HEALTH_BAR_APPEAR;
	HEALTH_BAR_PAUSE;
	HEALTH_BAR_FILL;
	BOSS_ROAR;
	SCROLL_TO_PLAYER;
	COMPLETE;
}