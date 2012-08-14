Class CFileCopyAction Extends CAction
{
	static Type := RegisterType(CFileCopyAction, "Copy file")
	static Category := RegisterCategory(CFileCopyAction, "File")
	static _ImplementsFileOperation := ImplementFileOperationInterface(CFileCopyAction)

	Execute(Event)
	{
		this.FileOperationProcessPaths(Event, sources, targets, flags)
		ShellFileOperation(0x2, sources, targets, flags)  
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