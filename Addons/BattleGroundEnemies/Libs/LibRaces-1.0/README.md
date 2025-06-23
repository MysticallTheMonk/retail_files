# LibRaces-1.0 (WoW AddOn Library)
![Build](https://github.com/HizurosWoWAddOns/LibRaces-1.0/actions/workflows/bigwigsmods-packager.yml/badge.svg)
![Tag](https://img.shields.io/github/v/tag/HizurosWoWAddOns/LibRaces-1.0?style=flat-square)
![Downloads](https://img.shields.io/github/downloads/HizurosWoWAddOns/LibRaces-1.0/total?style=flat-square)
![Downloads](https://img.shields.io/github/downloads/HizurosWoWAddOns/LibRaces-1.0/latest/total?style=flat-square)
&nbsp; &nbsp; &nbsp; &nbsp;
[![Patreon](https://img.shields.io/badge/&zwj;-Patreon-gray?logo=patreon&color=red&style=flat-square)](https://www.patreon.com/bePatron?u=12558524)
[![Paypal](https://img.shields.io/badge/&zwj;-Paypal-gray?logo=paypal&color=blue&style=flat-square)](https://paypal.me/hizuro)
![Sponsors](https://img.shields.io/github/sponsors/HizurosWoWAddOns?logo=github&style=flat-square)

## Description
This is a little library to translate localized race names to english names like "Mensch" to "Human". (Female and male names)

## To use in addons
```lua
lib = LibStub("LibRaces-1.0")
```

## API

### GetRaceToken
```lua
lib:GetRaceToken(<raceName>)
```

**Example:**
```lua
"NightElf", "Night Elf" = lib:GetRaceToken("Elfe de la nuit")
```

**Arguments:**
* raceName - race name (all client supported languages)

**Return values:**
* englishToken - english version without spacer like realm name behind character names

### GetRaceName
```lua
lib:GetRaceName(<raceName>[,<languageCode>[,<gender>]])
```

Examples:
```lua
-- Orc [english to italian] "Orco", "Orchessa" = lib:GetRaceName("Orc","itIT")

-- Blood Elf [Russian to female portuguese] "Elfa Sangrenta" = lib:GetRaceName("Эльф крови","ptPT",2)
```

**Arguments:**
* raceName - race name (all client supported languages)
* languageCode - deDE, enGB, enUS, esES, esMX, frFR, itIT, koKR, ptBR, ptPT, ruRU, zhCN, zhTW or de, en, es, mx, fr, it, ko, pt, br, ru, cn, tw
* genderIndex - 0=Neutral, 1=Male, 2=Female

**Return values without 3. argument:**
* raceNameMale - male race name in choosen language
* raceNameFemale - female race name in choosen language

**Return values with 3. argument:**
* raceName - neutral, male or female race name in choosen language

### GetLanguageByRaceNamelib
```lua
lib:GetLanguageByRaceNamelib(<raceName>)
```

**Example:**
```lua
"deDE","enGB","enUS","frFR","itIT","ptBT","ptPT" = lib:GetLanguageByRaceName("Troll")
```

**Arguments:**
* raceName - race name (all client supported languages)

**Return values:**
* languageCodeN - a list of language code matching with given race name

### GetGenderByRaceName
```lua
lib:GetGenderByRaceName(<raceName>)
```

**Example:**
```lua
2, "FEMALE" = lib:GetGenderByRaceName("Nachtelfe") -- german female night elf
```

**Arguments:**
* raceName - race name (all client supported languages)

**Return values:**
* genderIndex - 0=Neutral, 1=Male, 2=Female
* genderName - english gender name (uppercase)


## My other projects
* [On Curseforge](https://www.curseforge.com/members/hizuro_de/projects)
* [On Github](https://github.com/HizurosWoWAddOns?tab=repositories)

## Disclaimer
> World of Warcraft© and Blizzard Entertainment© are all trademarks or registered trademarks of Blizzard Entertainment in the United States and/or other countries. These terms and all related materials, logos, and images are copyright © Blizzard Entertainment.
