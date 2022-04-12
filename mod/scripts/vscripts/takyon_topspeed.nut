global function TopSpeedInit

struct TS_PlayerData{
	string name 
	float speed = 0
}

array<TS_PlayerData> ts_playerData = []

void function TopSpeedInit(){
	AddCallback_OnPlayerRespawned(TS_OnPlayerSpawned)
    AddCallback_OnClientDisconnected(TS_OnPlayerDisconnected)
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
					}
				} catch(e){}
			}
		}
	}
}

/*
 *	HELPER FUNCTIONS
 */

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

	Chat_ServerBroadcast("\x1b[34m[TopSpeed] \x1b[38;2;0;220;30mLeaderboard")
	for(int i = 0; i < rankAmount; i++){
		switch(i){
			case 0:
				Chat_ServerBroadcast("\x1b[38;2;254;214;0m" + tempPD[0].name + ": \x1b[38;2;75;245;66m" + SpeedToKmh(sqrt(tempPD[0].speed)) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + SpeedToMph(sqrt(tempPD[0].speed)) + "mph")
				break
			case 1:
				Chat_ServerBroadcast("\x1b[38;2;210;210;210m" + tempPD[1].name + ": \x1b[38;2;75;245;66m" + SpeedToKmh(sqrt(tempPD[1].speed)) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + SpeedToMph(sqrt(tempPD[1].speed)) + "mph")
				break
			case 2:
				Chat_ServerBroadcast("\x1b[38;2;204;126;49m" + tempPD[2].name + ": \x1b[38;2;75;245;66m" + SpeedToKmh(sqrt(tempPD[2].speed)) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + SpeedToMph(sqrt(tempPD[2].speed)) + "mph")
				break
			default:
				Chat_ServerBroadcast(": \x1b[38;2;75;245;66m" + SpeedToKmh(sqrt(tempPD[i].speed)) + "kmh\x1b[0m/\x1b[38;2;75;245;66m" + SpeedToMph(sqrt(tempPD[i].speed)) + "mph")
				break
		}
	}

	Chat_ServerBroadcast("\n")
	print("[TS] Leaderboard sent")
}

int function SpeedSort(TS_PlayerData data1, TS_PlayerData data2)
{
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
		ts_playerData.append(tmp)
	}
}

void function TS_OnPlayerDisconnected(entity player){
	for(int i = 0; i < ts_playerData.len(); i++){
		try{
			if(player.GetPlayerName() == ts_playerData[i].name){
				ts_playerData.remove(i)
			}
		} catch(e){}
	}
}