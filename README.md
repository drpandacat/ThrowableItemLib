## ThrowableItemLib
- Easily create active items and cards/runes/objects that are throwable akin to Bob’s Rotten Head or The Candle
- Proper item interactions with Void, Metronome, and on-use effects such as Book of Virtues and 'M
- Blank Card, Clear Rune, and Fiend Folio Perfectly Generic Object support for throwable cards, runes, and objects, also allowing for registering custom pocket mimic items
- 10 flags to modify default lift, throw, and hide behavior
- Hold Condition system to allow for control over disabled, default, or allowed lift item use
- Support for multiple configs per item, avoiding mod incompatibilities when adding throw behavior to vanilla items
- Allows for dynamically changing the sprite that is lifted, hidden, or thrown

| Cool Void support!  | Cool pocket item support! |
| ------------- | ------------- |
| ![Void support](https://files.catbox.moe/h4jth2.gif)  | ![Pocket item support](https://files.catbox.moe/73cyng.gif) |
## Example code
Does not display all features mentioned above!
```lua
include("throwableitemlib").Init()

local emptySprite = Sprite()
local game = Game()

-- Active item example
ThrowableItemLib:RegisterThrowableItem({
    ID = Isaac.GetItemIdByName("Big Rock"),
    Type = ThrowableItemLib.Type.ACTIVE,
    Identifier = "Big Rock",
    ThrowFn = function (player, vect)
        local tear = player:FireTear(player.Position, vect:Resized(player.ShotSpeed * 10) + player:GetTearMovementInheritance(vect))

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
    Identifier = "Explosive Card",
    ThrowFn = function (player, vect)
        game:Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_TROLL, player.Position, vect:Resized(20), player, 0, math.max(Random(), 1))
    end,
    HideFn = function (player)
        game:BombExplosionEffects(player.Position, player.Damage * 3, player:GetBombFlags(), nil, player, 2)
        player:UseActiveItem(CollectibleType.COLLECTIBLE_HOW_TO_JUMP)
    end,
    Flags = ThrowableItemLib.Flag.DISCHARGE_HIDE
})
```
