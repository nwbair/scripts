# Import the Excel module
Import-Module ImportExcel

# Clear the screen
Clear-Host

# Define the path to the Excel file
$excelPath = "D:\testing.xlsx"

# Define the Excel tab name (default to the first tab if not specified)
$excelTabName = "Sheet1"  

# Toggle for appending numbers (1),(2), etc to duplicate filenames
$appendFlag = 'Y'

# Define the path to the log files
$logPath = "$PSScriptRoot\reorg.log"
$errorLogPath = "$PSScriptRoot\reorg_errors.log"
$errorExcelPath = "$PSScriptRoot\failed_files.xlsx"

# Maximum number of concurrent jobs
$maxConcurrentJobs = 10

# Create a temporary directory for log files
$tempLogDir = "$PSScriptRoot\temp_logs"
if (!(Test-Path -Path $tempLogDir)) {
    New-Item -ItemType Directory -Path $tempLogDir > $null
}

# Function to write a log entry (main script context)
function Write-Log {
    param (
        [string]$message
    )
    $logMessage = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $message
    Add-Content -Path $logPath -Value $logMessage
}

# Function to get a unique filename by appending numbers
function Get-UniqueFileName {
    param (
        [string]$filePath
    )
    $directory = [System.IO.Path]::GetDirectoryName($filePath)
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    $extension = [System.IO.Path]::GetExtension($filePath)
    
    $counter = 1
    $newFilePath = $filePath
    while (Test-Path $newFilePath) {
        $newFilePath = Join-Path $directory ("{0} ({1}){2}" -f $fileName, $counter, $extension)
        $counter++
    }
    return $newFilePath
}

# Announce the process start
Write-Log -message "File reorganization process started."

# Read the Excel file
if ($excelTabName -eq "First") {
    $worksheet = (Import-Excel -Path $excelPath -DataOnly | Select-Object -First 1).PSObject.Properties.Name
    $fileList = Import-Excel -Path $excelPath -WorksheetName $worksheet
} else {
    $fileList = Import-Excel -Path $excelPath -WorksheetName $excelTabName
}

$totalFiles = $fileList.Count
$currentFile = 0

# Start jobs and limit concurrency
foreach ($row in $fileList) {
    $sourcePath = $row.SourcePath
    $destinationPath = $row.DestinationPath
    $tempLogPath = "$tempLogDir\temp_log_$([System.Guid]::NewGuid().ToString()).log"

    # Wait if the number of jobs exceeds the max concurrent jobs
    while ((Get-Job -State Running).Count -ge $maxConcurrentJobs) {
        Start-Sleep -Seconds 1
    }

    # Start the job and include the function definition within the script block
    $job = Start-Job -ScriptBlock {
        param($sourcePath, $destinationPath, $tempLogPath, $appendFlag)

        # Function to write a log entry to a temporary file
        function Write-Log {
            param (
                [string]$message
            )
            $logMessage = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $message
            Add-Content -Path $using:tempLogPath -Value $logMessage
        }

        # Function to get a unique filename by appending numbers
        function Get-UniqueFileName {
            param (
                [string]$filePath
            )
            $directory = [System.IO.Path]::GetDirectoryName($filePath)
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
            $extension = [System.IO.Path]::GetExtension($filePath)
            
            $counter = 1
            $newFilePath = $filePath
            while (Test-Path $newFilePath) {
                $newFilePath = Join-Path $directory ("{0} ({1}){2}" -f $fileName, $counter, $extension)
                $counter++
            }
            return $newFilePath
        }

        # Display the file being copied
        Write-Log -message "Copying $sourcePath to $destinationPath"

        # Ensure the destination directory exists
        $destinationDir = [System.IO.Path]::GetDirectoryName($destinationPath)
        if (!(Test-Path -Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir
        }

        if (Test-Path $sourcePath) {
            if (Test-Path $destinationPath) {
                if ($appendFlag -eq 'Y') {
                    $destinationPath = Get-UniqueFileName $destinationPath
                } else {
                    Write-Log -message "Error: Failed to copy $sourcePath to $destinationPath - File already exists"
                    return
                }
            }
            try {
                # Copy the file while preserving metadata
                Copy-Item -Path $sourcePath -Destination $destinationPath
                $fileCreationTime = (Get-Item $sourcePath).CreationTime
                (Get-Item $destinationPath).CreationTime = $fileCreationTime
                Write-Log -message "Completed job: Successfully copied $sourcePath to $destinationPath"
            }
            catch {
                Write-Log -message "Error: Failed to copy $sourcePath to $destinationPath - $_"
            }
        } else {
            Write-Log -message "Error: Failed to copy $sourcePath to $destinationPath - Source file not found"
        }
    } -ArgumentList $sourcePath, $destinationPath, $tempLogPath, $appendFlag
    
    # Update progress bar
    $currentFile++
    Write-Progress -Activity "Copying Files" -Status "Processing file $currentFile of $totalFiles" -PercentComplete (($currentFile / $totalFiles) * 100)
}

# Wait for all jobs to complete
Get-Job | Wait-Job | Out-Null

# Consolidate all temporary log files into the main log file
foreach ($tempLog in Get-ChildItem -Path $tempLogDir -Filter "temp_log_*.log") {
    Get-Content $tempLog.FullName | Add-Content -Path $logPath
    # Also add errors to the error log
    Get-Content $tempLog.FullName | Select-String -Pattern "Error:" | Add-Content -Path $errorLogPath
    Remove-Item $tempLog.FullName
}

# Remove the temporary log directory
Remove-Item -Path $tempLogDir -Recurse

# Announce the process completion
Write-Log -message "All files copied successfully. File reorganization process completed."
Write-Progress -Activity "Copying Files" -Status "Completed" -PercentComplete 100

# Extract errors and write to Excel for reprocessing
if (Test-Path $errorLogPath) {
    $errorLines = Get-Content $errorLogPath | Select-String -Pattern "Error: Failed to copy"
    $failedFiles = @()
    foreach ($line in $errorLines) {
        $line = $line -replace ".*Error: Failed to copy ", ""
        $components = $line -split " to "
        if ($components.Count -eq 2) {
            $pathInfo = $components[1] -split " - "
            $failedFiles += [PSCustomObject]@{
                SourcePath       = $components[0]
                DestinationPath  = $pathInfo[0]
                Reason           = $pathInfo[1]
            }
        }
    }
    $failedFiles | Export-Excel -Path $errorExcelPath -WorksheetName "Failed Files"
}
