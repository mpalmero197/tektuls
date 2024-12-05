<#
.SYNOPSIS
    A PowerShell script that displays network disconnection events in a dark mode GUI with improved readability.
.DESCRIPTION
    This script loads a GUI form first and waits for the user to press a button to check for network disconnection events.
    The DataGrid now has a dark background and white text for better readability.
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# Function to create the GUI
function Show-NetworkEventsGUI {
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Network Disconnection Events" Height="650" Width="800" WindowStartupLocation="CenterScreen" Background="#2D2D30" Foreground="White">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Orientation="Horizontal" Grid.Row="0" Margin="0,0,0,10">
            <Label Content="Time Range:" VerticalAlignment="Center"/>
            <ComboBox Name="TimeRangeComboBox" Width="150" Margin="5,0">
                <ComboBoxItem Content="Last 24 Hours" IsSelected="True"/>
                <ComboBoxItem Content="Last 7 Days"/>
                <ComboBoxItem Content="Last 30 Days"/>
            </ComboBox>
            <Button Name="CheckEventsButton" Content="Check for Events" Width="120" Margin="10,0"/>
        </StackPanel>
        <DataGrid Name="EventsDataGrid" Grid.Row="1" AutoGenerateColumns="False" CanUserAddRows="False"
                  Background="#1E1E1E" Foreground="White"
                  RowBackground="#1E1E1E" AlternatingRowBackground="#252526"
                  GridLinesVisibility="None" HeadersVisibility="Column" BorderBrush="#2D2D30">
            <DataGrid.Resources>
                <!-- Style for DataGridRow -->
                <Style TargetType="{x:Type DataGridRow}">
                    <Setter Property="Background" Value="#1E1E1E"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="BorderThickness" Value="0"/>
                    <Style.Triggers>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter Property="Background" Value="#007ACC"/>
                            <Setter Property="Foreground" Value="White"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
                <!-- Style for DataGridCell -->
                <Style TargetType="{x:Type DataGridCell}">
                    <Setter Property="Background" Value="#1E1E1E"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="BorderThickness" Value="0.5"/>
                    <Setter Property="BorderBrush" Value="#2D2D30"/>
                    <Style.Triggers>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter Property="Background" Value="#007ACC"/>
                            <Setter Property="Foreground" Value="White"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
                <!-- Style for DataGridColumnHeader -->
                <Style TargetType="{x:Type DataGridColumnHeader}">
                    <Setter Property="Background" Value="#2D2D30"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="BorderBrush" Value="#2D2D30"/>
                </Style>
            </DataGrid.Resources>
            <DataGrid.Columns>
                <DataGridTextColumn Header="Time" Binding="{Binding TimeGenerated}" Width="150">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Foreground" Value="White"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Source" Binding="{Binding Source}" Width="150">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Foreground" Value="White"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Event ID" Binding="{Binding EventID}" Width="75">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Foreground" Value="White"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Message" Binding="{Binding Message}" Width="*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="Foreground" Value="White"/>
                            <Setter Property="TextWrapping" Value="Wrap"/>
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>
        <!-- Footer Label -->
        <Label Grid.Row="2" Content="© 2024 Michael Palmero" HorizontalAlignment="Center" Margin="0,10,0,0"
               Foreground="Gray" FontSize="12"/>
    </Grid>
</Window>
"@

    # Load the XAML
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Find controls
    $TimeRangeComboBox = $window.FindName("TimeRangeComboBox")
    $CheckEventsButton = $window.FindName("CheckEventsButton")
    $EventsDataGrid = $window.FindName("EventsDataGrid")

    # Function to retrieve network disconnection events
    function Get-NetworkEvents {
        param (
            [int]$Days = 1
        )
        $startTime = (Get-Date).AddDays(-$Days)

        # Retrieve events from the 'System' log
        $events = Get-EventLog -LogName 'System' -After $startTime

        # Filter network disconnection events
        $networkEvents = $events | Where-Object {
            $_.Message -match 'disconnect|network link is disconnected|no network connectivity|lost connection|network interface is down|link is down|network is disconnected|media disconnected|NIC disconnected'
        }

        return $networkEvents
    }

    # Event handler for the Check Events button
    $CheckEventsButton.Add_Click({
        # Determine the time range
        $selectedTimeRange = $TimeRangeComboBox.SelectionBoxItem.ToString()
        switch ($selectedTimeRange) {
            'Last 24 Hours' { $days = 1 }
            'Last 7 Days' { $days = 7 }
            'Last 30 Days' { $days = 30 }
            default { $days = 1 }
        }

        # Get network events
        $networkEvents = Get-NetworkEvents -Days $days

        # Update the data grid
        if ($networkEvents) {
            $EventsDataGrid.ItemsSource = $networkEvents
        } else {
            $EventsDataGrid.ItemsSource = @()
            [System.Windows.MessageBox]::Show("No network disconnection events found in the selected time range.", "Information", "OK", "Information")
        }
    })

    # Show the window
    $window.ShowDialog() | Out-Null
}

# Run the GUI function
Show-NetworkEventsGUI
