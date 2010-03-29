/* 
http://msdn.microsoft.com/library/en-us/wininet/wininet/ftp_sessions.asp 
http://msdn.microsoft.com/library/en-us/wininet/wininet/internetopen.asp 
http://msdn.microsoft.com/library/en-us/wininet/wininet/internetconnect.asp 
*/ 

FtpCreateDirectory(DirName) { 
global ic_hInternet 
r := DllCall("wininet\FtpCreateDirectoryA", "uint", ic_hInternet, "str", DirName) 
If (ErrorLevel != 0 or r = 0) 
return 0 
else 
return 1 
} 

FtpRemoveDirectory(DirName) { 
global ic_hInternet 
r := DllCall("wininet\FtpRemoveDirectoryA", "uint", ic_hInternet, "str", DirName) 
If (ErrorLevel != 0 or r = 0) 
return 0 
else 
return 1
} 

FtpSetCurrentDirectory(DirName) { 
global ic_hInternet 
r := DllCall("wininet\FtpSetCurrentDirectoryA", "uint", ic_hInternet, "str", DirName) 
If (ErrorLevel != 0 or r = 0) 
return 0 
else 
return 1 
} 

FtpPutFile(LocalFile, NewRemoteFile="", Flags=0) { 
;Flags: 
;FTP_TRANSFER_TYPE_UNKNOWN = 0 (Defaults to FTP_TRANSFER_TYPE_BINARY) 
;FTP_TRANSFER_TYPE_ASCII = 1 
;FTP_TRANSFER_TYPE_BINARY = 2 
If NewRemoteFile= 
NewRemoteFile := LocalFile 
global ic_hInternet 
r := DllCall("wininet\FtpPutFileA" 
, "uint", ic_hInternet 
, "str", LocalFile 
, "str", NewRemoteFile 
, "uint", Flags 
, "uint", 0) ;dwContext 
If (ErrorLevel != 0 or r = 0) 
return 0 
else 
return 1 
} 

FtpGetFile(RemoteFile, NewFile="", Flags=0) { 
;Flags: 
;FTP_TRANSFER_TYPE_UNKNOWN = 0 (Defaults to FTP_TRANSFER_TYPE_BINARY) 
;FTP_TRANSFER_TYPE_ASCII = 1 
;FTP_TRANSFER_TYPE_BINARY = 2 
If NewFile= 
NewFile := RemoteFile 
global ic_hInternet 
r := DllCall("wininet\FtpGetFileA" 
, "uint", ic_hInternet 
, "str", RemoteFile 
, "str", NewFile 
, "int", 1 ;do not overwrite existing files 
, "uint", 0 ;dwFlagsAndAttributes 
, "uint", Flags 
, "uint", 0) ;dwContext 
If (ErrorLevel != 0 or r = 0) 
return 0 
else 
return 1 
} 

FtpGetFileSize(FileName, Flags=0) { 
;Flags: 
;FTP_TRANSFER_TYPE_UNKNOWN = 0 (Defaults to FTP_TRANSFER_TYPE_BINARY) 
;FTP_TRANSFER_TYPE_ASCII = 1 
;FTP_TRANSFER_TYPE_BINARY = 2 
global ic_hInternet 
fof_hInternet := DllCall("wininet\FtpOpenFileA" 
, "uint", ic_hInternet 
, "str", FileName 
, "uint", 0x80000000 ;dwAccess: GENERIC_READ 
, "uint", Flags 
, "uint", 0) ;dwContext 
If (ErrorLevel != 0 or fof_hInternet = 0) 
return -1 

FileSize := DllCall("wininet\FtpGetFileSize", "uint", fof_hInternet, "uint", 0) 
DllCall("wininet\InternetCloseHandle",  "UInt", fof_hInternet) 
return, FileSize 
} 


FtpDeleteFile(FileName) { 
global ic_hInternet 
r :=  DllCall("wininet\FtpDeleteFileA", "uint", ic_hInternet, "str", FileName) 
If (ErrorLevel != 0 or r = 0) 
return 0 
else 
return 1 
} 

FtpRenameFile(Existing, New) { 
global ic_hInternet 
r := DllCall("wininet\FtpRenameFileA", "uint", ic_hInternet, "str", Existing, "str", New) 
If (ErrorLevel != 0 or r = 0) 
return 0 
else 
return 1 
} 

FtpOpen(Server, Port=21, Username=0, Password=0 ,Proxy="", ProxyBypass="") { 
IfEqual, Username, 0, SetEnv, Username, anonymous 
IfEqual, Password, 0, SetEnv, Password, anonymous 

If (Proxy != "") 
AccessType=3 
Else 
AccessType=1 
;#define INTERNET_OPEN_TYPE_PRECONFIG                    0   // use registry configuration 
;#define INTERNET_OPEN_TYPE_DIRECT                       1   // direct to net 
;#define INTERNET_OPEN_TYPE_PROXY                        3   // via named proxy 
;#define INTERNET_OPEN_TYPE_PRECONFIG_WITH_NO_AUTOPROXY  4   // prevent using java/script/INS 

global ic_hInternet, io_hInternet, hModule 
hModule := DllCall("LoadLibrary", "str", "wininet.dll") 

io_hInternet := DllCall("wininet\InternetOpenA" 
, "str", A_ScriptName ;lpszAgent 
, "UInt", AccessType 
, "str", Proxy 
, "str", ProxyBypass 
, "UInt", 0) ;dwFlags 

If (ErrorLevel != 0 or io_hInternet = 0) { 
FtpClose() 
return 0
} 

ic_hInternet := DllCall("wininet\InternetConnectA" 
, "uint", io_hInternet 
, "str", Server 
, "uint", Port 
, "str", Username 
, "str", Password 
, "uint" , 1 ;dwService (INTERNET_SERVICE_FTP = 1) 
, "uint", 0 ;dwFlags 
, "uint", 0) ;dwContext 

If (ErrorLevel != 0 or ic_hInternet = 0) 
return 0 
else 
return 1 
} 

FtpClose() { 
global ic_hInternet, io_hInternet, hModule 
DllCall("wininet\InternetCloseHandle",  "UInt", ic_hInternet) 
DllCall("wininet\InternetCloseHandle",  "UInt", io_hInternet) 
DllCall("FreeLibrary", "UInt", hModule) 
}
