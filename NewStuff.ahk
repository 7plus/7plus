#if WinActive("ahk_group ExplorerGroup")
+Enter::
if(FileExist(a_scriptdir "\temp.search-ms"))
	FileDelete %a_scriptdir%\temp.search-ms 
files:=GetSelectedFiles()
searchString=
(
<?xml version="1.0"?>
<persistedQuery version="1.0"><viewInfo viewMode="details" iconSize="16" stackIconSize="0" autoListFlags="0"><visibleColumns><column viewField="System.ItemNameDisplay"/><column viewField="System.ItemTypeText"/><column viewField="System.Size"/><column viewField="System.ItemFolderPathDisplayNarrow"/></visibleColumns><sortList><sort viewField="System.Search.Rank" direction="descending"/><sort viewField="System.ItemNameDisplay" direction="ascending"/></sortList></viewInfo><query><attributes/><kindList><kind name="item"/></kindList><scope>

)
Loop, Parse, files, `n,`r  ; Rows are delimited by linefeeds ('r`n). 
{ 
  if InStr(FileExist(A_LoopField), "D")
	{
		searchString=%searchString%<include path="%A_LoopField%"/>
	}
} 
searchString.="</scope></query></persistedQuery>"
Fileappend,%searchString%, %a_scriptdir%\temp.search-ms 
SetDirectory(a_scriptdir "\temp.search-ms")
return
