Function CompanyBeDefault() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	Companies.Ref AS Ref
		|FROM
		|	Catalog.Companies AS Companies";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Undefined;	
	EndIf; 
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	Return Selection.Ref;	

EndFunction // CompanyBeDefault()

 