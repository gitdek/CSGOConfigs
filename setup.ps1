# setup.ps1
# Script to backup, update, and copy over all files from CSGOConfigs

function Write-ProgressHelper {
	param (
	    [int]$StepNumber,
	    [string]$Message
	)

	Write-Progress -Activity 'CSGOConfigs' -Status $Message -PercentComplete (($StepNumber / $steps) * 100)
}

function DownloadGitHubRepository { 
    param( 
       [Parameter(Mandatory=$True)] 
       [string] $Name, 
         
       [Parameter(Mandatory=$True)] 
       [string] $Author, 
         
       [Parameter(Mandatory=$False)] 
       [string] $Branch = "master", 
         
       [Parameter(Mandatory=$False)] 
       [string] $Location = "c:\temp"
    )
	
    $ZipFile = "$location\$Name.zip"
    New-Item $ZipFile -ItemType File -Force
    $RepositoryZipUrl = "https://api.github.com/repos/$Author/$Name/zipball/$Branch" 
    Invoke-RestMethod -Uri $RepositoryZipUrl -OutFile $ZipFile
    Expand-Archive -Path $ZipFile -DestinationPath $Location -Force
    Remove-Item -Path $ZipFile -Force
}

$configs = @(
    'autoexec.cfg'
    'watchdemo.cfg'
    'crosshairs.cfg'
    'buybinds.cfg'
)

$skipUpdate = 0
$script:steps = (($configs.Count * 2) + 4)
$stepCounter = 0
$userdata = "${env:ProgramFiles(x86)}\Steam\userdata\"
$cfgdir = "\730\local\cfg"
$date = Get-Date
$dateStr = Get-Date $date -Format "yyyMMdd"

$ids = @(Get-ChildItem "${env:ProgramFiles(x86)}\Steam\userdata\" | Out-GridView -Title 'Choose a steam id' -PassThru)
$x=$userdata+$ids+$cfgdir

Write-Host 'Selected'$x

$title    = 'Install'
$question = 'Are you sure you want to proceed?'
$choices  = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 0)
if ($decision -eq 0) {
    Write-Host ':)'
} else {
    Write-Host 'Exiting...'
	exit
}

if (!$skipUpdate) {
	$title    = 'Update'
	$question = 'Would you like to download updates?'
	$choices  = '&Yes', '&No'

	$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
	if ($decision -eq 0) {
		DownloadGitHubRepository -Name CSGOConfigs -Author gitdek -Location $PSScriptRoot
	}
}

Write-Host "Backing up files..."

foreach ($k in $configs) {
	Rename-Item -Path $x\$k -NewName $x\$k.$dateStr.backup -ErrorAction Ignore
	Write-ProgressHelper -Message "Backing up $k..." -StepNumber ($stepCounter++)
	Start-Sleep -Seconds 1
}

Copy-Item $x\video.txt -Destination $x\video.txt.$dateStr.backup -ErrorAction Ignore
Write-ProgressHelper -Message 'Backing up files...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 1
	
Copy-Item $x\config.cfg -Destination $x\config.cfg.$dateStr.backup -ErrorAction Ignore
Write-ProgressHelper -Message 'Backing up files...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 1

Rename-Item -Path "${env:ProgramFiles(x86)}\Steam\steamapps\common\Counter-Strike Global Offensive\csgo\resource\ui\RadioPanel.txt" -NewName "${env:ProgramFiles(x86)}\Steam\steamapps\common\Counter-Strike Global Offensive\csgo\resource\ui\RadioPanel.txt.$dateStr.backup" -ErrorAction Ignore
Write-ProgressHelper -Message 'Backing up files...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 1


Write-Host "Copying over files..."

foreach ($c in $configs) {
	Copy-Item "$PSScriptRoot\$c" -Destination "$x\$c" -ErrorAction Ignore
	Write-ProgressHelper -Message "Copying $PSScriptRoot\$c to $x\$c ..." -StepNumber ($stepCounter++)
	Start-Sleep -Seconds 1
}

Copy-Item $PSScriptRoot\RadioPanel.txt -Destination "${env:ProgramFiles(x86)}\Steam\steamapps\common\Counter-Strike Global Offensive\csgo\resource\ui\RadioPanel.txt" -ErrorAction Ignore
Write-ProgressHelper -Message 'Backing up files...' -StepNumber ($stepCounter++)
Start-Sleep -Seconds 1

$lo = (Get-Content .\autoexec.cfg)[2] -split "(:)" # Parse from autoexec the launch options
Write-Host 'Complete! Please make sure your launch options to:'
Write-Host $lo[2].trim()
