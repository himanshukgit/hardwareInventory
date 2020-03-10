<#
browse report on browser

for local
.\Get-Server_Inventory.ps1 -ComputerName localhost -Nomail


for other server than local add $credetial and replace code (-ComputerName $computername) with (-ComputerName $computername -Credential $Credential) 
.\Get-Server_Inventory.ps1 -ComputerName servername -Credential $Credential -Nomail


send report on email (comment out and fillup your details in email section)
.\Get-Server_Inventory.ps1 -ComputerName localhost 

$c = Get-Credential
Get-WmiObject Win32_DiskDrive -ComputerName $env:computername -Credential $c
#>

[CmdletBinding()]

    Param(
    [string[]]$ComputerName=$env:COMPUTERNAME,
    [System.Management.Automation.PSCredential]$Credential,
    [switch]$Nomail,
    $Outfile ="$env:temp\out.html",
    $EmailTo="$env:USERNAME@yourcompany.com"

    )
  

function Get-Information {

param($computername)

$osx = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computername
$csx =Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computername
$bios =Get-WmiObject -Class Win32_BIOS -ComputerName $computername
$disk=Get-WmiObject -Class Win32_DiskDrive -ComputerName $computername

$properties = [ordered]@{
‘RegisteredUser’=$osx.RegisteredUser
'SystemDirectory'=$osx.SystemDirectory
'SerialNumber'=$osx.SerialNumber
‘OS Version’=$osx.version
‘OS Build’=$osx.buildnumber
‘RAM’=$csx.totalphysicalmemory
‘Processors’=$csx.numberofprocessors
‘BIOS Serial’=$bios.serialnumber 
'Partitions'=$disk.Partitions
'DeviceID'=$disk.DeviceID
'Model'=$disk.Model
'Size'=$disk.Size
'Caption'=$disk.Caption
}

$singleserver = New-Object -TypeName PSObject -Property $properties
echo $singleserver

}


$maintable = Get-Information –ComputerName $ComputerName | ConvertTo-Html -As LIST -Fragment -PreContent "<h2>$($ComputerName) Info</h2>"| Out-String

$subtable = Get-WmiObject -Class Win32_LogicalDisk -Filter ‘DriveType=3’ -ComputerName $ComputerName | Select DeviceID, 
@{l="Freespace in MB";e={[math]::round($_.FreeSpace/1024/1024, 0)} },
@{l="Size in MB";e={[math]::round($_.FreeSpace/1024/1024, 0)} } | ConvertTo-Html -Fragment -PreContent ‘<h2>Disk Info</h2>’ | Out-String

$head=@'
<style>
@charset "UTF-8";

table
{
font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;
border-collapse:collapse;
}
td
{
font-size:1em;
border:1px solid #98bf21;
padding:5px 5px 5px 5px;
}
th
{
font-size:1.1em;
text-align:center;
padding-top:5px;
padding-bottom:5px;
padding-right:7px;
padding-left:7px;
background-color:#A7C942;
color:#ffffff;
}
name tr
{
color:#F00000;
background-color:#EAF2D3;
}
</style>
'@

$report=ConvertTo-HTML -head $head -PostContent $maintable,$subtable -PreContent “<h1>Inventory on $($ComputerName)</h1>”


    if ($nomail)
    {
        [System.IO.File]::Delete($Outfile)
        $report| Out-File -FilePath $Outfile
        Invoke-Expression -Command $Outfile
    }
    else
    {
    <#
        $From = "d87c09e4a2-90269b@inbox.mailtrap.io"
        $To = $EmailTo
        $CC="abc@gmail.com"
        $Subject = "Photos of Drogon"
        $Body = "<h2>Guys, look at these pics of Drogon!</h2><br><br>"
        $Body += “He is so cute!” 
        $SMTPServer = "smtp.mailtrap.io"
        $SMTPPort = "587"
        $Attachment=$Outfile
        Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -Port $SMTPPort -UseSsl  -Attachments $Attachment -Credential (Get-Credential)
    #>
    }

    

