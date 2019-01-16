
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If ThisNode Then
		CheckedAttributes.Delete(CheckedAttributes.Find("Company"));	
	EndIf; 
	
EndProcedure
