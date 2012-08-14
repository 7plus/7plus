Class CQueue extends CArray
{
	static MaxSize := 100
	static Unique := true
	static Pop := CArray.Remove ;Alias
	;Puts an item in the queue
	Push(item)
	{
		itemPosition := this.Unique ? this.IndexOf(item) : this.IndexOfEqual(item)
		if(!itemPosition)
		{
			this.Insert(1, item)
			if(this.MaxIndex() = this.MaxSize + 1)
				this.Remove()
		}
		else
			this.Move(itemPosition, 1)
	}
}