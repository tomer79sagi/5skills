Option Explicit
Dim objIEA
Set objIEA = CreateObject("InternetExplorer.Application")
objIEA.Navigate "http://www.jobby.co.nz:3000/"
While objIEA.Busy
Wend
objIEA.Quit
Set objIEA = Nothing