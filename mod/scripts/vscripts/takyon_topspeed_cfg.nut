global function TS_CfgInit
global array<TS_PlayerData> ts_cfg_players = []

void function TS_CfgInit(){
ts_cfg_players.clear()
AddPlayer("Takyon_Scure", "1006880507304", 2323908.250000)
AddPlayer("ASDasdas", "1003880507304", 344343.906250)
AddPlayer("ddssdsdsd", "1046880507304", 234123.921875)
}

void function AddPlayer(string name, string uid, float speed){
TS_PlayerData tmp
tmp.name = name
tmp.uid = uid
tmp.speed = speed
ts_cfg_players.append(tmp)
}