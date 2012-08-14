/*
Class: CEnumerator
Generic enumerator object that can be used for iterating over numeric keys.
The array must not be modified during iteration, otherwise the iterated range will be invalid.
It's possible to define a custom MaxIndex() functions for array boundaries.
If there are missing array members between 1 and max index, they will be iterated but will have a value of "".
This means that real sparse arrays are not supported by this enumerator by design.
To make an object use this iterator, insert this function in the class definition:
|_NewEnum()
|{
|	return new CEnumerator(this)
|}
*/
Class CEnumerator
{
	__New(Object)
	{
		this.Object := Object
		this.first := true
		;Cache for speed. Useful if custom MaxIndex() functions have crappy performance.
		;In return that means that no key-value pairs may be inserted during iteration or the range will become invalid.
		this.ObjMaxIndex := Object.MaxIndex()
	}
	Next(byref key, byref value)
	{
		if(this.first)
		{
			this.Remove("first")
			key := this.Object.MinIndex.Name && IsFunc(this.Object.MinIndex) ? this.Object.MinIndex() : 1
		}
		else
			key++
		if(key <= this.ObjMaxIndex)
			value := this.Object[key]
		else
			key := ""
		return key != ""
	}
}