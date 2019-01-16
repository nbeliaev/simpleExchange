
#Region ImportData

Function ImportData(SenderNodeId, SenderNodeDescription, Data) Export

	Nodes = ExchangePlans.NoRull.FindCreateExchangeNodes(SenderNodeId, SenderNodeDescription); 
	
	If Nodes.NeedFullExchange Then
		ExchangePlans.NoRull.ObjectsRegistrationForFullExchange(Nodes.Sender);
	EndIf; 
	
	Response = InitResponseResult();

	Data = CommonUse.Base64ValueToString(Data);
	
	XMLReader = New XMLReader;
	XMLReader.SetString(Data);
	ReadingMessage = ExchangePlans.CreateMessageReader();
	Try
		ReadingMessage.BeginRead(XMLReader, AllowedMessageNo.Greater);	
	Except
		Response.Status  = 0;
		Response.Message = BriefErrorDescription(ErrorInfo());
		Return CommonUse.DataToJSON(Response);
	EndTry;
		
	ExchangePlans.DeleteChangeRecords(ReadingMessage.Sender, ReadingMessage.ReceivedNo);
	
	NewObjects = XDTOFactory.ReadXML(XMLReader);
	XDTOObjects = XDTOObjectsToArray(NewObjects, "Object");	
	For Each XDTOObject In XDTOObjects Do
		
		If XDTOObject.Type().Name = "SupplierInvoice" Then
			FindCreateSupplierInvoice(XDTOObject, ReadingMessage.Sender); 	
		Else
			// unknown type
			Continue;
		EndIf;
	
	EndDo; 
		
	ReadingMessage.EndRead(); 
	XMLReader.Close();
	
	Return CommonUse.DataToJSON(Response);

EndFunction

Function FindCreateSupplierInvoice(XDTOSupplierInvoice, SenderNode)
	
	SupplierInvoice = Documents.SupplierInvoice.GetRef(New UUID(XDTOSupplierInvoice.Id));
	If Not CommonUse.IsRefExist(SupplierInvoice) Then
		SupplierInvoiceObject = Documents.SupplierInvoice.CreateDocument();
		SupplierInvoiceObject.SetNewObjectRef(SupplierInvoice);
		SupplierInvoiceObject.Company = SenderNode.Company;
	Else
		SupplierInvoiceObject = SupplierInvoice.GetObject();
		SupplierInvoiceObject.Inventory.Clear();
	EndIf; 
	
	FillPropertyValues(SupplierInvoiceObject, XDTOSupplierInvoice, "Date,Number");
	
	SupplierInvoiceObject.Counterparty = Catalogs.Counterparties.GetRef(New UUID(XDTOSupplierInvoice.Counterparty));
	
	XDTOInventory = XDTOObjectsToArray(XDTOSupplierInvoice.Inventory, "InventoryItem");
	For Each XDTOInventoryItem In XDTOInventory Do
	
		Item = SupplierInvoiceObject.Inventory.Add();
		Item.Product = Catalogs.Products.GetRef(New UUID(XDTOInventoryItem.Product));
		Item.Quantity = XDTOInventoryItem.Quantity;
	
	EndDo; 
	
	SupplierInvoiceObject.DataExchange.Sender = SenderNode;
	SupplierInvoiceObject.DataExchange.Load = True;
	
	SupplierInvoiceObject.Write();
	
	If SupplierInvoiceObject.DeletionMark <> XDTOSupplierInvoice.DeletionMark Then
		SupplierInvoiceObject.SetDeletionMark(XDTOSupplierInvoice.DeletionMark);
	EndIf; 

	Return SupplierInvoiceObject.Ref;

EndFunction // FindCreateSupplierInvoice()	
	
#EndRegion 

#Region ExportData

Function ExportData(NodeId) Export
	
	Response = InitResponseResult();
	
	NodeRecipient = ExchangePlans.NoRull.FindByCode(NodeId);
	
	XDTOTypeObjects = XDTOFactory.Type(URI(), "Objects");
	XDTOTypeObject  = XDTOTypeObjects.Properties.Get("Object").Type;
	XDTOTypeSupplierInvoice = XDTOFactory.Type(URI(), "SupplierInvoice");
	
	XDTOObjects = XDTOFactory.Create(XDTOTypeObjects);	

	RecordOfMessage = ExchangePlans.CreateMessageWriter();
	Record = New XMLWriter;
	Record.SetString("UTF-8");
	RecordOfMessage.BeginWrite(Record, NodeRecipient);
		
	Selection = ExchangePlans.SelectChanges(RecordOfMessage.Recipient, RecordOfMessage.MessageNo);
	While Selection.Next() Do
		
		Object = Selection.Get();
		
		If TypeOf(Object) = Type("CatalogObject.Counterparties") Then
			XDTOObject = XDTOCounterparty(Object);		
		ElsIf TypeOf(Object) = Type("CatalogObject.Products") Then
			XDTOObject = XDTOProduct(Object);	
		ElsIf TypeOf(Object) = Type("DocumentObject.SupplierInvoice") Then
			XDTOObject = XDTOSupplierInvoice(Object);	
		Else
			// unknown type
			Continue;		   
		EndIf; 
		
		XDTOObjects.Object.Add(XDTOObject);
		
	EndDo;
	
	XDTOFactory.WriteXML(Record, XDTOObjects);
	
	RecordOfMessage.EndWrite();
	ExchangeData = Record.Close();
	
	Data = CommonUse.StringToBase64String(ExchangeData);	
	
	Response.Data = Data;
	
	Return CommonUse.DataToJSON(Response);

EndFunction

Function XDTOCounterparty(Object)

	XDTOType = XDTOType("Counterparty");
	XDTOObject = XDTOFactory.Create(XDTOType);
	XDTOObject.Id = CommonUse.ObjectUUID(Object);
	XDTOObject.DeletionMark = Object.DeletionMark;
	XDTOObject.Description = Object.Description;
	
	Return XDTOObject;

EndFunction // XDTOCounterparty()

Function XDTOProduct(Object)

	XDTOType = XDTOType("Product");
	XDTOObject = XDTOFactory.Create(XDTOType);
	XDTOObject.Id = CommonUse.ObjectUUID(Object);
	XDTOObject.DeletionMark = Object.DeletionMark;
	XDTOObject.Description = Object.Description;
	XDTOObject.SKU = Object.SKU;
	
	Return XDTOObject;

EndFunction // XDTOProduct()

Function XDTOSupplierInvoice(Object)

	XDTOType = XDTOType("SupplierInvoice");
	XDTOObject = XDTOFactory.Create(XDTOType);
	XDTOObject.Id = CommonUse.ObjectUUID(Object);
	XDTOObject.DeletionMark = Object.DeletionMark;
	XDTOObject.Number = Object.Number;
	XDTOObject.Date = Object.Date;
	XDTOObject.Counterparty = CommonUse.ObjectUUID(Object.Counterparty);
	
	XDTOTypeInventory = XDTOType.Properties.Get("Inventory").Type;
	XDTOTypeInventoryItem = XDTOTypeInventory.Properties.Get("InventoryItem").Type;
	
	XDTOInventory = XDTOFactory.Create(XDTOTypeInventory);
	For Each InventoryItem In Object.Inventory Do
		
		XDTOInventoryItem = XDTOFactory.Create(XDTOTypeInventoryItem);
		XDTOInventoryItem.Product = CommonUse.ObjectUUID(InventoryItem.Product);
		XDTOInventoryItem.Quantity = InventoryItem.Quantity;
		
		XDTOInventory.InventoryItem.Add(XDTOInventoryItem);
	
	EndDo; 
	
	XDTOObject.Inventory = XDTOInventory;
	
	Return XDTOObject;

EndFunction // XDTOSupplierInvoice()

#EndRegion 

#Region EventHandlers

Procedure OnWriteDocument(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;	
	EndIf; 
	
	Nodes = ExchangePlans.NoRull.ExchangeNodesByCompany(Source.Company);
	If Nodes.Count() > 0 Then
		ExchangePlans.RecordChanges(Nodes, Source.Ref);	
	EndIf; 
	
EndProcedure

Procedure OnWriteCatalog(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;	
	EndIf; 
	
	Nodes = ExchangePlans.NoRull.ExchangeNodesByCompany(Source.Ref);
	If Nodes.Count() > 0 Then
		ExchangePlans.RecordChanges(Nodes, Source.Ref);	
	EndIf; 
	
EndProcedure
	
#EndRegion 

#Region ServiceProceduresAndFunctions

Function InitResponseResult()
	Return New Structure("Status, Message, Data", 1, "", "");
EndFunction 

Function URI()
	Return "http://norull.com"; 
EndFunction // URI()

Function XDTOType(TypeName)
	Return XDTOFactory.Type(URI(), TypeName);
EndFunction // XDTOType()
 
Function XDTOObjectsToArray(Objects, Name)

	XDTOObjects = New Array;
	If Objects.Properties().Get(Name) = Undefined Then
		Return XDTOObjects;	
	EndIf; 
	
	If TypeOf(Objects[Name]) = Type("XDTOList") Then
		For Each Object In Objects[Name] Do
			XDTOObjects.Add(Object);		
		EndDo; 
	Else
		XDTOObjects.Add(Objects[Name]);	
	EndIf;
	
	Return XDTOObjects;
	
EndFunction // XDTOObjectsToArray()
	
#EndRegion 


 
