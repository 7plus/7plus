;: Title: sizeof function by HotKeyIt
;

; Function: sizeof
; Description:
;      sizeof() is based on AHK_L Objects and supports both, ANSI and UNICODE version, so to use it you will require <a href=http://www.autohotkey.com/forum/viewtopic.php?t=43049>Lexikos AutoHotkey_L.exe</a> or other versions based on it that supports objects.<br><br>nsizeof is used to calculate the size of structures or data types. <br>Visit <a href=http://www.autohotkey.com/forum/viewtopic.php?t=43049>sizeof at AutoHotkey</a> forum, any feedback is welcome.
; Syntax: size:= sizeof(Structure_Definition or Structure_Object)
; Parameters:
;	   Field types - All AutoHotkey and Windows Data Types are supported<br>AutoHotkey Data Types<br> Int, Uint, Int64, UInt64, Char, UChar, Short, UShort, Fload and Double.<br>Windows Data Types<br> - note, TCHAR UCHAR and CHAR return actual character rather than the value, use Asc() function to find out the value/code<br>Windows Data types: Asc(char)<br>ATOM,BOOL,BOOLEAN,BYTE,CHAR,COLORREF,DWORD,DWORDLONG,DWORD_PTR,<br>DWORD32,DWORD64,FLOAT,HACCEL,HALF_PTR,HANDLE,HBITMAP,HBRUSH,HCOLORSPACE,HCONV,HCONVLIST,HCURSOR,HDC,<br>HDDEDATA,HDESK,HDROP,HDWP,HENHMETAFILE,HFILE,HFONT,HGDIOBJ,HGLOBAL,HHOOK,HICON,HINSTANCE,HKEY,HKL,<br>HLOCAL,HMENU,HMETAFILE,HMODULE,HMONITOR,HPALETTE,HPEN,HRESULT,HRGN,HRSRC,HSZ,HWINSTA,HWND,INT,<br>INT_PTR,INT32,INT64,LANGID,LCID,LCTYPE,LGRPID,LONG,LONGLONG,LONG_PTR,LONG32,LONG64,LPARAM,LPBOOL,<br>LPBYTE,LPCOLORREF,LPCSTR,LPCTSTR,LPCVOID,LPCWSTR,LPDWORD,LPHANDLE,LPINT,LPLONG,LPSTR,LPTSTR,LPVOID,<br>LPWORD,LPWSTR,LRESULT,PBOOL,PBOOLEAN,PBYTE,PCHAR,PCSTR,PCTSTR,PCWSTR,PDWORD,PDWORDLONG,PDWORD_PTR,<br>PDWORD32,PDWORD64,PFLOAT,PHALF_PTR,PHANDLE,PHKEY,PINT,PINT_PTR,PINT32,PINT64,PLCID,PLONG,PLONGLONG,<br>PLONG_PTR,PLONG32,PLONG64,POINTER_32,POINTER_64,POINTER_SIGNED,POINTER_UNSIGNED,PSHORT,PSIZE_T,<br>PSSIZE_T,PSTR,PTBYTE,PTCHAR,PTSTR,PUCHAR,PUHALF_PTR,PUINT,PUINT_PTR,PUINT32,PUINT64,PULONG,PULONGLONG,<br>PULONG_PTR,PULONG32,PULONG64,PUSHORT,PVOID,PWCHAR,PWORD,PWSTR,SC_HANDLE,SC_LOCK,SERVICE_STATUS_HANDLE,<br>SHORT,SIZE_T,SSIZE_T,TBYTE,TCHAR,UCHAR,UHALF_PTR,UINT,UINT_PTR,UINT32,UINT64,ULONG,ULONGLONG,<br>ULONG_PTR,ULONG32,ULONG64,USHORT,USN,WCHAR,WORD,WPARAM
;	   <b>Parameters</b> - <b>Description</b>
;	   size - The size of structure or data type
;	   Structure_Definition - C/C++ syntax or usual definition (must not be multiline) e.g. "Int x,Int y", C/C++ definitions must be multiline.
; Return Value:
;     sizeof returns size of structures or data types
; Remarks:
;		None.
; Related:
; Example:
;		file:

sizeof(_TYPE_){
  ;Windows and AHK Data Types, used to find out the corresponding size
  static _types__:="
  (LTrim Join
    ,ATOM:2,LANGID:2,WCHAR:2,WORD:2,PTR:" A_PtrSize ",UPTR:" A_PtrSize ",SHORT:2,USHORT:2,INT:4,UINT:4,INT64:8,UINT64:8,DOUBLE:8,FLOAT:4,CHAR:1,UCHAR:1,__int64:8
    ,TBYTE:" (A_IsUnicode?2:1) ",TCHAR:" (A_IsUnicode?2:1) ",HALF_PTR:" (A_PtrSize=8?4:2) ",UHALF_PTR:" (A_PtrSize=8?4:2) ",INT32:4,LONG:4,LONG32:4,LONGLONG:8
    ,LONG64:8,USN:8,HFILE:4,HRESULT:4,INT_PTR:" A_PtrSize ",LONG_PTR:" A_PtrSize ",POINTER_64:" A_PtrSize ",POINTER_SIGNED:" A_PtrSize "
    ,BOOL:4,SSIZE_T:" A_PtrSize ",WPARAM:" A_PtrSize ",BOOLEAN:1,BYTE:1,COLORREF:4,DWORD:4,DWORD32:4,LCID:4,LCTYPE:4,LGRPID:4,LRESULT:4,PBOOL:" A_PtrSize "
    ,PBOOLEAN:" A_PtrSize ",PBYTE:" A_PtrSize ",PCHAR:" A_PtrSize ",PCSTR:" A_PtrSize ",PCTSTR:" A_PtrSize ",PCWSTR:" A_PtrSize ",PDWORD:" A_PtrSize "
    ,PDWORDLONG:" A_PtrSize ",PDWORD_PTR:" A_PtrSize ",PDWORD32:" A_PtrSize ",PDWORD64:" A_PtrSize ",PFLOAT:" A_PtrSize ",PHALF_PTR:" A_PtrSize "
    ,UINT32:4,ULONG:4,ULONG32:4,DWORDLONG:8,DWORD64:8,ULONGLONG:8,ULONG64:8,DWORD_PTR:" A_PtrSize ",HACCEL:" A_PtrSize ",HANDLE:" A_PtrSize "
     ,HBITMAP:" A_PtrSize ",HBRUSH:" A_PtrSize ",HCOLORSPACE:" A_PtrSize ",HCONV:" A_PtrSize ",HCONVLIST:" A_PtrSize ",HCURSOR:" A_PtrSize ",HDC:" A_PtrSize "
     ,HDDEDATA:" A_PtrSize ",HDESK:" A_PtrSize ",HDROP:" A_PtrSize ",HDWP:" A_PtrSize ",HENHMETAFILE:" A_PtrSize ",HFONT:" A_PtrSize "
   )"
  static _types_:=_types__ "
  (LTrim Join
     ,HGDIOBJ:" A_PtrSize ",HGLOBAL:" A_PtrSize ",HHOOK:" A_PtrSize ",HICON:" A_PtrSize ",HINSTANCE:" A_PtrSize ",HKEY:" A_PtrSize ",HKL:" A_PtrSize "
     ,HLOCAL:" A_PtrSize ",HMENU:" A_PtrSize ",HMETAFILE:" A_PtrSize ",HMODULE:" A_PtrSize ",HMONITOR:" A_PtrSize ",HPALETTE:" A_PtrSize ",HPEN:" A_PtrSize "
     ,HRGN:" A_PtrSize ",HRSRC:" A_PtrSize ",HSZ:" A_PtrSize ",HWINSTA:" A_PtrSize ",HWND:" A_PtrSize ",LPARAM:" A_PtrSize ",LPBOOL:" A_PtrSize ",LPBYTE:" A_PtrSize "
     ,LPCOLORREF:" A_PtrSize ",LPCSTR:" A_PtrSize ",LPCTSTR:" A_PtrSize ",LPCVOID:" A_PtrSize ",LPCWSTR:" A_PtrSize ",LPDWORD:" A_PtrSize ",LPHANDLE:" A_PtrSize "
     ,LPINT:" A_PtrSize ",LPLONG:" A_PtrSize ",LPSTR:" A_PtrSize ",LPTSTR:" A_PtrSize ",LPVOID:" A_PtrSize ",LPWORD:" A_PtrSize ",LPWSTR:" A_PtrSize "
     ,PHANDLE:" A_PtrSize ",PHKEY:" A_PtrSize ",PINT:" A_PtrSize ",PINT_PTR:" A_PtrSize ",PINT32:" A_PtrSize ",PINT64:" A_PtrSize ",PLCID:" A_PtrSize "
     ,PLONG:" A_PtrSize ",PLONGLONG:" A_PtrSize ",PLONG_PTR:" A_PtrSize ",PLONG32:" A_PtrSize ",PLONG64:" A_PtrSize ",POINTER_32:" A_PtrSize "
     ,POINTER_UNSIGNED:" A_PtrSize ",PSHORT:" A_PtrSize ",PSIZE_T:" A_PtrSize ",PSSIZE_T:" A_PtrSize ",PSTR:" A_PtrSize ",PTBYTE:" A_PtrSize "
     ,PTCHAR:" A_PtrSize ",PTSTR:" A_PtrSize ",PUCHAR:" A_PtrSize ",PUHALF_PTR:" A_PtrSize ",PUINT:" A_PtrSize ",PUINT_PTR:" A_PtrSize "
     ,PUINT32:" A_PtrSize ",PUINT64:" A_PtrSize ",PULONG:" A_PtrSize ",PULONGLONG:" A_PtrSize ",PULONG_PTR:" A_PtrSize ",PULONG32:" A_PtrSize "
     ,PULONG64:" A_PtrSize ",PUSHORT:" A_PtrSize ",PVOID:" A_PtrSize ",PWCHAR:" A_PtrSize ",PWORD:" A_PtrSize ",PWSTR:" A_PtrSize ",SC_HANDLE:" A_PtrSize "
     ,SC_LOCK:" A_PtrSize ",SERVICE_STATUS_HANDLE:" A_PtrSize ",SIZE_T:" A_PtrSize ",UINT_PTR:" A_PtrSize ",ULONG_PTR:" A_PtrSize ",VOID:" A_PtrSize "
     )"
  
  _offset_:=0           ; Init size/offset to 0
  
  If IsObject(_TYPE_){    ; If structure object - check for offset in structure and return pointer + last offset + its data size
    for _union_,_struct_ in _TYPE_
    {
      If (InStr(_union_,"`b")=1){
        If (_offset_<_total_union_size_:=_struct_ + (_TYPE_["`r" SubStr(_union_,2)]?A_PtrSize:sizeof(_TYPE_["`t" SubStr(_union_,2)])) )
          _offset_:=_total_union_size_
      } else if (IsObject(_struct_) && (_offset_<_total_union_size_:=_struct_[""]-_TYPE_[""]+sizeof(_struct_))){
        _offset_:=_total_union_size_
      }
    }
    If _TYPE_["`t"] ; type only, structure has no members and its a pointer
        _offset_:=_TYPE_["`r"]?A_PtrSize:sizeof(_TYPE_["`t"])
    Return _offset_  ;(_TYPE_["`t"]?4:0) ; if offset 0 and memory set,must be a pointer
  }
  
  If (RegExMatch(_TYPE_,"^[\w\d.]+$") && !this.base.HasKey(_TYPE_)) ; structures name was supplied, resolve to global var and run again
      If InStr(_types_,"," _TYPE_ ":")
        Return SubStr(_types_,InStr(_types_,"," _TYPE_ ":") + 2 + StrLen(_TYPE_),1)
      else If InStr(_TYPE_,"."){ ;check for object that holds structure definition
        Loop,Parse,_TYPE_,.
          If A_Index=1
            _defobj_:=%A_LoopField%
          else _defobj_:=_defobj_[A_LoopField]
        Return sizeof(_defobj_)
      } else Return sizeof(%_TYPE_%)
      
  If InStr(_TYPE_,"`n") {   ; C/C++ style definition, convert
    _offset_:=""            ; This will hold new structure
    _struct_:=[]            ; This will keep track if union is structure
    _union_:=0              ; This will keep track of union depth
    Loop,Parse,_TYPE_,`n,`r`t%A_Space%%A_Tab%
    {
      _LF_:=""
      Loop,parse,A_LoopField,`,`;,`t%A_Space%%A_Tab%
      {
        If RegExMatch(A_LoopField,"^\s*//") ;break on comments and continue main loop
            break
        If (A_LoopField){
            If (!_LF_ && _ArrType_:=RegExMatch(A_LoopField,"\w\s+\w"))
              _LF_:=RegExReplace(A_LoopField,"\w\K\s+.*$")
            If Instr(A_LoopField,"{"){
              _union_++,_struct_.Insert(_union_,RegExMatch(A_LoopField,"i)^\s*struct\s*\{"))
            } else If InStr(A_LoopField,"}")
              _offset_.="}"
            else {
              If _union_
                  Loop % _union_
                    _ArrName_.=(_struct_[A_Index]?"struct":"") "{"
              _offset_.=(_offset_ ? "," : "") _ArrName_ ((_ArrType_ && A_Index!=1)?(_LF_ " "):"") RegExReplace(A_LoopField,"\s+"," ")
              _ArrName_:="",_union_:=0
            }
        }
      }
    }
    _TYPE_:=_offset_
    _offset_:=0           ; Init size/offset to 0
  }
  
  ; Following keep track of union size/offset
  _union_:=[]               ; keep track of union level, required to reset offset after union is parsed
  _struct_:=[]              ; for each union level keep track if it is a structure (because here offset needs to increase
  _union_size_:=[]        ; keep track of highest member within the union or structure, used to calculate new offset after union
  _total_union_size_:=0   ; used in combination with above, each loop the total offset is updated if current data size is higher
  
  ; Parse given structure definition and calculate size
  ; Structures will be resolved by recrusive calls (a structure must be global)
  Loop,Parse,_TYPE_,`,`;,%A_Space%%A_Tab%`n`r
  {
    _LF_ := A_LoopField
    ; Check for STARTING union and set union helpers
    While (RegExMatch(_LF_,"i)(struct|union)?\s*\{\K"))
        _union_.Insert(_offset_)
        ,_union_size_.Insert(0)
        ,_struct_.Insert(RegExMatch(_LF_,"i)struct\s*\{")?1:0)
        ,_LF_:=SubStr(_LF_,RegExMatch(_LF_,"i)(struct|union)?\s*\{\K"))
      
    _LF_BKP_:=_LF_ ;to check for ending brackets = union,struct
    StringReplace,_LF_,_LF_,},,A
    
    
    If InStr(_LF_,"*") ; It's a pointer, size will be always A_PtrSize
      _offset_ += A_PtrSize
    else {
      ; Split array type and optionally the size of array, e.g. "TCHAR chr[5]"
      RegExMatch(_LF_,"^\s*(?<ArrType_>[\w\d.]+)?\s*(?<ArrName_>\w+)?\s*\[?(?<ArrSize_>\d+)?\]?\s*$",_)
      If (!_ArrName_ && !_ArrSize_ && !InStr( _types_  ,"," _ArrType_ ":"))
        _ArrName_:=_ArrType_,_ArrType_:="UInt"
      
      If InStr(this["`t" _key_],"."){ ;check for object that holds structure definition
        _ArrType_:=this["`t" _key_]
        Loop,Parse,_ArrType_,.
          If A_Index=1
            _defobj_:=%A_LoopField%
          else _defobj_:=_defobj_[A_LoopField]
      }
      If (_idx_:=InStr( _types_  ,"," _ArrType_ ":")){ ; AHK or Windows data type
        ; find out the size in _types_ and add to total size
        _offset_ += SubStr( _types_  , _idx_+StrLen(_ArrType_)+2 , 1 ) * (_ArrSize_?_ArrSize_:1)
      } else ; resolve structure
        _offset_ += sizeof(_defobj_?_defobj_:%_ArrType_%) * (_ArrSize_?_ArrSize_:1) ; %Array1% will resolve to global variable
    }
    If _union_.MaxIndex()
          _union_size_[_union_.MaxIndex()]:=(_offset_ - _union_[_union_.MaxIndex()]>_union_size_[_union_.MaxIndex()])
                                            ?(_offset_ - _union_[_union_.MaxIndex()]):_union_size_[_union_.MaxIndex()]
    If (_union_.MaxIndex() && !_struct_[_struct_.MaxIndex()])
      _offset_:=_union_[_union_.MaxIndex()]
      
    ; Check for ENDING union and reset offset and union helpers
    While (SubStr(_LF_BKP_,0)="}"){
      If !_union_.MaxIndex(){
        MsgBox Incorrect structure, missing opening braket {`nProgram will exit now `n%_TYPE_%
        ExitApp
      }
      _offset_:=_union_[_union_.MaxIndex()] ; reset offset because we left a union or structure
      ; Increase total size of union/structure if necessary
      _total_union_size_ := _union_size_[_union_.MaxIndex()]>_total_union_size_?_union_size_[_union_.MaxIndex()]:_total_union_size_
      ,_union_.Remove() ; remove latest items
      ,_struct_.Remove()
      ,_union_size_.Remove()
      ,_LF_BKP_:=SubStr(_LF_BKP_,1,StrLen(_LF_BKP_)-1)
      If !_union_.MaxIndex(){ ; leaving top union, add offset
        _offset_+=_total_union_size_
        _total_union_size_:=0
      }
    }
  }
  Return _offset_
}