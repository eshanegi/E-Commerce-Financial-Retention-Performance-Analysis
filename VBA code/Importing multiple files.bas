Attribute VB_Name = "Module1"

Public Sub ImportingFiles()
Dim Files As Workbook
Dim OpenFiles() As Variant
Dim i As Integer


    OpenFiles = Application.GetOpenFilename(Title:="Select file(s) to import.", MultiSelect:=True)
    
    Application.ScreenUpdating = False
    
    For i = 1 To Application.CountA(OpenFiles)
    
        Set Files = Workbooks.Open(OpenFiles(i))
        Files.Sheets(1).Range("A1").CurrentRegion.Copy
        
        Workbooks(1).Activate
        
        Workbooks(1).Worksheets.Add
        ActiveSheet.Range("A1").Select
        ActiveSheet.Paste
        
        Application.CutCopyMode = False
        
        Files.Close
    
    Next i
    
    Application.ScreenUpdating = True
    
End Sub
