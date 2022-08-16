function Get-MyApplicationEvent
{
    [int]$days = $null; #initilaliser la varaible qui va demander le nombre de jour afin qu'elle soit reconnu dans la boucle Do/While
    do #répète l'action ci-dessous
    {
        $days = read-host "Nombre de jours à remonter?"; #Demander le nombre de jour
    }
    while($days -lt 1) #tant que le chiffre est plus petit que 1.

    $date= (Get-Date).AddDays(-$days) 	#la varaible qui contient le nombre de jour qu'on retourn en arriere pour chercher les events
    Write-host "Obtention des évènements systèmes en cours..." -InformationAction Ignore; #écrit du texte a la console
    
    #variable qui Obtient les Entrées du Event log  
    $EventLog = Get-WinEvent -FilterHashtable @{LogName='system';StartTime=$date} | #Chercher les log system depuis tel date
      Where-Object {($_.Level -eq 2) -or ($_.Level -eq 1)} | #de niveau error et critique
      Where-Object  {$_.ProviderName -ne 'Microsoft-Windows-DistributedCOM' -and $_.ProviderName -ne 'DCOM' -and $_.ProviderName -ne 'Microsoft-Windows-Dhcp-Client'-and $_.ProviderName -ne 'DHCP'}; #en excluant les Soruces suivantes


      if($eventlog)
      { 
        [int]$EntryCount = 0; $SysEventLogEntries = $null; #Initialiser les variables qui vont être utilisé dans la boucle foreach

        #Boucle qui va chercher les infos et créer la variable $SysEventLogEntries
        $EventLog | foreach `
        {
            $EntryCount++; #incrémenter de +1 le compte pour chaque entré trouvé, doit être mis en haut sinon la barre de progress se rend a 99%
            [System.Array]$SysEventLogEntries += $_ | `
            select -Property @{Name = 'Date et heure'; Expression = {$_.TimeCreated -replace "2021-", ""}}, ID, @{Name = 'ID name (Source)'; Expression = {$_.ProviderName}}, @{Name = 'Niveau'; Expression = {$_.LevelDisplayName}},@{Name = 'Description'; Expression = {$_.Message}},@{Name = '# Emplacement'; Expression = {$_.RecordID}}; #sélectionner les propriétés qui nous intéresse
            Write-Progress -Activity "Evènements total trouvés: $($EventLog.Count)" `
            -PercentComplete (($EntryCount/$EventLog.Count)*100) `
            -Status "Progrès: $("$EntryCount")";
          
            Start-Sleep -Milliseconds 50;  #Ajouter du délai pour permettre de bien voir la progress bar                       
        }

        Write-Progress -activity "Fini" -Completed  #enelve l'affichage de la barre quand elle est a 100%
        $SysEventLogEntries | Out-GridView -Title "Observateur d'évenement" -wait   #Afficher le resultat dans une grille et le -wait empeche de fermer la grille a la fin de l'éxécution
       }

       else
       {
            write-host "Aucun évènements trouvés."
       }
} 
Get-MyApplicationEvent #appel de la fonction


<#
#Trouver toutes les sources
$Sources = Get-WmiObject -Class Win32_NTEventLOgFile | 
  Select-Object FileName, Sources | 
  ForEach-Object -Begin { $hash = @{}} -Process { $hash[$_.FileName] = $_.Sources } -end { $Hash }

$Sources["System"] | out-gridview 
#>