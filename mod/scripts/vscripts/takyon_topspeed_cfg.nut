global function TS_CfgInit
global array<TS_PlayerData> ts_cfg_players = []

void function TS_CfgInit(){
ts_cfg_players.clear()
AddPlayer("Takyon_Scure", "1006880507304", 7527508.000000)
AddPlayer("darthelmo10", "1009099551543", 530541.000000)
AddPlayer("D16hvv", "1011732926770", 53891.750000)
AddPlayer("ppaulki34", "1003790209029", 49218.406250)
AddPlayer("nut1123", "1011112532827", 112390.531250)
AddPlayer("darksXI", "1004533006501", 239745.250000)
AddPlayer("Gamecrusher216", "1008569916633", 222893.500000)
AddPlayer("ArKKestral", "1006322919372", 188129.750000)
AddPlayer("Lemmienaids", "1009077334958", 172151.125000)
AddPlayer("setdisplay", "1003495333189", 178330.125000)
AddPlayer("b1tc0d3", "1004125857267", 158012.000000)
AddPlayer("I_-m-a-n-g-0_I", "1009102785046", 150968.375000)
AddPlayer("TheLastPepega", "1007189202763", 75863.312500)
AddPlayer("rythmic_claps", "1002205933333", 75417.125000)
}

void function AddPlayer(string name, string uid, float speed){
TS_PlayerData tmp
tmp.name = name
tmp.uid = uid
tmp.speed = speed
ts_cfg_players.append(tmp)
}