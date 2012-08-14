/*
<Node1>value</Node1>
<Node2>
<key>value</key>
<key2>value</key2>
</Node2>

<Node1>value</Node1> <Node2> <key>value</key> <key2>value</key2> </Node2>
<key>value</key> <key2>value</key2>
*/
;xml := XML_Write("", "Node1", "value")
;node2:= XML_Write("", "key", "value")
;node2:=XML_Write(node2, "key2", "value")
;xml:=XML_Write(xml,"Node2", "`r`n" node2)
;outputdebug % xml
;obj := XML_Read(xml)
;exitapp

XML_Write(xml, name, value)
{
	return xml "<" name ">" value "</" name ">`r`n"
}

XML_Save(xmlObject, path, xml = "", level = 0)
{
	enum := xmlObject._newEnum()
	while enum[k,v]
	{
		if(IsObject(v) && v.Is(CArray)) ;If current value is an array
		{
			Loop % v.MaxIndex()
			{
				if(IsObject(v[A_Index]))
				{
					xml .= "<" k ">`r`n" 
					xml := XML_Save(v[A_Index], "", xml, level + 1)
					xml .= "</" k ">"
				}
				else
				{
					value := StringReplace(v[A_Index],"<","&lt;",1)
					value := StringReplace(value,">","&gt;",1)
					value := StringReplace(value,"`r","&r;",1)
					value := StringReplace(value,"`n","&n;",1)
					xml .= "<" k ">" value "</" k ">`r`n"
				}
			}
			continue
		}
		else if(IsObject(v))
		{
			xml .= "<" k ">`r`n"
			xml := XML_Save(v, "", xml, level + 1) 
			xml .= "</" k ">"
		}
		else
		{
			value := StringReplace(v,"<","&lt;",1)
			value := StringReplace(value,">","&gt;",1)
			value := StringReplace(value,"`r","&r;",1)
			value := StringReplace(value,"`n","&n;",1)
			xml .= "<" k ">" value "</" k ">"
		}
		xml .= "`r`n"
		
	}
	if(path)
	{
		FileDelete, %path%
		FileAppend, %xml%, %path%
	}
	return xml
}
XML_Read(xml,node = 0)
{ 
	if(node = 0)
		node := Object()
	xml := strTrim(xml,"`r`n")
	xml := strTrim(xml,"`n")
	if(InStr(xml,"<") != 1)
		return ""
	start := 1
	while(start != 0) ;loop until no more keys, all keys from this level read
	{
		len := InStr(xml,">", 0, start + 1) - start - 1
		key := SubStr(xml,start + 1,InStr(xml,">", 0, start + 1) - start - 1)
		if(strEndsWith(key,"/"))
		{
			start += strlen(key) + 3
			continue
		}
		start += StrLen(key) + 2
		depth := 1
		end := start
		while(depth > 0)
		{
			open := InStr(xml, "<" key ">",0,end)
			close := InStr(xml, "</" key ">",0,end)
			
			if(!close) ;No closing key, ERROR
				return ""
			if(open && open < close)
			{
				depth++
				end := open + StrLen("<" key ">")
				continue
			}
			else
			{
				depth--
				end := close + StrLen("</" key ">")
				continue
			}
		}
		value := SubStr(xml, start, end - start - 2 - strlen(key) - 1)
		value := strTrimLeft(value, "`r`n")
		value := strTrimLeft(value, "`n")
		
		if(InStr(value, "<"))
		{
			subnode := Object()
			value := XML_Read(value, subnode)
		}
		else
		{
			value := StringReplace(value, "&gt;",">",1)
			value := StringReplace(value, "&lt;","<",1)
			value := StringReplace(value, "&r;","`r",1)
			value := StringReplace(value, "&n;","`n",1)
		}
		if(node.HasKey(key) && !node[key].Is(CArray)) ;Key already exists and is not an array, make it one and append things
		{
			array := Array()
			array.Insert(node[key])
			array.Insert(value)
			node[key] := array
		}
		else if(node.HasKey(key) && node[key].Is(CArray)) ;Key already exists and is an array, just append the new key
			node[key].Insert(value)
		else
			node[key] := value
		start := InStr(xml, "<",0,end)
	}
	return node
}

XML_Get(XMLObject, path)
{
	StringSplit, node, path, /
	if(node0 = 0)
		return ""
	obj := XMLObject
	Loop %node0%
	{
		node := node%A_Index%
		if(strEndsWith(node,"]"))
		{
			pos := strTrimRight(SubStr(node, InStr(node,"[",0,0) + 1),"]")
			node := SubStr(node, 1, InStr(node,"[",0,0) - 1)
		}
		else
			pos := 0
		if(pos = 0)
			obj := obj[node]
		else
			obj := obj[node][pos]		
	}
	return obj
}