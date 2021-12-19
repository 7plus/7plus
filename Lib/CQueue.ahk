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

class queue 
{
  __New()
  {
    this.items := Object()
  }

  push(item)
  {
    this.items.Insert(item)
  }

  pop()
  {
    return this.items.Remove(1)
  }

  size()
  {
    return (this.items.MaxIndex() ? this.items.MaxIndex() : 0)
  }

}