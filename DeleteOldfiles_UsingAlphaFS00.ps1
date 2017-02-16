#----------------------------------------------------------------
#Please fill the parameters
# Koldo Santisteban 2017
# This script delete files based on date criteria and write output file in the correspond Directory
# allowing end users to know it
#----------------------------------------------------------------
$path =  "\\server\share"
#$path =  "c:\logs"
#$extensions = '\.doc|\.xls|\.txt|\.bat|\.log'
$extensions = '\.*'
$TestMode = $False
$DeleteBasedOnCreationTime = $True #False will use ModificationTime
$Daysback = "-6"
$DeleteFolders = $True

#https://github.com/alphaleonis/AlphaFS
Import-Module '--LOCAL PATH--\Lib\Net40\AlphaFS.dll'


$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)
$DateTime = Get-Date -Format "Ddd-MM-yyyy_THH-mm"

$FileExists = Test-Path $path 
    If ($FileExists -eq $False)  
    { 
        Write-host "Provided path is not correct, please check it!!" 
        Exit
    } 
   


$dirEnumOptions = [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::Recursive -bor
                  [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::SkipReparsePoints -bor
                  [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::Files -bor
                  [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::LargeCache -bor
                  [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::ContinueOnException


$dirs = [Alphaleonis.Win32.Filesystem.Directory]::EnumerateFiles($Path,$dirEnumOptions)
$fsei = $dirs | Foreach-Object { [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo($_) }

if ($DeleteBasedOnCreationTime)
{
    if ($DeleteFolders)
        {$result = $fsei| Where-Object {$_.CreationTime -lt $DatetoDelete -and $_.FileName.Substring($_.FileName.Length - 5) -match $extensions}}
    else
        {$result = $fsei| Where-Object {$_.CreationTime -lt $DatetoDelete -and $_.FileName.Substring($_.FileName.Length - 5) -match $extensions -and $_.FileName -notmatch "Deleted-"} }
}
else
{
    if ($DeleteFolders)
        {$result = $fsei| Where-Object {$_.LastWriteTime -lt $DatetoDelete -and $_.FileName.Substring($_.FileName.Length - 5) -match $extensions} }
    else
        {$result = $fsei| Where-Object {$_.LastWriteTime -lt $DatetoDelete -and $_.FileName.Substring($_.FileName.Length - 5) -match $extensions -and $_.FileName -notmatch "Deleted-"}}

    
}





$result | Foreach-Object  { 
                                    $LogDir = $_.FullPath.Substring(0,$_.FullPath.Length - $_.FileName.Length)
                                    $FileDeletedName = "FileName: "  + $_.FileName +"|" + " Size: " + $_.FileSize +"|" + " CreationTime: " + $_.CreationTime +"|" + " ModifiedTime: " + $_.LastWriteTime
                                    if ($_.FileName -notmatch "Deleted-*")
                                    { 
                                     $FileDeletedName >> $LogDir"Deleted-$DateTime.txt"
                                     Write-host $_.FullPath  $_.LastWriteTime  $DatetoDelete ($_.LastWriteTime -lt $DatetoDelete) ($_.FileName.Substring($_.FileName.Length - 5) -match $extensions)  }
                             
                            } 
if (!$TestMode)
    {$result | Foreach-Object {[Alphaleonis.Win32.Filesystem.File]::Delete($_.LongFullPath,$true)}}

if ($DeleteFolders -And !$TestMode)
    {

        #http://alphafs.alphaleonis.com/doc/2.0/api/html/6354F8EE.htm    
        $dirEnumOptions = [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::Recursive -bor
                  [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::SkipReparsePoints -bor
                  [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::Folders -bor
                  [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::LargeCache -bor
                  [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::AsLongPath -bor
                  [Alphaleonis.Win32.Filesystem.DirectoryEnumerationOptions]::ContinueOnException

        #http://alphafs.alphaleonis.com/doc/2.0/api/html/1CA004B1.htm
        $dirs = [Alphaleonis.Win32.Filesystem.Directory]::EnumerateDirectories($Path,$dirEnumOptions)
        
        #http://alphafs.alphaleonis.com/doc/2.0/api/html/E2BA4648.htm
        $dirs  | Foreach-Object {  [Alphaleonis.Win32.Filesystem.Directory]::DeleteEmptySubdirectories($_,$false, $false,[Alphaleonis.Win32.Filesystem.PathFormat]::FullPath) }
    }

