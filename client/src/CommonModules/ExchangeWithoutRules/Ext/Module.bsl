
#Region ApplicationInterface

Function ExecuteExchange(DataBaseAddress) Export

	ExchangeResult = InitResponseResult();
	
	Proxy = CommonUse.WebServiceProxy(DataBaseAddress, ExchangeResult);
	If Proxy = Undefined Then
		Return ExchangeResult;	
	EndIf; 
	
	Result = ExportData(Proxy);
	If Result.Status = 0 Then
		ExchangeResult.Status = 0;
		ExchangeResult.Message = Result.Message;
		Return ExchangeResult;
	EndIf; 
	
	Result = ImportData(Proxy);
	If Result.Status = 0 Then
		ExchangeResult.Status = 0;
		ExchangeResult.Message = Result.Message;
		Return ExchangeResult;
	EndIf; 
	
	ExchangeResult.Message = NStr("en = 'The exchange was successful.'; ru = 'Обмен выполнен успешно.'");
	Return ExchangeResult

EndFunction
	
#EndRegion 

#Region ImportData

Function ImportData(Proxy)

	NodeId = ExchangePlans.NoRull.ThisNode().Code;
	Response = Proxy.ExportData(NodeId);
	Result = CommonUse.DataFromJSON(Response);
	If Result.Status = 0 Then
		Return Result;
	EndIf; 
	
	Response = InitResponseResult();

	Data = CommonUse.Base64ValueToString(Result.Data);
	
	XMLReader = New XMLReader;
	XMLReader.SetString(Data);
	ReadingMessage = ExchangePlans.CreateMessageReader();
	Try
		ReadingMessage.BeginRead(XMLReader, AllowedMessageNo.Greater);	
	Except
		Response.Status  = 0;
		Response.Message = BriefErrorDescription(ErrorInfo());
		Return Response;
	EndTry;
		
	ExchangePlans.DeleteChangeRecords(ReadingMessage.Sender, ReadingMessage.ReceivedNo);

	NewObjects = Proxy.XDTOFactory.ReadXML(XMLReader);
	XDTOObjects = XDTOObjectsToArray(NewObjects, "Object");	
	For Each XDTOObject In XDTOObjects Do
		
		If XDTOObject.Type().Name = "Counterparty" Then
			FindCreateCounterparty(XDTOObject, ReadingMessage.Sender);	
		ElsIf XDTOObject.Type().Name = "Product" Then
			FindCreateProduct(XDTOObject, ReadingMessage.Sender);	
		ElsIf XDTOObject.Type().Name = "SupplierInvoice" Then
			FindCreateSupplierInvoice(XDTOObject, ReadingMessage.Sender); 	
		Else
			// unknown type
			Continue;
		EndIf;
	
	EndDo; 
	
	ReadingMessage.EndRead(); 
	XMLReader.Close();
	
	Return Response;

EndFunction

Function FindCreateCounterparty(XDTOCounterparty, SenderNode)

	Counterparty = Catalogs.Counterparties.GetRef(New UUID(XDTOCounterparty.Id));
	If Not CommonUse.IsRefExist(Counterparty) Then
		CounterpartyObject = Catalogs.Counterparties.CreateItem();
		CounterpartyObject.SetNewObjectRef(Counterparty);
	Else
		CounterpartyObject = Counterparty.GetObject();	
	EndIf; 
	
	FillPropertyValues(CounterpartyObject, XDTOCounterparty,,"DeletionMark");
	
	CounterpartyObject.DataExchange.Sender = SenderNode;
	CounterpartyObject.DataExchange.Load = True;
	
	CounterpartyObject.Write();
	
	If CounterpartyObject.DeletionMark <> XDTOCounterparty.DeletionMark Then
		CounterpartyObject.SetDeletionMark(XDTOCounterparty.DeletionMark);	
	EndIf; 

	Return CounterpartyObject.Ref;

EndFunction // FindCreateCounterparty()

Function FindCreateProduct(XDTOProduct, SenderNode)

	Product = Catalogs.Products.GetRef(New UUID(XDTOProduct.Id));
	If Not CommonUse.IsRefExist(Product) Then
		ProductObject = Catalogs.Products.CreateItem();
		ProductObject.SetNewObjectRef(Product);
	Else
		ProductObject = Product.GetObject();	
	EndIf; 
	
	FillPropertyValues(ProductObject, XDTOProduct,,"DeletionMark");
	
	ProductObject.DataExchange.Sender = SenderNode;
	ProductObject.DataExchange.Load = True;
	
	ProductObject.Write();
	
	If ProductObject.DeletionMark <> XDTOProduct.DeletionMark Then
		ProductObject.SetDeletionMark(XDTOProduct.DeletionMark);		
	EndIf; 

	Return ProductObject.Ref;

EndFunction // FindCreateProduct()

Function FindCreateSupplierInvoice(XDTOSupplierInvoice, SenderNode)
	
	SupplierInvoice = Documents.SupplierInvoice.GetRef(New UUID(XDTOSupplierInvoice.Id));
	If Not CommonUse.IsRefExist(SupplierInvoice) Then
		SupplierInvoiceObject = Documents.SupplierInvoice.CreateDocument();
		SupplierInvoiceObject.SetNewObjectRef(SupplierInvoice);
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

Function ExportData(Proxy)
	
	Nodes = ExchangePlans.NoRull.FindCreateExchangeNodes();
	
	XDTOTypeObjects = Proxy.XDTOFactory.Type(URI(), "Objects");
	XDTOTypeObject  = XDTOTypeObjects.Properties.Get("Object").Type;
	XDTOTypeSupplierInvoice = Proxy.XDTOFactory.Type(URI(), "SupplierInvoice");
	
	XDTOObjects = Proxy.XDTOFactory.Create(XDTOTypeObjects);	

	RecordOfMessage = ExchangePlans.CreateMessageWriter();
	Record = New XMLWriter;
	Record.SetString("UTF-8");
	RecordOfMessage.BeginWrite(Record, Nodes.Recipient);
	
	Selection = ExchangePlans.SelectChanges(RecordOfMessage.Recipient, RecordOfMessage.MessageNo);
	While Selection.Next() Do
		
		Object = Selection.Get();
		If TypeOf(Object) = Type("DocumentObject.SupplierInvoice") Then
			XDTOObject = XDTOSupplierInvoice(Object, Proxy);
		Else
			// unknown type
			Continue;		
		EndIf; 
		
		XDTOObjects.Object.Add(XDTOObject);
		
	EndDo;
	
	Proxy.XDTOFactory.WriteXML(Record, XDTOObjects);
	
	RecordOfMessage.EndWrite();
	ExchangeData = Record.Close();
	
	Data = CommonUse.StringToBase64String(ExchangeData);
	
	Response = Proxy.ImportData(
		Nodes.Sender.Code, 
		Nodes.Sender.Description, 
		Data);
		
	Return CommonUse.DataFromJSON(Response);

EndFunction

Function XDTOSupplierInvoice(Object, Proxy)

	XDTOType = XDTOType("SupplierInvoice", Proxy);
	XDTOObject = Proxy.XDTOFactory.Create(XDTOType);
	XDTOObject.Id = CommonUse.ObjectUUID(Object);
	XDTOObject.DeletionMark = Object.DeletionMark;
	XDTOObject.Number = Object.Number;
	XDTOObject.Date = Object.Date;
	XDTOObject.Counterparty = CommonUse.ObjectUUID(Object.Counterparty);
	
	XDTOTypeInventory = XDTOType.Properties.Get("Inventory").Type;
	XDTOTypeInventoryItem = XDTOTypeInventory.Properties.Get("InventoryItem").Type;
	
	XDTOInventory = Proxy.XDTOFactory.Create(XDTOTypeInventory);
	For Each InventoryItem In Object.Inventory Do
		
		XDTOInventoryItem = Proxy.XDTOFactory.Create(XDTOTypeInventoryItem);
		XDTOInventoryItem.Product = CommonUse.ObjectUUID(InventoryItem.Product);
		XDTOInventoryItem.Quantity = InventoryItem.Quantity;
		
		XDTOInventory.InventoryItem.Add(XDTOInventoryItem);
	
	EndDo; 
	
	XDTOObject.Inventory = XDTOInventory;
	
	Return XDTOObject;

EndFunction // XDTOSupplierInvoice()

#EndRegion 

#Region ServiceProceduresAndFunctions

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
	
Function XDTOType(TypeName, Proxy)
	Return Proxy.XDTOFactory.Type(URI(), TypeName);
EndFunction // XDTOType()

Function URI()
	Return "http://norull.com"; 
EndFunction // URI()

Function InitResponseResult()
	Return New Structure("Status, Message, Data", 1, "", "");
EndFunction 
	
#EndRegion 
 
 
