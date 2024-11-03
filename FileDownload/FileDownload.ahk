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
        This.DialogGUI.AddText("Section", "Downloaded")
        This.DialogGUI.AddText("YS vCurrentSize", "0 B")
        This.DialogGUI.AddText("YS", "of")
        This.DialogGUI.AddText("YS", This.FormatSize(This.DownloadSize))
        This.DialogGUI.AddText("Section", "Speed:")
        This.DialogGUI.AddText("YS vDownloadSpeed", "0 B/s")
        This.DialogGUI.AddButton("Section XS", "Cancel").OnEvent("Click", ObjBindMethod(This, "Cancel"))
        This.DialogGUI.Show()
    }
    
    FormatSize(Size, DecimalPlaces := 2) {
        Units := ["KB", "MB", "GB", "TB"]
        Index := 0
        While Size >= 1024 {
            Index++
            Size /= 1024
            If Index = 4
            Break
        }
        If Index > 1 {
            Size := Round(Size, DecimalPlaces)
            While Substr(Size, -1) = "0"
            Size := Substr(Size, -1)
            If Substr(Size, -1) = "."
            Size .= "0"
        }
        Return (Index = 0 ? Size . " B" : (Index = 1 ? Size . " " . Units[Index] : Size . " " . Units[Index]))
    }
    
    GetCurrentSize() {
        PreviousSize := This.CurrentSize
        Try
        This.CurrentSize := FileGetSize(This.DestinationFile, "B")
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
            SetTimer ObjBindMethod(This, "UpdateStatus"), 250
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
        Static CurrentSizeTick := 0, PreviousSizeTick := 0
        PreviousSize := This.CurrentSize
        This.CurrentSize := This.GetCurrentSize()
        CurrentSizeTick := A_TickCount
        DownloadSpeed := This.FormatSize(Round((This.CurrentSize - PreviousSize) / ((CurrentSizeTick - PreviousSizeTick) / 1000)))
        PreviousSizeTick := CurrentSizeTick
        This.PercentComplete := Round(This.CurrentSize / This.DownloadSize * 100)
        If This.DialogGUI Is Gui {
            This.DialogGUI["DownloadProgress"].Value := This.PercentComplete
            This.DialogGUI["CurrentSize"].Value := This.FormatSize(This.CurrentSize)
            This.DialogGUI["DownloadSpeed"].Value := DownloadSpeed . "/s"
        }
    }
    
}
