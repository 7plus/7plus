Class C7plusStartTrigger Extends CTrigger
{
	static Type := RegisterType(C7plusStartTrigger, "On 7plus start")
	static Category := RegisterCategory(C7plusStartTrigger, "7plus")
	
	Matches(Filter)
	{
		return true ;type is checked elsewhere
	}
}