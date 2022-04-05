# sourcemod nmrih-diffmoder-fork
**Allows changing of gamemode via voting.**

For base information about the plugin go here:
*https://forums.alliedmods.net/showthread.php?t=301322*

This fork includes some changes and features to the original, such as:

- Automatically reverts back to the default gamemode after the server has been empty for a while. This may be set with the nmrih_autodefault_timer ConVar
- Runner mod now uses the game's built in BecomeRunner() function using a vscript function. This method prevents nmrih zombie spawn brushes from completely stopping spawning.
- A new mode to play: Anklebiters, which converts all zombies into speedy crawlers.
- The option to toggle double jump; requires Double Jump (1.0.1) by Paegus (https://forums.alliedmods.net/showthread.php?p=895212)


Feel free to use the code or plugin in any way
