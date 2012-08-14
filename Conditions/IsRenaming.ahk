Class CIsRenamingCondition Extends CCondition
{
	static Type := RegisterType(CIsRenamingCondition, "Explorer is renaming")
	static Category := RegisterCategory(CIsRenamingCondition, "Explorer")
	static __WikiLink := "IsRenaming"
	Evaluate()
	{
		return IsRenaming()
	}
	DisplayString()
	{
		return "Explorer is renaming"
	}
}
