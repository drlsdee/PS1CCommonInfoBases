<#
.SYNOPSIS
    The function sets the list of the 1C:Enterprise config files
.DESCRIPTION
    The function sets the list of the 1C:Enterprise config files
.EXAMPLE
    PS C:\> Set-CommonInfoBasesList -Path '\\fileserver\bases1c$' -ConfigLocation ProgramData -Encoding UTF8 -LogDir 'C:\Logs' -LogCount 100
    The function gets paths to the all "*.v8i" files from the hidden share "\\fileserver\bases1c$" and saves these paths in the file "1CEStart.cfg" in the folder "$env:ProgramData" (default location is "C:\ProgramData", folder for the config file is "...\1C\1CEStart\"). Output encoding is UTF8. THe function writes log to the folder "C:\Logs" and removes old log files if the count is greater than 100.
.INPUTS
    [System.String]
    [System.Int32]
.OUTPUTS
    Normally should be none
.NOTES
    WIP
#>
function Set-CommonInfoBasesList {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory   = $true,
            HelpMessage = 'Enter the path to the folder with 1C:Enterprise config files (*.v8i). It may be a folder on a local filesystem or a network share. All config files will be enumerated recursively.'
        )]
        # Path to local folder or network share with configuration files
        [string]
        $Path,

        [Parameter()]
        # Path to the file "1CEStart.cfg": either ProgramData for the system-wide configuration or AppData - for the userspace.
        [ValidateSet(
            'ProgramData',
            'AppData'
        )]
        [string]
        $ConfigLocation = 'AppData',

        [Parameter()]
        # Encoding
        [ValidateSet(
            'ASCII',
            'BIGENDIANUNICODE',
            'DEFAULT',
            'OEM',
            'STRING',
            'UNICODE',
            'UTF32',
            'UTF7',
            'UTF8'
        )]
        [string]
        $Encoding,

        [Parameter(
            Mandatory   = $true,
            HelpMessage = 'Enter the path to the folder where log files will be saved. You should be able to create and delete files and write file content in this folder.'
        )]
        # Path to the logs folder
        [string]
        $LogDir,

        [Parameter()]
        # Max log files count
        [int]
        $LogCount = 100
    )
    [string]$myName = $MyInvocation.InvocationName
    #   Creating the instance of the [LogWriter] class
    $logWriter      = [LogWriter]::new($myName, $LogDir, $LogCount)
    #   Creating the instance of [LogStamp] class for timestamping the log.
    $timeStamp      = [LogStamp]::new($myName)
    #   Creating message string with timestamp...
    $logMessage     = $timeStamp.GetStamp('Starting the function...')
    #   ...and print it
    Write-Verbose -Message $logMessage
    $logWriter.WriteLog($logMessage)

    switch ($ConfigLocation) {
        'AppData' {
            $programData1CPath  = [System.IO.Path]::Combine($env:APPDATA,       '1C\1CEStart\1CEStart.cfg')
        }
        'ProgramData' {
            $programData1CPath  = [System.IO.Path]::Combine($env:ProgramData,   '1C\1CEStart\1CEStart.cfg')
        }
        Default {
            $programData1CPath  = [System.IO.Path]::Combine($env:APPDATA,       '1C\1CEStart\1CEStart.cfg')
        }
    }
    
    if (-not [System.IO.File]::Exists($programData1CPath)) {
        $logMessage     = $timeStamp.GetStamp("Configuration file not found: `"$programData1CPath`"! Exiting...")
        $logWriter.WriteLog($logMessage)
        Write-Error     -Category ObjectNotFound -Message $logMessage
        return
    } else {
        $logMessage     = $timeStamp.GetStamp("Configuration file found: `"$programData1CPath`".")
        $logWriter.WriteLog($logMessage)
        Write-Verbose   -Message $logMessage
    }

    if (-not (Test-Path -Path $Path -PathType Container)) {
        $logMessage     = $timeStamp.GetStamp("Folder not found: `"$Path`"! Exiting...")
        $logWriter.WriteLog($logMessage)
        Write-Error     -Category ObjectNotFound -Message $logMessage
        return
    } else {
        $logMessage     = $timeStamp.GetStamp("Folder found: `"$Path`".")
        $logWriter.WriteLog($logMessage)
        Write-Verbose   -Message $logMessage
    }

    [string[]]$currentContent   = Get-Content -Path $programData1CPath
    [int]$stringIndex   = 0
    while ($stringIndex -lt $currentContent.Count) {
        [string]$stringCurrent  = $currentContent[$stringIndex]
        $logMessage     = $timeStamp.GetStamp("String found: `"$stringCurrent`".")
        $logWriter.WriteLog($logMessage)
        if      ($stringIndex -lt 10)
        {
            Write-Verbose       -Message        $logMessage
        }
        elseif  ($stringIndex -eq 10)
        {
            Write-Verbose       -Message        $timeStamp.GetStamp("First 10 strings were shown in the verbose output. See the full content in the log file.")
            Write-Information   -MessageData    $logMessage
        }
        else {
            Write-Information   -MessageData    $logMessage
        }
        $stringIndex++
    }
    [string[]]$preservingData = $currentContent.Where({-not $_.StartsWith('CommonInfoBases')})
    [string[]]$newConfigList = @()
    [string[]]$newConfigPaths = [System.IO.Directory]::EnumerateFiles($Path, '*.v8i', 'AllDirectories')
    if (-not $newConfigPaths) {
        $logMessage = $timeStamp.GetStamp("Configs were not found in the path: `"$Path`"! Exiting...")
        $logWriter.WriteLog($logMessage)
        Write-Error -Category ObjectNotFound -Message $logMessage
        return
    } else {
        [int]$configIndex = 0
        while ($configIndex -lt $newConfigPaths.Count) {
            [string]$pathCurrent = $newConfigPaths[$configIndex]
            $logMessage = $timeStamp.GetStamp("File found: `"$pathCurrent`". Adding string...")
            $logWriter.WriteLog($logMessage)
            if      ($configIndex -lt 5)
            {
                Write-Verbose       -Message        $logMessage
            }
            elseif  ($configIndex -eq 5)
            {
                Write-Verbose       -Message        $timeStamp.GetStamp("First 5 strings were shown in the verbose output. See the full content in the log file.")
                Write-Information   -MessageData    $logMessage
            }
            else {
                Write-Information   -MessageData    $logMessage
            }
            $configIndex++
        }
    }
    $newConfigList += $preservingData
    $logMessage = $timeStamp.GetStamp("Creating backup of the file `"$programData1CPath`"...")
    $logWriter.WriteLog($logMessage)
    Write-Verbose -Message $logMessage
    [string]$programData1CBackup = "$($programData1CPath).OLD"
    Copy-Item -Path $programData1CPath -Destination "$programData1CBackup" -Force
    if (-not [System.IO.File]::Exists($programData1CBackup)) {
        $logMessage = $timeStamp.GetStamp("Backup of file `"$programData1CPath`" not found. File will not be overwritten! Exiting...")
        $logWriter.WriteLog($logMessage)
        Write-Error -Category ObjectNotFound -Message $logMessage
        return
    } else {
        $logMessage = $timeStamp.GetStamp("Copy of file `"$programData1CPath`" created. Overwriting with new values...")
        $logWriter.WriteLog($logMessage)
        Write-Verbose -Message $logMessage
        $newConfigList | Out-File -FilePath $programData1CPath -Force -Encoding utf8
    }
    $logMessage = $timeStamp.GetStamp("End of function...")
    $logWriter.WriteLog($logMessage)
    Write-Verbose -Message $logMessage
    return
}
