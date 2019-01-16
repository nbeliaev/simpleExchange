#Region ApplicationInterface

Function ExchangeNodesByCompany(Company) Export

	Nodes = New Array;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	NoRull.Ref AS Ref
		|FROM
		|	ExchangePlan.NoRull AS NoRull
		|WHERE
		|	NOT NoRull.ThisNode
		|	AND NoRull.Company = &Company";
	
	Query.SetParameter("Company", Company);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	While Selection.Next() Do
		Nodes.Add(Selection.Ref);	
	EndDo;
	
	Return Nodes;	

EndFunction // ExchangeNodesByCompany()

Function FindCreateExchangeNodes(NodeSenderId, NodeSenderDescription) Export

	NeedFullExchange = False;
	
	NodeRecipient = ExchangePlans.NoRull.ThisNode();
	If IsBlankString(NodeRecipient.Code) Then
		
		NodeObject = NodeRecipient.GetObject();
		NodeObject.Code = "01";
		NodeObject.Description = NStr("en = 'Main'; ru = 'Центральный'");
		NodeObject.Write();		
	
	EndIf; 
	
	NodeSender = ExchangePlans.NoRull.FindByCode(NodeSenderId);
	If NodeSender.IsEmpty() Then
	
		NodeObject = ExchangePlans.NoRull.CreateNode();
		NodeObject.Code = NodeSenderId;
		NodeObject.Description = NodeSenderDescription;
		NodeObject.Company = Catalogs.Companies.CompanyBeDefault();
		NodeObject.Write();
		
		NodeSender = NodeObject.Ref;
		
		NeedFullExchange = True;
	
	EndIf; 
	
	Return New Structure("Sender, Recipient, NeedFullExchange", NodeSender, NodeRecipient, NeedFullExchange);

EndFunction // FindNodeRecipient()

Procedure ObjectsRegistrationForFullExchange(Node) Export

	ExchangePlans.RecordChanges(Node, Metadata.Catalogs.Counterparties);
	ExchangePlans.RecordChanges(Node, Metadata.Catalogs.Products);
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	NoRull.Company AS Company
		|INTO Compamy
		|FROM
		|	ExchangePlan.NoRull AS NoRull
		|WHERE
		|	NoRull.Ref = &Node
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SupplierInvoice.Ref AS Ref
		|FROM
		|	Document.SupplierInvoice AS SupplierInvoice
		|		INNER JOIN Compamy AS Compamy
		|		ON SupplierInvoice.Company = Compamy.Company";
	
	Query.SetParameter("Node", Node.Company);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		ExchangePlans.RecordChanges(Node, Selection.Ref);
	EndDo;
	
EndProcedure
 
#EndRegion 