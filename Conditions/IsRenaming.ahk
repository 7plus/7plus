Class CIsRenamingCondition Extends CCondition
{
	static Type := RegisterType(CIsRenamingCondition, "Explorer is renaming")
	static Category := RegisterCategory(CIsRenamingCondition, "Explorer")
	Evaluate()
	{
		return IsRenaming()
	}
	DisplayString()
	{
		return "Explorer is renaming"
	}
}