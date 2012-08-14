Class CShutdownAction Extends CAction
{
	static Type := RegisterType(CShutdownAction, "Shutdown computer")
	static Category := RegisterCategory(CShutdownAction, "System")	
	static ShutDownSelection := "Shutdown"
	static ForceClose := false
	
	Execute()
	{
		if(this.ShutdownSelection = "LogOff")
			code := 0
		else if(this.ShutdownSelection = "Shutdown")
			code := 1 + 8
		else if(this.ShutdownSelection = "Reboot")
			code := 2
		else if(this.ShutdownSelection = "Lock Workstation")
		{
			DllCall("LockWorkStation", "UINT")
			return 1
		}
		else if(this.ShutdownSelection = "Hibernate")
		{
			; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
			; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
			; Parameter #3: Pass 1 instead of 0 to disable all wake events.
			if(this.ShutdownSelection = "Hibernate")
				DllCall("PowrProf\SetSuspendState", "int", 1, "int", 0, "int", 0)
			else if(this.ShutdownSelection = "Standby")
				DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
			return 1
		}
		else
		{
			Notify(this.Type " Error!", "Invalid action: " this.ShutDownSelection, 5, NotifyIcons.Error)
			return 0
		}
		if(this.ForceClose)
			code += 4
		Shutdown, %code%
		return 1
	} 

	DisplayString()
	{
		return this.ShutdownSelection
	}
	
	GuiShow(GUI)
	{
		this.AddControl(GUI, "DropDownList", "ShutdownSelection", "LogOff|Shutdown|Reboot|Hibernate|Standby|Lock Workstation", "", "Selection:")
		this.AddControl(GUI, "Checkbox", "ForceClose", "Force-close applications", "", "")
	}
}