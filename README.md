## ThrowableItemLib
- Easily create active/pocket items and cards/runes/objects that are throwable akin to Bob’s Rotten Head or The Candle
- Proper item interactions with Void, Metronome, and on-use effects such as Book of Virtues and 'M
- Blank Card and Clear Rune support for throwable cards and runes
- 10 flags to modify default lift, throw, and hide behavior
- Hold Condition system to allow for control over disabled, default, or allowed lift item use
- Support for multiple configs per item, avoiding mod incompatibilities when adding throw behavior to vanilla items
- Allows for dynamically changing the sprite that is lifted, hidden, or thrown

| Cool Void support!  | Cool pocket item support! |
| ------------- | ------------- |
| ![Void support](https://file.garden/Z6WcLcheFD8ZldqK/ex1.gif)  | ![Pocket item support](https://file.garden/Z6WcLcheFD8ZldqK/ex2) |
## Example code
(Does not display all optional ThrowableItemConfig fields)
```lua
include("throwableitemlib").Init()

-- Active item example
ThrowableItemLib:RegisterThrowableItem({
    ID = Isaac.GetItemIdByName("Big Rock"),
    Type = ThrowableItemLib.Type.ACTIVE,
    Identifier = "Realllly big rock",
    ThrowFn = function (player, vect)
        local tear = player:FireTear(player.Position, vect:Resized(player.ShotSpeed * 10))

        tear:AddTearFlags(TearFlags.TEAR_BOUNCE | TearFlags.TEAR_PIERCING)
        tear:ChangeVariant(TearVariant.ROCK)
        tear.CollisionDamage = tear.CollisionDamage * 3
        tear.Scale = tear.Scale * 2
    end,
    AnimateFn = function (player, state)
        if state == ThrowableItemLib.State.THROW then
            player:AnimatePickup(emptySprite, true, "HideItem")
            return true
        end
    end
})

-- Pocket item example
ThrowableItemLib:RegisterThrowableItem({
    ID = Isaac.GetCardIdByName("Explosive Card"),
    Type = ThrowableItemLib.Type.CARD,
    Identifier = "Explosive card",
    ThrowFn = function (player, vect)
        Game():Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_TROLL, player.Position, vect:Resized(20), player, 0, math.max(Random(), 1))
    end,
    HideFn = function (player)
        Game():BombExplosionEffects(player.Position, player.Damage * 3, player:GetBombFlags(), nil, player, 2)
        player:UseActiveItem(CollectibleType.COLLECTIBLE_HOW_TO_JUMP)
    end,
    Flags = ThrowableItemLib.Flag.DISCHARGE_HIDE
})
```
