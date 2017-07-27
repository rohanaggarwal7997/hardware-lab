loadProjectFile -file "E:\DDP\Xilinx\counter\auto_project.ipf"
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
setMode -bs
setMode -bs
setMode -bs
setMode -bs
setMode -bs
setMode -bs
deleteDevice -position 1
setMode -bs
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
setMode -bs
setMode -bs
setCable -port auto
addDevice -p 1 -file "E:/Desktop/Assign4/Attempt2 - Shivram/top.bit"
expressxsvf -p 1 -program -erase -verify -file "E:\Desktop\Assign4\Attempt2 - Shivram\default.xsvf" 
expressxsvf -p 1 -program -erase -verify -file "E:\Desktop\Assign4\Attempt2 - Shivram\default.xsvf" 
setMode -bs
setMode -bs
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
saveProjectFile -file "E:/Desktop/Assign4/Attempt2 - Shivram/impact_proj.ipf"
setMode -bs
setMode -bs
deleteDevice -position 1
setMode -bs
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
