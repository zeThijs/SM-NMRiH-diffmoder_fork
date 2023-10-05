#if defined _diffmoder_included_
  #endinput
#endif
#define _diffmoder_included_

enum GameMod{
	GameMod_NoMod,
	GameMod_Runner,
	GameMod_Kid,
	GameMod_Crawler
};
enum GameDif{
	GameDif_Default,
	GameDif_Classic,
	GameDif_Casual,
	GameDif_Nightmare
};
enum GameConf{
	GameConf_Default,
	GameConf_Realism,
	GameConf_Friendly,
	GameConf_Hardcore,
	GameConf_Infinity,
	GameConf_DoubleJump,
	GameConf_GlassCannon
};


native GameMod     Diffmoder_GetMod();
native GameDif     Diffmoder_GetDif();
native int         Diffmoder_GetGameCFG(GameConf index);    //pass gameconf item to retrieve on or off , -1 for invalid GameConf


