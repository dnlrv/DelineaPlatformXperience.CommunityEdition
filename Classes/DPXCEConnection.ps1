# class to hold DPXCEConnections
[NoRunspaceAffinity()]
class DPXCEConnection
{
    [System.String]$Url
    [PSCustomObject]$DPXCEConnection
    [System.Collections.Hashtable]$DPXCESessionInformation

    DPXCEConnection($u,$ssc,$ss)
    {
        $this.Url = $u
        $this.DPXCEConnection = $ssc
        $this.DPXCESessionInformation = $ss
    }
}# class DPXCEConnection