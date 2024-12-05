Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define color scheme for darker dark mode
$backgroundColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")      # Darker background
$foregroundColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")      # White text
$buttonColor = [System.Drawing.ColorTranslator]::FromHtml("#2E2E2E")          # Darker buttons
$buttonHoverColor = [System.Drawing.ColorTranslator]::FromHtml("#3E3E3E")     # Hover color for buttons
$listBoxBackColor = [System.Drawing.ColorTranslator]::FromHtml("#2E2E2E")     # Darker ListBox
$listBoxForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")     # White text in ListBox

# Create the GUI form
$form = New-Object System.Windows.Forms.Form
$form.Text = "TXT to PS1 Converter"
$form.Size = New-Object System.Drawing.Size(530, 400)                      # Increased width for better layout
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $backgroundColor
$form.ForeColor = $foregroundColor

# Define a common font
$commonFont = New-Object System.Drawing.Font("Segoe UI", 10)

# Calculate padding and spacing
$paddingLeft = 20
$paddingTop = 20
$controlSpacing = 20
$buttonWidth = 100
$buttonHeight = 35
$paddingRight = 20

# Create the file selection label
$label = New-Object System.Windows.Forms.Label
$labelX = $paddingLeft
$labelY = $paddingTop
$label.Location = New-Object System.Drawing.Point($labelX, $labelY)
$label.Size = New-Object System.Drawing.Size(200, 25)
$label.Text = "Select files to convert:"
$label.Font = $commonFont
$label.ForeColor = $foregroundColor
$form.Controls.Add($label)

# Create the browse button positioned at the far right
$browseButton = New-Object System.Windows.Forms.Button
$browseButtonX = $form.ClientSize.Width - $paddingRight - $buttonWidth   # Far right position
$browseButtonY = $paddingTop - 2                                       # Slight vertical adjustment
$browseButton.Location = New-Object System.Drawing.Point($browseButtonX, $browseButtonY)
$browseButton.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
$browseButton.Text = "Browse"
$browseButton.Font = $commonFont
$browseButton.BackColor = $buttonColor
$browseButton.ForeColor = $foregroundColor
$browseButton.FlatStyle = "Flat"
$browseButton.FlatAppearance.BorderSize = 0
# Add hover effect
$browseButton.Add_MouseEnter({
    $browseButton.BackColor = $buttonHoverColor
})
$browseButton.Add_MouseLeave({
    $browseButton.BackColor = $buttonColor
})
$browseButton.Add_Click({ Get-Files })
$form.Controls.Add($browseButton)

# Adjust label width if necessary to prevent overlap
$label.Size = New-Object System.Drawing.Size(200, 25) # Ensure label width doesn't overlap with Browse button

# Create the file list box
$listBox = New-Object System.Windows.Forms.ListBox
$listBoxX = $paddingLeft
$listBoxY = $paddingTop + 50
$listBox.Location = New-Object System.Drawing.Point($listBoxX, $listBoxY)
$listBox.Size = New-Object System.Drawing.Size(490, 200)                  # Adjusted width to fit within the form
$listBox.SelectionMode = "MultiExtended"
$listBox.BackColor = $listBoxBackColor
$listBox.ForeColor = $listBoxForeColor
$listBox.Font = $commonFont
$listBox.BorderStyle = "FixedSingle"
$form.Controls.Add($listBox)

# Create the convert button
$convertButton = New-Object System.Windows.Forms.Button
$convertButtonX = $paddingLeft
$convertButtonY = $paddingTop + 270
$convertButton.Location = New-Object System.Drawing.Point($convertButtonX, $convertButtonY)
$convertButton.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
$convertButton.Text = "Convert"
$convertButton.Font = $commonFont
$convertButton.BackColor = $buttonColor
$convertButton.ForeColor = $foregroundColor
$convertButton.FlatStyle = "Flat"
$convertButton.FlatAppearance.BorderSize = 0
# Add hover effect
$convertButton.Add_MouseEnter({
    $convertButton.BackColor = $buttonHoverColor
})
$convertButton.Add_MouseLeave({
    $convertButton.BackColor = $buttonColor
})
$convertButton.Add_Click({ Convert-Files })
$form.Controls.Add($convertButton)

# Create the exit button
$exitButton = New-Object System.Windows.Forms.Button
$exitButtonX = $form.ClientSize.Width - $paddingRight - $buttonWidth  # Far right position
$exitButtonY = $paddingTop + 270
$exitButton.Location = New-Object System.Drawing.Point($exitButtonX, $exitButtonY)
$exitButton.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
$exitButton.Text = "Exit"
$exitButton.Font = $commonFont
$exitButton.BackColor = $buttonColor
$exitButton.ForeColor = $foregroundColor
$exitButton.FlatStyle = "Flat"
$exitButton.FlatAppearance.BorderSize = 0
# Add hover effect
$exitButton.Add_MouseEnter({
    $exitButton.BackColor = $buttonHoverColor
})
$exitButton.Add_MouseLeave({
    $exitButton.BackColor = $buttonColor
})
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Function to get files
function Get-Files {
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath("MyDocuments")
        Filter = "Text files (*.txt)|*.txt"
        Multiselect = $true
    }
    if ($fileDialog.ShowDialog() -eq "OK") {
        $listBox.Items.Clear()
        foreach ($file in $fileDialog.FileNames) {
            if ([System.IO.Path]::GetExtension($file) -eq ".txt") {
                $listBox.Items.Add($file)
            } else {
                [System.Windows.Forms.MessageBox]::Show("Invalid file type: $file", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    }
}

# Function to convert files
function Convert-Files {
    if ($listBox.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No files selected for conversion.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $firstFile = $listBox.Items[0]
    $directory = [System.IO.Path]::GetDirectoryName($firstFile)
    $outputFolder = Join-Path $directory "Converted PS1 Files"
    if (!(Test-Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder | Out-Null
    }
    foreach ($file in $listBox.Items) {
        $fileName = [System.IO.Path]::GetFileName($file)
        $newFile = Join-Path $outputFolder ($fileName -replace "\.txt$", ".ps1")
        if (Test-Path $newFile) {
            $response = [System.Windows.Forms.MessageBox]::Show("File $newFile already exists. Overwrite?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
            if ($response -eq [System.Windows.Forms.DialogResult]::No) {
                continue
            }
        }
        Copy-Item $file $newFile -Force
    }
    [System.Windows.Forms.MessageBox]::Show("Conversion complete!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# Show the GUI form
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
