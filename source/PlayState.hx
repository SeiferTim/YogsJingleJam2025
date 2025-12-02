package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.tile.FlxBaseTilemap.FlxTilemapAutoTiling;
import flixel.tile.FlxTilemap;

class PlayState extends FlxState
{
var map:FlxTilemap;
var player:Player;
var projectiles:FlxTypedGroup<Projectile>;
var hud:HUD;
var boss:Boss;

override public function create()
{
super.create();
Actions.init();

map = new FlxTilemap();
map.loadMapFromCSV("assets/maps/base.csv", "assets/images/lofi_environment.png", 8, 8, FlxTilemapAutoTiling.OFF, 0, 0);
add(map);

FlxG.worldBounds.set(8, 8, map.width - 16, map.height - 16);

projectiles = new FlxTypedGroup<Projectile>();
add(projectiles);

player = new Player((map.width / 2) - 4, map.height - 32, projectiles);
add(player);

boss = new Boss(map.width / 2 - 16, map.height / 2 - 16);
add(boss);

FlxG.camera.follow(player, LOCKON);
FlxG.camera.setScrollBoundsRect(0, 0, map.width, map.height);

hud = new HUD(player, boss);
add(hud);
}

override public function update(elapsed:Float)
{
checkProjectileCollisions();
checkBossCollisions();
super.update(elapsed);
}

function checkProjectileCollisions():Void
{
projectiles.forEachAlive(function(proj:Projectile)
{
if (proj.isStuck)
return;

if (proj.x < FlxG.worldBounds.left
|| proj.x + proj.width > FlxG.worldBounds.right
|| proj.y < FlxG.worldBounds.top
|| proj.y + proj.height > FlxG.worldBounds.bottom)
{
proj.stick();
}
});
}

function checkBossCollisions():Void
{
if (!boss.alive)
return;

FlxG.overlap(projectiles, boss, arrowHitBoss);
FlxG.overlap(player, boss, playerHitBoss);
}

function arrowHitBoss(arrow:Projectile, boss:Boss):Void
{
if (arrow.isStuck)
return;

boss.takeDamage(arrow.damage);
arrow.stick();
}

function playerHitBoss(player:Player, boss:Boss):Void
{
player.knockback(boss.x + boss.width / 2, boss.y + boss.height / 2, 300);

if (!player.isInvincible)
{
player.takeDamage(boss.contactDamage);
}
}
}