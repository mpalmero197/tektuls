Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define colors for Dark Mode
$darkBackground = [System.Drawing.ColorTranslator]::FromHtml("#2D2D30") # Dark gray
$darkControlBackground = [System.Drawing.ColorTranslator]::FromHtml("#3E3E42") # Slightly lighter dark gray
$lightForeground = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF") # White
$lightGrayForeground = [System.Drawing.ColorTranslator]::FromHtml("#CCCCCC") # Light gray
$buttonBlue = [System.Drawing.ColorTranslator]::FromHtml("#007ACC")
$buttonGreen = [System.Drawing.ColorTranslator]::FromHtml("#0EAD69")
$buttonOrange = [System.Drawing.ColorTranslator]::FromHtml("#FFB900")
$buttonRed = [System.Drawing.ColorTranslator]::FromHtml("#D13438")

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "OneDrive Sync Checker"
$form.Size = New-Object System.Drawing.Size(450, 300)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.BackColor = $darkBackground
$form.ForeColor = $lightForeground

# Optional: Add an icon (ensure the path to the icon is correct)
# $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Path\To\Your\Icon.ico")

# Create a TableLayoutPanel for structured layout
$tableLayout = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayout.RowCount = 5
$tableLayout.ColumnCount = 2
$tableLayout.Dock = [System.Windows.Forms.DockStyle]::Fill
$tableLayout.Padding = New-Object System.Windows.Forms.Padding(10)
$tableLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::AutoSize)))
$tableLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100)))

# Adjusted RowStyles: Increased the height of the second row from 40 to 60
$tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 40)))  # Row 0
$tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 60)))  # Row 1 (Increased from 40 to 60)
$tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))      # Row 2
$tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 50)))  # Row 3
$tableLayout.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::AutoSize)))      # Row 4
$tableLayout.BackColor = $darkBackground
$form.Controls.Add($tableLayout)

# Create a label for the username
$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter Username:"
$label.TextAlign = "MiddleLeft"
$label.AutoSize = $true
$label.Margin = New-Object System.Windows.Forms.Padding(3, 10, 3, 10)
$label.ForeColor = $lightForeground
$tableLayout.Controls.Add($label, 0, 0)

# Create a textbox for the username input
$usernameTextBox = New-Object System.Windows.Forms.TextBox
$usernameTextBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$usernameTextBox.BackColor = $darkControlBackground
$usernameTextBox.ForeColor = $lightForeground
$usernameTextBox.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$tableLayout.Controls.Add($usernameTextBox, 1, 0)

# Create a button to check OneDrive status
$checkButton = New-Object System.Windows.Forms.Button
$checkButton.Text = "Check OneDrive Status"
$checkButton.BackColor = $buttonBlue
$checkButton.ForeColor = $lightForeground
$checkButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$checkButton.FlatAppearance.BorderColor = $buttonBlue
$checkButton.Height = 40  # Increased from 30 to 40
$checkButton.Dock = [System.Windows.Forms.DockStyle]::Fill
$checkButton.Margin = New-Object System.Windows.Forms.Padding(3, 10, 3, 10)
$tableLayout.Controls.Add($checkButton, 0, 1)
$tableLayout.SetColumnSpan($checkButton, 2)

# Create a label to display the status message
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Status will be displayed here."
$statusLabel.TextAlign = "MiddleLeft"
$statusLabel.AutoSize = $false
$statusLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
$statusLabel.Height = 60
$statusLabel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$statusLabel.Padding = New-Object System.Windows.Forms.Padding(5)
$statusLabel.BackColor = $darkControlBackground
$statusLabel.ForeColor = $lightForeground
$tableLayout.Controls.Add($statusLabel, 0, 2)
$tableLayout.SetColumnSpan($statusLabel, 2)

# Create a button to start OneDrive
$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "Start OneDrive"
$startButton.BackColor = $buttonGreen
$startButton.ForeColor = $lightForeground
$startButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$startButton.FlatAppearance.BorderColor = $buttonGreen
$startButton.Height = 30
$startButton.Dock = [System.Windows.Forms.DockStyle]::Fill
$startButton.Enabled = $false # Initially disabled
$startButton.Margin = New-Object System.Windows.Forms.Padding(3, 10, 3, 10)
$tableLayout.Controls.Add($startButton, 0, 3)
$tableLayout.SetColumnSpan($startButton, 2)

# Create a footer label (optional)
$footerLabel = New-Object System.Windows.Forms.Label
$footerLabel.Text = "© 2024 Michael Palmero"
$footerLabel.TextAlign = "MiddleCenter"
$footerLabel.ForeColor = $lightGrayForeground
$footerLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
$footerLabel.AutoSize = $false
$footerLabel.BackColor = $darkBackground
$tableLayout.Controls.Add($footerLabel, 0, 4)
$tableLayout.SetColumnSpan($footerLabel, 2)

# Event handler for the Check button
$checkButton.Add_Click({
    $username = $usernameTextBox.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($username)) {
        $statusLabel.Text = "Username cannot be empty."
        $statusLabel.ForeColor = $buttonRed
        return
    }

    # Get the user profile for the specified username
    $userProfile = Get-WmiObject -Class Win32_UserProfile -ErrorAction SilentlyContinue | Where-Object { $_.LocalPath -like "*$username*" }

    if ($userProfile) {
        # Get the session ID of the user
        $sessionId = $userProfile.SID.Split('-')[-1] # Use SID to derive session ID

        # Get the OneDrive process for the specific user
        $onedriveProcess = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -eq $sessionId }

        # Check if the process is running
        if ($onedriveProcess) {
            $statusLabel.Text = "OneDrive is currently running and syncing for user '$username'."
            $statusLabel.ForeColor = $buttonGreen
            $startButton.Enabled = $false
        } else {
            $statusLabel.Text = "OneDrive is not running for user '$username'."
            $statusLabel.ForeColor = $buttonOrange
            $startButton.Enabled = $true
        }
    } else {
        $statusLabel.Text = "User '$username' does not have an active session or profile."
        $statusLabel.ForeColor = $buttonRed
        $startButton.Enabled = $false
    }
})

# Event handler for the Start button
$startButton.Add_Click({
    $username = $usernameTextBox.Text.Trim()
    $statusLabel.Text = "Attempting to start OneDrive for user '$username'..."
    $statusLabel.ForeColor = $lightForeground

    # Construct the paths to OneDrive executable
    $onedrivePaths = @(
        "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
        "C:\Program Files\Microsoft OneDrive\OneDrive.exe",
        "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe"
    )

    # Check if OneDrive executable exists in any of the locations
    $foundPath = $onedrivePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($foundPath) {
        try {
            # Start OneDrive process for the user
            Start-Process -FilePath $foundPath -ArgumentList "/background" -ErrorAction Stop
            Start-Sleep -Seconds 2 # Wait for a moment to let OneDrive initialize
            $statusLabel.Text = "OneDrive has been started for user '$username'."
            $statusLabel.ForeColor = $buttonGreen
            $startButton.Enabled = $false
        } catch {
            $statusLabel.Text = "Failed to start OneDrive. Error: $_"
            $statusLabel.ForeColor = $buttonRed
        }
    } else {
        $statusLabel.Text = "OneDrive executable not found. Please ensure OneDrive is installed for user '$username'."
        $statusLabel.ForeColor = $buttonRed
    }
})

# Optional: Add tooltip for better user guidance
$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.SetToolTip($checkButton, "Click to check the OneDrive sync status for the entered username.")
$toolTip.SetToolTip($startButton, "Click to start OneDrive for the entered username.")

# Show the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
