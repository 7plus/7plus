Class CFileMoveAction Extends CAction
{
	static Type := RegisterType(CFileMoveAction, "Move file")
	static Category := RegisterCategory(CFileMoveAction, "File")
	static __WikiLink := "Move"
	static _ImplementsFileOperation := ImplementFileOperationInterface(CFileMoveAction)

	Execute(Event)
	{
		this.FileOperationProcessPaths(Event, sources, targets, flags)
		ShellFileOperation(0x1, sources, targets, flags)  
		return 1
	}

	DisplayString()
	{
		return this.FileOperationDisplayString()
	}

	GuiShow(GUI, GoToLabel = "")
	{	
		this.FileOperationGuiShow(GUI)
	}
	GuiSubmit(GUI)
	{
		this.FileOperationGuiSubmit(GUI)
		Base.GuiSubmit(GUI)
	}
}
