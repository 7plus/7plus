; namespace DBA

/*
#####################################################################################
	Abstract Database Classes
	Base for all concrete implementations for the supported DataBases.
#####################################################################################
*/

/*
	data := Row[index]
	data := Row["ColumnName"]
*/

class Row
{
	_columns := 0
	_fields := new Collection()
	
	Count(){
		return this._fields.Count()
	}
	
	ToString(){
		return this._fields.ToString()
	}
	
	__Get(param){
		
		if(IsObject(param)){
			throw Exception("Expected Index or Column Name!", -1)
		}
		
		if(!IsObjectMember(this, param)){
			if param is Integer
			{
				; // assume that an indexed access is desired
				; // return the corresponding ROW
				if(this.ContainsIndex(param))
					return this._fields[param]
			} else {
				; // assume that an columnname access is desired
				; // find index
				
				index := 0
				for i, col in this._columns
				{
					if(col = param){
						index := i
						break
					}
				}
				if(this.ContainsIndex(index)){
					return this._fields[index]
				}
			}
		}
	}
	
	ContainsIndex(index){
		return ((index > 0) && (index <= this._fields.Count()))
	}
	
	/*
		Creates a New Row.
		columns	:	Collection of the Columnames
		fields:	Collection of the Fields (Data)
	*/
	__New(columns, fields){

		if(!is(columns, "Collection")){
			throw Exception("columns must be a Collection Object",-1)
		}
		
		if(!is(fields, "Collection")){
			throw Exception("fields must be a Collection Object",-1)
		}
		
		
		this._fields := fields
		this._columns := columns
	}
}

/*
	row := table[index]
*/

class Table
{
	Rows := new Collection()
	Columns := new Collection()
	
	Count(){
		return this.Rows.Count()
	}
	
	ToString(){
		colstr := this.Columns.ToString()
		StringReplace, colstr, colstr, `n, |
		return "(" this.Rows.Count() ")" . colstr
	}
	
	__Get(param){
		
		if(IsObject(param)){
			throw Exception("Expected non-Object Index!",-1)
		}
		if(!IsObjectMember(this, param)){
			if param is Integer
			{
				; // assume that an indexed access is desired
				; // return the corresponding ROW
				if((param > 0) && (param < this.Rows.Count()) )
					return this.Rows[param]
			}
		}
	}
	
	/*
		Creates a New Table.
		rows:	Collection of the Rows (Data)
		columns	:	Collection of the Columnames
	*/
	__New(rows, columns){

		if(!is(rows, "Collection")){
			throw Exception("rows must be a Collection Object",-1)
		}
		
		if(!is(columns, "Collection")){
			throw Exception("rows must be a Collection Object",-1)
		}
		
		this.Rows := rows
		this.Columns := columns
	}
}

class DataBase
{
	static NULL := Object()
	static TRUE := Object()
	static FALSE := Object()
	
	__delete() {
		this.Close()
	}
	
	IsValid(){
		throw Exceptions.MustOverride()
	}
	
	Query(sql){
		throw Exceptions.MustOverride()
	}
	
	QueryValue(sQry){
		rs := this.OpenRecordSet(sQry)
		value := rs[1]
		rs.Close()
		return value
	}
	
	QueryRow(sQry){
		rs := this.OpenRecordSet(sQry)
		myrow := rs.getCurrentRow()
		rs.Close()
		return myrow
	}
	
	OpenRecordSet(sql){
		throw Exceptions.MustOverride()
	}
	
	ToSqlLiteral(value) {
		if (IsObject(value)) {
			if (value == DBA.DataBase.NULL)
				return "NULL"
			if (value == DBA.DataBase.TRUE)
				return "TRUE"
			if (value == DBA.DataBase.FALSE)
				return "FALSE"
		}
		return "'" this.EscapeString(value) "'"
	}
	
	EscapeString(string){
		throw Exceptions.MustOverride()
	}
	
	QuoteIdentifier(identifier){
		throw Exceptions.MustOverride()
	}
	
	BeginTransaction(){
		throw Exceptions.MustOverride()
	}
	
	EndTransaction(){
		throw Exceptions.MustOverride()
	}
	
	Rollback(){
		throw Exceptions.MustOverride()
	}
	
	Insert(record, tableName){
		throw Exceptions.MustOverride()
	}
	
	InsertMany(records, tableName){
		throw Exceptions.MustOverride()
	}
	
	Update(fields, constraints, tableName, safe = True){
		throw Exception.MustOverride()
	}
	
	Close(){
		throw Exceptions.MustOverride()
	}
}

class RecordSet
{
	_currentRow := 0 	; Row
	
	__delete() {
		this.Close()
	}
	
	MoveNext(){
		throw Exceptions.MustOverride()
	}
	
	Update(){
		throw Exceptions.MustOverride()
	}
	
	Close(){
		throw Exceptions.MustOverride()
	}
	
	getEOF(){
		throw Exceptions.MustOverride()
	}
	
	IsValid(){
		throw Exceptions.MustOverride()
	}
	
	getColumnNames(){
		throw Exceptions.MustOverride()
	}
	
	getCurrentRow(){
		return this._currentRow
	}
	
	__Get(param){
		
		if(IsObject(param)){
			throw Exception("Expected Index or Column Name!",-1)
		}

		if(param = "EOF")
			return this.getEOF()


		if(!IsObjectMember(this, param) && param != "_currentRow"){

			if(!is(this._currentRow, DBA.Row))
				return ""
				
			;// assume memberaccess are the column names/indexes
			return this._currentRow[param]
		}
	}
}