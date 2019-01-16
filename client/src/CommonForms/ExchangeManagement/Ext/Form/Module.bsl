
&AtClient
Procedure RunExchange(Command)
	
	RunExchangeAtServer(DataBaseAddress);
	
EndProcedure

&AtServerNoContext
Procedure RunExchangeAtServer(DataBaseAddress)

	Result = ExchangeWithoutRules.ExecuteExchange(DataBaseAddress);
	Message(Result.Message);

EndProcedure // RunExchangeAtServer() 
