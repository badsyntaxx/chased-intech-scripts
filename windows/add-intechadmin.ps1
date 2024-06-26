function add-intechadmin {
    try {
        write-welcome -Title "Add InTechAdmin Account" -Description "Add an InTech administrator account to this PC." -Command "intech add admin"

        write-text -type "header" -text "Getting credentials" -lineBefore -lineAfter

        $accountName = "InTechAdmin"
        $downloads = [ordered]@{
            "$env:TEMP\KEY.txt"    = "https://drive.google.com/uc?export=download&id=1EGASU9cvnl5E055krXXcXUcgbr4ED4ry"
            "$env:TEMP\PHRASE.txt" = "https://drive.google.com/uc?export=download&id=1jbppZfGusqAUM2aU7V4IeK0uHG2OYgoY"
        }

        foreach ($d in $downloads.Keys) { $download = get-download -Url $downloads[$d] -Target $d } 
        if (!$download) { throw "Unable to acquire credentials." }

        $password = Get-Content -Path "$env:TEMP\PHRASE.txt" | ConvertTo-SecureString -Key (Get-Content -Path "$env:TEMP\KEY.txt")

        write-text -type "done" -text "Credentials acquired."

        $account = Get-LocalUser -Name $accountName -ErrorAction SilentlyContinue

        if ($null -eq $account) {
            write-text -type "header" -text "Creating account" -lineBefore -lineAfter
            New-LocalUser -Name $accountName -Password $password -FullName "" -Description "InTech Administrator" -AccountNeverExpires -PasswordNeverExpires -ErrorAction stop | Out-Null
            write-text -type "done" -text "Account created."
            $finalMessage = "Success! The InTechAdmin account has been created."
        } else {
            write-text -type "header" -text "InTechAdmin account already exists!" -lineBefore -lineAfter
            write-text -text "Updating password..."
            $account | Set-LocalUser -Password $password

            $finalMessage = "Success! The password was updated and the groups were applied."
        }

        write-text -text "Updating group membership..."
        Add-LocalGroupMember -Group "Administrators" -Member $accountName -ErrorAction SilentlyContinue
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $accountName -ErrorAction SilentlyContinue
        Add-LocalGroupMember -Group "Users" -Member $accountName -ErrorAction SilentlyContinue

        Remove-Item -Path "$env:TEMP\PHRASE.txt"
        Remove-Item -Path "$env:TEMP\KEY.txt"

        exit-script -type "success" -text $finalMessage
    } catch {
        # Display error message and end the script
        exit-script -type "error" -text "add-intechadmin-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
}
