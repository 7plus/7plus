/*
fileO:
FO_MOVE   := 0x1 
FO_COPY   := 0x2 
FO_DELETE := 0x3 
FO_RENAME := 0x4

flags:
Const FOF_SILENT = 4
Const FOF_RENAMEONCOLLISION = 8
Const FOF_NOCONFIRMATION = 16
Const FOF_NOERRORUI = 1024
http://msdn.microsoft.com/en-us/library/bb759795(VS.85).aspx for more
*/
ShellFileOperation( fileO=0x0, fSource="", fTarget="", flags=0x0, ghwnd=0x0 )     
{
   ;dout_f(A_ThisFunc)
   FO_MOVE   := 0x1
   FO_COPY   := 0x2
   FO_DELETE := 0x3
   FO_RENAME := 0x4
   
   FOF_MULTIDESTFILES :=           0x1            ; Indicates that the to member specifies multiple destination files (one for each source file) rather than one directory where all source files are to be deposited.
   FOF_SILENT :=                0x4            ; Does not display a progress dialog box.
   FOF_RENAMEONCOLLISION :=       0x8            ; Gives the file being operated on a new name (such as "Copy #1 of...") in a move, copy, or rename operation if a file of the target name already exists.
   FOF_NOCONFIRMATION :=          0x10         ; Responds with "yes to all" for any dialog box that is displayed.
   FOF_ALLOWUNDO :=             0x40         ; Preserves undo information, if possible. With del, uses recycle bin.
   FOF_FILESONLY :=             0x80         ; Performs the operation only on files if a wildcard filename (*.*) is specified.
   FOF_SIMPLEPROGRESS :=          0x100         ; Displays a progress dialog box, but does not show the filenames.
   FOF_NOCONFIRMMKDIR :=          0x200         ; Does not confirm the creation of a new directory if the operation requires one to be created.
   FOF_NOERRORUI :=             0x400         ; don't put up error UI
   FOF_NOCOPYSECURITYATTRIBS :=    0x800         ; dont copy file security attributes
   FOF_NORECURSION :=             0x1000         ; Only operate in the specified directory. Don't operate recursively into subdirectories.
   FOF_NO_CONNECTED_ELEMENTS :=    0x2000         ; Do not move connected files as a group (e.g. html file together with images). Only move the specified files.
   FOF_WANTNUKEWARNING :=          0x4000         ; Send a warning if a file is being destroyed during a delete operation rather than recycled. This flag partially overrides FOF_NOCONFIRMATION.

   
   ; no more annoying numbers to deal with (but they should still work, if you really want them to)
   fileO := %fileO% ? %fileO% : fileO
   
   ; the double ternary was too fun to pass up
   _flags := 0
   Loop Parse, flags, |
      _flags |= %A_LoopField%   
   flags := _flags ? _flags : (%flags% ? %flags% : flags)
   
   If ( SubStr(fSource,0) != "|" )
      fSource := fSource . "|"

   If ( SubStr(fTarget,0) != "|" )
      fTarget := fTarget . "|"
   
   char_size := A_IsUnicode ? 2 : 1
   char_type := A_IsUnicode ? "UShort" : "Char"
   
   fsPtr := &fSource
   Loop % StrLen(fSource)
      if NumGet(fSource, (A_Index-1)*char_size, char_type) = 124
         NumPut(0, fSource, (A_Index-1)*char_size, char_type)

   ftPtr := &fTarget
   Loop % StrLen(fTarget)
      if NumGet(fTarget, (A_Index-1)*char_size, char_type) = 124
         NumPut(0, fTarget, (A_Index-1)*char_size, char_type)
   
   VarSetCapacity( SHFILEOPSTRUCT, 60, 0 )                 ; Encoding SHFILEOPSTRUCT
   NextOffset := NumPut( ghwnd, &SHFILEOPSTRUCT )          ; hWnd of calling GUI
   NextOffset := NumPut( fileO, NextOffset+0    )          ; File operation
   NextOffset := NumPut( fsPtr, NextOffset+0    )          ; Source file / pattern
   NextOffset := NumPut( ftPtr, NextOffset+0    )          ; Target file / folder
   NextOffset := NumPut( flags, NextOffset+0, 0, "Short" ) ; options

   code := DllCall( "Shell32\SHFileOperation" . (A_IsUnicode ? "W" : "A"), UInt,&SHFILEOPSTRUCT )
   ErrorLevel := ShellFileOperation_InterpretReturn(code)

   Return NumGet( NextOffset+0 )
}

ShellFileOperation_InterpretReturn(c)
{
   static dict
   if !dict
   {
      dict := Object()
      dict[0x0]      :=    ""
      dict[0x71]      :=   "DE_SAMEFILE - The source and destination files are the same file."
      dict[0x72]      :=   "DE_MANYSRC1DEST - Multiple file paths were specified in the source buffer, but only one destination file path."
      dict[0x73]      :=   "DE_DIFFDIR - Rename operation was specified but the destination path is a different directory. Use the move operation instead."
      dict[0x74]      :=   "DE_ROOTDIR - The source is a root directory, which cannot be moved or renamed."
      dict[0x75]      :=   "DE_OPCANCELLED - The operation was cancelled by the user, or silently cancelled if the appropriate flags were supplied to SHFileOperation."
      dict[0x76]      :=   "DE_DESTSUBTREE - The destination is a subtree of the source."
      dict[0x78]      :=   "DE_ACCESSDENIEDSRC - Security settings denied access to the source."
      dict[0x79]      :=   "DE_PATHTOODEEP - The source or destination path exceeded or would exceed MAX_PATH."
      dict[0x7A]      :=   "DE_MANYDEST - The operation involved multiple destination paths, which can fail in the case of a move operation."
      dict[0x7C]      :=   "DE_INVALIDFILES   - The path in the source or destination or both was invalid."
      dict[0x7D]      :=   "DE_DESTSAMETREE   - The source and destination have the same parent folder."
      dict[0x7E]      :=   "DE_FLDDESTISFILE - The destination path is an existing file."
      dict[0x80]      :=   "DE_FILEDESTISFLD - The destination path is an existing folder."
      dict[0x81]      :=   "DE_FILENAMETOOLONG - The name of the file exceeds MAX_PATH."
      dict[0x82]      :=   "DE_DEST_IS_CDROM - The destination is a read-only CD-ROM, possibly unformatted."
      dict[0x83]      :=   "DE_DEST_IS_DVD - The destination is a read-only DVD, possibly unformatted."
      dict[0x84]      :=   "DE_DEST_IS_CDRECORD - The destination is a writable CD-ROM, possibly unformatted."
      dict[0x85]      :=   "DE_FILE_TOO_LARGE - The file involved in the operation is too large for the destination media or file system."
      dict[0x86]      :=   "DE_SRC_IS_CDROM - The source is a read-only CD-ROM, possibly unformatted."
      dict[0x87]      :=   "DE_SRC_IS_DVD - The source is a read-only DVD, possibly unformatted."
      dict[0x88]      :=   "DE_SRC_IS_CDRECORD - The source is a writable CD-ROM, possibly unformatted."
      dict[0xB7]      :=   "DE_ERROR_MAX - MAX_PATH was exceeded during the operation."
      dict[0x402]      :=    "An unknown error occurred. This is typically due to an invalid path in the source or destination. This error does not occur on Windows Vista and later."
      dict[0x10000]   :=   "RRORONDEST   - An unspecified error occurred on the destination."
      dict[0x10074]   :=   "E_ROOTDIR | ERRORONDEST   - Destination is a root directory and cannot be renamed."
   }
   
   return dict[c] ? dict[c] : "Error code not recognized"
}

IsDialog(window=0,ListViewSelected = False)
{
	result:=0
	if(window)
		window:="ahk_id " window
	else
		window:="A"
	if(WinGetClass(window)="#32770")
	{
		;Check for new FileOpen dialog
		ControlGet, hwnd, Hwnd , , DirectUIHWND3, %window%
		if(hwnd)
		{
			ControlGet, hwnd, Hwnd , , SysTreeView321, %window%
			if(hwnd)
			{
				ControlGet, hwnd, Hwnd , , Edit1, %window%
				if(hwnd)
				{
					ControlGet, hwnd, Hwnd , , Button2, %window%
					if(hwnd)
					{
						ControlGet, hwnd, Hwnd , , ComboBox2, %window%
						if(hwnd)
						{
						ControlGet, hwnd, Hwnd , , ToolBarWindow323, %window%
						if(hwnd)
							result:=(!ListViewSelected||IsControlActive("DirectUIHWND2")||IsControlActive("SysTreeView321"))
						}
					}
				}
			}
		}
		;Check for old FileOpen dialog
		if(!result)
		{ 
			ControlGet, hwnd, Hwnd , , ToolbarWindow321, %window%
			if(hwnd)
			{
				ControlGet, hwnd, Hwnd , , SysListView321, %window%
				if(hwnd)
				{
					ControlGet, hwnd, Hwnd , , ComboBox3, %window%
					if(hwnd)
					{
						ControlGet, hwnd, Hwnd , , Button3, %window%
						if(hwnd)
						{
							ControlGet, hwnd, Hwnd , , SysHeader321 , %window%
							if(hwnd)
								result:=(!ListViewSelected||IsControlActive("DirectUIHWND2")||IsControlActive("SysTreeView321")) ? 2 : 0
						}
					}
				}
			}
		}
	}
	return result
}