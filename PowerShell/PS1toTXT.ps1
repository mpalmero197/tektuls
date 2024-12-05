Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the GUI form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PS1 to TXT Converter"
$form.Size = New-Object System.Drawing.Size(410, 300)
$form.StartPosition = "CenterScreen"

# Create the file selection label and button
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 20)
$label.Size = New-Object System.Drawing.Size(280, 20)
$label.Text = "Select files to convert:"
$form.Controls.Add($label)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(300, 20)
$browseButton.Size = New-Object System.Drawing.Size(75, 23)
$browseButton.Text = "Browse"
$browseButton.Add_Click({ Get-Files })
$form.Controls.Add($browseButton)

# Create the file list box
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 50)
$listBox.Size = New-Object System.Drawing.Size(365, 150)
$listBox.SelectionMode = "MultiExtended"
$form.Controls.Add($listBox)

# Create the convert button
$convertButton = New-Object System.Windows.Forms.Button
$convertButton.Location = New-Object System.Drawing.Point(10, 210)
$convertButton.Size = New-Object System.Drawing.Size(75, 23)
$convertButton.Text = "Convert"
$convertButton.Add_Click({ Convert-Files })
$form.Controls.Add($convertButton)

# Create the exit button
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Location = New-Object System.Drawing.Point(300, 210)
$exitButton.Size = New-Object System.Drawing.Size(75, 23)
$exitButton.Text = "Exit"
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Function to get files
function Get-Files {
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        InitialDirectory = [Environment]::GetFolderPath("MyDocuments")
        Filter = "PowerShell files (*.ps1)|*.ps1"
        Multiselect = $true
    }
    if ($fileDialog.ShowDialog() -eq "OK") {
        $listBox.Items.Clear()
        foreach ($file in $fileDialog.FileNames) {
            if ([System.IO.Path]::GetExtension($file) -eq ".ps1") {
                $listBox.Items.Add($file)
            } else {
                [System.Windows.Forms.MessageBox]::Show("Invalid file type: $file", "Error", "OK", "Error")
            }
        }
    }
}

# Function to convert files
function Convert-Files {
    $firstFile = $listBox.Items[0]
    $directory = [System.IO.Path]::GetDirectoryName($firstFile)
    $outputFolder = Join-Path $directory "Converted TXT Files"
    if (!(Test-Path $outputFolder)) {
        New-Item -ItemType Directory -Path $outputFolder
    }
    foreach ($file in $listBox.Items) {
        $fileName = [System.IO.Path]::GetFileName($file)
        $newFile = Join-Path $outputFolder ($fileName -replace "\.ps1$", ".txt")
        if (Test-Path $newFile) {
            $response = [System.Windows.Forms.MessageBox]::Show("File $newFile already exists. Overwrite?", "Confirm", "YesNo", "Question")
            if ($response -eq "No") {
                continue
            }
        }
        Copy-Item $file $newFile
    }
    [System.Windows.Forms.MessageBox]::Show("Conversion complete!", "Success", "OK", "Information")
}

# Show the GUI form
$form.Add_Shown({ $form.Activate() })
$form.ShowDialog()