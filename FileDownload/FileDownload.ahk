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
        ExitApp
    }
    
    DestroyDialog() {
        If This.DialogGUI Is Gui {
            This.DialogGUI.Destroy()
            This.DialogGUI := Object()
        }
    }
    
    DisplayDialog() {
        This.DialogGUI := Gui(, This.DialogTitle)
        This.DialogGUI.AddProgress("Section vDownloadProgress")
        This.DialogGUI.AddText("Section XS", "Speed:")
        This.DialogGUI.AddText("XS vDownloadSpeed", "0 B/s")
        This.DialogGUI.AddButton("Section XS", "Cancel").OnEvent("Click", ObjBindMethod(This, "Cancel"))
        This.DialogGUI.Show()
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
        If This.DownloadSize And This.DownloadSize > 0 {
            This.CurrentSize := 0
            This.PercentComplete := 0
            This.DisplayDialog()
            SetTimer ObjBindMethod(This, "UpdateDialog"), 250
            Download This.DownloadURL, This.DestinationFile
            SetTimer ObjBindMethod(This, "UpdateDialog"), 0
            This.DestroyDialog()
            This.CurrentSize := This.GetCurrentSize()
            If This.CurrentSize = This.DownloadSize
            This.PercentComplete := 100
        }
        ExitApp
    }
    
    UpdateDialog() {
        Critical
        Static CurrentSizeTick := 0, PreviousSizeTick := 0
        PreviousSize := This.CurrentSize
        This.CurrentSize := This.GetCurrentSize()
        CurrentSizeTick := A_TickCount
        DownloadSpeed := AutoByteFormat((This.CurrentSize - PreviousSize) / ((CurrentSizeTick - PreviousSizeTick) / 1000)) . "/s"
        PreviousSizeTick := CurrentSizeTick
        This.PercentComplete := Round(This.CurrentSize / This.DownloadSize * 100)
        Try
        If This.DialogGUI Is Gui {
            This.DialogGUI["DownloadProgress"].Value := This.PercentComplete
            This.DialogGUI["DownloadSpeed"].Value := DownloadSpeed
        }
        AutoByteFormat(Size, DecimalPlaces := 2) {
            Static Size1 := "KB", Size2 := "MB", Size3 := "GB", Size4 := "TB"
            SizeIndex := 0
            While Size >= 1024 {
                SizeIndex++
                Size /= 1024.0
                If SizeIndex = 4
                Break
            }
            Return (SizeIndex = 0) ? Size " byte" . (Size != 1 ? "s" : "") : round(Size, DecimalPlaces) . " " . Size%SizeIndex%
        }
    }
    
}
