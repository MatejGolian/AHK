#Requires AutoHotkey v2.0

Class FileDownload {
    
    CurrentSize := 0
    DestinationFile := ""
    DownloadSize := 0
    DownloadURL := ""
    Overwrite := True
    PercentComplete := 0
    ProgressBar := True
    ProgressBarGui := Object()
    Title := "File Download"
    
    __New(DownloadURL, DestinationFile, Overwrite := True, ProgressBar := True, Title := False) {
        This.DestinationFile := DestinationFile
        This.DownloadURL := DownloadURL
        This.Overwrite := Overwrite
        This.ProgressBar := ProgressBar
        If Title
        This.Title := Title
        This.DownloadSize := This.GetDownloadSize()
    }
    
    Cancel(*) {
        ExitApp
    }
    
    DestroyProgressBar() {
        If This.ProgressBarGui Is Gui {
            This.ProgressBarGui.Destroy()
            This.ProgressBarGui := Object()
        }
    }
    
    DisplayProgressBar() {
        This.ProgressBarGui := Gui(, This.Title)
        This.ProgressBarGui.AddProgress("Section vDownloadProgress")
        This.ProgressBarGui.AddText("XS vDownloadSpeed", "Speed: 0 Kb/s")
        This.ProgressBarGui.AddButton("Section XS", "Cancel").OnEvent("Click", ObjBindMethod(This, "Cancel"))
        This.ProgressBarGui.Show()
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
        If Not This.Overwrite And FileExist(This.DestinationFile) And Not InStr(FileExist(This.DestinationFile), "D")
        Return
        This.CurrentSize := 0
        This.PercentComplete := 0
        If This.ProgressBar
        This.DisplayProgressBar()
        SetTimer ObjBindMethod(This, "UpdateProgress"), 100
        Download This.DownloadURL, This.DestinationFile
        SetTimer ObjBindMethod(This, "UpdateProgress"), 0
        If This.ProgressBar
        This.DestroyProgressBar()
        This.CurrentSize := This.GetCurrentSize()
        If This.CurrentSize = This.DownloadSize
        This.PercentComplete := 100
        ExitApp
    }
    
    UpdateProgress() {
        Static CurrentSizeTick := 0, PreviousSizeTick := 0
        PreviousSize := This.CurrentSize
        This.CurrentSize := This.GetCurrentSize()
        CurrentSizeTick := A_TickCount
        DownloadSpeed := Round((This.CurrentSize / 1024 - PreviousSize / 1024) / ((CurrentSizeTick - PreviousSizeTick) / 1000)) . " Kb/s"
        PreviousSizeTick := CurrentSizeTick
        If This.DownloadSize And This.DownloadSize > 0
        This.PercentComplete := Round(This.CurrentSize / This.DownloadSize * 100)
        Try
        If This.ProgressBar And This.ProgressBarGui Is Gui {
            This.ProgressBarGui["DownloadProgress"].Value := This.PercentComplete
            This.ProgressBarGui["DownloadSpeed"].Value := "Speed: " . DownloadSpeed
        }
    }
    
}
