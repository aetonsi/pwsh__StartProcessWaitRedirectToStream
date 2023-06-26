# alternatives:
#   https://stackoverflow.com/a/8762068/9156059
#   https://stackoverflow.com/a/11549817/9156059


function Invoke-StartProcessWaitRedirectToStream {
    [CmdletBinding(DefaultParameterSetName = '__AllParameterSets')]
    Param (
        [string] $FilePath,
        [string[]] $ArgumentList = @(),
        [Parameter(ParameterSetName = 'winstyle')][System.Diagnostics.ProcessWindowStyle] $WindowStyle = 0,
        [Parameter(ParameterSetName = 'nonewwindow')][switch] $NoNewWindow,
        [AllowNull()] [Nullable[System.Int32]] $RedirectStandardOutputToStream = $null,
        [AllowNull()] [Nullable[System.Int32]] $RedirectStandardErrorToStream = $null,
        [switch] $VVV
    )

    # parse args
    switch ($RedirectStandardOutputToStream) {
        { $_ -eq $null -or $_ -eq 0 } { $stdoutOutputStream = 'Out-Null' }
        1 { $stdoutOutputStream = 'Write-Output' }
        2 { $stdoutOutputStream = 'Write-Error' }
        3 { $stdoutOutputStream = 'Write-Warning' }
        4 { $stdoutOutputStream = 'Write-Verbose' }
        5 { $stdoutOutputStream = 'Write-Information' }
        default { $stderrOutputStream = 'Out-Null' }
    }
    switch ($RedirectStandardErrorToStream) {
        { $_ -eq $null -or $_ -eq 0 } { $stderrOutputStream = 'Out-Null' }
        1 { $stderrOutputStream = 'Write-Output' }
        2 { $stderrOutputStream = 'Write-Error' }
        3 { $stderrOutputStream = 'Write-Warning' }
        4 { $stderrOutputStream = 'Write-Verbose' }
        5 { $stderrOutputStream = 'Write-Information' }
        default { $stderrOutputStream = 'Out-Null' }
    }
    try {
        $TempFileOutput = New-TemporaryFile
        $TempFileError = New-TemporaryFile
    } catch {
        # fix for https://github.com/PowerShell/PowerShell/issues/14100
        $TempFileOutput = Get-Item ([System.IO.Path]::GetTempFilename())
        $TempFileError = Get-Item ([System.IO.Path]::GetTempFilename())
    }

    $v = $VVV -or ($MyInvocation.BoundParameters -and
        $MyInvocation.BoundParameters['Verbose'] -and $MyInvocation.BoundParameters['Verbose'].IsPresent)
    if ($v) {
        Write-Output "RedirectStandardOutputToStream=$RedirectStandardOutputToStream"
        Write-Output "RedirectStandardErrorToStream=$RedirectStandardErrorToStream"
        Write-Output "stdoutOutputStream=$stdoutOutputStream"
        Write-Output "stderrOutputStream=$stderrOutputStream"
        Write-Output "TempFileOutput=$TempFileOutput"
        Write-Output "TempFileError=$TempFileError"
        Write-Output "TempFilesEncryptionKey=$TempFilesEncryptionKey"
    }

    # main call
    # TODO use $PSBoundParameters or similar to splat any parameter given
    # TODO run async?
    $win = if ($NoNewWindow) { @{NoNewWindow = $true } } else { @{WindowStyle = $WindowStyle } }
    Start-Process -FilePath $FilePath -ArgumentList $ArgumentList `
        -Wait @win `
        -RedirectStandardOutput $TempFileOutput `
        -RedirectStandardError $TempFileError

    # output
    Get-Content $TempFileOutput | & $stdoutOutputStream
    Get-Content $TempFileError | & $stderrOutputStream

    # cleanup
    Remove-Item $TempFileOutput -Force
    Remove-Item $TempFileError -Force
}


Export-ModuleMember -Function Invoke-StartProcessWaitRedirectToStream