#Region FindCreateExchangeNodes

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

Function WebServiceProxy(DataBaseAddress, Result) Export
	
	WSDLAddress = DataBaseAddress + "/ws/server.ws?wsdl"; 
	
	Try
		WSDefinitions = New WSDefinitions(WSDLAddress);
	Except
		Result.Status = 0;
		Result.Message = BriefErrorDescription(ErrorInfo());
		Return Undefined;
	EndTry;
	
	If WSDefinitions = Undefined Then
		Result.Status = 0;
		Result.Message = TextMessageServerIsNotAvaliable();
		Return Undefined;
	EndIf;
	
	Services = WSDefinitions.Services;
	If NOT Boolean(Services.Count()) Then
		Result.Status = 0;
		Result.Message = TextMessageServerIsNotAvaliable();
		Return Undefined;
	EndIf;	
	
	EInvoiceService = Services.Get(0);
	
	Endpoints = EInvoiceService.Endpoints;
	If NOT Boolean(Endpoints.Count()) Then
		Result.Status = 0;
		Result.Message = TextMessageServerIsNotAvaliable();
		Return Undefined;
	EndIf;
	
	EndPoint = Endpoints.Get(0);
		
	Return New WSProxy(WSDefinitions, EInvoiceService.NamespaceURI, EInvoiceService.Name, EndPoint.Name);
	
EndFunction

Function DataFromJSON(JSON) Export

	JSONReader = New JSONReader;
	JSONReader.SetString(JSON);
	Data = ReadJSON(JSONReader);
	JSONReader.Close();
	
	Return Data;

EndFunction // DataFromJSON()

Function DataToJSON(Data) Export

	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Data); 
	Return JSONWriter.Close();	

EndFunction // DataToJSON()

Function ObjectUUID(Object) Export
	Return String(Object.Ref.UUID());
EndFunction // ObjectUUID()

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

#EndRegion 

#Region ServiceProceduresAndFunctions

Function TableNameByRef(Ref)
	Return Ref.Metadata().FullName();
EndFunction

Function TextMessageServerIsNotAvaliable()
	Return NStr("en = 'Server is not available.'; ru = 'Сервер недоступен.'");
EndFunction // TextMessageServerIsNotAvaliable()
	
#EndRegion 

