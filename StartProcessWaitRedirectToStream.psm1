# alternatives:
#   https://stackoverflow.com/a/8762068/9156059
#   https://stackoverflow.com/a/11549817/9156059


Import-Module -Force "$pwd\StringEncrypt\StringEncrypt.psm1"


function Invoke-StartProcessWaitRedirectToStream {
    Param (
        [Parameter(Mandatory = $true)] [string] $FilePath,
        [Parameter(Mandatory = $false)] [string[]] $ArgumentList = @(),
        [Parameter(Mandatory = $false)] [System.Diagnostics.ProcessWindowStyle] $WindowStyle = 0,
        [Parameter(Mandatory = $false)] [AllowNull()] [Nullable[System.Int32]] $RedirectStandardOutputToStream = $null,
        [Parameter(Mandatory = $false)] [AllowNull()] [Nullable[System.Int32]] $RedirectStandardErrorToStream = $null,
        [Parameter(Mandatory = $false)] [switch] $vvv = $false
    )

    # parse args
    switch ($RedirectStandardOutputToStream) {
        $null { $stdoutOutputStream = 'Out-Null' }
        1 { $stdoutOutputStream = 'Write-Output' }
        2 { $stdoutOutputStream = 'Write-Error' }
        3 { $stdoutOutputStream = 'Write-Warning' }
        4 { $stdoutOutputStream = 'Write-Verbose' }
        5 { $stdoutOutputStream = 'Write-Information' }
    }
    switch ($RedirectStandardErrorToStream) {
        $null { $stderrOutputStream = 'Out-Null' }
        1 { $stderrOutputStream = 'Write-Output' }
        2 { $stderrOutputStream = 'Write-Error' }
        3 { $stderrOutputStream = 'Write-Warning' }
        4 { $stderrOutputStream = 'Write-Verbose' }
        5 { $stderrOutputStream = 'Write-Information' }
    }
    $TempFileOutput = New-TemporaryFile
    $TempFileError = New-TemporaryFile

    # get encryption key
    $TempFilesEncryptionKey = Get-AesEncryptionKey -bytes 16

    # verbose info
    $vvv = $vvv -or $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent;
    if ($vvv) {
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
    Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -WindowStyle $WindowStyle -Wait -RedirectStandardOutput $TempFileOutput -RedirectStandardError $TempFileError

    # encrypt temp output files for added safety
    Get-Content $TempFileOutput | ConvertTo-EncryptedString -EncryptionKey $TempFilesEncryptionKey | Set-Content $TempFileOutput
    Get-Content $TempFileError | ConvertTo-EncryptedString -EncryptionKey $TempFilesEncryptionKey | Set-Content $TempFileError

    # output as requested
    Get-Content $TempFileOutput | ConvertFrom-EncryptedString -EncryptionKey $TempFilesEncryptionKey | & $stdoutOutputStream
    Get-Content $TempFileError | ConvertFrom-EncryptedString -EncryptionKey $TempFilesEncryptionKey | & $stderrOutputStream

    # cleanup
    Remove-Item $TempFileOutput -Force
    Remove-Item $TempFileError -Force
    Remove-Variable TempFilesEncryptionKey -Force
}


Export-ModuleMember -Function Invoke-StartProcessWaitRedirectToStream