Class C7plusStartTrigger Extends CTrigger
{
	static Type := RegisterType(C7plusStartTrigger, "On 7plus start")
	static Category := RegisterCategory(C7plusStartTrigger, "7plus")
	static __WikiLink := "7plusStart"
	
	Matches(Filter)
	{
		return true ;type is checked elsewhere
	}
}
