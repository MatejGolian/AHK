#Requires AutoHotkey v2.0

Class FileDownload {
    
    CurrentSize := 0
    DestinationFile := ""
    DialogGUI := Object()
    DialogTitle := "File Download"
    DownloadSize := 0
    DownloadURL := ""
    PercentComplete := 0
    
    __New(DownloadURL, DestinationFile, DialogTitle := False) {
        This.DestinationFile := DestinationFile
        This.DownloadURL := DownloadURL
        If DialogTitle
        This.DialogTitle := DialogTitle
        This.DownloadSize := This.GetDownloadSize()
    }
    
    Cancel(*) {
        If This.DialogGUI Is GUI
        This.DialogGUI.Hide()
        ConfirmationDialog := MsgBox("Are you sure you want to cancel the download?", This.DialogTitle, 4)
        If ConfirmationDialog == "Yes"
        ExitApp
        If This.DialogGUI Is GUI
        This.DialogGUI.Show()
    }
    
    DestroyDialog() {
        If This.DialogGUI Is GUI {
            This.DialogGUI.Destroy()
            This.DialogGUI := Object()
        }
    }
    
    DisplayDialog() {
        This.DialogGUI := GUI(, This.DialogTitle)
        This.DialogGUI.OnEvent("Close", ObjBindMethod(This, "Cancel"))
        This.DialogGUI.OnEvent("Escape", ObjBindMethod(This, "Cancel"))
        This.DialogGUI.AddProgress("Section vDownloadProgress")
        This.DialogGUI.AddText("Section W100", "Downloaded")
        This.DialogGUI.AddText("W450 YS vDownloadRatio", "0 B of " . This.FormatSize(This.DownloadSize))
        This.DialogGUI.AddText("Section W100", "Speed")
        This.DialogGUI.AddText("W450 YS vDownloadSpeed", "0 B/s")
        This.DialogGUI.AddText("Section W100", "Time remaining")
        This.DialogGUI.AddText("W450 YS vTimeRemaining", "∞")
        This.DialogGUI.AddButton("Default Section XS", "Cancel").OnEvent("Click", ObjBindMethod(This, "Cancel"))
        This.DialogGUI.Show()
    }
    
    FormatSize(Size, DecimalPlaces := 2) {
        Units := ["B", "KB", "MB", "GB", "TB"]
        Index := 1
        While Size >= 1024 {
            Index++
            Size /= 1024
            If Index = 5
            Break
        }
        If Index = 2
        Size := Round(Size)
        Else
        If Index > 2 {
            Size := Round(Size, DecimalPlaces)
            If DecimalPlaces > 0
            While Substr(Size, -1) = "0"
            Size := SubStr(Size, 1, StrLen(Size) -1)
            If Substr(Size, -1) = "."
            Size .= "0"
        }
        Return Size . " " . Units[Index]
    }
    
    FormatTime(Seconds) {
        Time := 19990101
        Time := DateAdd(Time, Seconds, "Seconds")
        Hrs := Seconds // 3600
        Mins := FormatTime(Time, "m")
        Secs := FormatTime(Time, "s")
        Return Trim((Hrs = 0 ? "" : Hrs . " h ") . (Mins = 0 ? "" : Mins . " m ") . (Hrs = 0 And Mins = 0 ? Secs . " s" : (Secs = 0 ? "" : Secs . " s")))
    }
    
    GetCurrentSize() {
        PreviousSize := This.CurrentSize
        Try
        This.CurrentSize := FileGetSize(This.DestinationFile)
        Catch
        This.CurrentSize := PreviousSize
        Return This.CurrentSize
    }
    
    GetDownloadSize() {
        WHR := ComObject("WinHttp.WinHttpRequest.5.1")
        WHR.Open("HEAD", This.DownloadURL, True)
        WHR.Send()
        WHR.WaitForResponse()
        This.DownloadSize := WHR.GetResponseHeader("Content-Length")
        Return This.DownloadSize
    }
    
    Start() {
        This.CurrentSize := 0
        This.PercentComplete := 0
        If This.DownloadSize And This.DownloadSize > 0 {
            This.DisplayDialog()
            SetTimer ObjBindMethod(This, "UpdateStatus"), 200
        }
        Download This.DownloadURL, This.DestinationFile
        If This.DownloadSize And This.DownloadSize > 0 {
            SetTimer ObjBindMethod(This, "UpdateStatus"), 0
            This.DestroyDialog()
        }
        This.CurrentSize := This.GetCurrentSize()
        If This.CurrentSize = This.DownloadSize
        This.PercentComplete := 100
        ExitApp
    }
    
    UpdateStatus() {
        Static CurrentSizeTick := 0, DownloadSpeed := 0, FormattedDownloadSize := This.FormatSize(This.DownloadSize), FormattedTimeRemaining := "∞", PreviousSize := This.CurrentSize, PreviousSizeTick := 0
        TickCount := A_TickCount
        CurrentSizeTick := TickCount
        If PreviousSizeTick = 0
        PreviousSizeTick := TickCount
        This.CurrentSize := This.GetCurrentSize()
        FormattedCurrentSize := This.FormatSize(This.CurrentSize)
        If CurrentSizeTick = PreviousSizeTick {
            DownloadSpeed := This.CurrentSize
            FormatTimeRemaining()
        }
        Else
        If CurrentSizeTick >= PreviousSizeTick + 1000 {
            DownloadSpeed := This.CurrentSize - PreviousSize
            PreviousSize := This.CurrentSize
            PreviousSizeTick := CurrentSizeTick
            FormatTimeRemaining()
        }
        This.PercentComplete := Round(This.CurrentSize / This.DownloadSize * 100)
        FormattedSpeed := This.FormatSize(DownloadSpeed) . "/s"
        If This.DialogGUI Is GUI {
            This.DialogGUI["DownloadProgress"].Value := This.PercentComplete
            This.DialogGUI["DownloadRatio"].Value := FormattedCurrentSize . " of " . FormattedDownloadSize
            This.DialogGUI["DownloadSpeed"].Value := FormattedSpeed
            This.DialogGUI["TimeRemaining"].Value := FormattedTimeRemaining
        }
        FormatTimeRemaining() {
            If DownloadSpeed = 0
            FormattedTimeRemaining := "∞"
            Else
            FormattedTimeRemaining := This.FormatTime(Round(((This.DownloadSize - This.CurrentSize) * 8) / (DownloadSpeed * 8)))
        }
    }
    
}
