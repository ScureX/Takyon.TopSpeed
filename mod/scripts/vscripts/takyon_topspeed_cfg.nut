global function TS_CfgInit
global array<TS_PlayerData> ts_cfg_players = []

void function TS_CfgInit(){
ts_cfg_players.clear()
}

void function AddPlayer(string name, string uid, float speed){
TS_PlayerData tmp
tmp.name = name
tmp.uid = uid
tmp.speed = speed
ts_cfg_players.append(tmp)
}