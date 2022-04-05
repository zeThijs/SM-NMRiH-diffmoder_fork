# [NMRiH] NMRiH Diffmoder fork     
**Sourcemod plugins which allows changing of gamemode via voting.**

For base information about the plugin go here:
*https://forums.alliedmods.net/showthread.php?t=301322*

This fork includes some changes and features to the original, such as:

- Automatically reverts back to the default gamemode after the server has been empty for a while. This may be set with the nmrih_autodefault_timer ConVar
- Runner mod now uses the game's built in BecomeRunner() function using a vscript function. This method prevents nmrih zombie spawn brushes from completely stopping spawning.
- A new mode to play: Anklebiters, which converts all zombies into speedy crawlers.
- The option to toggle double jump; requires Double Jump (1.0.1) by Paegus (_https://forums.alliedmods.net/showthread.php?p=895212_)
<pre>

Feel free to use the code or plugin in any way

Credits:

Mostten - [NMRiH] Difficulty and Mod changer(zombies convert to all runners)  - Original diffmoder plugins
Ryan    - [NMRiH] Zombie Speeds (v1.6, 2020-04-06)                            - speed manip snippets
Dysphie - [NMRiH] Backpack 2                                                  - Vscript Proxy 
</pre>
