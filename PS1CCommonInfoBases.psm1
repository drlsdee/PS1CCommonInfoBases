[string]$myName = "$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.ScriptName)):"
[string]$classesPath = "$($PSScriptRoot)\Classes\"
[string]$functionsPathPublic = "$($PSScriptRoot)\Functions\Public\"
[string]$functionsPathPrivate = "$($PSScriptRoot)\Functions\Private\"
# Importing classes
if ([System.IO.Directory]::Exists($classesPath))
{
    Write-Verbose -Message "$myName Folder with custom PS classes found: $classesPath"
    [string[]]$psClasses = [System.IO.Directory]::EnumerateFiles($classesPath, '*.ps1', 'AllDirectories')
    if ($psClasses.Count -eq 0)
    {
        Write-Verbose -Message "$myName Folder DOES NOT CONTAIN custom PS classes: $classesPath"
    }
    else
    {
        $psClasses.ForEach({
            Write-Verbose -Message "$myName Importing custom PS class ffom file: $_"
            . $_
        })
    }
}

# Enumerating functions, both public and private
if ([System.IO.Directory]::Exists($functionsPathPrivate))
{
    Write-Verbose -Message "$myName Folder with private functions found: $functionsPathPrivate"
    [string[]]$psFuncPrivate = [System.IO.Directory]::EnumerateFiles($functionsPathPrivate, '*.ps1')
}
if ([System.IO.Directory]::Exists($functionsPathPublic))
{
    Write-Verbose -Message "$myName Folder with private functions found: $functionsPathPublic"
    [string[]]$psFuncPublic = [System.IO.Directory]::EnumerateFiles($functionsPathPublic, '*.ps1')
}

# Importing functions
[string[]]$psFuncAll = $psFuncPrivate + $psFuncPublic
if ($psFuncAll.Count -gt 0)
{
    Write-Verbose -Message "$myName Found $($psFuncAll.Count) functions total. Importing..."
    $psFuncAll.ForEach({
        Write-Verbose -Message "$myName Importing function from the file: $_"
        . $_
    })
}

# Getting function names for export
if ($psFuncPublic.Count -gt 0)
{
    Write-Verbose -Message "$myName Found $($psFuncPublic.Count) function(s) to export."
    $psFuncPublic.ForEach({
        [string]$funcShortName = [System.IO.Path]::GetFileNameWithoutExtension($_)
        Write-Verbose -Message "$myName Exporting function `"$funcShortName`" from the file `"$_`"..."
        Export-ModuleMember -Function $funcShortName
    })
}
