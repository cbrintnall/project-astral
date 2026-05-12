```countdown-to
title: Jam Ends
startDate: 2026-05-08
startTime: 13:00:00
endDate: 2026-05-17
endTime: 15:00:00
type: circle
color: #ff5722
trailColor: #f5f5f5
infoFormat: {percent}% complete - {remaining} until {end:LLL d, yyyy}
updateInRealTime: true
updateIntervalInSeconds: 30
```
### Theme updates:
- You are still Eos, but your job is now to claim a bounty on Nyx’ head.    
- You’ll use the power of the stars to take Nyx down and fight against her children
### Design Guidelines
1. Tiles can **never** resolve sequentially, they must all resolve at the same time to prevent non-obvious turns. EG if two tiles next to each other will destroy each other, they both should be destroyed when they resolve instead of one only destroying the other.
2. Generally statuses should accumulate before round start and resolve on round end
### Design updates (ideas, we can pull from this list):
- [ ] Tile deck removals in shop
- [ ] Tile modification in shop (eg add buffs to tiles, add effects to tiles)
- [ ] Two sided tiles (tiles can have two different sides, each act as different tiles, tiles can be flipped to activate one or the other depending on which is facing up)
- [x] Moveable tiles (support is already sort of there for this, more just need to see how it fits in with design)
- [ ] More statuses (more than just wrath right now)
- [ ] Tile zone previewing on placement (already has dev support, just needs the visuals)
- [ ] Grid events (areas that destroys tiles, areas that block placement of tiles, etc)
- [ ] “Potions”, items that have limited use that can perform actions
- [ ] Better FX for tiles
- [x] Updated UI (just for better visuals
- [ ] Top bar should have a diablo-esque health orb for remaining health on Nyx
- [x] Effect bar doesn’t even thematically fit the game
- [ ] Shop selling individual tiles doesn’t really add much and makes it difficult to do “builds”, it should sell bundles of tiles with themes in addition to individual tiles.
- [ ] Board modifiers per cycle to change up gameplay cycle over cycle
- [ ] Shop isn't explained at all and there is no confirmation if you want to buy something
- [ ] Need an actual hand / discard, right now the hand just gets random tiles which makes it hard to plan around what tiles you'll get in the future
- [ ] Pauses in music / variations
- [ ] Tiles spawn on the map "locked", placing tiles near them unlocks them (this helps with the player not getting tiles, encourages placing in different places). The dawn from the surrounding tile will instead go to the locked one, once the requirement is given the tile is gained
### Card Ideas:

#### Player Card Ideas:
- On destroy: Gain 30 points
- refresh hand
- extra turn / less turn
- On activate: remove a stack of wrath from surrounding tiles, for each stack consumed generate 1 point
- On activate: for each stack of wrath on this tile, all surrounding tiles give 100% additional points
- On round start: increase point by 1, on activate: give points per activation
- On place: fill hand completely, on activate: 10% chance to gain wrath
- On activate: push a nearby tile in a direction [wingTile]
- On place: “Deactivate” (prevent tile from running) the surrounding tiles (grid context will need support for disabled tiles) [eclipse -> actually blackholeTile would be good]
- On activate: Consume a stack of wrath from each surrounding neighbor, for each wrath taken gain 2 points
- On activate: Give each neighbor one wrath, gain 20 points
- On place: The tile directly below this gives 500% additional points [star2Tile]
- On place: “Protect” all neighbor tiles (requires protection support, where if a tile would be destroyed, it destroys this one instead) [dove/blessing]
- On activate: Gain a random number of points in a range
- Black hole: Any tile within 5x5 is pulled toward the black hole, if within 1 tile the target tile is destroyed
- Bacteria like tile that moves around, when it bumps into another bacteria tile it combines their point total 2048 style

#### Negative Card Ideas:
- On activate: remove 10 points [arrowTile]
- On end of round, 50% chance to spawn a minion tile, who removes 1 point per turn