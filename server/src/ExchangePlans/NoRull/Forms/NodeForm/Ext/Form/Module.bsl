
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Items.Company.Visible = Not Object.ThisNode;
EndProcedure
