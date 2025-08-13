function Get-MyApplicationEvent {
    param (
        [string]$LogName = 'System'
    )

    $days = $null

    # Demander le nombre de jours avec option d'annulation
    do {
        $inputDays = Read-Host "Nombre de jours à remonter ? (Entrée vide ou 'q' pour annuler)"
        
        if ([string]::IsNullOrWhiteSpace($inputDays) -or $inputDays -match '^(q|quit)$') {
            Write-Host "Opération annulée par l'utilisateur."
            return
        }

        if ([int]::TryParse($inputDays, [ref]$days) -and $days -ge 1) {
            break
        }
        else {
            Write-Host "Veuillez entrer un nombre entier supérieur ou égal à 1." -ForegroundColor Yellow
        }
    } while ($true)

    $date = (Get-Date).AddDays(-$days)
    Write-Host "Obtention des évènements systèmes depuis le $date ..." -ForegroundColor Cyan

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
        Write-Host "Aucun évènement trouvé." -ForegroundColor Yellow
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
