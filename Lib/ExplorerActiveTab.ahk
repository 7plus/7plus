; ExplorerActiveTab.ahk
; ------------------------------------------------------------------------
; Windows 11 gives every Explorer tab its own real (but hidden-when-inactive)
; ShellTabWindowClass child window, while Shell.Application.Windows still
; exposes one COM item PER TAB but with ALL of them reporting the SAME
; top-level frame hwnd. That means "for Window in Shell.Application.Windows
; if (Window.hwnd = hwnd)" is ambiguous whenever a frame has more than one
; tab open - it will return an arbitrary (but consistent) tab, not
; necessarily the active one.
;
; This module resolves that ambiguity in two steps:
;   1. Find the currently VISIBLE ShellTabWindowClass child of the frame
;      (= the active tab). This is unambiguous and cheap (Win32 only).
;   2. Use UI Automation to build a lightweight "fingerprint" of that tab's
;      content (folder display name, item count, and the set of item
;      names), then use that fingerprint to pick the matching COM Window
;      object out of the (possibly several) Shell.Application.Windows
;      candidates that share the frame's hwnd.
;
; If, after all fingerprint checks, more than one candidate remains, they
; are tabs pointing at the literal same path/content, so returning any of
; them yields the correct result anyway.
;
; Requires: UIA_Interface.ahk (AHK v1 / AHK_L compatible fork), included
; once by the host script BEFORE this file, e.g.:
;   #Include %A_ScriptDir%\Lib\UIA_Interface.ahk
;   #Include %A_ScriptDir%\Lib\ExplorerActiveTab.ahk
; ------------------------------------------------------------------------

global ExplorerUIA := 0

; Lazily initializes and returns the shared UIA_Interface instance.
GetExplorerUIA()
{
	global ExplorerUIA
	if (!IsObject(ExplorerUIA))
		ExplorerUIA := UIA_Interface()
	return ExplorerUIA
}

; Returns the hwnd of the currently visible ShellTabWindowClass child of the
; given Explorer frame window (i.e. the active tab). Returns 0 if none found
; (shouldn't happen on Win11, kept defensive).
GetActiveShellTabWindow(FrameHwnd)
{
	WinGet, ChildList, ControlListHwnd, ahk_id %FrameHwnd%
	Loop, Parse, ChildList, `n
	{
		ChildHwnd := A_LoopField
		WinGetClass, cclass, ahk_id %ChildHwnd%
		if (cclass != "ShellTabWindowClass")
			continue
		WinGet, Style, Style, ahk_id %ChildHwnd%
		if (Style & 0x10000000) ; WS_VISIBLE
			return ChildHwnd
	}
	return 0
}

; Builds a fingerprint {Name, Count, NameSet} for the active tab's file list,
; using UI Automation scoped to the given (already-resolved) active tab hwnd.
; NameSet is an associative array (name -> true) for O(1) membership checks.
GetActiveTabFingerprint(ActiveTabHwnd)
{
	Fingerprint := {Name: "", Count: -1, NameSet: {}, HasNames: false}
	try
	{
		UIA := GetExplorerUIA()
		TabRoot := UIA.ElementFromHandle(ActiveTabHwnd)
		Fingerprint.Name := TabRoot.CurrentName

		ListEl := TabRoot.FindFirstByType("List", 0x4) ; TreeScope_Descendants
		if (IsObject(ListEl))
		{
			Items := ListEl.FindAllByType("ListItem", 0x2) ; TreeScope_Children
			Fingerprint.Count := Items.Length()
			Loop % Fingerprint.Count
				Fingerprint.NameSet[Items[A_Index].CurrentName] := true
			Fingerprint.HasNames := (Fingerprint.Count > 0)
		}
	}
	catch e
	{
		OutputDebug % "[ExplorerActiveTab] Error building UIA fingerprint: " e.message
	}
	return Fingerprint
}

; Main entry point: returns the Shell.Application.Windows COM object that
; corresponds to the ACTIVE tab of the given Explorer frame hwnd, or 0 if
; the frame isn't found among Shell.Application.Windows at all.
;
; Use this instead of "for Window in Shell.Application.Windows if
; (Window.hwnd = hwnd)" everywhere a specific tab's Document/Folder is
; needed.
ResolveActiveExplorerWindow(hwnd)
{
	ActiveTabHwnd := GetActiveShellTabWindow(hwnd)
	if (!ActiveTabHwnd)
		ActiveTabHwnd := hwnd ; defensive fallback, shouldn't normally happen

	Fingerprint := GetActiveTabFingerprint(ActiveTabHwnd)

	; Collect all Shell.Application.Windows candidates sharing this frame's hwnd
	Candidates := []
	try
	{
		for Window in ComObjCreate("Shell.Application").Windows
		{
			try
			{
				if (Window.hwnd = hwnd)
					Candidates.Insert(Window)
			}
			catch e
			{
			}
		}
	}
	catch e
	{
		OutputDebug % "[ExplorerActiveTab] Error enumerating Shell.Application.Windows: " e.message
		return 0
	}

	if (Candidates.MaxIndex() = 0)
		return 0
	if (Candidates.MaxIndex() = 1)
		return Candidates[1]

	; --- Disambiguation step 1: folder display name ---
	if (Fingerprint.Name != "")
	{
		Filtered := []
		for index, Cand in Candidates
		{
			try
				if (Cand.Document.Folder.Self.Name = Fingerprint.Name)
					Filtered.Insert(Cand)
			catch e
			{
			}
		}
		if (Filtered.MaxIndex() = 1)
			return Filtered[1]
		if (Filtered.MaxIndex() > 1)
			Candidates := Filtered
	}

	; --- Disambiguation step 2: item count ---
	if (Fingerprint.Count >= 0)
	{
		Filtered := []
		for index, Cand in Candidates
		{
			try
				if (Cand.Document.Folder.Items.Count = Fingerprint.Count)
					Filtered.Insert(Cand)
			catch e
			{
			}
		}
		if (Filtered.MaxIndex() = 1)
			return Filtered[1]
		if (Filtered.MaxIndex() > 1)
			Candidates := Filtered
	}

	; --- Disambiguation step 3: full item-name set comparison ---
	; (Only reached if step 1+2 left multiple candidates, e.g. same folder
	; name AND same item count but different paths - rare but possible.)
	if (Fingerprint.HasNames)
	{
		for index, Cand in Candidates
		{
			try
			{
				doc := Cand.Document
				AllMatch := true
				Loop % doc.Folder.Items.Count
				{
					ItemName := doc.Folder.Items.Item(A_Index - 1).Name
					if (!Fingerprint.NameSet.HasKey(ItemName))
					{
						AllMatch := false
						break
					}
				}
				if (AllMatch)
					return Cand
			}
			catch e
			{
			}
		}
	}

	; All remaining candidates are indistinguishable by content - they point
	; at the same path, so any of them yields the correct result.
	return Candidates[1]
}
