global function TopSpeedInit

global struct TS_PlayerData{
	string name 
	string uid
	float speed = 0
	bool aboveAnnounceSpeed = false
}

string path = "../R2Northstar/mods/Takyon.TopSpeed/mod/scripts/vscripts/takyon_topspeed_cfg.nut" // where the config is stored
array<TS_PlayerData> ts_playerData = [] // data from current match

void function TopSpeedInit(){
	AddCallback_OnReceivedSayTextMessage(TS_ChatCallback)

	AddCallback_OnPlayerRespawned(TS_OnPlayerSpawned)
	AddCallback_OnPlayerKilled(TS_OnPlayerKilled)
	AddCallback_GameStateEnter(eGameState.Postmatch, TS_Postmatch)

	thread TopSpeedMain()
}

void function TopSpeedMain(){
	while(!IsLobby()){
		wait 0.1
		
		foreach(entity player in GetPlayerArray()){
			foreach(TS_PlayerData pd in ts_playerData){
				try{
					if(player.GetPlayerName() == pd.name){
						float speed = GetPlayerSpeed(player)

						if(speed > pd.speed)
							pd.speed = speed
						
						if(SpeedToKmh(sqrt(speed)) > GetConVarInt("ts_announce_min_speed") && !pd.aboveAnnounceSpeed){ // special announcement for being fast af
							Chat_ServerBroadcast(format("\x1b[34m[TopSpeed] \x1b[38;2;220;220;20m%s is zooming! \x1b[0m(\x1b[38;2;0;220;30m%.2fkmh\x1b[0m/\x1b[38;2;0;220;30m%.2fmph\x1b[0m)", pd.name, SpeedToKmh(sqrt(speed)), SpeedToMph(sqrt(speed))))
							pd.aboveAnnounceSpeed = true
							TS_SaveConfig()
							foreach(entity p in GetPlayerArray()){
								try{
									EmitSoundOnEntity(p, "HUD_Boost_Card_Earned_1P")
								} catch(e){} // dont care lol
							}
						}
						else if (SpeedToKmh(sqrt(speed)) < GetConVarInt("ts_announce_min_speed")) pd.aboveAnnounceSpeed = false
					}
				} catch(e){print(e)}
			}
		}
	}
}

void function TS_LeaderBoard(entity player){
	TS_CfgInit() // load config

	array<TS_PlayerData> ts_sortedConfig = ts_cfg_players // sort config in new array to not fuck with other shit
	ts_sortedConfig.sort(TopSpeedSort)
	Chat_ServerPrivateMessage(player, "\x1b[34m[TopSpeed] \x1b[38;2;0;220;30mTop Leaderboard", false)

	int loopAmount = GetConVarInt("ts_cfg_leaderboard_amount") > ts_sortedConfig.len() ? ts_sortedConfig.len() : GetConVarInt("ts_cfg_leaderboard_amount")

	for(int i = 0; i < loopAmount; i++){
		Chat_ServerPrivateMessage(player, "[" + (i+1) + "] " + ts_sortedConfig[i].name + ": \x1b[38;2;75;245;66m" + format("%.2f", SpeedToKmh(sqrt(ts_sortedConfig[i].speed))) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + format("%.2f", SpeedToMph(sqrt(ts_sortedConfig[i].speed))) + "mph", false)
	}
}

void function TS_RankSpeed(entity player){
	TS_CfgInit() // load config

	array<TS_PlayerData> ts_sortedConfig = ts_cfg_players // sort config in new array to not fuck with other shit
	ts_sortedConfig.sort(TopSpeedSort)

	for(int i = 0; i < ts_sortedConfig.len(); i++){
		if(ts_sortedConfig[i].uid == player.GetUID()){
			Chat_ServerPrivateMessage(player, "[" + (i+1) + "] " + ts_sortedConfig[i].name + ": \x1b[38;2;75;245;66m" + format("%.2f", SpeedToKmh(sqrt(ts_sortedConfig[i].speed))) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + format("%.2f", SpeedToMph(sqrt(ts_sortedConfig[i].speed))) + "mph", false)
			break
		}
	}
}

/*
 *	CHAT COMMANDS
 */

ClServer_MessageStruct function TS_ChatCallback(ClServer_MessageStruct message) {
    string msg = message.message.tolower()
    // find first char -> gotta be ! to recognize command
    if (format("%c", msg[0]) == "!") {
        // command
        msg = msg.slice(1) // remove !
        array<string> msgArr = split(msg, " ") // split at space, [0] = command
        string cmd
        
        try{
            cmd = msgArr[0] // save command
        }
        catch(e){
            return message
        }

        // command logic
		if(cmd == "topspeed" || cmd == "ts"){
			TS_LeaderBoard(message.player)
		}
		else if(cmd == "rankspeed"){
			TS_RankSpeed(message.player)
		}
    }
    return message
}

/*
 *	CONFIG
 */

const string TS_HEADER = "global function TS_CfgInit\n" +
						 "global array<TS_PlayerData> ts_cfg_players = []\n\n" +
						 "void function TS_CfgInit(){\n" +
						 "ts_cfg_players.clear()\n"

const string TS_FOOTER = "}\n\n" +
						 "void function AddPlayer(string name, string uid, float speed){\n" +
						 "TS_PlayerData tmp\ntmp.name = name\ntmp.uid = uid\ntmp.speed = speed\nts_cfg_players.append(tmp)\n" +
						 "}"

void function TS_SaveConfig(){
	TS_CfgInit()

	array<TS_PlayerData> livePlayersToSave = []
	array<TS_PlayerData> offlinePlayersToSave = []

	foreach(TS_PlayerData pd in ts_playerData){ // loop through each player in current match, save all players with higher times or not in cfg
		bool found = false
		foreach(TS_PlayerData pdcfg in ts_cfg_players){
			if(pd.uid == pdcfg.uid){ // player is in cfg and faster -> should save
				found = true
				if(pdcfg.speed < pd.speed)
					livePlayersToSave.append(pd)
			}
		}

		if(!found){ // not in cfg -> save
			livePlayersToSave.append(pd)
		}
	}

	// loop through cfg to save players not online
	foreach(TS_PlayerData pdcfg in ts_cfg_players){ // loop through everyone in config
		bool found = false
		foreach(TS_PlayerData pd in livePlayersToSave){ // loop through each player that should be saved. if pdcfg cant be found there player is offline. save pdcfg
			if(pd.uid == pdcfg.uid)
				found = true // player is aleady in livePLayerToSave, dont save their cfg
		}

		if(!found){ // player not in livePlayersToSave -> is offline, save cfg
			offlinePlayersToSave.append(pdcfg)
		}
	}

	// merge live and offline players
	array<TS_PlayerData> allPlayersToSave = []
	allPlayersToSave.extend(livePlayersToSave)
	allPlayersToSave.extend(offlinePlayersToSave)

	// write to buffer
	DevTextBufferClear()
	DevTextBufferWrite(TS_HEADER)

	foreach(TS_PlayerData pd in allPlayersToSave){
		DevTextBufferWrite(format("AddPlayer(\"%s\", \"%s\", %f)\n", pd.name, pd.uid, pd.speed))
	}

    DevTextBufferWrite(TS_FOOTER)

    DevP4Checkout(path)
	DevTextBufferDumpToFile(path)
	DevP4Add(path)

	print("[TopSpeed] Saved config at " + path)
	//Chat_ServerBroadcast("\x1b[34m[TopSpeed] \x1b[38;2;75;245;66mSpeeds have been saved and will be updated on map-reload")
}

/*
 *	HELPER FUNCTIONS
 */

int function TopSpeedSort(TS_PlayerData data1, TS_PlayerData data2)
{
  if ( data1.speed == data2.speed )
    return 0
  return data1.speed < data2.speed ? 1 : -1
}

float function GetPlayerSpeed(entity player){
	vector playerVelV = player.GetVelocity()
    return (playerVelV.x * playerVelV.x + playerVelV.y * playerVelV.y)
}

float function SpeedToKmh(float vel){
	return vel * (0.274176/3)
}

float function SpeedToMph(float vel){
	return (vel * (0.274176/3)) * (0.621371)
}

void function TS_Postmatch(){
	array<TS_PlayerData> tempPD = ts_playerData
	tempPD.sort(SpeedSort)

	// avoid infinite loop
	int rankAmount
	if(tempPD.len() < GetConVarInt("ts_rank_amount")) rankAmount = tempPD.len()
	else rankAmount = GetConVarInt("ts_rank_amount")

	Chat_ServerBroadcast("\x1b[34m[TopSpeed] \x1b[38;2;0;220;30mMatch-Leaderboard")
	for(int i = 0; i < rankAmount; i++){
		switch(i){
			case 0:
				Chat_ServerBroadcast("\x1b[38;2;254;214;0m" + tempPD[0].name + ": \x1b[38;2;75;245;66m" + format("%.2f", SpeedToKmh(sqrt(tempPD[0].speed))) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + format("%.2f", SpeedToMph(sqrt(tempPD[0].speed))) + "mph")
				break
			case 1:
				Chat_ServerBroadcast("\x1b[38;2;210;210;210m" + tempPD[1].name + ": \x1b[38;2;75;245;66m" + format("%.2f", SpeedToKmh(sqrt(tempPD[1].speed))) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + format("%.2f", SpeedToMph(sqrt(tempPD[1].speed))) + "mph")
				break
			case 2:
				Chat_ServerBroadcast("\x1b[38;2;204;126;49m" + tempPD[2].name + ": \x1b[38;2;75;245;66m" + format("%.2f", SpeedToKmh(sqrt(tempPD[2].speed))) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + format("%.2f", SpeedToMph(sqrt(tempPD[2].speed))) + "mph")
				break
			default:
				Chat_ServerBroadcast(tempPD[i].name +": \x1b[38;2;75;245;66m" + format("%.2f", SpeedToKmh(sqrt(tempPD[i].speed))) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + format("%.2f", SpeedToMph(sqrt(tempPD[i].speed)) + "mph"))
				break
		}
	}

	Chat_ServerBroadcast("")
	print("[TS] Leaderboard sent")
	TS_SaveConfig()
}

int function SpeedSort(TS_PlayerData data1, TS_PlayerData data2){
  if ( data1.speed == data2.speed )
    return 0
  return data1.speed < data2.speed ? 1 : -1
}

void function TS_OnPlayerSpawned(entity player){
	bool found = false
	foreach(TS_PlayerData pd in ts_playerData){
		try{
			if(player.GetPlayerName() == pd.name){
				found = true
			}
		} catch(e){}
	}

	if(!found){
		TS_PlayerData tmp
		tmp.name = player.GetPlayerName()
		tmp.uid = player.GetUID()
		ts_playerData.append(tmp)
	}
}

void function TS_OnPlayerKilled(entity player){
	TS_SaveConfig() // use this as periodic saving lol
}