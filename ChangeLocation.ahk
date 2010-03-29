#NoEnv
#include %A_ScriptDir%\Lib\com.ahk 
#include %A_ScriptDir%\navigate.ahk
#include %A_ScriptDir%\MiscFunctions.ahk
GroupAdd, ExplorerGroup, ahk_class ExploreWClass
GroupAdd, ExplorerGroup, ahk_class CabinetWClass
sPath=%1%
SetDirectory(sPath)
