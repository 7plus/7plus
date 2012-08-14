/*
Class: CSettings
A generic class for managing program settings.
*/
Class CSettings
{
	;Properties which should be saved are stored in the subclass object.
	;This allows to add dynamic properties to the instances of the classes during runtime which aren't saved.
	;Notes: 
	;- All class names must start with C, but their instance variables must not!
	;- The ini file will only use the name of the current (sub)category, not the full hierarchy, so the names of the (sub)categories should be unique.
	Class CExplorer
	{
		Class CFastFolders
		{
			static ShowInPlacesBar := 0
			static CleanFolderBand := 0
			static ShowInFolderBand := 0
			static Folder0 := "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
			static FolderTitle0 := "Computer"
			static Folder1 := "C:\"
			static FolderTitle1 := "C:\"
			static Folder2 := ""
			static FolderTitle2 := ""
			static Folder3 := ""
			static FolderTitle3 := ""
			static Folder4 := ""
			static FolderTitle4 := ""
			static Folder5 := ""
			static FolderTitle5 := ""
			static Folder6 := ""
			static FolderTitle6 := ""
			static Folder7 := ""
			static FolderTitle7 := ""
			static Folder8 := ""
			static FolderTitle8 := ""
			static Folder9 := ""
			static FolderTitle9 := ""
		}
		FastFolders := new this.CFastFolders()
		
		Class CTabs
		{
			static UseTabs 			:= 1
			static NewTabPosition 	:= 1
			static TabStartupPath 	:= "C:\"
			static ActivateTab 		:= 1
			static TabWindowClose 	:= 1
			static OnTabClose 		:= 1
		}		
		Tabs := new this.CTabs()
		
		static AutoSelectFirstFile 		 	:= 1
		static ImproveEnter 				:= 1 
		static AdvancedStatusBarInfo 	 	:= 1
		static MouseGestures 			 	:= 1
		static AutoCheckApplyToAllFiles 	:= 1 
		static ScrollTreeUnderMouse 		:= 1 
		static RememberPath 				:= 1 
		static AlignNewExplorer 			:= 1
		static EnhancedRenaming				:= 1
		static PasteImageAsFileName     	:= "clip.png"
		static PasteTextAsFileName       	:= "clip.txt"	
		static PreviousPath         		:= "C:\"
		static CurrentPath                  := "C:\"	
	}
	Explorer := new this.CExplorer()
	
	Class CWindows
	{
		Class CSlideWindows
		{
			static HideSlideWindows 					:= 1
			static BorderActivationRequiresMouseUp 		:= 1
			static LimitToOnePerSide 					:= 1
			static BorderSize 							:= 30
			static ModifierKey 							:= "Control"
		}
		SlideWindows := new this.CSlideWindows()
		
		static ShowResizeTooltip := 0
		static AutoCloseWindowsUpdate := 0
	}
	Windows := new this.CWindows()
	
	Class CMisc
	{
		static ImageExtensions               := "jpg,png,bmp,gif,tga,tif,ico,jpeg"
		static DefaultImageExtension         := "png"
		static ImageQuality                  := 95
		static GamepadRemoteControl          := 0
		static FixEditControlWordDelete      := 1
		static TabAutocompletion			 := 1
		static FullscreenExclude             := "VLC DirectX,OpWindow,CabinetWClass"
		static FullscreenInclude             := "Project64"
		static RunAsAdmin                    := "Always/Ask"
		static HideTrayIcon                  := 0
		static IgnoredPrograms				 := "KeePass.exe"
		static DefaultImageEditor			 := "%ProgramFiles%\Paint.NET\PaintDotNet.exe"
		static DefaultTextEditor			 := "%ProgramFiles%\Notepad++\notepad++.exe"
	}
	Misc := new this.CMisc()
	
	Class CGeneral
	{
		static DebugEnabled 		                := false
		static ProfilingEnabled 	                := false
		static AutoUpdate 		                    := true
		static FirstRun								:= true
		static ShowAdvancedEvents	                := false
		static ShowExecutingEvents             	    := false
		static Language								:= "En"
		static ShowTips								:= true
		static ShownTips							:= "00000000000000000000000000000000000000000000000000000000000000" ;Array of values that indicate if a tip has been shown yet
		static DontRegisterSelectionChanged			:= false
	}
	General := new this.CGeneral()

	Class CIFTTT
	{
		static From 		               			:= "The email address you use in the email channel of IFTTT"
		static Server 	                			:= "SMTP Server address, e.g. smtp.gmail.com"
		static Port 		                   		:= 465
		static TLS									:= true
		static Username	                			:= "Email login name, e.g. user@gmail.com"
		static Password             	    		:= ""
		static Timeout								:= 10
	}
	IFTTT := new this.CIFTTT()
	
	;ModifiedKeyNames is a class containing mappings of new key names to old key names. It's used to ease transform from older
	;nondescriptive key names to better fitting ones.
	Class ModifiedKeyNames
	{ 
		static PasteImageAsFileName := "Image"
		static PasteTextAsFileName := "Text"
		static ShowInPlacesBar := "HKPlacesBar"
		static CleanFolderBand := "HKCleanFolderBand"
		static ShowInFolderBand := "HKFolderBand"
		static AutoSelectFirstFile 	:= "HKSelectFirstFile"
		static ImproveEnter 			:= "HKImproveEnter"
		static AdvancedStatusBarInfo 	:= "HKShowSpaceAndSize"
		static MouseGestures 			:= "HKMouseGestures"
		static AutoCheckApplyToAllFiles := "HKAutoCheck"
		static ScrollTreeUnderMouse 	:= "ScrollUnderMouse"
		static RememberPath 			:= "RecallExplorerPath"
		static DefaultImageExtension := "ImageExtension"
		static FixEditControlWordDelete := "WordDelete"
		static GamepadRemoteControl := "JoyControl"
		static HideSlideWindows := "SlideWinHide"
		static BorderActivationRequiresMouseUp := "SlideWindowRequireMouseUp"
		static LimitToOnePerSide := "SlideWindowSideLimit"
		static BorderSize := "SlideWindowsBorder"
		static ModifierKey := "SlideWindowsModifier"
		static AlignNewExplorer := "AlignExplorer"
		static ShowAdvancedEvents := "ShowComplexEvents"
	}
	
	SetupConfigurationPath()
	{
		;Try to use config file from script dir in portable mode or when it wasn't neccessary to copy it to appdata yet
		if(ApplicationState.IsPortable)
			this.ConfigPath := A_ScriptDir 
		Else
		{
			this.ConfigPath := A_AppData "\7plus"
			if(!FileExist(this.ConfigPath))
				FileCreateDir, %ConfigPath%
		}
		this.IniPath := this.ConfigPath "\Settings.ini"
		this.DllPath := A_ScriptDir "\lib" (A_PtrSize = 8 ? "\x64" : "")
	}

	Load(Category = "")
	{
		global FastFolders
		if(!Category)
			Category := this
		;Subcategories are stored in instance objects while keys are stored in the class objects.
		;Look for subcategories first
		for key, value in Category
		{
			if key in base,ModifiedKeyNames,__Class,__Init
				continue
			
			;Subcategories are stored in the instance. Due to some quirk, there is also an empty key with their name in the base object,
			;so we can nearly iterate over them as if they were located in the base.
			; if(Category.HasKey(key))
				; value := Category[key]
			
			;Skip classes
			if(SubStr(key, 1, 1) = "C" && IsObject(value) && value.HasKey("__Class"))
				continue
			
			if(IsObject(value))
				this.Load(value)
		}
		
		;Now look for properties defined in the base object
		for key, value in Category.base
		{
			if key in base,ModifiedKeyNames,__Class,__Init
				continue
			
			;Subcategories are stored in the instance. Due to some quirk, there is also an empty key with their name in the base object,
			;so we can nearly iterate over them as if they were located in the base.
			; if(Category.HasKey(key))
				; value := Category[key]
			
			;Skip classes
			if(SubStr(key, 1, 1) = "C" && IsObject(value) && value.HasKey("__Class"))
				continue
			
			if(!IsObject(value) && !IsFunc(this[key]))
			{
				Class := SubStr(SubStr(Category.__Class, InStr(Category.__Class, ".", false, 0) + 1), 2)
				
				;Read value from Ini file
				AcquiredSetting := IniRead(this.IniPath, Class, key)
				
				;Value not found under this key -> Use old key names
				if(AcquiredSetting = "ERROR" && this.ModifiedKeyNames.HasKey(key))
					AcquiredSetting := IniRead(this.IniPath, Class, this.ModifiedKeyNames[key])
					
				;Value doesn't exist, use default
				if(AcquiredSetting = "ERROR")
					AcquiredSetting := Category.base[key]
				
				;Set it to the instance object of Category, default values are still stored in base
				Category[key] := AcquiredSetting
			}
		}
		
		;Main recursion, do some further specific processing
		if(Category = this)
		{
			FastFolders := new CFastFolders()
			Loop 10
				FastFolders[A_Index - 1] := Object("Path", this.Explorer.FastFolders["Folder" A_Index - 1], "Name", this.Explorer.FastFolders["FolderTitle" A_Index - 1])
			
			;the path where the image/text files from clipboard are saved for copying
			this.Explorer.PasteImageAsFileTempPath := A_Temp "\" this.Explorer.PasteImageAsFileName ; temp_img
			this.Explorer.PasteTextAsFileTempPath := A_Temp "\" this.Explorer.PasteTextAsFileName ; temp_txt
			
			;5 is really ugly quality, lower values don't really make sense
			this.Misc.ImageQuality := Clamp(this.Misc.ImageQuality, 5, 100)
		}
	}
	Save(Category = "")
	{
		global FastFolders
		
		if(Category = "")
		{
			Category := this
			;Make sure path exists to be sure
			if(!FileExist(this.ConfigPath))
				FileCreateDir % this.ConfigPath
			
			;Purge old settings from last ini file
			FileDelete, % this.IniPath			
			
			;Update the FastFolder values in this class
			Loop 10
			{
				this.Explorer.FastFolders["Folder" A_Index - 1] := FastFolders[A_Index - 1].Path
				this.Explorer.FastFolders["FolderTitle" A_Index - 1] := FastFolders[A_Index - 1].Name
			}
			this.General.FirstRun := 0
		}
		
		;Look for subcategories first
		for key, value in Category
		{
			if key in base,__Class,__Init,ModifiedKeyNames
				continue
			
			;Subcategories and changed values are stored in the instance. Due to some quirk, there is also an empty key with their name in the base object,
			;so we can nearly iterate over them as if they were located in the base.
			; if(Category.HasKey(key))
				; value := Category[key]
			
			;Skip classes
			if(IsObject(value) && SubStr(key, 1, 1) = "C" && value.HasKey("__Class"))
				continue
			
			;Value is an instance of a class
			if(IsObject(value))
				this.Save(value)
		}
		
		;Now look for keys defined in base object
		for key, value in Category.base
		{
			if key in base,__Class,__Init,ModifiedKeyNames
				continue
			
			;If the key was changed it can be located in the instance object so it's preferrable to use that value.
			if(Category.HasKey(key))
				value := Category[key]
			
			;Skip classes
			if(IsObject(value) && SubStr(key, 1, 1) = "C" && value.HasKey("__Class"))
				continue
			
			;Value is a key in this category
			if(!IsObject(value) && !IsFunc(this[key]))
			{
				Class := SubStr(SubStr(Category.__Class, InStr(Category.__Class, ".", false, 0) + 1), 2)
				IniWrite(value, this.IniPath, Class, key)
			}
		}
	}
}