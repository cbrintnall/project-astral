---

kanban-plugin: board

---

## BUGS

- [ ] Dawn indicator paths should only show on tiles that will give or take dawn
- [ ] Area indicator became an arrow
- [ ] Weird issue where tile cache's immediately attempt to free(), but nothing actually happens besides errors in console.


## TODO

- [ ] [[Create builds of tiles to make game less easy]]
- [ ] Handle case where movement tries to "swap" tiles
	#design
- [ ] Add chipped build
- [ ] Add move build
- [ ] Add effect forging
- [ ] Remove purchasing individual tiles from shop, add forging to shop
- [ ] [[Add deadlock check in tile moves]]
- [ ] Rifts need to auto-leave after 2 turns
- [ ] Rifts need more tile-esque art
- [ ] [[Create overview UI for round to make decisions easier post round (tiles destroyed, max points gained from tile, min points, friendly tiles active enemy tiles active)]]


## Doin

- [ ] Hovering a tile needs to also show what stacks of debuffs (and buffs) it has


## DONE

- [ ] Add tiles into board that can be claimed by the player by placing other tiles near it.
- [ ] Add on move tile effect event
- [ ] Hovering on the grid needs to display what the mult is at that location
- [ ] Add tile rewards after turn ends
- [ ] Add cycle effect where tiles spawn on cycle start
- [ ] Add tile lifetime binding commands
- [ ] Area multiply effect doesn't move areas when the tile itself is moved
- [ ] Add tile movement binding commands




%% kanban:settings
```
{"kanban-plugin":"board","list-collapse":[false,false,false,false]}
```
%%