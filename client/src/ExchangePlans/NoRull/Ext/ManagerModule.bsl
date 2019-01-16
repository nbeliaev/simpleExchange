#Region ApplicationInterface

Function FindCreateExchangeNodes() Export

	SystemInfo = New SystemInfo;
	
	NodeSender = ExchangePlans.NoRull.ThisNode();
	If IsBlankString(NodeSender.Code) Then
		
		NodeObject = NodeSender.GetObject();
		NodeObject.Code = SystemInfo.ClientID;
		NodeObject.Description = SystemInfo.OSVersion;
		NodeObject.Write();	
		
	EndIf; 
	
	NodeRecipient = ExchangePlans.NoRull.FindByCode("01");
	If NodeRecipient.IsEmpty() Then
		
		NodeObject = ExchangePlans.NoRull.CreateNode();
		NodeObject.Code = "01";
		NodeObject.Description = NStr("en = 'Main'; ru = 'Центральный'");
		NodeObject.Write();
		
		NodeRecipient = NodeObject.Ref;
		
	EndIf;
	
	Return New Structure("Sender, Recipient", NodeSender, NodeRecipient);

EndFunction // FindCreateExchangeNodes()
	
#EndRegion 


 

 