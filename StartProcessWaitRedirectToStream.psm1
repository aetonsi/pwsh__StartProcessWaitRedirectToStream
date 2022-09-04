# alternatives:
#   https://stackoverflow.com/a/8762068/9156059
#   https://stackoverflow.com/a/11549817/9156059

function Invoke-StartProcessWaitRedirectToStream {
    Param (
        [Parameter(Mandatory = $true)] [string] $FilePath,
        [Parameter(Mandatory = $false)] [string[]] $ArgumentList = @(),
        [Parameter(Mandatory = $false)] [System.Diagnostics.ProcessWindowStyle] $WindowStyle = 0,
        [Parameter(Mandatory = $false)] [AllowNull()] [Nullable[System.Int32]] $RedirectStandardOutputToStream = $null,
        [Parameter(Mandatory = $false)] [AllowNull()] [Nullable[System.Int32]] $RedirectStandardErrorToStream = $null,
        [Parameter(Mandatory = $false)] [switch] $vvv = $false
    )

    switch ($RedirectStandardOutputToStream) {
        $null { $stdoutOutput = 'Out-Null' }
        1 { $stdoutOutput = 'Write-Output' }
        2 { $stdoutOutput = 'Write-Error' }
        3 { $stdoutOutput = 'Write-Warning' }
        4 { $stdoutOutput = 'Write-Verbose' }
        5 { $stdoutOutput = 'Write-Information' }
    }

    switch ($RedirectStandardErrorToStream) {
        $null { $stderrOutput = 'Out-Null' }
        1 { $stderrOutput = 'Write-Output' }
        2 { $stderrOutput = 'Write-Error' }
        3 { $stderrOutput = 'Write-Warning' }
        4 { $stderrOutput = 'Write-Verbose' }
        5 { $stderrOutput = 'Write-Information' }
    }

    $TempFileOutput = New-TemporaryFile
    $TempFileError = New-TemporaryFile

    if ($vvv) {
        Write-Output "RedirectStandardOutputToStream=$RedirectStandardOutputToStream"
        Write-Output "RedirectStandardErrorToStream=$RedirectStandardErrorToStream"
        Write-Output "stdoutOutput=$stdoutOutput"
        Write-Output "stderrOutput=$stderrOutput"
        Write-Output "TempFileOutput=$TempFileOutput"
        Write-Output "TempFileError=$TempFileError"
    }

    # TODO use $PSBoundParameters or similar to splat any parameter given
    Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -WindowStyle $WindowStyle -Wait -RedirectStandardOutput $TempFileOutput -RedirectStandardError $TempFileError

    Get-Content $TempFileOutput | & $stdoutOutput
    Get-Content $TempFileError | & $stderrOutput

    Remove-Item $TempFileOutput -Force
    Remove-Item $TempFileError -Force
}


Export-ModuleMember -Function Invoke-StartProcessWaitRedirectToStream