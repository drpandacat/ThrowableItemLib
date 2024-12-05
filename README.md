throwable item library (1.0)

cool library to create active items and cards that are throwable similarly to bob's rotten head

works with cards in addition to active items
- blank card support
- clear rune support

7 throw flags to modify behavior
- no discharge
- discharge on hide
- usable any charge
- disable hide
- persist through animation interruptions
- disable item use
- no sparkle

register throwable item function with throwable item config argument

throwable item config:
- ID - CollectibleType / Card
- Type - ThrowableItemType
- LiftFn (optional) - fun(player: EntityPlayer)
- HideFn (optional) - fun(player: EntityPlayer)
- ThrowFn (optional) - fun(player: EntityPlayer, vect: Vector)
- Flags (optional) - ThrowableItemFlag
- HoldCondition (optional) - fun(player: EntityPlayer, config: ThrowableItemConfig): HoldConditionReturnType

hold condition return type:
- default use
- allow hold
- disable use

its cool and simple
