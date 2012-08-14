;: Title: Class _Struct + sizeof() by HotKeyIt
;

; Function: _Struct
; Description:
;      _Struct is based on AHK_L Objects and supports both, ANSI and UNICODE version, so to use it you will require <a href=http://www.autohotkey.com/forum/viewtopic.php?t=43049>Lexikos AutoHotkey_L.exe</a> or other versions based on it that supports objects.<br><br>new _Struct is used to create new structure. You can create predefined structures that are saved as global variables or pass you own structure definition.<br>_Struct supportes structure in structure as well as Arrays of structures and Vectors.<br>Visit <a href=http://www.autohotkey.com/forum/viewtopic.php?t=43049>_Struct at AutoHotkey</a> forum, any feedback is welcome.
; Syntax: MyStruct:= new _Struct(Structure_Definition,Address,initialization)
; Parameters:
;	   General Design - Class _Struct will create Object(s) that will manage fields of structure(s), for example RC := new _Struct("RECT") creates a RECT structure with fields left,top,right,bottom. To pass structure its pointer to a function or DllCall or SendMessage you will need to use RC[""] or RC[].<br><br>To access fields you can use usual Object syntax: RC.left, RC.right ...<br>To set a field of the structure use RC.top := 100.
;	   Field types - All AutoHotkey and Windows Data Types are supported<br>AutoHotkey Data Types<br> Int, Uint, Int64, UInt64, Char, UChar, Short, UShort, Fload and Double.<br>Windows Data Types<br> - note, TCHAR UCHAR and CHAR return actual character rather than the value, use Asc() function to find out the value/code<br>Windows Data types: Asc(char)<br>ATOM,BOOL,BOOLEAN,BYTE,CHAR,COLORREF,DWORD,DWORDLONG,DWORD_PTR,<br>DWORD32,DWORD64,FLOAT,HACCEL,HALF_PTR,HANDLE,HBITMAP,HBRUSH,HCOLORSPACE,HCONV,HCONVLIST,HCURSOR,HDC,<br>HDDEDATA,HDESK,HDROP,HDWP,HENHMETAFILE,HFILE,HFONT,HGDIOBJ,HGLOBAL,HHOOK,HICON,HINSTANCE,HKEY,HKL,<br>HLOCAL,HMENU,HMETAFILE,HMODULE,HMONITOR,HPALETTE,HPEN,HRESULT,HRGN,HRSRC,HSZ,HWINSTA,HWND,INT,<br>INT_PTR,INT32,INT64,LANGID,LCID,LCTYPE,LGRPID,LONG,LONGLONG,LONG_PTR,LONG32,LONG64,LPARAM,LPBOOL,<br>LPBYTE,LPCOLORREF,LPCSTR,LPCTSTR,LPCVOID,LPCWSTR,LPDWORD,LPHANDLE,LPINT,LPLONG,LPSTR,LPTSTR,LPVOID,<br>LPWORD,LPWSTR,LRESULT,PBOOL,PBOOLEAN,PBYTE,PCHAR,PCSTR,PCTSTR,PCWSTR,PDWORD,PDWORDLONG,PDWORD_PTR,<br>PDWORD32,PDWORD64,PFLOAT,PHALF_PTR,PHANDLE,PHKEY,PINT,PINT_PTR,PINT32,PINT64,PLCID,PLONG,PLONGLONG,<br>PLONG_PTR,PLONG32,PLONG64,POINTER_32,POINTER_64,POINTER_SIGNED,POINTER_UNSIGNED,PSHORT,PSIZE_T,<br>PSSIZE_T,PSTR,PTBYTE,PTCHAR,PTSTR,PUCHAR,PUHALF_PTR,PUINT,PUINT_PTR,PUINT32,PUINT64,PULONG,PULONGLONG,<br>PULONG_PTR,PULONG32,PULONG64,PUSHORT,PVOID,PWCHAR,PWORD,PWSTR,SC_HANDLE,SC_LOCK,SERVICE_STATUS_HANDLE,<br>SHORT,SIZE_T,SSIZE_T,TBYTE,TCHAR,UCHAR,UHALF_PTR,UINT,UINT_PTR,UINT32,UINT64,ULONG,ULONGLONG,<br>ULONG_PTR,ULONG32,ULONG64,USHORT,USN,WCHAR,WORD,WPARAM
;	   <b>Structure Definition</b> - <b>Description</b>
;	   User defined - To create a user defined structure you will need to pass a string of predefined types and field names.<br>Default type is UInt, so for example for a RECT structure type can be omited: <b>"left,top,right,left"</b>, which is the same as <b>"Uint left,Uint top,Uint right,Uint bottom"</b><br><br>You can also use structures very similar to C#/C++ syntax, see example.
;	   Global - Global variables can be used to save structures, easily pass name of that variable as first parameter, e.g. new _Struct("MyStruct") where MyStruct must be a global variable with structure definition. Also new _Struct(MyStruct) can be used if variable is accessible.
;	   Array - To create an array of structures include a digit in the end of your string enclosed in squared brackets.<br>For example "RECT[2]" would create an array of 2 structures.<br>This feature can also be used for user defined arrays, for example "Int age,TCHAR name[10]".
;	   Union - Using {} you can create union, for example: <br>AHKVar:="{Int64 ContentsInt64,Double ContentsDouble,object},...
;	   Struct - Using struct{} you can create structures in union.
;	   Pointer - To create a pointer you can use *, for example: CHR:="char *str" will hold a pointer to a character. Same way you can have a structure in structure so you can call for example Label.NextLabel.NextLabel.JumpToLine
;	   <b>Parameters</b> - <b>Description</b>
;	   MyStruct - This will become a class object representing the strucuture
;	   Structure_Definition - C/C++ syntax or usual definition (must not be multiline) e.g. "Int x,Int y", C/C++ definitions must be multiline.
;	   pointer - Pass a pointer as second parameter to occupy existing strucure.
;	   Initialization - Pass an object to initialize structure, e.g. {left:100,top:20}. If pointer is not used initialization can be specified in second parameter.
; Return Value:
;     Return value is a class object representing your structure
; Remarks:
;		<b>NOTE!!! accessing a field that does not exist will crash your application, these errors are not catched for performance reasons.</b>
; Related:
; Example:
;		file:Struct_Example.ahk
;
#Include <sizeof>
Class _Struct {
	; Data Sizes
  static PTR:=A_PtrSize,UPTR:=A_PtrSize,SHORT:=2,USHORT:=2,INT:=4,UINT:=4,__int64:=8,INT64:=8,UINT64:=8,DOUBLE:=8,FLOAT:=4,CHAR:=1,UCHAR:=1,VOID:=A_PtrSize
    ,TBYTE:=A_IsUnicode?2:1,TCHAR:=A_IsUnicode?2:1,HALF_PTR:=A_PtrSize=8?4:2,UHALF_PTR:=A_PtrSize=8?4:2,INT32:=4,LONG:=4,LONG32:=4,LONGLONG:=8
    ,LONG64:=8,USN:=8,HFILE:=4,HRESULT:=4,INT_PTR:=A_PtrSize,LONG_PTR:=A_PtrSize,POINTER_64:=A_PtrSize,POINTER_SIGNED:=A_PtrSize
    ,BOOL:=4,SSIZE_T:=A_PtrSize,WPARAM:=A_PtrSize,BOOLEAN:=1,BYTE:=1,COLORREF:=4,DWORD:=4,DWORD32:=4,LCID:=4,LCTYPE:=4,LGRPID:=4,LRESULT:=4,PBOOL:=4
    ,PBOOLEAN:=A_PtrSize,PBYTE:=A_PtrSize,PCHAR:=A_PtrSize,PCSTR:=A_PtrSize,PCTSTR:=A_PtrSize,PCWSTR:=A_PtrSize,PDWORD:=A_PtrSize,PDWORDLONG:=A_PtrSize
    ,PDWORD_PTR:=A_PtrSize,PDWORD32:=A_PtrSize,PDWORD64:=A_PtrSize,PFLOAT:=A_PtrSize,PHALF_PTR:=A_PtrSize
    ,UINT32:=4,ULONG:=4,ULONG32:=4,DWORDLONG:=8,DWORD64:=8,ULONGLONG:=8,ULONG64:=8,DWORD_PTR:=A_PtrSize,HACCEL:=A_PtrSize,HANDLE:=A_PtrSize
    ,HBITMAP:=A_PtrSize,HBRUSH:=A_PtrSize,HCOLORSPACE:=A_PtrSize,HCONV:=A_PtrSize,HCONVLIST:=A_PtrSize,HCURSOR:=A_PtrSize,HDC:=A_PtrSize
    ,HDDEDATA:=A_PtrSize,HDESK:=A_PtrSize,HDROP:=A_PtrSize,HDWP:=A_PtrSize,HENHMETAFILE:=A_PtrSize,HFONT:=A_PtrSize
  static HGDIOBJ:=A_PtrSize,HGLOBAL:=A_PtrSize,HHOOK:=A_PtrSize,HICON:=A_PtrSize,HINSTANCE:=A_PtrSize,HKEY:=A_PtrSize,HKL:=A_PtrSize
    ,HLOCAL:=A_PtrSize,HMENU:=A_PtrSize,HMETAFILE:=A_PtrSize,HMODULE:=A_PtrSize,HMONITOR:=A_PtrSize,HPALETTE:=A_PtrSize,HPEN:=A_PtrSize
    ,HRGN:=A_PtrSize,HRSRC:=A_PtrSize,HSZ:=A_PtrSize,HWINSTA:=A_PtrSize,HWND:=A_PtrSize,LPARAM:=A_PtrSize,LPBOOL:=A_PtrSize,LPBYTE:=A_PtrSize
    ,LPCOLORREF:=A_PtrSize,LPCSTR:=A_PtrSize,LPCTSTR:=A_PtrSize,LPCVOID:=A_PtrSize,LPCWSTR:=A_PtrSize,LPDWORD:=A_PtrSize,LPHANDLE:=A_PtrSize
    ,LPINT:=A_PtrSize,LPLONG:=A_PtrSize,LPSTR:=A_PtrSize,LPTSTR:=A_PtrSize,LPVOID:=A_PtrSize,LPWORD:=A_PtrSize,LPWSTR:=A_PtrSize,PHANDLE:=A_PtrSize
    ,PHKEY:=A_PtrSize,PINT:=A_PtrSize,PINT_PTR:=A_PtrSize,PINT32:=A_PtrSize,PINT64:=A_PtrSize,PLCID:=A_PtrSize,PLONG:=A_PtrSize,PLONGLONG:=A_PtrSize
    ,PLONG_PTR:=A_PtrSize,PLONG32:=A_PtrSize,PLONG64:=A_PtrSize,POINTER_32:=A_PtrSize,POINTER_UNSIGNED:=A_PtrSize,PSHORT:=A_PtrSize,PSIZE_T:=A_PtrSize
    ,PSSIZE_T:=A_PtrSize,PSTR:=A_PtrSize,PTBYTE:=A_PtrSize,PTCHAR:=A_PtrSize,PTSTR:=A_PtrSize,PUCHAR:=A_PtrSize,PUHALF_PTR:=A_PtrSize,PUINT:=A_PtrSize
    ,PUINT_PTR:=A_PtrSize,PUINT32:=A_PtrSize,PUINT64:=A_PtrSize,PULONG:=A_PtrSize,PULONGLONG:=A_PtrSize,PULONG_PTR:=A_PtrSize,PULONG32:=A_PtrSize
    ,PULONG64:=A_PtrSize,PUSHORT:=A_PtrSize,PVOID:=A_PtrSize,PWCHAR:=A_PtrSize,PWORD:=A_PtrSize,PWSTR:=A_PtrSize,SC_HANDLE:=A_PtrSize
    ,SC_LOCK:=A_PtrSize,SERVICE_STATUS_HANDLE:=A_PtrSize,SIZE_T:=A_PtrSize,UINT_PTR:=A_PtrSize,ULONG_PTR:=A_PtrSize,ATOM:=2,LANGID:=2,WCHAR:=2,WORD:=2
	; Data Types
  static _PTR:="PTR",_UPTR:="UPTR",_SHORT:="Short",_USHORT:="UShort",_INT:="Int",_UINT:="UInt"
    ,_INT64:="Int64",_UINT64:="UInt64",_DOUBLE:="Double",_FLOAT:="Float",_CHAR:="Char",_UCHAR:="UChar"
    ,_VOID:="PTR",_TBYTE:=A_IsUnicode?"USHORT":"UCHAR",_TCHAR:=A_IsUnicode?"USHORT":"UCHAR",_HALF_PTR:=A_PtrSize=8?"INT":"SHORT"
    ,_UHALF_PTR:=A_PtrSize=8?"UINT":"USHORT",_BOOL:="Int",_INT32:="Int",_LONG:="Int",_LONG32:="Int",_LONGLONG:="Int64",_LONG64:="Int64"
    ,_USN:="Int64",_HFILE:="UInt",_HRESULT:="UInt",_INT_PTR:="PTR",_LONG_PTR:="PTR",_POINTER_64:="PTR",_POINTER_SIGNED:="PTR",_SSIZE_T:="PTR"
    ,_WPARAM:="PTR",_BOOLEAN:="UCHAR",_BYTE:="UCHAR",_COLORREF:="UInt",_DWORD:="UInt",_DWORD32:="UInt",_LCID:="UInt",_LCTYPE:="UInt"
    ,_LGRPID:="UInt",_LRESULT:="UInt",_PBOOL:="UPTR",_PBOOLEAN:="UPTR",_PBYTE:="UPTR",_PCHAR:="UPTR",_PCSTR:="UPTR",_PCTSTR:="UPTR"
    ,_PCWSTR:="UPTR",_PDWORD:="UPTR",_PDWORDLONG:="UPTR",_PDWORD_PTR:="UPTR",_PDWORD32:="UPTR",_PDWORD64:="UPTR",_PFLOAT:="UPTR",___int64:="Int64"
    ,_PHALF_PTR:="UPTR",_UINT32:="UInt",_ULONG:="UInt",_ULONG32:="UInt",_DWORDLONG:="UInt64",_DWORD64:="UInt64",_ULONGLONG:="UInt64"
    ,_ULONG64:="UInt64",_DWORD_PTR:="UPTR",_HACCEL:="UPTR",_HANDLE:="UPTR",_HBITMAP:="UPTR",_HBRUSH:="UPTR",_HCOLORSPACE:="UPTR"
    ,_HCONV:="UPTR",_HCONVLIST:="UPTR",_HCURSOR:="UPTR",_HDC:="UPTR",_HDDEDATA:="UPTR",_HDESK:="UPTR",_HDROP:="UPTR",_HDWP:="UPTR"
  static _HENHMETAFILE:="UPTR",_HFONT:="UPTR",_HGDIOBJ:="UPTR",_HGLOBAL:="UPTR",_HHOOK:="UPTR",_HICON:="UPTR",_HINSTANCE:="UPTR",_HKEY:="UPTR"
    ,_HKL:="UPTR",_HLOCAL:="UPTR",_HMENU:="UPTR",_HMETAFILE:="UPTR",_HMODULE:="UPTR",_HMONITOR:="UPTR",_HPALETTE:="UPTR",_HPEN:="UPTR"
    ,_HRGN:="UPTR",_HRSRC:="UPTR",_HSZ:="UPTR",_HWINSTA:="UPTR",_HWND:="UPTR",_LPARAM:="UPTR",_LPBOOL:="UPTR",_LPBYTE:="UPTR",_LPCOLORREF:="UPTR"
    ,_LPCSTR:="UPTR",_LPCTSTR:="UPTR",_LPCVOID:="UPTR",_LPCWSTR:="UPTR",_LPDWORD:="UPTR",_LPHANDLE:="UPTR",_LPINT:="UPTR",_LPLONG:="UPTR"
    ,_LPSTR:="UPTR",_LPTSTR:="UPTR",_LPVOID:="UPTR",_LPWORD:="UPTR",_LPWSTR:="UPTR",_PHANDLE:="UPTR",_PHKEY:="UPTR",_PINT:="UPTR"
    ,_PINT_PTR:="UPTR",_PINT32:="UPTR",_PINT64:="UPTR",_PLCID:="UPTR",_PLONG:="UPTR",_PLONGLONG:="UPTR",_PLONG_PTR:="UPTR",_PLONG32:="UPTR"
    ,_PLONG64:="UPTR",_POINTER_32:="UPTR",_POINTER_UNSIGNED:="UPTR",_PSHORT:="UPTR",_PSIZE_T:="UPTR",_PSSIZE_T:="UPTR",_PSTR:="UPTR"
    ,_PTBYTE:="UPTR",_PTCHAR:="UPTR",_PTSTR:="UPTR",_PUCHAR:="UPTR",_PUHALF_PTR:="UPTR",_PUINT:="UPTR",_PUINT_PTR:="UPTR",_PUINT32:="UPTR"
    ,_PUINT64:="UPTR",_PULONG:="UPTR",_PULONGLONG:="UPTR",_PULONG_PTR:="UPTR",_PULONG32:="UPTR",_PULONG64:="UPTR",_PUSHORT:="UPTR"
    ,_PVOID:="UPTR",_PWCHAR:="UPTR",_PWORD:="UPTR",_PWSTR:="UPTR",_SC_HANDLE:="UPTR",_SC_LOCK:="UPTR",_SERVICE_STATUS_HANDLE:="UPTR"
    ,_SIZE_T:="UPTR",_UINT_PTR:="UPTR",_ULONG_PTR:="UPTR",_ATOM:="Ushort",_LANGID:="Ushort",_WCHAR:="Ushort",_WORD:="UShort"
    
  ; Struct Contstructor
  ; Memory, offset and definitions are saved in following character + given key/name
  ;   `a = Allocated Memory
  ;   `b = Byte Offset (related to struct address)
  ;   `f = Format (encoding for string data types)
  ;   `n = New data type (AHK data type)
  ;   `r = Is Pointer (requred for __GET and __SET)
  ;   `t = Type (data type, also when it is name of a Structure it is used to resolve structure pointers dynamically
  ;   `v = Memory used to save string
  
  __NEW(_TYPE_,_pointer_=0,_init_=0){
    global _Struct
    static _base_:={__GET:_Struct.___GET,__SET:_Struct.___SET,__SETPTR:_Struct.___SETPTR,__Clone:_Struct.___Clone,__NEW:_Struct.___NEW}

    If (RegExMatch(_TYPE_,"^[\w\d\.]+$") && !this.base.HasKey(_TYPE_)) ; structures name was supplied, resolve to global var and run again
      If InStr(_TYPE_,"."){ ;check for object that holds structure definition
        Loop,Parse,_TYPE_,.
          If A_Index=1
            _defobj_:=%A_LoopField%
          else _defobj_:=_defobj_[A_LoopField]
        _TYPE_:=_defobj_
      } else _TYPE_:=%_TYPE_%
    
    ; If a pointer is supplied, save it in key [""] else reserve and zero-fill memory + set pointer in key [""]
    If (_pointer_ && !IsObject(_pointer_))
      this[""] := _pointer_,this["`a"]:=0
    else
      this._SetCapacity("`a",_StructSize_:=sizeof(_TYPE_)) ; Set Capacity in key ["`a"]
      ,this[""]:=this._GetAddress("`a") ; Save pointer in key [""]
      ,DllCall("RtlFillMemory","UPTR",this[""],"UInt",_StructSize_,"UChar",0) ; zero-fill memory
    
    ; C/C++ style structure definition, convert it
    If InStr(_TYPE_,"`n") {
      _struct_:=[] ; keep track of structures (union is just removed because {} = union, struct{} = struct
      _union_:=0   ; init to 0, used to keep track of union depth
      Loop,Parse,_TYPE_,`n,`r`t%A_Space%%A_Tab% ; Parse each line
      {
        _LF_:=""
        Loop,parse,A_LoopField,`,`;,`t%A_Space%%A_Tab% ; Parse each item
        {
          If RegExMatch(A_LoopField,"^\s*//") ;break on comments and continue main loop
              break
          If (A_LoopField){ ; skip empty lines
              If (!_LF_ && _ArrType_:=RegExMatch(A_LoopField,"\w\s+\w")) ; new line, find out data type and save key in _LF_ Data type will be added later
                _LF_:=RegExReplace(A_LoopField,"\w\K\s+.*$")
              If Instr(A_LoopField,"{"){ ; Union, also check if it is a structure
                _union_++,_struct_.Insert(_union_,RegExMatch(A_LoopField,"i)^\s*struct\s*\{"))
              } else If InStr(A_LoopField,"}") ; end of union/struct
                _offset_.="}"
              else { ; not starting or ending struct or union so add definitions and apply Data Type.
                If _union_ ; add { or struct{
                    Loop % _union_
                      _ArrName_.=(_struct_[A_Index]?"struct":"") "{"
                _offset_.=(_offset_ ? "," : "") _ArrName_ ((_ArrType_ && A_Index!=1)?(_LF_ " "):"") RegExReplace(A_LoopField,"\s+"," ")
                _ArrName_:="",_union_:=0
              }
          }
        }
      }
      _TYPE_:=_offset_
    }

    _offset_:=0                 
    _union_:=[]                 ; keep track of union level, required to reset offset after union is parsed
    _struct_:=[]                ; for each union level keep track if it is a structure (because here offset needs to increase
    _union_size_:=[]          ; keep track of highest member within the union or structure, used to calculate new offset after union
    _total_union_size_:=0     ; used in combination with above, each loop the total offset is updated if current data size is higher
    
    this["`t"]:=0,this["`r"]:=0 ; will identify a Structure Pointer without members
    
    ; Parse given structure definition and create struct members
    ; User structures will be resolved by recrusive calls (!!! a structure must be a global variable)
    Loop,Parse,_TYPE_,`,`;,%A_Space%%A_Tab%`n`r
    {
      If (""=_LF_ := A_LoopField)
        Continue
      _IsPtr_:=0
      ; Check for STARTING union and set union helpers
      While (RegExMatch(_LF_,"i)(struct|union)?\s*\{\K"))
        _union_.Insert(_offset_)
        ,_union_size_.Insert(0)
        ,_struct_.Insert(RegExMatch(_LF_,"i)struct\s*\{")?1:0)
        ,_LF_:=SubStr(_LF_,RegExMatch(_LF_,"i)(struct|union)?\s*\{\K"))
       
      _LF_BKP_:=_LF_ ;to check for ending brackets = union,struct
      StringReplace,_LF_,_LF_,},,A ;remove all closing brackets (these will be checked later)
      
      ; Check if item is a pointer and remove * for further processing, separate key will store that information
      While % (InStr(_LF_,"*")){
        StringReplace,_LF_,_LF_,*
        _IsPtr_:=A_Index
      }

      ; Split off data type, name and size (only data type is mandatory)
      RegExMatch(_LF_,"^\s*(?<ArrType_>[\w\d\.]+)?\s*(?<ArrName_>\w+)?\s*\[?(?<ArrSize_>\d+)?\]?\s*\}*\s*$",_)

      If (!_ArrName_ && !_ArrSize_){
        ; If (_ArrType_=_TYPE_ || (_ArrType_ "*") =_TYPE_ || ("*" _ArrType_=_TYPE_)) {
        If RegExMatch(_TYPE_,"^\**" _ArrType_ "\**$"){
          this["`t"]:=_ArrType_
          ,this["`n"]:=_IsPtr_?"PTR":this.base.HasKey("_" _ArrType_)?this.base["_" _ArrType_]:"PTR"
          ,this["`r"]:=_IsPtr_
          ,this["`b"]:=0
          If _ArrType_ in LPTSTR,LPCTSTR,TCHAR
            this["`f"] := A_IsUnicode ? "UTF-16" : "CP0"
          else if _ArrType_ in LPWSTR,LPCWSTR,WCHAR
            this["`f"] := "UTF-16"
          else
            this["`f"] := "CP0"
          this.base:=_base_
          If (IsObject(_init_)||IsObject(_pointer_)){ ; Initialization of structures members, e.g. _Struct(_RECT,{left:10,right:20})
            for _key_,_value_ in IsObject(_init_)?_init_:_pointer_
            {
              If !this["`r"] ; It is not a pointer, assign value
                this[_key_] := _value_
              else if (_value_<>"") ; It is not empty
                if _value_ is digit ; It is a new pointer
                  this[_key_][""]:=_value_
            }
          }
          Return this ;:= new _Struct(%_ArrType_%,_pointer_)   ;only Data type was supplied, object/structure has got no members/keys
        } else 
          _ArrName_:=_ArrType_,_ArrType_:="UInt"
      }
      If InStr(this["`t" _key_],"."){ ;check for object that holds structure definition
        _ArrType_:=this["`t" _key_]
        Loop,Parse,_ArrType_,.
          If A_Index=1
            _defobj_:=%A_LoopField%
          else _defobj_:=_defobj_[A_LoopField]
      }
      ; Set structure keys.
      ; If type is not a pointer and not a Windows or AHK data type, it must be a global variable containing structure definition
      If (!_IsPtr_ && _ArrSize_) {  ; Array size supplied, e.g. TCHAR chr[5]
        _new_struct_:=""            ; concatenate new structure definition and save it as object in _ArrName_
        Loop % _ArrSize_            ; the new structure/object will contain digit keys and usual members
          _new_struct_ .= (_new_struct_?",":"") _ArrType_ " " A_Index
        If RegExMatch(_TYPE_,"^\s*" _ArrType_ "\s*\[\s*" _ArrSize_ "\s*\]\s*$")
          return this:=new _struct(_new_struct_,pointer)
        else {
          this.Insert(_ArrName_,new _Struct(_new_struct_,this[""] + _offset_))     ; Create new structure and assign to _ArrName_
          _offset_+=sizeof(_new_struct_)       ; update offset
        }
        Continue
      } else If (!_IsPtr_ && !_Struct.HasKey(_ArrType_) && !_defobj_ && !%_ArrType_%) {     ; Data type not found, also not structure was found
          ListVars
          MsgBox Structure %_ArrType_% not found, program will exit now         ; Display error message and exit app
          ExitApp
      } else if (!_IsPtr_ && !_Struct.HasKey(_ArrType_)){  ; _ArrType_ not found resolve to global variable (must contain struct definition)
          this.Insert(_ArrName_, new _Struct(_defobj_?_defobj_:%_ArrType_%,this[""] + _offset_,1))
          _offset_+=sizeof(_defobj_?_defobj_:%_ArrType_%) ; move offset
          Continue
      } else {
        this["`t" _ArrName_] := _ArrType_
        ,this["`n" _ArrName_]:=_IsPtr_?"PTR":this.base.HasKey("_" _ArrType_)?this.base["_" _ArrType_]:_ArrType_
        ,this["`b" _ArrName_] := _offset_ ; offset and pointer identifier for __GET, __SET
        ,this["`r" _ArrName_] := _IsPtr_ ; reqired for __GET, __SET
        
        ; Set Encoding format
        If _ArrType_ in LPTSTR,LPCTSTR,TCHAR
          this["`f" _ArrName_] := A_IsUnicode ? "UTF-16" : "CP0"
        else if _ArrType_ in LPWSTR,LPCWSTR,WCHAR
          this["`f" _ArrName_] := "UTF-16"
        else
          this["`f" _ArrName_] := "CP0"
        
        ; update current union size
        If _union_.MaxIndex()
          _union_size_[_union_.MaxIndex()]:=(_offset_ + this.base[this["`n" _ArrName_]] - _union_[_union_.MaxIndex()]>_union_size_[_union_.MaxIndex()])
                                            ?(_offset_ + this.base[this["`n" _ArrName_]] - _union_[_union_.MaxIndex()]):_union_size_[_union_.MaxIndex()]
        ; if not a union or a union + structure then offset must be moved (when structure offset will be reset below
        If (!_union_.MaxIndex()||_struct_[_struct_.MaxIndex()])
          _offset_+=_IsPtr_?A_PtrSize:_Struct[_ArrType_]
      }
      
      
      ; Check for ENDING union and reset offset and union helpers
      While (SubStr(_LF_BKP_,0)="}"){
        If !_union_.MaxIndex(){
          MsgBox Incorrect structure, missing opening braket {`nProgram will exit now `n%_TYPE_%
          ExitApp
        }
        ; Increase total size of union/structure if necessary
        _offset_:=_union_[_union_.MaxIndex()] ; reset offset because we left a union or structure
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
    this.base:=_base_ ; apply new base which uses below functions and uses ___GET for __GET and ___SET for __SET
    If (IsObject(_init_)||IsObject(_pointer_)){ ; Initialization of structures members, e.g. _Struct(_RECT,{left:10,right:20})
      for _key_,_value_ in IsObject(_init_)?_init_:_pointer_
      {
        If !this["`r" _key_] ; It is not a pointer, assign value
          this[_key_] := _value_
        else if (_value_<>"") ; It is not empty
          if _value_ is digit ; It is a new pointer
            this[_key_][""]:=_value_
      }
    }
    Return this
  }
  
  ___NEW(init*){
    this:=this.base
    new := this.__Clone(1) ;clone structure and keep pointer (1), it will be changed below
    If (init.MaxIndex() && !IsObject(init.1))
      new[""] := init.1
    else If (init.MaxIndex()>1 && !IsObject(init.2))
      new[""] := init.2
    else
      new._SetCapacity("`a",_StructSize_:=sizeof(this)) ; Set Capacity in key ["`a"]
      ,new[""]:=new._GetAddress("`a") ; Save pointer in key [""]
      ,DllCall("RtlFillMemory","UPTR",new[""],"UInt",_StructSize_,"UChar",0) ; zero-fill memory
    If (IsObject(init.1)||IsObject(init.2))
      for _key_,_value_ in IsObject(init.1)?init.1:init.2
          new[_key_] := _value_
    return new
  }
  ___SETPTR(_newPTR_="",_object_=0){ ;only called internally to reset pointers in structure
    If !_object_ ; called not recrusive so use this (main structure)
      _obj_:=this
    else _obj_:=_object_
    for _key_,_value_ in _obj_ ; Loop trough structure to check for structures
      If IsObject(_value_)
        this.__SETPTR(_newPTR_  + (_value_[""] - this[""]),_value_) ; _value_ contains an object/structure, call recrusive so it gets changed below
      else if (_key_="" && _obj_!=this){ ; do not apply main pointer yet because it is used to calculate offset
        _obj_[""]:=_newPTR_ ; assign new pointer.
      }
    If !_object_ ; In the end, apply main pointer
      this[""]:=_newPTR_
  }
  
  ; Clone structure and move pointer for new structure
  ___Clone(offset){
    global _Struct
    static _base_:={__GET:_Struct.___GET,__SET:_Struct.___SET,__SETPTR:_Struct.___SETPTR,__Clone:_Struct.___Clone,__NEW:_Struct.___NEW}
    new:={} ; new structure object
    for k,v in this ; copy all values/objects
      if IsObject(v) ; its an object (structure in structure)
        v.__Clone(offset) ; call function recursively
      else new[k]:=v ; add key to new object and assign value
    If this["`r"]{ ; its a pointer so we need too move internal memory
      new._SetCapacity("`a",sizeof(this)),new[""]:=new._GetAddress("`a") ;assign new memory to structure
      If (this["`r"]=1) { ; it is a pointer so read next pointer in structure and write to new structure
        NumPut(NumGet(this[""],0,"PTR")+A_PtrSize*(offset-1),new[""],0,"Ptr")
      } else { ; it is a pointer to pointer so keep pointer and move pointer of pointer ...
        pointer:=NumGet(this[""],0,"PTR"),newPointer:=new[""] ; initial pointers
        Loop % this["`r"]-1 ; exclude last/deepest pointer, the one we need to move
          NumPut(pointer:=NumGet(pointer,0,"PTR"),newPointer:=NumGet(newPointer,0,"PTR"),0,"Ptr")
        ; Last/deepest pointer, move it
        NumPut(NumGet(pointer,0,"PTR")+sizeof(this)*(offset-1),NumGet(newPointer,0,"PTR"),0,"Ptr")
      }
      new.base:=_base_ ;assign base of _Struct
    } else ; do not use internal memory, simply assign new pointer to new structure
      new.base:=_base_,new[]:=this[""]+sizeof(this)*(offset-1)
    return new ; return new object
  }
  ___GET(_key_="",opt="~"){
    global _Struct          ; Used for dynamic structure creation
    If (_key_="")           ; Key was not given so structure[] has been called, return pointer to structure
      Return this[""]
    else If this["`t"]{ ; structure without members (pure pointer)
      If this["`r"]{ ;similar as below but always creates new structure
        Loop % (this["`r"]-1) 
          pointer.="*"
        if (opt="~")
          Return (new _Struct(pointer this["`t"],NumGet(this[""],0,"PTR")))[_key_]
        else Return (new _Struct(pointer (!pointer&&_defobj_?_defobj_:this["`t"]),NumGet(this[""],0,"PTR")))[_key_,opt]
      } else If _key_ is digit ; struct.1, struct.2.. was called
      {
        If _Struct.HasKey("_" this["`t"]){ ;???????????
          If (opt="") ; address of item requested
            return this[""]+sizeof(this["`t"])*(_key_-1)
          If (InStr( ",CHAR,UCHAR,TCHAR,WCHAR," , "," this["`t"] "," )){  ; StrGet 1 character only
            Return StrGet(this[""]+sizeof(this["`t"])*(_key_-1),1,this["`f"])
          } else if InStr( ",LPSTR,LPCSTR,LPTSTR,LPCTSTR,LPWSTR,LPCWSTR," , "," this["`t"] "," ){ ; StrGet string
            Return StrGet(NumGet(this[""]+sizeof(this["`t"])*(_key_-1),0,"PTR"),this["`f"])
          } else    ; It is not a pointer and not a string so use NumGet
            Return NumGet(this[""]+sizeof(this["`t"])*(_key_-1),0,this["`n"])
        } else
          return opt?this.__Clone(_key_):(this.__Clone(_key_))[opt]
      }  else return
    ; from here on we have items in structure
    } else If (!this.HasKey("`t" _key_)){
      If _key_ is digit
      {
        If (opt="~")
          return this.__Clone(_key_)
        else return (this.__Clone(_key_))[opt]
      }
    } else If (this["`r" _key_]){ ; Pointer, create structure using structure its type and address saved in structure
      Loop % (this["`r" _key_]-1) 
          pointer.="*"
      If (opt="~"){
        Return new _Struct(pointer this["`t" _key_],pointer?NumGet(NumGet(this[""]+this["`b" _key_],0,"PTR"),0,"ptr"):NumGet(this[""]+this["`b" _key_],0,"PTR"))
      } else Return (new _Struct(pointer this["`t" _key_],pointer?NumGet(NumGet(this[""]+this["`b" _key_],0,"PTR"),0,"ptr"):NumGet(this[""]+this["`b" _key_],0,"PTR")))[opt] ;NumGet(this[""]+this["`b" _key_],0,"PTR") ;this[_key_][opt]
    } else if (opt=""){        ; Additional parameter was given and it is empty so return pointer to _key_ (struct.key[""])ListVars
      Return this[""]+this["`b" _key_]
    } else If (InStr( ",CHAR,UCHAR,TCHAR,WCHAR," , "," this["`t" _key_] "," )){  ; StrGet 1 character only
      Return StrGet(this[""]+this["`b" _key_],1,this["`f" _key_])
    } else if InStr( ",LPSTR,LPCSTR,LPTSTR,LPCTSTR,LPWSTR,LPCWSTR," , "," this["`t" _key_] "," ){ ; StrGet string
      Return StrGet(NumGet(this[""]+this["`b" _key_],0,"PTR"),this["`f" _key_])
    } else    ; It is not a pointer and not a string so use NumGet
      Return NumGet(this[""]+this["`b" _key_],0,this["`n" _key_])
  }
  ___SET(_key_="",_value_=-0x8000000000000000 ,opt="~"){
      global _Struct
      If (_value_=-0x8000000000000000){ ; Set new Pointer, here a value was assigned e.g. struct[]:=&var
          this._SetCapacity("`a",0) ; free internal memory as this is not used anymore
          this.__SETPTR(_key_) ; Reset all pointers in structure
          Return
      } else if this["`t"] { ; structure without members (pure pointer)
        If opt ; optional parameter was given and it is not empty [""]
          If opt is digit  ; it is a new pointer for structure
          {
            If (this["`r"]>1) { ; pointer to pointer...
              If !NumGet(this[""],0,"PTR") ; pointer is empty, need memory to assign pointer
                this._SetCapacity("`v",A_PtrSize),NumPut(this._GetAddress("`v"),this[""],0,"PTR")
              return NumPut(opt,this._GetAddress("`v"),0,"PTR") ; address already set do not need to use internal memory
            } else return NumPut(opt,this[""],0,"PTR") ; not a pointer to pointer, set pointer in main structure
          }
        If (!this["`r"]&&_Struct.HasKey("_" this["`t"])){ ;???????????
          if InStr( ",LPSTR,LPCSTR,LPTSTR,LPCTSTR,LPWSTR,LPCWSTR," , "," this["`t"] "," ){ 
            this._SetCapacity("`v",(this["`f"]="CP0" ? 1 : 2)*(StrLen(_value_)+1)) ; +1 for string terminator
            ,StrPut(_value_,this._GetAddress("`v"),this["`f"]) ; StrPut string to addr
            ,NumPut(this._GetAddress("`v"),this[""]+sizeof(this["`t"])*(_key_-1),0,"PTR") ; NumPut string addr to key
          } else if InStr( ",TCHAR,CHAR,UCHAR,WCHAR," , "," this["`t"] "," ){
            StrPut(SubStr(_value_,1,1),this[""]+sizeof(this["`t"])*(_key_-1),1,this["`f"]) ; StrPut character key
          } else
            NumPut(_value_,this[""]+sizeof(this["`t"])*(_key_-1),0,this["`n"]) ; NumPut new value to key
          return _value_
        } else if this["`r"] {
          Loop % (this["`r"]-1) 
            pointer.="*"
          return (new _Struct(pointer this["`t"],this["`r"]?NumGet(this[""],0,"PTR"):this[""]))[_key_]:=_value_
        }
      } else if this["`r" _key_]{ ; Pointer
        If opt ;same as above but our structure has items
          If opt is digit  
          {
            If (this["`r" _key_]>1) {
              If !NumGet(this[""]+this["`b" _key_],0,"PTR")
                this._SetCapacity("`v" _key_,A_PtrSize),NumPut(this._GetAddress("`v" _key_),this[""]+this["`b" _key_],0,"PTR")
              return NumPut(opt,this._GetAddress("`v" _key_),0,"PTR")
            } else return NumPut(opt,this[""] + this["`b" _key_],0,"PTR")
          }
        ; else It is a string, use internal memory for string and pointer, then save pointer in key so it is a Pointer to Pointer of a string
        If InStr( ",LPSTR,LPCSTR,LPTSTR,LPCTSTR,LPWSTR,LPCWSTR," , "," this["`t" _key_] "," )
          this._SetCapacity("`v" _key_,(this["`f" _key_]="CP0" ? 1 : 2)*(StrLen(_value_)+1) + A_PtrSize) ; A_PtrSize to save additionally a pionter to string
          ,NumPut(this._GetAddress("`v" _key_)+A_PtrSize,this._GetAddress("`v" _key_),0,"PTR") ; NumPut addr of string
          ,StrPut(_value_,this._GetAddress("`v" _key_)+A_PtrSize,this["`f" _key_]) ; StrPut char to addr+A_PtrSize
          ,NumPut(this._GetAddress("`v" _key_),this[""]+this["`b" _key_],0,"PTR") ; NumPut pointer addr to key
        else if InStr( ",TCHAR,CHAR,UCHAR,WCHAR," , "," this["`t" _key_] "," ) ; same as above but for 1 Character only
          this._SetCapacity("`v" _key_,(this["`f" _key_]="CP0" ? 1 : 2)) ; Internal memory for character
          ,StrPut(SubStr(_value_,1,1),this._GetAddress("`v" _key_),1,this["`f" _key_]) ; StrPut char to addr
          ,NumPut(this._GetAddress("`v" _key_),this[""]+this["`b" _key_],0,"PTR") ; NumPut pointer addr to key
        else
          this._SetCapacity("`v" _key_,A_PtrSize) ; Internal memory for address
          ,NumPut(_value_,this._GetAddress("`v" _key_),0,this["`n" _key_])
          ,NumPut(this._GetAddress("`v" _key_),this[""]+this["`b" _key_],A_PtrSize=8?"UInt64":"UInt") ; NumPut new addr to key
      } else if InStr( ",LPSTR,LPCSTR,LPTSTR,LPCTSTR,LPWSTR,LPCWSTR," , "," this["`t" _key_] "," ){ 
        this._SetCapacity("`v" _key_,(this["`f" _key_]="CP0" ? 1 : 2)*(StrLen(_value_)+1)) ; +1 for string terminator
        ,StrPut(_value_,this._GetAddress("`v" _key_),this["`f" _key_]) ; StrPut string to addr
        ,NumPut(this._GetAddress("`v" _key_),this[""]+this["`b" _key_],0,"PTR") ; NumPut string addr to key
      } else if InStr( ",TCHAR,CHAR,UCHAR,WCHAR," , "," this["`t" _key_] "," ){
        StrPut(SubStr(_value_,1,1),this[""] + this["`b" _key_],1,this["`f" _key_]) ; StrPut character key
      } else
        NumPut(_value_,this[""]+this["`b" _key_],0,this["`n" _key_]) ; NumPut new value to key
      Return _value_
  }
}