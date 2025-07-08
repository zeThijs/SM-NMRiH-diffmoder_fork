# [NMRiH] NMRiH Diffmoder fork     
## Description
**Sourcemod plugin** which allows changing of **gamemode** via **voting.** 
You can vote to change the difficulty and mod or the other configs, for example: Enable the zombies to run all or kids all......


**[Commands]**
- sm_dif: open the menu;
- sm_difshow: show your curren info of the mod.



## Changes to the original
This **fork** includes some **changes** and features to the original, such as:

- Automatically **revert**s back to the default **gamemode** after the server has been empty for a while. This may be set with the nmrih_autodefault_timer ConVar
- A new mode to play: **Speedycrawlers**, which converts all zombies into speedy crawlers.
- The option to **toggle double jump**; requires Double Jump (1.0.1) by Paegus (_https://forums.alliedmods.net/showthread.php?p=895212_)
- **Toggling Mutators**
- **Changing spawn density**
- **Glasscannon mode** ( players shatter if lightly touched )
- **Casual cooldown**, useful when players inevitably abuse casual switch for infinite respawns

**[Changelog]**
- 11/11/2024 **Add**ed feature: **mutator toggle** support, convar diffmoder_mutators

**[Language]**
English and sChinese or the other by yourself to edit the file of the path is translations/nmrih.diffmoder.phrases.txt
If you translate to your language, put a pull request I will integrate the translations.

## Requires DHooks:
Note, only required on older sourcemod versions. Newer sourcemod versions already have DHooks internally
https://forums.alliedmods.net/showthread.php?t=180114


## Cvars:
<pre>
g_cfg_doublejump_enabled, 0, Double Jump: 0 - disabled, 1 - enabled
diffmoder, 1, Enable/Disable plugin.
diffmoder_infinity_default, 0, 0 Normal ammo/clip, 1 Infinite ammo, 2 Infinite clip.
diffmoder_gamemode_default, 0, 0 No gamemod, 1 Runners, 2 - All kids, 3 - Crawlers
diffmoder_friendly_default, 0, Friendly fire: 0 - off, 1 - on
diffmoder_realism_default, 0, Realism: 0 - off, 1 - on
diffmoder_hardcore_default, 0, Hardcore survival: 0 - off, 1 - on
diffmoder_glasscannon_default, 0, 0 - off, 1 on
diffmoder_difficulty_default, classic, Difficulty: classic, casual, nightmare
diffmoder_casual_cooldown, 300, Casual switch refractory period. Locks untill cooldown finished
diffmoder_autodefault_timer, 1200.0, Time until diffmoder revert to default gamemode.
diffmoder_mapchange_default, 0, 0: off, 1: on. Change the diffmode to default after map change.
diffmoder_modeswitch_cooldown, 60, Delay after a vote before another may be started again.
diffmoder_difficulties, casual classic nightmare default, Enabled difficulties, those not in this list cannot be selected.
diffmoder_mods, runner kid crawler default, Enabled mods, those not in this list cannot be selected.
diffmoder_configs, realism hardcore doublejump glasscannon default, Enabled configs, those not in this list cannot be selected.
diffmoder_density, 1, Enable the ability to select zombie spawn density.
diffmoder_mutators, , Which mutators can people choose from?. Keeping empty disables.
</pre>

## Credits:
<pre>

Credits:

Mostten - [NMRiH] Difficulty and Mod changer        - Original diffmoder plugin *https://forums.alliedmods.net/showthread.php?t=301322*
Ryan    - [NMRiH] Zombie Speeds (v1.6, 2020-04-06)  - speed manip snippets
Dysphie - [NMRiH] Backpack 2                        - Vscript Proxy, and giving the idea of using it
Blueberryy - Translations
</pre>
