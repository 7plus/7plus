;: Title: FTP Functions [AHK_L]

/* 
Original FTP Functions by Olfen & Andreone -> http://www.autohotkey.com/forum/viewtopic.php?t=10393
Modified by ahklerner

Modified by me for AHK_L, 
- added object syntax 
- added GetCurrentDirectory() 
- corrected FileTime retrieval from Win32_Find_Data structure 
- created documentation (thanks fincs for GenDocs and Scite4Autohotkey) 

Update 2011-01-17: 
- Added FTP_Init(), which needs to be called first to retrieve Object reference 
- Error/Extended Error (if any) is retrieved in human readable form [.LastError property] 
- FTP connection properties can be set (see documentation) 
- Uses only one global variable (an object) 

Update 2011-01-21: 
- Added .InternetReadFile() and .InternetWriteFile() methods 
- Progress indicator for uploads and downloads 

Update 2011-02-03:
- Bugfixes
- FTP_Init() now has two optional parameters - Proxy and ProxyBypass
- oFTP.CloseSocket() function added
*/

;
; Function: FTP_Init
; Description:
;      Initializes and returns the FTP object (MUST be called before any other functions)
; Syntax: FTP_Init([Proxy, ProxyBypass])
; Parameters:
;      Proxy - (Optional) Connect via proxy (TIS FTP gateway, Socks only if IE installed)
;      ProxyBypass - (Optional) Bypass addresses from proxy (localhost bypassed by default)
; Return Value:
;      Returns object with Methods and Properties as described below
; Remarks:
;      Options can be set (see Properties) before calling oFTP.Open() method
; Related: oFTP.Open , oFTP.Close
; Example:
;      file:Example.ahk
;
FTP_Init( Proxy = "" , ProxyBypass = "" ) {
  global ftp_$obj$
  if !ftp_$obj$
    ftp_$obj$ := Object()
  
  AccessType := (Proxy = "") ? 1 : 3  ;0-registry conf, 1-direct, 3-named proxy, 4- prevent using java/script
  ftp_$obj$.hModule := DllCall("LoadLibrary", "str", "wininet.dll", "Ptr")
  ftp_$obj$.o_hInternet := DllCall("wininet\InternetOpen"
  , "str" , A_ScriptName ;lpszAgent
  , "UInt", AccessType
  , "str" , Proxy , "str", ProxyBypass
  , "UInt", 0, "Ptr") ;dwFlags

  If (ErrorLevel != 0 or ftp_$obj$.o_hInternet = 0)
    Return 0 , FTP_Close()
  
  ftp_$obj$.InternetConnectFlags := 0
  ftp_$obj$.Port := 21
  ftp_$obj$.Open := "FTP_Open"
  ftp_$obj$.GetCurrentDirectory := "FTP_GetCurrentDirectory"
  ftp_$obj$.CreateDirectory := "FTP_CreateDirectory"
  ftp_$obj$.RemoveDirectory := "FTP_RemoveDirectory"
  ftp_$obj$.SetCurrentDirectory := "FTP_SetCurrentDirectory"
  ftp_$obj$.PutFile := "FTP_PutFile"
  ftp_$obj$.GetFile := "FTP_GetFile"
  ftp_$obj$.GetFileSize := "FTP_GetFileSize"
  ftp_$obj$.DeleteFile := "FTP_DeleteFile"
  ftp_$obj$.RenameFile := "FTP_RenameFile"
  ftp_$obj$.CloseSocket := "FTP_CloseSocket"
  ftp_$obj$.Close := "FTP_Close"
  ftp_$obj$.GetFileInfoObj := "FTP_GetFileInfo"
  ftp_$obj$.FindFirstFile := "FTP_FindFirstFile"
  ftp_$obj$.FindNextFile := "FTP_FindNextFile"
  ftp_$obj$.InternetWriteFile := "FTP_InternetWriteFile"
  ftp_$obj$.InternetReadFile := "FTP_InternetReadFile"
  ftp_$obj$["File","BufferSize"] := 1024
  return ftp_$obj$
}

;
; Function: oFTP.Open
; Description:
;      Opens an FTP connection and returns the FTP object on success, 0 on failure
; Syntax: FTP_Open(Server, [Username, Password])
; Parameters:
;      Server - FTP server
;      Username - (Optional) Username
;      Password - (Optional) Password
; Return Value:
;      True on success, false otherwise.
; Remarks:
;      Port, InternetConnectFlags can be set beforehand [see Properties in FTP_Init()]
; Related: FTP_Init , oFTP.CloseSocket , oFTP.Close
; Example:
;      oFTP.Open("ftp.autohotkey.net", "myUserName", "myPassword")
;
FTP_Open(Server, Username=0, Password=0) {
  global ftp_$obj$

  IfEqual, Username, 0, SetEnv, Username, anonymous
  IfEqual, Password, 0, SetEnv, Password, anonymous

  ftp_$obj$.hInternet := DllCall("wininet\InternetConnect" , "PTR", ftp_$obj$.o_hInternet , "str", Server , "uint", ftp_$obj$.Port
  , "str", Username , "str", Password
  , "uint" , 1 ;dwService (INTERNET_SERVICE_FTP = 1)
  , "uint", ftp_$obj$.InternetConnectFlags ;dwFlags
  , "uint", 0, "Ptr") ;dwContext
  
  If (ErrorLevel or !ftp_$obj$.hInternet)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return 1 , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.GetCurrentDirectory
; Description:
;      Gets the current directory path on FTP server
; Syntax: oFTP.GetCurrentDirectory()
; Remarks:
;      None
; Return Value:
;      Current directory path, 0 on error
; Related: oFTP.SetCurrentDirectory
; Example:
;      sCurrentDir := oFTP.GetCurrentDirectory()
;
FTP_GetCurrentDirectory() {
  global ftp_$obj$
  nSize := A_IsUnicode ? (2*260) : 260 ;Maxpath
  VarSetCapacity(ic_currdir, nSize)
  nSize := 260 ;lpdwCurrentDirectory is in TCHARs
  If !DllCall("wininet\FtpGetCurrentDirectory", "PTR", ftp_$obj$.hInternet, "PTR", &ic_currdir, "UIntP", &nSize)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return StrGet(&ic_currdir,nSize) , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.SetCurrentDirectory
; Description:
;      Sets the current directory path on FTP server
; Syntax: oFTP.SetCurrentDirectory(DirName)
; Parameters:
;      DirName - Existing directory name on FTP server
; Remarks:
;      None
; Return Value:
;      True on success
; Related: oFTP.GetCurrentDirectory
; Example:
;      oFTP.SetCurrentDirectory("testing")
;
FTP_SetCurrentDirectory(DirName) {
  global ftp_$obj$
  
  r := DllCall("wininet\FtpSetCurrentDirectory", "PTR", ftp_$obj$.hInternet, "str", DirName)
  If (ErrorLevel or !r)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return 1 , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.CreateDirectory
; Description:
;      Creates a new directory on FTP server
; Syntax: oFTP.CreateDirectory(DirName)
; Parameters:
;      DirName - New directory name on FTP server
; Remarks:
;      None
; Return Value:
;      True on success
; Related: oFTP.RemoveDirectory
; Example:
;      oFTP.CreateDirectory("testing")
;
FTP_CreateDirectory(DirName) {
  global ftp_$obj$

  r := DllCall("wininet\FtpCreateDirectory", "PTR", ftp_$obj$.hInternet, "str", DirName)
  If (ErrorLevel or !r)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return 1 , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.RemoveDirectory
; Description:
;      Deletes a directory on FTP server
; Syntax: oFTP.RemoveDirectory(DirName)
; Parameters:
;      DirName - Existing directory name on FTP server
; Remarks:
;      None
; Return Value:
;      True on success
; Related: oFTP.CreateDirectory
; Example:
;      oFTP.RemoveDirectory("testing")
;
FTP_RemoveDirectory(DirName) {
  global ftp_$obj$

  r := DllCall("wininet\FtpRemoveDirectory", "PTR", ftp_$obj$.hInternet, "str", DirName)
  If (ErrorLevel or !r)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return 1 , ftp_$obj$.LastError := 0
}


FTP_OpenFile(FileName,Write = 0) {
  global ftp_$obj$
  
  access := Write ? 0x40000000 : 0x80000000
  r := DllCall( "wininet\FtpOpenFile", "PTR", ftp_$obj$.hInternet ,"str" , FileName
   ,"UInt" , access ;dwAccess
   ,"UInt" , 0 ;dwFlags
   ,"UInt" , 0) ;dwContext   
  If (ErrorLevel or !r)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return r , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.InternetWriteFile
; Description:
;      Uploads a file (with progress bar)
; Syntax: oFTP.InternetWriteFile(LocalFile, [NewRemoteFile, FnProgress])
; Parameters:
;      LocalFile - Path of local file to upload
;      NewRemoteFile - (Optional) Remote file name/path (if omitted, defaults to name of Local file)
;      FnProgress - (Optional) Name of function to handle progress data (similar to registercallback). If not specified, built in function to show progress is used. (see example)
; Return Value:
;      True on success, false otherwise.
; Remarks:
;      Use .LastError property to get error data
; Related: oFTP.InternetReadFile
; Example:
;      oFTP.InternetWriteFile("TestFile.zip", "RTestFile.zip", "MyProgressFunction")
;      MyProgressFunction() {
;        global oFTP
;        my := oFTP.File
;        static init
;        done := my.BytesTransfered
;        total := my.BytesTotal
;        if ( my.TransferComplete )
;          {
;          Progress, Off
;          init := 0
;          return 1
;          }
;        str_sub := "Time Elapsed - " . Round((my.CurrentTime - my.StartTime)/1000) . " seconds"
;        if !init
;          {
;          str_main := my.LocalName . A_Tab . "->" . A_Tab . my.RemoteName
;          Progress,B R0-%total% P%done%,%str_sub%, %str_main% ,FTP Transfer Progress
;          init :=1
;          return 1
;          }
;        Progress, %done%
;        Progress,,%str_sub%
;       }
;
FTP_InternetWriteFile(LocalFile, NewRemoteFile="", FnProgress = "FTP_Progress") {
  global ftp_$obj$
  my := ftp_$obj$.File
  my.BytesTransfered := my.TransferComplete := 0

  SplitPath,LocalFile,tvar
  my.RemoteName := (NewRemoteFile="") ? tvar : NewRemoteFile
  my.LocalName := tvar
  
  hFile := FTP_OpenFile(my.RemoteName,1) ;Write
  if !hFile
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)

  oFile := FileOpen(LocalFile,"r")
  if !oFile
    Return 0 , DllCall("wininet\InternetCloseHandle",  "PTR", hFile) , ftp_$obj$.LastError := "File not found!"

  my.BytesTotal := oFile.Length , blocks := Floor(oFile.Length/my.BufferSize) , my.StartTime := A_TickCount
  VarSetCapacity(Buffer,my.BufferSize)
  Loop, %blocks%
  {
  oFile.RawRead(Buffer,my.BufferSize)
  if ( DllCall("wininet\InternetWriteFile", "PTR", hFile  , "PTR", &Buffer  , "UInt",  my.BufferSize , "UIntP", outSize) )
    my.BytesTransfered := my.BytesTransfered + my.BufferSize , my.CurrentTime := A_TickCount , %FnProgress%()
  else
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError) , DllCall("wininet\InternetCloseHandle",  "PTR", hFile)
  }
  if (lastBufferSize := my.BytesTotal - my.BytesTransfered)
    {
    oFile.RawRead(Buffer,lastBufferSize)
    DllCall("wininet\InternetWriteFile", "PTR", hFile  , "PTR", &Buffer  , "UInt",  lastBufferSize , "UIntP", outSize)
    }
  DllCall("wininet\InternetCloseHandle",  "PTR", hFile)
  oFile.Close()
  my.TransferComplete := 1
  %FnProgress%()
  Return 1 , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.InternetReadFile
; Description:
;      Downloads a file (with progress bar)
; Syntax: oFTP.InternetReadFile(RemoteFile, [NewLocalFile, FnProgress])
; Parameters:
;      RemoteFile - Path of remote file to download
;      NewLocalFile - (Optional) Local file name/path (if omitted, defaults to name of remote file, saved to script directory)
;      FnProgress - (Optional) Name of function to handle progress data (similar to registercallback). If not specified, built in function to show progress is used. (see example)
; Return Value:
;      True on success, false otherwise.
; Remarks:
;      Use .LastError property to get error data
; Related: oFTP.InternetWriteFile
; Example:
;      oFTP.InternetReadFile("RTestFile.zip", "LTestFile.zip", "MyProgressFunction")
;      MyProgressFunction() {
;        global oFTP
;        my := oFTP.File
;        static init
;        done := my.BytesTransfered
;        total := my.BytesTotal
;        if ( my.TransferComplete )
;          {
;          Progress, Off
;          init := 0
;          return 1
;          }
;        str_sub := "Time Elapsed - " . Round((my.CurrentTime - my.StartTime)/1000) . " seconds"
;        if !init
;          {
;          str_main := my.LocalName . A_Tab . "->" . A_Tab . my.RemoteName
;          Progress,B R0-%total% P%done%,%str_sub%, %str_main% ,FTP Transfer Progress
;          init :=1
;          return 1
;          }
;        Progress, %done%
;        Progress,,%str_sub%
;       }
;
FTP_InternetReadFile(RemoteFile, NewLocalFile = "", FnProgress = "FTP_Progress") {
  global ftp_$obj$

  my := ftp_$obj$.File
  my.BytesTransfered := my.TransferComplete := 0
  SplitPath,RemoteFile,tvar
  my.LocalName := (NewLocalFile="") ? tvar : NewLocalFile
  my.RemoteName := tvar
  
  hFile := FTP_OpenFile(RemoteFile) ;Read
  if !hFile
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)

  oFile := FileOpen(NewLocalFile,"w")
  if !oFile
    Return 0 , DllCall("wininet\InternetCloseHandle",  "PTR", hFile) , ftp_$obj$.LastError := "File could not be created!"

  my.BytesTotal := DllCall("wininet\FtpGetFileSize", "PTR", hFile, "uint", 0)
  blocks := Floor(my.BytesTotal/my.BufferSize) , my.StartTime := A_TickCount
  VarSetCapacity(Buffer,my.BufferSize)

  Loop, %blocks%
  {
  if ( DllCall("wininet\InternetReadFile", "PTR", hFile , "PTR", &Buffer , "UInt", my.BufferSize , "UIntP", outSize) )
    {
    oFile.RawWrite(Buffer,my.BufferSize)
    my.BytesTransfered := my.BytesTransfered + my.BufferSize , my.CurrentTime := A_TickCount , 
    %FnProgress%()
    }
  else
    Return 0 , DllCall("wininet\InternetCloseHandle",  "PTR", hFile) , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  }
  if (lastBufferSize := my.BytesTotal - my.BytesTransfered)
    {
    DllCall("wininet\InternetReadFile", "PTR", hFile , "PTR", &Buffer , "UInt",  lastBufferSize , "UIntP", outSize)
    ; VarSetCapacity(Buffer,-1)
    oFile.RawWrite(Buffer,lastBufferSize)
    }
  DllCall("wininet\InternetCloseHandle",  "PTR", hFile)
  oFile.Close()
  my.TransferComplete := 1
  %FnProgress%()
  Return 1 , ftp_$obj$.LastError := 0
}


FTP_Progress() {
  global ftp_$obj$
  my := ftp_$obj$.File
  static init
  done := my.BytesTransfered , total := my.BytesTotal
  if ( my.TransferComplete )
    {
    Progress, Off
    return 1 , init := 0
    }
  str_sub := "Time Elapsed - " . Round((my.CurrentTime - my.StartTime)/1000) . " seconds"
  if !init
    {
    str_main := my.LocalName . A_Tab . "->" . A_Tab . my.RemoteName
    Progress,B R0-%total% P%done%,%str_sub%, %str_main% ,FTP Transfer Progress
    return 1, init :=1
    }
  Progress, %done%
  Progress,,%str_sub%
}

;
; Function: oFTP.PutFile
; Description:
;      Puts a file to FTP location
; Syntax: oFTP.PutFile(LocalFile, [NewRemoteFile, Flags])
; Parameters:
;      LocalFile - Existing file name 
;      NewRemoteFile - Remote path to the file to be created (fully qualified path or relative path to current dir)
;      Flags - See remarks
; Remarks:
;      Flags:
;      FTP_TRANSFER_TYPE_UNKNOWN = 0 (Defaults to FTP_TRANSFER_TYPE_BINARY)
;      FTP_TRANSFER_TYPE_ASCII = 1
;      FTP_TRANSFER_TYPE_BINARY = 2
; Return Value:
;      True on success
; Related: oFTP.GetFile
; Example:
;      oFTP.PutFile("LocalFile.ahk", "MyTestScript.ahk", 0)
;
FTP_PutFile(LocalFile, NewRemoteFile="", Flags=0) {
  If NewRemoteFile=
    SplitPath,LocalFile,NewRemoteFile
  global ftp_$obj$

  r := DllCall("wininet\FtpPutFile" , "PTR", ftp_$obj$.hInternet , "str", LocalFile , "str", NewRemoteFile , "uint", Flags , "PTR", 0) ;dwContext
  If (ErrorLevel or !r)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return 1 , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.GetFile
; Description:
;      Retrieves a file
; Syntax: oFTP.GetFile(RemoteFile, [NewFile, Flags])
; Parameters:
;      RemoteFile - Existing file name (fully qualified path or relative path to current dir)
;      NewFile - Local path to the file to be created
;      Flags - See remarks
; Remarks:
;      Flags:
;      FTP_TRANSFER_TYPE_UNKNOWN = 0 (Defaults to FTP_TRANSFER_TYPE_BINARY)
;      FTP_TRANSFER_TYPE_ASCII = 1
;      FTP_TRANSFER_TYPE_BINARY = 2
; Return Value:
;      True on success
; Related: oFTP.PutFile
; Example:
;      oFTP.GetFile("MyTestScript.ahk", "LocalFile.ahk", 0)
;
FTP_GetFile(RemoteFile, NewFile="", Flags=0) {
  If NewFile=
    NewFile := RemoteFile
  global ftp_$obj$

  r := DllCall("wininet\FtpGetFile" , "PTR", ftp_$obj$.hInternet , "str", RemoteFile , "str", NewFile
  , "int", 1 ;do not overwrite existing files
  , "uint", 0 ;dwFlagsAndAttributes
  , "uint", Flags
  , "PTR", 0) ;dwContext
  If (ErrorLevel or !r)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return 1 , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.GetFileSize
; Description:
;      Renames a file
; Syntax: oFTP.GetFileSize(FileName [, Flags])
; Parameters:
;      FileName - Existing file name (fully qualified path or relative path to current dir)
;      Flags - See remarks
; Remarks:
;      Flags:
;      FTP_TRANSFER_TYPE_UNKNOWN = 0 (Defaults to FTP_TRANSFER_TYPE_BINARY)
;      FTP_TRANSFER_TYPE_ASCII = 1
;      FTP_TRANSFER_TYPE_BINARY = 2
; Return Value:
;      Size of file in bytes (-1 on error)
; Related: oFTP.FindFirstFile , oFTP.FindNextFile
; Example:
;      oFTP.GetFileSize("MyTestScript.ahk", 0)
;
FTP_GetFileSize(FileName, Flags=0) {
  global ftp_$obj$

  fof_hInternet := DllCall("wininet\FtpOpenFile", "PTR", ftp_$obj$.hInternet, "str", FileName
  , "uint", 0x80000000 ;dwAccess: GENERIC_READ
  , "uint", Flags
  , "PTR", 0) ;dwContext
  If (ErrorLevel or !fof_hInternet)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  FileSize := DllCall("wininet\FtpGetFileSize", "PTR", fof_hInternet, "PTR", 0)
  DllCall("wininet\InternetCloseHandle",  "PTR", fof_hInternet)
  Return FileSize , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.DeleteFile
; Description:
;      Deletes a remote file
; Syntax: oFTP.Deletefile(FileName)
; Parameters:
;      FileName - Existing file name (fully qualified path or relative path to current dir)
; Remarks:
;      none
; Return Value:
;      True on success, false otherwise
; Related: oFTP.RenameFile
; Example:
;      oFTP.DeleteFile("MyTestScript.ahk")
;
FTP_DeleteFile(FileName) {
  global ftp_$obj$

  r :=  DllCall("wininet\FtpDeleteFile", "PTR", ftp_$obj$.hInternet, "str", FileName)
  If (ErrorLevel or !r)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return 1 , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.RenameFile
; Description:
;      Renames a file
; Syntax: oFTP.RenameFile(Existing, New)
; Parameters:
;      Existing - Existing file name, fully qualified path or relative path to current dir
;      New - New file name
; Return Value:
;      True on success, false otherwise
; Remarks:
;      none
; Related: oFTP.DeleteFile
; Example:
;      oFTP.RenameFile("MyScript.ahk", "MyTestScript.ahk")
;
FTP_RenameFile(Existing, New) {
  global ftp_$obj$

  r := DllCall("wininet\FtpRenameFile", "PTR", ftp_$obj$.hInternet, "str", Existing, "str", New)
  If (ErrorLevel or !r)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return 1 , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.CloseSocket
; Description:
;      Closes session created by oFTP.Open
; Syntax: oFTP.CloseSocket()
; Return Value:
;      True on success, false otherwise
; Remarks:
;      The wininet module and wininet Internet open handles are not released.
; Related: oFTP.Open , oFTP.Close
; Example:
;      oFTP.CloseSocket() ;you can now create a new session with oFTP.Open
;
FTP_CloseSocket() {
  global ftp_$obj$

  DllCall("wininet\InternetCloseHandle",  "PTR", ftp_$obj$.hInternet)
  If (ErrorLevel or !r)
    Return 0 , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return 1 , ftp_$obj$.LastError := 0
}

;
; Function: oFTP.Close
; Description:
;      Close FTP session, wininet internet handle, unload library, free resources
; Syntax: oFTP.Close()
; Remarks:
;      Required only when FTP is no longer required (See oFTP.CloseSocket aslo)
; Related: FTP_Init , oFTP.CloseSocket
; Example:
;      oFTP.close()
;
FTP_Close() {
  global ftp_$obj$
  DllCall("wininet\InternetCloseHandle",  "PTR", ftp_$obj$.hInternet)
  DllCall("wininet\InternetCloseHandle",  "PTR", ftp_$obj$.o_hInternet)
  DllCall("FreeLibrary", "PTR", ftp_$obj$.hModule)
  ftp_$obj$ := ""
}

;
; Function: oFTP.GetFileInfo
; Description:
;      Get File info from WIN32_FIND_DATA structure
; Syntax: oFTP.GetFileInfo(DataStruct)
; Parameters:
;      DataStruct - Data structure retrieved by .FindFirstFile() / .FindNextFile() functions
; Return Value:
;      Returns an object with file details (properties described below)
;      oFile.Name - Name of File
;      oFile.CreationTime - Creation Time (0 if absent)
;      oFile.LastAccessTime - Last Access Time (0 if absent)
;      oFile.LastWriteTime - Last Write Time (0 if absent)
;      oFile.Size - File Size in bytes
;      oFile.Attribs - String of file attributes
; Related: oFTP.FindFirstFile , oFTP.FindNextFile
;
FTP_GetFileInfo(ByRef @FindData) { ;http://www.autohotkey.com/forum/viewtopic.php?p=408830#408830
if !IsObject(fiObj)
	fiObj := Object()

VarSetCapacity(value, 1040, 0) 
DllCall("RtlMoveMemory", "str", value, "uint", &@FindData + 44, "uint", 1040) 
VarSetCapacity(value, -1) 
fiObj.Name := value

VarSetCapacity(ftstr, 8) 
DllCall("RtlMoveMemory", "str", ftstr, "uint", &@FindData + 4, "uint", 8)
fiObj.CreationTime := FileTimeToStr(ftstr)
DllCall("RtlMoveMemory", "str", ftstr, "uint", &@FindData + 12, "uint", 8)
fiObj.LastAccessTime := FileTimeToStr(ftstr)
DllCall("RtlMoveMemory", "str", ftstr, "uint", &@FindData + 20, "uint", 8)
fiObj.LastWriteTime := FileTimeToStr(ftstr) 
fiObj.Size := NumGet(@FindData, 28, "UInt") << 32 | NumGet(@FindData, 32, "UInt")

value=
value .= (NumGet(@FindData, 0, "UInt") & 1) != 0 ? "R" : ""
value .= (NumGet(@FindData, 0, "UInt") & 2) != 0 ? "H" : ""
value .= (NumGet(@FindData, 0, "UInt") & 4) != 0 ? "S" : ""
value .= (NumGet(@FindData, 0, "UInt") & 16) != 0 ? "D" : ""
value .= (NumGet(@FindData, 0, "UInt") & 32) != 0 ? "A" : ""
value .= (NumGet(@FindData, 0, "UInt") & 128) != 0 ? "N" : ""
value .= (NumGet(@FindData, 0, "UInt") & 256) != 0 ? "T" : ""
value .= (NumGet(@FindData, 0, "UInt") & 2048) != 0 ? "O" : ""
value .= (NumGet(@FindData, 0, "UInt") & 4096) != 0 ? "E" : ""
value .= (NumGet(@FindData, 0, "UInt") & 16384) != 0 ? "C" : ""
value .= (NumGet(@FindData, 0, "UInt") & 65536) != 0 ? "V" : ""
fiObj.Attribs := value

Return fiObj
} 

FileTimeToStr(FileTime) { 
   VarSetCapacity(SystemTime, 16, 0) 
   If (!NumGet(FileTime,"UInt") && !NumGet(FileTime,4,"UInt"))
     Return 0
   DllCall("FileTimeToSystemTime", "PTR", &FileTime, "PTR", &SystemTime) 
   Return NumGet(SystemTime,6,"short") ;date
      . "/" . NumGet(SystemTime,2,"short") ;month
      . "/" . NumGet(SystemTime,0,"short") ;year
      . " " . NumGet(SystemTime,8,"short") ;hours
      . ":" . ((StrLen(tvar := NumGet(SystemTime,10,"short")) = 1) ? "0" . tvar : tvar) ;minutes
      . ":" . ((StrLen(tvar := NumGet(SystemTime,12,"short")) = 1) ? "0" . tvar : tvar) ;seconds
;      . "." . NumGet(SystemTime,14,"short") ;milliseconds
}

;
; Function: oFTP.FindFirstFile
; Description:
;      Get first file
; Syntax: oFTP.FindFirstFile(SearchFile)
; Parameters:
;      SearchFile - file(mask) to search for 
; Return Value:
;      Returns an object (oFile) with file details (properties described below)
;      oFile.Name - Name of File
;      oFile.CreationTime - Creation Time (0 if absent)
;      oFile.LastAccessTime - Last Access Time (0 if absent)
;      oFile.LastWriteTime - Last Write Time (0 if absent)
;      oFile.Size - File Size in bytes
;      oFile.Attribs - String of file attributes
; Related: oFTP.GetFileInfo, oFTP.FindNextFile
;
FTP_FindFirstFile(SearchFile) { 
   ; WIN32_FIND_DATA structure size is 4 + 3*8 + 4*4 + 260*4 + 14*4 = 1140 
  global ftp_$obj$
  ftp_$obj$.LastError := 0

  VarSetCapacity(@FindData, 1140, 0) 
  ftp_$obj$.hEnum := DllCall("wininet\FtpFindFirstFile" 
    , "PTR", ftp_$obj$.hInternet
    , "str", SearchFile 
    , "PTR", &@FindData 
    , "uint", 0 
    , "PTR", 0, "PTR") 

  If(!ftp_$obj$.hEnum) 
    Return 0 , VarSetCapacity(@FindData, 0) , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return oFile := FTP_GetFileInfo(@FindData)
} 

;
; Function: oFTP.FindNextFile
; Description:
;      Get next file
; Syntax: oFTP.FindNextFile()
; Return Value:
;      Returns an object (oFile) with file details (properties described below)
;      oFile.Name - Name of File
;      oFile.CreationTime - Creation Time (0 if absent)
;      oFile.LastAccessTime - Last Access Time (0 if absent)
;      oFile.LastWriteTime - Last Write Time (0 if absent)
;      oFile.Size - File Size in bytes
;      oFile.Attribs - String of file attributes
; Related: oFTP.GetFileInfo, oFTP.FindFirstFile
;
FTP_FindNextFile() { 
  global ftp_$obj$
  ftp_$obj$.LastError := 0
  VarSetCapacity(@FindData, 1140, 0) 
  If !DllCall("wininet\InternetFindNextFile" , "PTR", ftp_$obj$.hEnum , "PTR", &@FindData) 
    Return 0 , VarSetCapacity(@FindData, 0) , ftp_$obj$.LastError := GetModuleErrorText(ftp_$obj$.hModule,A_LastError)
  Return oFile := FTP_GetFileInfo(@FindData)
} 

;
; Property: oFile
; Description:
;      Properties of object (oFile) returned by .FindFirstFile()/.FindNextFile() 
; Parameters:
;      oFile.Name - Name of File
;      oFile.CreationTime - Creation Time (0 if absent)
;      oFile.LastAccessTime - Last Access Time (0 if absent)
;      oFile.LastWriteTime - Last Write Time (0 if absent)
;      oFile.Size - File Size in bytes
;      oFile.Attribs - String of file attributes
;
GetModuleErrorText(hModule,errNr) ;http://msdn.microsoft.com/en-us/library/ms679351(v=vs.85).aspx
{
	bufferSize = 1024 ; Arbitrary, should be large enough for most uses
	VarSetCapacity(buffer, bufferSize)
    if (errNr = 12003)  ;ERROR_INTERNET_EXTENDED_ERROR
	{
		VarSetCapacity(ErrorMsg,4)
		DllCall("wininet\InternetGetLastResponseInfo", "UIntP", &ErrorMsg, "PTR", &buffer, "UIntP", &bufferSize)
		Msg := StrGet(&buffer,bufferSize)
		Return "Error : " errNr . "`n" . Msg
	}
	DllCall("FormatMessage"
	 , "UInt", FORMAT_MESSAGE_FROM_HMODULE := 0x00000800
	 , "PTR", hModule , "UInt", errNr
	 , "UInt", 0 ;0 - looks in following order -> langNuetral->thread->user->system->USEnglish
	 , "Str", buffer , "UInt", bufferSize
	 , "PTR", 0)
	Return "Error : " . errNr . " - " . buffer
}
