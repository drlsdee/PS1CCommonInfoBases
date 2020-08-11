class LogWriter {
    #   Property: the invocation name
    [string]
    $InvocationName

    #   Property: datetime format for log filenames
    [string]
    $DateStringFormat  = 'yyyy-MM-dd-HH-mm-ss-fff'

    #   Property: datetime string
    [string]
    $DateTimeString

    #   Property: log file name
    [string]
    $LogFileName

    #   Property: log files extension
    [string]
    $Extension  = '.txt'

    #   Property: encoding
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
    $Encoding   = 'UTF8'

    #   Property: path to the logs folder
    [string]
    $LogRootDirectory

    #   Max log count
    [int]
    $Count

    #   Method: set end folder path
    [string]
    SetPath()
    {
        [string]$rootFolderPath = [System.IO.Path]::GetFullPath($this.LogRootDirectory)
        [string]$endFolderPath  = [System.IO.Path]::Combine($rootFolderPath, $this.InvocationName)
        return $endFolderPath
    }

    #   Method: create folder
    [void]
    CreateFolderIfNotExists(
        [string]
        $folderPath
    )
    {
        [bool]$folderExists     = [System.IO.Directory]::Exists($folderPath)
        [bool]$fileExists       = [System.IO.File]::Exists($folderPath)
        if ($fileExists) {
            Write-Warning -Message "Should be a folder, but file exists: $($folderPath)! Removing..."
            Remove-Item -Path $folderPath -Force -Confirm:$false | Out-Null
        }

        if (-not $folderExists) {
            Write-Verbose -Message "Folder does not exist: $($folderPath)! Creating..."
            New-Item -Path $folderPath -ItemType Directory -Force -Confirm:$false
        }
        else {
            Write-Verbose -Message "Folder already exists: $($folderPath)"
        }
    }

    #   Method: set log filename
    [string]
    SetLogName()
    {
        [string]$logBaseName    = "$($this.DateTimeString)_$($this.InvocationName)"
        Write-Verbose -Message "BaseName: $logBaseName"
        if ($this.Extension -match '^\.') {
            [string]$logName    = "$($logBaseName)$($this.Extension)"
        }
        else {
            [string]$logName    = "$($logBaseName).$($this.Extension)"
        }
        [string]$logFolderPath  = $this.SetPath()
        [string]$logFullName    = [System.IO.Path]::Combine($logFolderPath, $logName)
        Write-Verbose -Message "Log file name: $($logFullName)"
        return $logFullName
    }

    #   Method: rotate log files
    [void]
    RotateLogs()
    {
        [string]$logFolderPath      = $this.SetPath()
        if ($this.Extension -match '^\.') {
            [string]$logPatternAll  = "*$($this.Extension)"
        }
        else {
            [string]$logPatternAll  = "*.$($this.Extension)"
        }
        [System.IO.FileInfo[]]$logFilesAll  = [System.IO.Directory]::EnumerateFiles($logFolderPath, $logPatternAll) | Sort-Object -Property CreationTime -Descending
        Write-Verbose -Message "Found $($logFilesAll.Count) log files total"
        [string[]]$logFilesMatching     = $logFilesAll.Where({
            $_.BaseName -match $this.InvocationName
        })
        Write-Verbose -Message "Found $($logFilesMatching.Count) log files matching to $($this.InvocationName)"
        if ($logFilesMatching.Count     -gt $this.Count) {
            [int]$cntStart              = $this.Count
            [int]$cntEnd                = $logFilesMatching.Count - 1
            [string[]]$logFilesToRemove = $logFilesMatching[$cntStart..$cntEnd]
            $logFilesToRemove.ForEach({
                Remove-Item -Path $_ -Force -Confirm:$false
            })
        }
    }

    #   Method: write log message
    [void]
    WriteLog(
        [string]$logMessage
    )
    {
        [string]$logFullName    = $this.LogFileName
        if (-not [System.IO.File]::Exists($logFullName)) {
            Write-Verbose -Message "The file does not exist: $($logFullName). Creating..."
            Out-File -InputObject $logMessage -FilePath $logFullName -Encoding $this.Encoding -Force -Confirm:$false
        }
        else {
            Out-File -InputObject $logMessage -FilePath $logFullName -Encoding $this.Encoding -Force -Confirm:$false -Append
        }
    }

    #   Constructor: default
    LogWriter(
        [string]
        $newInvocationName,

        [string]
        $rootDirectory,

        [int]
        $maxCount
    )
    {
        $this.InvocationName    = $newInvocationName
        $this.LogRootDirectory  = $rootDirectory
        $this.Count             = $maxCount
        $this.DateTimeString    = [datetime]::Now.ToString($this.DateStringFormat)
        $this.LogFileName       = $this.SetLogName()

        [string]$logFolderPath  = $this.SetPath()
        $this.CreateFolderIfNotExists($logFolderPath)
        $this.RotateLogs()
    }
}
