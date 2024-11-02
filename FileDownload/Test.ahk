#Requires AutoHotkey v2.0

#Include FileDownload.ahk

TestDownload := FileDownload("http://download.documentfoundation.org/libreoffice/stable/24.8.2/win/x86_64/LibreOffice_24.8.2_Win_x86-64.msi", "LibreOffice_24.8.2_Win_x86-64.msi")
TestDownload.Start()
