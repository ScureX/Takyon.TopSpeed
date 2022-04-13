global function TS_CfgInit
global array<TS_PlayerData> ts_cfg_players = []

void function TS_CfgInit(){
ts_cfg_players.clear()
AddPlayer("Takyon_Scure", "1006880507304", 0.000000)
}

void function AddPlayer(string name, string uid, float speed){
TS_PlayerData tmp
tmp.name = name
tmp.uid = uid
tmp.speed = speed
ts_cfg_players.append(tmp)
}