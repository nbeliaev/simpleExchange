
Function ImportData(NodeId, NodeDescription, Data)
	Return ExchangeWithoutRules.ImportData(NodeId, NodeDescription, Data);
EndFunction

Function ExportData(NodeId)
	Return ExchangeWithoutRules.ExportData(NodeId);	
EndFunction
