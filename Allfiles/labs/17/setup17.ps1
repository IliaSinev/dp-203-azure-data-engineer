Clear-Host
write-host "Starting script at $(Get-Date)"

$resourceGroupName="Spielwiese_Ilia_Sinev"
# $synapseWorkspace = "synapsedp00006"
# $dataLakeAccountName="datalakedp00006"
# $sqlDatabaseName = "sql-dp000"
# $sqlUser="SQLuser"
# $sqlPassword="SC1004i$"
$Region="westeurope"
# $sparkPool="sparkdp00006"
$suffix="dp20317"

$storageAccountName = "store$suffix"
$eventNsName = "events$suffix"
$eventHubName = "eventhub$suffix"

# Create Azure resources
Write-Host "Creating $resourceGroupName resource group in $Region ..."
New-AzResourceGroup -Name $resourceGroupName -Location $Region | Out-Null

$storageAccountName = "store$suffix"
$eventNsName = "events$suffix"
$eventHubName = "eventhub$suffix"

write-host "Creating Azure resources in $resourceGroupName resource group..."
write-host "(This may take some time!)"
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
  -TemplateFile "setup.json" `
  -Mode Complete `
  -storageAccountName $storageAccountName `
  -uniqueSuffix $suffix `
  -eventNsName $eventNsName `
  -eventHubName $eventHubName `
  -Force

# Make the current user owner of the blob store
write-host "Granting permissions on the $storageAccountName storage account..."
$subscriptionId = (Get-AzContext).Subscription.Id
$userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
New-AzRoleAssignment -SignInName $userName -RoleDefinitionName "Storage Blob Data Owner" -Scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName" -ErrorAction SilentlyContinue;

# Prepare JavaScript EventHub client app
write-host "Creating Event Hub client app..."
npm install @azure/event-hubs | Out-Null
Update-AzConfig -DisplayBreakingChangeWarning $false | Out-Null
$conStrings = Get-AzEventHubKey -ResourceGroupName $resourceGroupName -NamespaceName $eventNsName -AuthorizationRuleName "RootManageSharedAccessKey"
$conString = $conStrings.PrimaryConnectionString
$javascript = Get-Content -Path "setup.txt" -Raw
$javascript = $javascript.Replace("EVENTHUBCONNECTIONSTRING", $conString)
$javascript = $javascript.Replace("EVENTHUBNAME",$eventHubName)
Set-Content -Path "orderclient.js" -Value $javascript

write-host "Script completed at $(Get-Date)"