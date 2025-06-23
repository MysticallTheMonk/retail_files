# BattleGroundEnemies

## [11.0.5.9](https://github.com/BullseiWoWAddons/BattleGroundEnemies/tree/11.0.5.9) (2024-11-25)
[Full Changelog](https://github.com/BullseiWoWAddons/BattleGroundEnemies/compare/11.0.5.8...11.0.5.9) [Previous Releases](https://github.com/BullseiWoWAddons/BattleGroundEnemies/releases)

- changelog: update to version 11.0.5.9 with bug fixes for ally updates, test mode errors, and respawn timer  
- refactor: add debug logging for player details and trigger PlayerDetailsChanged on update to fix bug mostly prominent in solo shuffle(buton order didn't change but there were new players on that button)  
- refactor: streamline module settings application and update button position handling  
- refactor: update PlayerButton class annotation to inherit from Button  
- refactor: fix issue respawn timer not resetting  
- refactor: update PlayerButton type annotations and improve sorting logic in MainFrame to fix bug when testmode in arena  
