untyped
global function TopSpeedInit

global struct TS_PlayerData{
	string name 
	string uid
	var speed = 0.0
	var aboveAnnounceSpeed = false
}

array<TS_PlayerData> ts_playerData = [] // data from current match
array<TS_PlayerData> ts_postmatch_playerData = [] // data with this games top speeds to display at end of round

void function TopSpeedInit(){
	AddCallback_OnReceivedSayTextMessage(TS_ChatCallback)

	AddCallback_GameStateEnter(eGameState.Postmatch, TS_Postmatch)

	FlagInit("TS_ReceivedGetPlayer")
	FlagInit("TS_SavedConfig")

	thread TopSpeedMain()
}

void function TopSpeedMain(){
	while(!IsLobby()){
		wait 0.1

		// clear shit
		ts_playerData = []
		// fill array
		foreach(entity player in GetPlayerArray()){

			TS_PlayerData data
			GetPlayer(player, data)

			FlagWait("TS_ReceivedGetPlayer")
			FlagClear("TS_ReceivedGetPlayer")

			ts_playerData.append(data)
		}

		try{
			foreach(TS_PlayerData pd in ts_playerData){
				float speed = GetPlayerSpeed(GetPlayerByUid(pd.uid))
				bool shouldSaveData = false

				// change this rounds top speed of player
				bool isSavedInPMList = false
				foreach(TS_PlayerData pm_data in ts_postmatch_playerData){
					if(pm_data.uid == pd.uid){
						isSavedInPMList = true
						if(pm_data.speed < speed)
							pm_data.speed = speed
						break
					}
				}

				if(!isSavedInPMList){
					TS_PlayerData pm_data
					pm_data.name = pd.name
					pm_data.uid = pd.uid
					pm_data.speed = speed
					ts_postmatch_playerData.append(pm_data)
				}

				// change overall top speed of player 
				if(pd.speed < speed){
					pd.speed = speed
					shouldSaveData = true
				}

				// check if above announcement speed
				if(SpeedToKmh(sqrt(speed)) > GetConVarInt("ts_announce_min_speed") && !pd.aboveAnnounceSpeed){ // special announcement for being fast af
					Chat_ServerBroadcast(format("\x1b[34m[TopSpeed] \x1b[38;2;220;220;20m%s is zooming! \x1b[0m(\x1b[38;2;0;220;30m%.2fkmh\x1b[0m/\x1b[38;2;0;220;30m%.2fmph\x1b[0m)", pd.name, SpeedToKmh(sqrt(speed)), SpeedToMph(sqrt(speed))))
					pd.aboveAnnounceSpeed = true
					shouldSaveData = true
					
					foreach(entity p in GetPlayerArray()){
						try{
							EmitSoundOnEntity(p, "HUD_Boost_Card_Earned_1P")
						} catch(e){} // dont care lol
					}
				}
				// reset aboveAnnounceSpeed bool
				else if (SpeedToKmh(sqrt(speed)) < GetConVarInt("ts_announce_min_speed")) { 
					if(pd.aboveAnnounceSpeed){
						pd.aboveAnnounceSpeed = false
						shouldSaveData = true
					}
				}

				// to minimize api requests and only send if better
				if(shouldSaveData){
					TS_SaveConfig(pd, GetPlayerByUid(pd.uid))
					FlagWait("TS_SavedConfig")
					FlagClear("TS_SavedConfig")
				}
			}
		}catch(e){} // dont care lol
	}
}

void function TS_LeaderBoard(entity player){
	HttpRequest request;
	request.method = HttpRequestMethod.GET;
	request.url = "http://localhost:8080";
	request.headers["t_querytype"] <- ["topspeed_leaderboard"];

	entity player = player

	void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response ) : ( player )
	{
		array<string> lines = split(response.body, "\n")

		int loopAmount = GetConVarInt("ts_cfg_leaderboard_amount")
		
		for(int i = 0; i < (loopAmount > lines.len() ? lines.len() : loopAmount); i++)
			Chat_ServerPrivateMessage(player, lines[i], false, false)
	}

	void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure ) : ( player )
	{
		Chat_ServerPrivateMessage(player, RM_SERVER_ERROR, false, false)
	}

	NSHttpRequest( request, onSuccess, onFailure );
}

void function TS_RankSpeed(entity player){
	HttpRequest request;
	request.method = HttpRequestMethod.GET;
	request.url = "http://localhost:8080";
	request.headers["t_querytype"] <- ["topspeed_queryplayer"];
	request.headers["t_uid"] <- [player.GetUID().tostring()];

	entity player = player

	void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response ) : ( player )
	{
		Chat_ServerPrivateMessage(player, response.body, false, false)
	}

	void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure ) : ( player )
	{
		Chat_ServerPrivateMessage(player, RM_SERVER_ERROR, false, false)
	}

	NSHttpRequest( request, onSuccess, onFailure );
}

void function TS_Postmatch(){
	array<TS_PlayerData> tempPD = ts_postmatch_playerData
	tempPD.sort(TopSpeedSort)

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

void function TS_SaveConfig(TS_PlayerData player_data, entity player){
	// send post request to update
	HttpRequest request;
	request.method = HttpRequestMethod.POST;
	request.url = "http://localhost:8080";
	request.headers["t_uid"] <- [player.GetUID().tostring()];
	request.contentType = "application/json; charset=utf-8"
	request.body =  PlayerDataToJson(player, player_data)

	void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response ) : ( player )
	{
		FlagSet("TS_SavedConfig")
	}

	void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure ) : ( player )
	{
		Chat_ServerPrivateMessage(player, RM_SERVER_ERROR, false, false)
		FlagSet("TS_SavedConfig")
	}

	NSHttpRequest( request, onSuccess, onFailure );
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

entity function GetPlayerByUid(string uid){
	foreach(entity player in GetPlayerArray()){
		if(player.GetUID() == uid)
			return player
	}
	return null // should maybe perhaps never reach
}

void function GetPlayer(entity player, TS_PlayerData tmp){
	HttpRequest request;
	request.method = HttpRequestMethod.GET;
	request.url = "http://localhost:8080";
	request.headers["t_querytype"] <- ["topspeed_queryplayer"];
	request.headers["t_returnraw"] <- ["true"];
	request.headers["t_uid"] <- [player.GetUID().tostring()];

	void functionref( HttpRequestResponse ) onSuccess = void function ( HttpRequestResponse response ) : ( player, tmp )
	{
		// failed to get player
		if(!NSIsSuccessHttpCode(response.statusCode)){
			print("uninitialized player, setting up default for " + player.GetPlayerName())
			tmp.name = player.GetPlayerName() 
			tmp.uid = player.GetUID()
			FlagSet("TS_ReceivedGetPlayer")
			return
		}
			
		// got player successfully
		table json = DecodeJSON(response.body)

		tmp.name = player.GetPlayerName() // maybe they changed their name? idk just gonna do it like this
		tmp.uid = player.GetUID()
		tmp.speed = json.rawget("speed").tofloat()
		tmp.aboveAnnounceSpeed = json.rawget("aboveAnnounceSpeed").tostring() == "true" ? true : false
		FlagSet("TS_ReceivedGetPlayer")
	}

	void functionref( HttpRequestFailure ) onFailure = void function ( HttpRequestFailure failure ) : ( player )
	{
		Chat_ServerPrivateMessage(player, RM_SERVER_ERROR, false, false)
	}
	
	NSHttpRequest( request, onSuccess, onFailure )
}

string function PlayerDataToJson(entity player, TS_PlayerData player_data){
	table tab_inner = {}
	tab_inner[ "mod" ] <- "topspeed"
	tab_inner[ "uid" ] <- player.GetUID()
	tab_inner[ "name" ] <- player.GetPlayerName()
	tab_inner[ "speed" ] <- player_data.speed
	tab_inner[ "aboveAnnounceSpeed" ] <- player_data.aboveAnnounceSpeed

	var mods = []
	mods.append(tab_inner)

	table tab_mods = {}
	tab_mods[ "mods" ] <- mods

	var players = []
	players.append(tab_mods)

	table tab_players = {}
	tab_players[ "players" ] <- players

	return EncodeJSON(tab_players)
}