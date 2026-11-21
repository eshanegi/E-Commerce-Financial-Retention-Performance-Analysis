Attribute VB_Name = "Module3"
Sub AdjustColumns()
Attribute AdjustColumns.VB_ProcData.VB_Invoke_Func = " \n14"
'
' AdjustColumns Macro
'

'
    Columns("A:A").Select
    Range(Selection, Selection.End(xlToRight)).Select
    Columns("A:I").EntireColumn.AutoFit
    Range("A1").Select
End Sub
Sub DateTimeConcat()
Attribute DateTimeConcat.VB_ProcData.VB_Invoke_Func = " \n14"
'
' DateTimeConcat Macro
'

'
    Range("C1").Select
    Selection.EntireColumn.Insert , CopyOrigin:=xlFormatFromLeftOrAbove
    Range("B2").Select
    Range(Selection, Selection.End(xlDown)).Select
    Selection.TextToColumns Destination:=Range("B2"), DataType:=xlDelimited, _
        TextQualifier:=xlDoubleQuote, ConsecutiveDelimiter:=True, Tab:=True, _
        Semicolon:=False, Comma:=False, Space:=True, Other:=False, FieldInfo _
        :=Array(Array(1, 1), Array(2, 1), Array(3, 9)), TrailingMinusNumbers:=True
    Range("C1").Select
    ActiveCell.FormulaR1C1 = "Time"
    Range("B1").Select
    ActiveCell.FormulaR1C1 = "Date"
    Range("B2").Select
    Range(Selection, Selection.End(xlDown)).Select
    Selection.NumberFormat = "m/d/yyyy"
    Range("C2").Select
    Range(Selection, Selection.End(xlDown)).Select
    Selection.NumberFormat = "[$-x-systime]h:mm:ss AM/PM"
End Sub

Sub FormatingHeaders()
'
' FormatingHeaders Macro
' to Formate column headers
'

'
    Range("A1").Select
    Range(Selection, Selection.End(xlToRight)).Select
    Selection.Font.Bold = True
    With Selection.Interior
        .Pattern = xlSolid
        .PatternColorIndex = xlAutomatic
        .ThemeColor = xlThemeColorAccent1
        .TintAndShade = 0.399975585192419
        .PatternTintAndShade = 0
    End With
    With Selection.Font
        .ThemeColor = xlThemeColorDark1
        .TintAndShade = 0
    End With
    Range("A2").Select
End Sub


Public Sub LoopingMacros()
Dim ws As Worksheet
For Each ws In Worksheets
Worksheets(ws.Name).Select
    If ws.Name <> "Data Dictionary" Then
        AdjustColumns
        DateTimeConcat
        FormatingHeaders
    Else
        AdjustColumns
        FormatingHeaders
    End If
Next ws
End Sub


