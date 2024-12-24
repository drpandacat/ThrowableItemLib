--[[
    Throwable item library by Kerkel
    Version 1.0.3.1
]]

---@class ThrowableItemConfig
---@field ID CollectibleType | Card
---@field Type ThrowableItemType
---@field LiftFn? fun(player: EntityPlayer)
---@field HideFn? fun(player: EntityPlayer)
---@field ThrowFn? fun(player: EntityPlayer, vect: Vector)
---@field Flags? ThrowableItemFlag | integer
---@field HoldCondition? fun(player: EntityPlayer, config: ThrowableItemConfig): HoldConditionReturnType

local VERSION = 1.06

return {Init = function ()
    local configs = {}

    if ThrowableItemLib then
        if ThrowableItemLib.Internal.VERSION > VERSION then
            return
        end

        for k, v in pairs(ThrowableItemLib.Internal.Configs) do
            configs[k] = v
        end

        ThrowableItemLib.Internal:ClearCallbacks()
    end

    ThrowableItemLib = RegisterMod("Throwable Item Library", 1)

    ThrowableItemLib.Utility = {}
    ThrowableItemLib.Internal = {}
    ThrowableItemLib.Internal.VERSION = VERSION
    ThrowableItemLib.Internal.CallbackEntries = {}
    ---@type ThrowableItemConfig[]
    ThrowableItemLib.Internal.Configs = configs or {}

    ---@param callback ModCallbacks
    ---@param fn function
    ---@param param any
    local function AddCallback(callback, fn, param)
        table.insert(ThrowableItemLib.Internal.CallbackEntries, {
            ID = callback,
            FN = fn,
            FILTER = param,
        })
    end

    ---@enum ThrowableItemFlag
    ThrowableItemLib.Flag = {
        NO_DISCHARGE = 1 << 0,
        DISCHARGE_HIDE = 1 << 1,
        USABLE_ANY_CHARGE = 1 << 2,
        DISABLE_HIDE = 1 << 3,
        ---Item lift persists when animation is interrupted 
        PERSISTENT = 1 << 4,
        ---Does not activate the item
        DISABLE_ITEM_USE = 1 << 5,
        ---Uses PlayerPickup instead of PlayerPickupSparkle
        NO_SPARKLE = 1 << 6,
        ---No item sprite when hiding
        EMPTY_HIDE = 1 << 7,
        ---No item sprite when throwing
        EMPTY_THROW = 1 << 8,
        ---Shows the animation so beware
        ENABLE_CARD_USE = 1 << 9,
    }

    ---@enum ThrowableItemType
    ThrowableItemLib.Type = {
        ACTIVE = 1,
        CARD = 2,
    }

    ---@enum HoldConditionReturnType
    ThrowableItemLib.HoldConditionReturnType = {
        DEFAULT_USE = 1,
        ALLOW_HOLD = 2,
        DISABLE_USE = 3,
    }

    function ThrowableItemLib.Internal:ClearCallbacks()
        for _, v in ipairs(ThrowableItemLib.Internal.CallbackEntries) do
            ThrowableItemLib:RemoveCallback(v.ID, v.FN)
        end
    end

    ---@param vector Vector
    function ThrowableItemLib.Utility:CardinalClamp(vector)
        return Vector.FromAngle(((vector:GetAngleDegrees() + 45) // 90) * 90)
    end

    ---@param player EntityPlayer
    ---@param disableClamp? boolean
    ---@return Vector
    function ThrowableItemLib.Utility:GetAimVect(player, disableClamp)
        local vect = player:GetAimDirection()
        local returnVect = Vector(vect.X, vect.Y)

        if not disableClamp then
            if returnVect:Length() > 0.001 then
                if not player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) and not player:HasCollectible(CollectibleType.COLLECTIBLE_ANALOG_STICK) then
                    returnVect = ThrowableItemLib.Utility:CardinalClamp(returnVect)
                end
            end
        end

        return returnVect
    end

    ---@param player EntityPlayer
    ---@return boolean
    function ThrowableItemLib.Utility:IsShooting(player)
        return ThrowableItemLib.Utility:GetAimVect(player):Length() > 0.001
    end

    ---@param entity Entity
    function ThrowableItemLib.Internal:GetData(entity)
        local data = entity:GetData()

        data.__THROWABLE_ITEM_LIBRARY = data.__THROWABLE_ITEM_LIBRARY or {}

        return data.__THROWABLE_ITEM_LIBRARY
    end

    ---@param flags integer
    ---@param flag integer
    ---@return boolean
    function ThrowableItemLib.Utility:HasFlags(flags, flag)
        return flags & flag ~= 0
    end

    ---@param id CollectibleType | Card
    ---@param type ThrowableItemType
    ---@return string
    function ThrowableItemLib.Internal:GetHeldConfigKey(id, type)
        return (type == ThrowableItemLib.Type.ACTIVE and "ACTIVE_" or "CARD_") .. id
    end

    ---@param player EntityPlayer
    ---@param slot ActiveSlot
    function ThrowableItemLib.Utility:NeedsCharge(player, slot)
        local item = player:GetActiveItem(slot) if not item or item == 0 then return end
        local charges = Isaac.GetItemConfig():GetCollectible(item).MaxCharges

        return player:GetActiveCharge(slot) + player:GetBloodCharge() + player:GetSoulCharge() < charges
    end

    ---@param player EntityPlayer
    ---@param id CollectibleType | Card
    ---@param type ThrowableItemType
    ---@param slot? ActiveSlot
    ---@param continue? boolean
    function ThrowableItemLib.Utility:LiftItem(player, id, type, slot, continue)
        local config = ThrowableItemLib.Internal.Configs[ThrowableItemLib.Internal:GetHeldConfigKey(id, type)] if not config then return end
        local data = ThrowableItemLib.Internal:GetData(player)

        data.HeldConfig = config
        data.ActiveSlot = slot

        if type == ThrowableItemLib.Type.ACTIVE then
            player:AnimateCollectible(data.HeldConfig.ID, "LiftItem", ThrowableItemLib.Utility:HasFlags(config.Flags, ThrowableItemLib.Flag.NO_SPARKLE) and "PlayerPickup" or "PlayerPickupSparkle")
        else
            player:AnimateCard(data.HeldConfig.ID, "LiftItem")
        end

        if REPENTOGON then
            ---@diagnostic disable-next-line: undefined-field
            player:SetItemState(type == ThrowableItemLib.Type.ACTIVE and config.ID or 0)
        end

        if data.HeldConfig.LiftFn and not continue then
            data.HeldConfig.LiftFn(player)
        end
    end

    ---@param player EntityPlayer
    ---@return ThrowableItemConfig
    function ThrowableItemLib.Utility:GetLiftedItem(player)
        return ThrowableItemLib.Internal:GetData(player).HeldConfig
    end

    ---@param player EntityPlayer
    ---@return boolean
    function ThrowableItemLib.Utility:IsItemLifted(player)
        return not not ThrowableItemLib.Utility:GetLiftedItem(player)
    end

    local EMPTY_SPRITE = Sprite()

    ---@param player EntityPlayer
    ---@param throw? boolean
    function ThrowableItemLib.Utility:HideItem(player, throw)
        if not ThrowableItemLib.Utility:IsItemLifted(player) then return end

        local data = ThrowableItemLib.Internal:GetData(player)
        local active = data.HeldConfig.Type == ThrowableItemLib.Type.ACTIVE

        if throw and ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.EMPTY_THROW) or ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.EMPTY_HIDE) then
            player:AnimatePickup(EMPTY_SPRITE, true, "HideItem")
        else
            if active then
                player:AnimateCollectible(data.HeldConfig.ID, "HideItem", ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.NO_SPARKLE) and "PlayerPickup" or "PlayerPickupSparkle")
            else
                player:AnimateCard(data.HeldConfig.ID, "HideItem")
            end
        end

        local function ThrowItem(card)
            data.ActiveSlot = data.ActiveSlot or ActiveSlot.SLOT_PRIMARY

            if ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.DISABLE_ITEM_USE) then
                if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.NO_DISCHARGE) then
                    player:SetActiveCharge(player:GetActiveCharge(data.ActiveSlot) - Isaac.GetItemConfig():GetCollectible(data.HeldConfig.ID).MaxCharges, data.ActiveSlot)
                end
            else
                local item = card and player:GetActiveItem(data.ActiveSlot) or data.HeldConfig.ID

                player:UseActiveItem(item)

                if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.NO_DISCHARGE) then
                    player:DischargeActiveItem(data.ActiveSlot)
                end
            end
        end

        local function ThrowCard()
            if data.Mimic then
                ThrowItem(true)
            else
                if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.ENABLE_CARD_USE)
                or ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.DISABLE_ITEM_USE) then
                    if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.NO_DISCHARGE) then
                        player:SetCard(0, 0)
                    end
                else
                    if ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.NO_DISCHARGE) then
                        player:UseCard(data.HeldConfig.ID)
                    else
                        data.ForceInputSlot = ActiveSlot.SLOT_POCKET
                    end
                end
            end
        end

        if throw then
            if active then
                ThrowItem()
            else
                ThrowCard()
            end
        else
            if data.HeldConfig.HideFn then
                data.HeldConfig.HideFn(player)
            end

            if ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.DISCHARGE_HIDE) then
                if active then
                    ThrowItem()
                else
                    ThrowCard()
                end
            end
        end

        data.HeldConfig = nil
        data.ActiveSlot = nil
        data.Mimic = nil

        if REPENTOGON then
            ---@diagnostic disable-next-line: undefined-field
            player:SetItemState(CollectibleType.COLLECTIBLE_NULL)
        end
    end

    ---@param player EntityPlayer
    ---@return ThrowableItemConfig?
    function ThrowableItemLib.Utility:GetThrowableActiveConfig(player)
        local data = ThrowableItemLib.Internal:GetData(player)

        if data.HeldConfig and data.HeldConfig.Type == ThrowableItemLib.Type.ACTIVE and data.ActiveSlot == ActiveSlot.SLOT_PRIMARY then
            return data.HeldConfig
        end

        return ThrowableItemLib.Internal.Configs[ThrowableItemLib.Internal:GetHeldConfigKey(player:GetActiveItem(ActiveSlot.SLOT_PRIMARY), ThrowableItemLib.Type.ACTIVE)]
    end

    ---@param player EntityPlayer
    ---@return ThrowableItemConfig?
    function ThrowableItemLib.Utility:GetThrowableCardConfig(player)
        local data = ThrowableItemLib.Internal:GetData(player)

        if data.HeldConfig and data.HeldConfig.Type == ThrowableItemLib.Type.CARD then
            return data.HeldConfig
        end

        return ThrowableItemLib.Internal.Configs[ThrowableItemLib.Internal:GetHeldConfigKey(player:GetCard(0), ThrowableItemLib.Type.CARD)]
    end

    ---@param player EntityPlayer
    ---@return ThrowableItemConfig?
    function ThrowableItemLib.Utility:GetThrowablePocketConfig(player)
        local data = ThrowableItemLib.Internal:GetData(player)

        if data.HeldConfig and data.HeldConfig.Type == ThrowableItemLib.Type.ACTIVE and data.ActiveSlot == ActiveSlot.SLOT_POCKET then
            return data.HeldConfig
        end

        if player:GetCard(0) ~= Card.CARD_NULL then return end
        return ThrowableItemLib.Internal.Configs[ThrowableItemLib.Internal:GetHeldConfigKey(player:GetActiveItem(ActiveSlot.SLOT_POCKET), ThrowableItemLib.Type.ACTIVE)]
    end

    ---@param config ThrowableItemConfig
    function ThrowableItemLib:RegisterThrowableItem(config)
        config.Flags = config.Flags or 0
        ThrowableItemLib.Internal.Configs[ThrowableItemLib.Internal:GetHeldConfigKey(config.ID, config.Type)] = config
    end

    ---@param player EntityPlayer
    ---@param config ThrowableItemConfig
    ---@return HoldConditionReturnType?
    function ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config)
        if config.HoldCondition then
            return config.HoldCondition(player, config)
        end
        return ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD
    end

    ---@param entity Entity?
    ---@param action ButtonAction
    AddCallback(ModCallbacks.MC_INPUT_ACTION, function (_, entity, _, action)
        local player = entity and entity:ToPlayer() if not player then return end

        if action == ButtonAction.ACTION_ITEM then
            local data = ThrowableItemLib.Internal:GetData(player)

            if data.ForceInputSlot == ActiveSlot.SLOT_PRIMARY then
                data.ForceInputSlot = false
                return true
            end

            local active = ThrowableItemLib.Utility:GetThrowableActiveConfig(player)

            if active then
                if ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, active) == ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE then return end
                return false
            end

            if ThrowableItemLib.Utility:GetThrowableCardConfig(player) then
                local card = player:GetCard(0)
                local config = Isaac.GetItemConfig():GetCard(card)
                local item = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)

                ---@diagnostic disable-next-line: undefined-field
                if (config:IsRune() and item == CollectibleType.COLLECTIBLE_CLEAR_RUNE or REPENTOGON and player:VoidHasCollectible(CollectibleType.COLLECTIBLE_CLEAR_RUNE)) or
                ---@diagnostic disable-next-line: undefined-field
                (config:IsCard() and item == CollectibleType.COLLECTIBLE_BLANK_CARD or REPENTOGON and player:VoidHasCollectible(CollectibleType.COLLECTIBLE_BLANK_CARD)) then
                    local cardThrowConfig = ThrowableItemLib.Utility:GetThrowableCardConfig(player)

                    if cardThrowConfig then
                        if ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, cardThrowConfig) == ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE then return end
                        return false
                    end
                end
            end
        elseif action == ButtonAction.ACTION_PILLCARD then
            local data = ThrowableItemLib.Internal:GetData(player)

            if data.ForceInputSlot == ActiveSlot.SLOT_POCKET then
                data.ForceInputSlot = false
                return true
            end

            local card = ThrowableItemLib.Utility:GetThrowableCardConfig(player)

            if card then
                if ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, card) == ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE then return end
                return false
            end

            local pocket = ThrowableItemLib.Utility:GetThrowablePocketConfig(player)

            if pocket then
                if ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, pocket) == ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE then return end
                return false
            end
        elseif action == ButtonAction.ACTION_DROP and ThrowableItemLib.Utility:IsItemLifted(player) then
            return false
        end
    end, InputHook.IS_ACTION_TRIGGERED)

    ---@param player EntityPlayer
    AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function(_, player)
        local q = Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
        local data = ThrowableItemLib.Internal:GetData(player)

        ---@param slot ActiveSlot
        ---@param config ThrowableItemConfig
        local function HandleAction(slot, config)
            local item = player:GetActiveItem(slot)

            if ThrowableItemLib.Utility:IsItemLifted(player) and data.ActiveSlot == slot then
                data.ScheduleHide = true
            elseif (not ThrowableItemLib.Utility:NeedsCharge(player, slot) or ThrowableItemLib.Utility:HasFlags(config.Flags, ThrowableItemLib.Flag.USABLE_ANY_CHARGE)) and ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config) == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD then
                ThrowableItemLib.Utility:LiftItem(player, item, ThrowableItemLib.Type.ACTIVE, slot)
            end
        end

        local active = ThrowableItemLib.Utility:GetThrowableActiveConfig(player)

        if active and Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex) then
            HandleAction(ActiveSlot.SLOT_PRIMARY, active)
        end

        local pocket = ThrowableItemLib.Utility:GetThrowablePocketConfig(player)

        if pocket and q then
            HandleAction(ActiveSlot.SLOT_POCKET, pocket)
        end

        local config = ThrowableItemLib.Utility:GetThrowableCardConfig(player)

        if config then
            local card = player:GetCard(0)

            if q then
                if ThrowableItemLib.Utility:IsItemLifted(player) and config.Type == ThrowableItemLib.Type.CARD then
                    data.ScheduleHide = true
                elseif ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config) == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD then
                    ThrowableItemLib.Utility:LiftItem(player, card, ThrowableItemLib.Type.CARD)
                end
            end

            local item = player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)

            if (not ThrowableItemLib.Utility:NeedsCharge(player, ActiveSlot.SLOT_PRIMARY)
            or ThrowableItemLib.Utility:HasFlags(config.Flags, ThrowableItemLib.Flag.USABLE_ANY_CHARGE))
            and Input.IsActionTriggered(ButtonAction.ACTION_ITEM, player.ControllerIndex) then
                local itemConfig = Isaac.GetItemConfig():GetCard(card)

                ---@diagnostic disable-next-line: undefined-field
                if (itemConfig:IsRune() and (item == CollectibleType.COLLECTIBLE_CLEAR_RUNE or (REPENTOGON and item == CollectibleType.COLLECTIBLE_VOID and player:VoidHasCollectible(CollectibleType.COLLECTIBLE_CLEAR_RUNE))))
                ---@diagnostic disable-next-line: undefined-field
                or (itemConfig:IsCard() and (item == CollectibleType.COLLECTIBLE_BLANK_CARD or (REPENTOGON and item == CollectibleType.COLLECTIBLE_VOID and player:VoidHasCollectible(CollectibleType.COLLECTIBLE_BLANK_CARD)))) then
                    if ThrowableItemLib.Utility:IsItemLifted(player) and config.Type == ThrowableItemLib.Type.CARD then
                        data.ScheduleHide = true
                    else
                        data.Mimic = item
                        data.ActiveSlot = ActiveSlot.SLOT_PRIMARY

                        if ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config) == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD then
                            ThrowableItemLib.Utility:LiftItem(player, card, ThrowableItemLib.Type.CARD)
                        end
                    end
                end
            end
        end

        if data.ScheduleLift then
            ThrowableItemLib.Utility:LiftItem(table.unpack(data.ScheduleLift))
            data.ScheduleLift = nil
        end
    end)

    ---@param player EntityPlayer
    AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
        local data = ThrowableItemLib.Internal:GetData(player)

        if data.ScheduleHide then
            if not ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.DISABLE_HIDE) then
                ThrowableItemLib.Utility:HideItem(player)
            end

            data.ScheduleHide = false
        end

        if ThrowableItemLib.Utility:IsItemLifted(player) then
            if player:IsExtraAnimationFinished() then
                if ThrowableItemLib.Utility:HasFlags(data.HeldConfig.Flags, ThrowableItemLib.Flag.PERSISTENT) then
                    ThrowableItemLib.Utility:LiftItem(player, data.HeldConfig.ID, data.HeldConfig.Type, data.ActiveSlot, true)
                else
                    data.HeldConfig = nil
                    data.ActiveSlot = nil
                    data.Mimic = nil
                end
            elseif ThrowableItemLib.Utility:IsShooting(player) then
                if data.HeldConfig.ThrowFn then
                    data.HeldConfig.ThrowFn(player, ThrowableItemLib.Utility:GetAimVect(player))
                end

                ThrowableItemLib.Utility:HideItem(player, true)
            end
        end
    end)

    ---@param id CollectibleType
    ---@param player EntityPlayer
    ---@param flags UseFlag | integer
    ---@param slot ActiveSlot
    AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function (_, id, _, player, flags, slot)
        local config = ThrowableItemLib.Internal.Configs[ThrowableItemLib.Internal:GetHeldConfigKey(id, ThrowableItemLib.Type.ACTIVE)] if not config then return end

        if not player:HasCollectible(id) then
            local condition = ThrowableItemLib.Utility:ShouldLiftThrowableItem(player, config)

            if condition == ThrowableItemLib.HoldConditionReturnType.DEFAULT_USE then return end

            if condition == ThrowableItemLib.HoldConditionReturnType.ALLOW_HOLD then
                ThrowableItemLib.Internal:GetData(player).ScheduleLift = {player, id, ThrowableItemLib.Type.ACTIVE, slot ~= -1 and slot or ActiveSlot.SLOT_PRIMARY}
                return true
            end

            if condition == ThrowableItemLib.HoldConditionReturnType.DISABLE_USE then
                return true
            end
        end
    end)

    for _, v in ipairs(ThrowableItemLib.Internal.CallbackEntries) do
        ThrowableItemLib:AddCallback(v.ID, v.FN, v.FILTER)
    end
end}