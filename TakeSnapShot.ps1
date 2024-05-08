try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

if($err) {

throw $err

}

# Get VMs with snapshot tag

$tagResList = Get-AzResource -TagName "<tagName>" -TagValue "<tagValue>" | foreach {

Get-AzResource -ResourceId $_.resourceid

}

#Add tag to snapshot 

$tags = @{"Name"=<"Diskname">; ; "OWNER"=<"Owner">}

foreach($tagRes in $tagResList) {

if($tagRes.ResourceId -match "Microsoft.Compute")

{

$vmInfo = Get-AzVM -ResourceGroupName $tagRes.ResourceId.Split("//")[4] -Name $tagRes.ResourceId.Split("//")[8]

#Set local variables

$location = $vmInfo.Location

$resourceGroupName = $vmInfo.ResourceGroupName

$timestamp = Get-Date -f MM-dd-yyyy_HH_mm_ss

#Snapshot name of OS data disk

$snapshotName = $vmInfo.Name + $timestamp

#Create snapshot configuration

$snapshot = New-AzSnapshotConfig -SourceUri $vmInfo.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy -Incremental

#Take snapshot

New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName 

#Get Snapshot ID

$resourcesnap = Get-AzSnapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

#Add tag

New-AzTag -ResourceId $resourcesnap.id -Tag $tags

if($vmInfo.StorageProfile.DataDisks.Count -ge 1){

#Condition with more than one data disks

for($i=0; $i -le $vmInfo.StorageProfile.DataDisks.Count - 1; $i++){

#Snapshot name of OS data disk

$snapshotName = $vmInfo.StorageProfile.DataDisks[$i].Name + $timestamp

#Create snapshot configuration

$snapshot = New-AzSnapshotConfig -SourceUri $vmInfo.StorageProfile.DataDisks[$i].ManagedDisk.Id -Location $location -CreateOption copy -Incremental

#Take snapshot

New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

#Get Snapshot ID

$resourcesnap = Get-AzSnapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName

#Add tag

New-AzTag -ResourceId $resourcesnap.id -Tag $tags

}

}

else{

Write-Host $vmInfo.Name + " doesn't have any additional data disk."

}

}

else{

$tagRes.ResourceId + " is not a compute instance"

}

}