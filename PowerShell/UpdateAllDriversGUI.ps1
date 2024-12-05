# Load necessary assemblies for Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define color scheme for dark mode
$BackgroundColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E") # Dark Gray
$ControlColor = [System.Drawing.ColorTranslator]::FromHtml("#2D2D30")    # Slightly lighter dark gray
$TextColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")       # White
$ButtonHoverColor = [System.Drawing.ColorTranslator]::FromHtml("#3E3E42") # Hover color for buttons

# Create the main form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Driver Update Manager"
$Form.Size = New-Object System.Drawing.Size(790, 560)
$Form.StartPosition = "CenterScreen"
$Form.BackColor = $BackgroundColor
$Form.FormBorderStyle = 'FixedDialog'
$Form.MaximizeBox = $false

# Set a modern font for the form
$FontFamily = New-Object System.Drawing.FontFamily("Segoe UI")
$Form.Font = New-Object System.Drawing.Font($FontFamily, 10)

# Create a ListBox to display driver updates
$ListBox = New-Object System.Windows.Forms.ListBox
$ListBox.Location = New-Object System.Drawing.Point(10, 10)
$ListBox.Size = New-Object System.Drawing.Size(760, 400)
$ListBox.BackColor = $ControlColor
$ListBox.ForeColor = $TextColor
$ListBox.Font = New-Object System.Drawing.Font($FontFamily, 10)
$ListBox.BorderStyle = 'FixedSingle'
$ListBox.FormattingEnabled = $true
$ListBox.HorizontalScrollbar = $true
$Form.Controls.Add($ListBox)

# Create a Status Label
$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Location = New-Object System.Drawing.Point(10, 420)
$StatusLabel.Size = New-Object System.Drawing.Size(760, 30)
$StatusLabel.Text = "Status: Ready"
$StatusLabel.ForeColor = $TextColor
$StatusLabel.BackColor = $BackgroundColor
$StatusLabel.Font = New-Object System.Drawing.Font($FontFamily, 10, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($StatusLabel)

# Function to create a styled button
function New-StyledButton($text, $location) {
    $Button = New-Object System.Windows.Forms.Button
    $Button.Text = $text
    $Button.Location = $location
    $Button.Size = New-Object System.Drawing.Size(240, 40)
    $Button.BackColor = $ControlColor
    $Button.ForeColor = $TextColor
    $Button.FlatStyle = 'Flat'
    $Button.FlatAppearance.BorderSize = 0
    $Button.Font = New-Object System.Drawing.Font($FontFamily, 10, [System.Drawing.FontStyle]::Bold)
    
    # Change cursor on hover
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand

    # Add hover effects using $sender instead of $Button
    $Button.Add_MouseEnter({
        param($sender, $eventArgs)
        $sender.BackColor = $ButtonHoverColor
    })
    $Button.Add_MouseLeave({
        param($sender, $eventArgs)
        $sender.BackColor = $ControlColor
    })
    return $Button
}

# Create Buttons
$SearchButton = New-StyledButton "Search for Missing Drivers" (New-Object System.Drawing.Point(10, 470))
$Form.Controls.Add($SearchButton)

$DownloadButton = New-StyledButton "Download Drivers" (New-Object System.Drawing.Point(270, 470))
$DownloadButton.Enabled = $false
$Form.Controls.Add($DownloadButton)

$InstallButton = New-StyledButton "Install Drivers" (New-Object System.Drawing.Point(530, 470))
$InstallButton.Enabled = $false
$Form.Controls.Add($InstallButton)

# Variable to store updates
$global:SearchResult = $null
$global:UpdatesToDownload = $null
$global:UpdatesToInstall = $null
$global:Downloader = $null
$global:Installer = $null

# Function to update status label
function Update-Status {
    param(
        [string]$message,
        [string]$color = "White"
    )
    switch ($color.ToLower()) {
        "green" { $StatusLabel.ForeColor = [System.Drawing.Color]::Lime }
        "red" { $StatusLabel.ForeColor = [System.Drawing.Color]::Crimson }
        "blue" { $StatusLabel.ForeColor = [System.Drawing.Color]::DeepSkyBlue }
        default { $StatusLabel.ForeColor = $TextColor }
    }
    $StatusLabel.Text = "Status: $message"
    $Form.Refresh()
}

# Function to add messages to the ListBox
function Add-Log {
    param([string]$message)
    $ListBox.Items.Add($message)
    # Auto-scroll to the bottom
    $ListBox.TopIndex = $ListBox.Items.Count - 1
}

# Event Handler for Search Button
$SearchButton.Add_Click({
    $ListBox.Items.Clear()
    Update-Status "Searching for driver updates..." "white"
    
    try {
        # Initialize Update Session and Searcher
        $Session = New-Object -ComObject Microsoft.Update.Session 
        $Searcher = $Session.CreateUpdateSearcher() 
        
        $Searcher.ServiceID = '7971f918-a847-4430-9279-4a52d1efe18d'
        $Searcher.SearchScope = 1 # MachineOnly
        $Searcher.ServerSelection = 3 # Third Party
        
        $Criteria = "IsInstalled=0 and Type='Driver' and IsHidden=0"
        Add-Log "Searching Driver-Updates..."
        
        $SearchResult = $Searcher.Search($Criteria) 
        $global:SearchResult = $SearchResult
        
        $Updates = $SearchResult.Updates
        
        if ($Updates.Count -eq 0) {
            Update-Status "No missing drivers found." "blue"
            Add-Log "No missing drivers found."
            return
        }
        
        # Display available drivers
        foreach ($update in $Updates) {
            $ListBox.Items.Add("Title: $($update.Title)")
            $ListBox.Items.Add("Driver Model: $($update.DriverModel)")
            $ListBox.Items.Add("Driver Version Date: $($update.DriverVerDate)")
            $ListBox.Items.Add("Driver Class: $($update.DriverClass)")
            $ListBox.Items.Add("Driver Manufacturer: $($update.DriverManufacturer)")
            $ListBox.Items.Add("------------------------------------------------------------")
        }
        
        Update-Status "Found $($Updates.Count) missing drivers." "green"
        Add-Log "Found $($Updates.Count) missing drivers."
        $DownloadButton.Enabled = $true
    }
    catch {
        Update-Status "Error during search: $_" "red"
        Add-Log "Error during search: $_"
    }
})

# Event Handler for Download Button
$DownloadButton.Add_Click({
    if (-not $global:SearchResult) {
        Update-Status "No updates to download. Please search first." "red"
        Add-Log "No updates to download. Please search first."
        return
    }

    Update-Status "Downloading drivers..." "white"
    Add-Log "Downloading drivers..."

    try {
        $UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
        $global:SearchResult.Updates | ForEach-Object { $UpdatesToDownload.Add($_) | Out-Null }
        $global:UpdatesToDownload = $UpdatesToDownload
        
        $UpdateSession = New-Object -Com Microsoft.Update.Session
        $Downloader = $UpdateSession.CreateUpdateDownloader()
        $Downloader.Updates = $UpdatesToDownload
        $global:Downloader = $Downloader
        
        $Downloader.Download()
        
        # Check download status
        $Downloaded = $false
        foreach ($update in $global:UpdatesToDownload) {
            if ($update.IsDownloaded) {
                $Downloaded = $true
                Add-Log "Downloaded: $($update.Title)"
            }
            else {
                Add-Log "Failed to download: $($update.Title)"
            }
        }
        
        if ($Downloaded) {
            Update-Status "Download completed." "green"
            Add-Log "Download completed."
            $InstallButton.Enabled = $true
        }
        else {
            Update-Status "No drivers were downloaded successfully." "red"
            Add-Log "No drivers were downloaded successfully."
        }
    }
    catch {
        Update-Status "Error during download: $_" "red"
        Add-Log "Error during download: $_"
    }
})

# Event Handler for Install Button
$InstallButton.Add_Click({
    if (-not $global:UpdatesToDownload) {
        Update-Status "No updates to install. Please download first." "red"
        Add-Log "No updates to install. Please download first."
        return
    }

    Update-Status "Installing drivers..." "white"
    Add-Log "Installing drivers..."

    try {
        $UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
        $global:UpdatesToDownload | ForEach-Object { 
            if ($_.IsDownloaded) { 
                $UpdatesToInstall.Add($_) | Out-Null 
            }
        }
        $global:UpdatesToInstall = $UpdatesToInstall
        
        $UpdateSession = New-Object -Com Microsoft.Update.Session
        $Installer = $UpdateSession.CreateUpdateInstaller()
        $Installer.Updates = $global:UpdatesToInstall
        $global:Installer = $Installer
        
        $InstallationResult = $Installer.Install()
        
        if ($InstallationResult.RebootRequired) { 
            Update-Status "Reboot required! Please reboot now." "red"
            Add-Log "Reboot required! Please reboot your system."
        } 
        else { 
            Update-Status "Installation completed successfully." "green"
            Add-Log "Installation completed successfully."
        }
    }
    catch {
        Update-Status "Error during installation: $_" "red"
        Add-Log "Error during installation: $_"
    }
})

# Show the form
[void]$Form.ShowDialog()
