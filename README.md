## ThrowableItemLib
- Easily create active items and consumables that follow the lift, hide, and throw behavior of items like Bob’s Rotten Head or The Candle
- Proper item interactions with Void, Metronome, ? Card, and on-use effects such as Book of Virtues and 'M + more
- Blank Card, Clear Rune, and Fiend Folio Perfectly Generic Object support for throwable cards, runes, and objects, also allowing for registering custom pocket mimic items
- 8 flags to modify default lift, throw, and hide behavior
- 7 callbacks for detecting and modifying custom throwable item behavior
- Hold Condition system to allow for control over disabled, default, or allowed lift item use
- Allows for dynamically changing the sprite that is lifted, hidden, or thrown
- Support for multiple configs per item, avoiding mod incompatibilities when adding throw behavior to vanilla items
- Easy to add compatibility with custom active charges akin to Soul/Blood Charge
- No dependencies (but REPENTOGON makes things work smoother and fully as expected)

| Cool Void support!  | Cool pocket item support! |
| ------------- | ------------- |
| ![Void support](https://files.catbox.moe/tgqed4.gif)  | ![Pocket item support](https://files.catbox.moe/49s8uj.gif) |
## Example code
Does not display all features mentioned above!
```lua
include("path.to.throwableitemlib")

local SPRITE = Sprite()
local GAME = Game()

-- Active item example
ThrowableItemLib:RegisterThrowableItem({
    ID = Isaac.GetItemIdByName("Big Rock"),
    Type = ThrowableItemLib.Type.ACTIVE,
    Identifier = "MY_MOD_BIG_ROCK",
    ThrowFn = function (player, vec)
        local tear = player:FireTear(player.Position, vec:Resized(player.ShotSpeed * 10) + player:GetTearMovementInheritance(vec))

        tear:AddTearFlags(TearFlags.TEAR_BOUNCE | TearFlags.TEAR_PIERCING)
        tear:ChangeVariant(TearVariant.ROCK)
        tear.CollisionDamage = tear.CollisionDamage * 3
        tear.Scale = tear.Scale * 2
    end,
    AnimateFn = function (player, state)
        if state == ThrowableItemLib.State.THROW then
            player:AnimatePickup(SPRITE, true, "HideItem")
            return true
        end
    end
})

-- Pocket item example
ThrowableItemLib:RegisterThrowableItem({
    ID = Isaac.GetCardIdByName("Explosive Card"),
    Type = ThrowableItemLib.Type.CARD,
    Identifier = "MY_MOD_EXPLOSIVE_CARD",
    ThrowFn = function (player, vec)
        Isaac.Spawn(EntityType.ENTITY_BOMB, BombVariant.BOMB_TROLL, 0, player.Position, vec:Resized(20) + player:GetTearMovementInheritance(vec), player)
    end,
    HideFn = function (player)
        GAME:BombExplosionEffects(player.Position, player.Damage * 3, player:GetBombFlags(), nil, player, 2)
        player:UseActiveItem(CollectibleType.COLLECTIBLE_HOW_TO_JUMP)
    end,
    Flags = ThrowableItemLib.Flag.DISCHARGE_HIDE
})
```
