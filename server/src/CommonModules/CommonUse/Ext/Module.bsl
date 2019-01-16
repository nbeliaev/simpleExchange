#Region ApplicationInterface

Function IsRefExist(RefChecked) Export
	
	QueryText = "
	|SELECT
	|	Ref AS Ref
	|FROM
	|	[TableName]
	|WHERE
	|	Ref = &Ref
	|";
	
	QueryText = StrReplace(QueryText, "[TableName]", TableNameByRef(RefChecked));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", RefChecked);
	
	SetPrivilegedMode(True);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function Base64ValueToString(Data) Export
	
	BinaryData = Base64Value(Data);	
	Reader = New DataReader(BinaryData);
	Return Reader.ReadChars(,TextEncoding.UTF8);
		
EndFunction

Function StringToBase64String(String) Export
		
	MemoryStream = New MemoryStream;
	Writer 		 = New DataWriter(MemoryStream);
	Writer.WriteLine(String);
	
	BinaryData = MemoryStream.CloseAndGetBinaryData();
				
	Return Base64String(BinaryData);
		
EndFunction

Function ObjectUUID(Object) Export
	Return String(Object.Ref.UUID());
EndFunction // ObjectUUID()

Function DataToJSON(Data) Export

	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Data); 
	Return JSONWriter.Close();	

EndFunction // DataToJSON()
 	
#EndRegion 

#Region ServiceProceduresAndFunctions

Function TableNameByRef(Ref)
	Return Ref.Metadata().FullName();
EndFunction

#EndRegion 
