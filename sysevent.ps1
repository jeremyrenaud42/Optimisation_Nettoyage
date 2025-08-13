Add-Type -AssemblyName Microsoft.VisualBasic

function Get-MyApplicationEvent {
    param (
        [string]$LogName = 'System'
    )

    $days = $null

    # Demander le nombre de jours via une boîte de dialogue
    do {
        $inputDays = [Microsoft.VisualBasic.Interaction]::InputBox(
            "Nombre de jours à remonter ? (Laissez vide ou entrez 'q' pour annuler)",
            "Entrée requise"
        )

        if ([string]::IsNullOrWhiteSpace($inputDays) -or $inputDays -match '^(q|quit)$') {
            [System.Windows.MessageBox]::Show(
                "Opération annulée par l'utilisateur.",
                "Annulation",
                'OK',
                'Information'
            ) | Out-Null
            return
        }

        if ([int]::TryParse($inputDays, [ref]$days) -and $days -ge 1) {
            break
        }
        else {
            [System.Windows.MessageBox]::Show(
                "Veuillez entrer un nombre entier supérieur ou égal à 1.",
                "Entrée invalide",
                'OK',
                'Warning'
            ) | Out-Null
        }
    } while ($true)

    $date = (Get-Date).AddDays(-$days)
    [System.Windows.MessageBox]::Show(
        "Obtention des évènements systèmes depuis le $date ...",
        "Information",
        'OK',
        'Information'
    ) | Out-Null

    # Récupération filtrée des événements
    $EventLog = Get-WinEvent -FilterHashtable @{LogName=$LogName; StartTime=$date} |
        Where-Object { $_.Level -in 1, 2 } |
        Where-Object { $_.ProviderName -notin @(
            'Microsoft-Windows-DistributedCOM',
            'DCOM',
            'Microsoft-Windows-Dhcp-Client',
            'DHCP'
        )}

    if (-not $EventLog) {
        [System.Windows.MessageBox]::Show(
            "Aucun évènement trouvé.",
            "Résultat",
            'OK',
            'Warning'
        ) | Out-Null
        return
    }

    $EntryCount = 0
    $SysEventLogEntries = @()

    foreach ($event in $EventLog) {
        $EntryCount++
        $SysEventLogEntries += [PSCustomObject]@{
            'Date et heure'        = $event.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
            'ID'                   = $event.Id
            'ID name (Source)'     = $event.ProviderName
            'Niveau'               = $event.LevelDisplayName
            'Description'          = $event.Message
            '# Emplacement'        = $event.RecordId
        }

        Write-Progress -Activity "Évènements total trouvés: $($EventLog.Count)" `
                       -PercentComplete (($EntryCount / $EventLog.Count) * 100) `
                       -Status "Progrès: $EntryCount"
    }

    Write-Progress -Activity "Fini" -Completed

    $SysEventLogEntries | Out-GridView -Title "Observateur d'évènements" -Wait
}

# Appel
Get-MyApplicationEvent
