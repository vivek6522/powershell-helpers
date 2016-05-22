<#

.SYNOPSIS
Compares JAR versions from given directories.

.DESCRIPTION
Does a comparison of what versions of JARs are used in two different directories (extracted EAR contents).
Outputs the report as a table indicating the version numbers and remarks for easy sorting

.PARAMETER OldDir
The older directory path containing versioned artifacts

.PARAMETER NewDir
The newer directory path containing versioned artifacts

.EXAMPLE
Report all components
Compare-Jar-Versions.ps1 C:\temp\oldEar C:\temp\newEar

.EXAMPLE
Report only changed components (pipe to Where-Object)
Compare-Jar-Versions.ps1 C:\temp\oldEar C:\temp\newEar | Where-Object Remarks -eq Change

#>

[CmdletBinding()]
param (
  [Parameter(Mandatory = $True, HelpMessage = "Older directory")]
  [string] $OldDir,
  [Parameter(Mandatory = $True, HelpMessage = "Newer directory")]
  [string] $NewDir
)

# Utility function which extracts JAR artifactId and version from the name and inserts into the given map
function AddJarToMap([string] $jarName, $map)
{
  # Throw away the extension
  $extensionTrimmedName = ($jarName -split '.jar')[0]

  # Extract the artifactId and version
  $artifactId = $extensionTrimmedName.SubString(0, $extensionTrimmedName.LastIndexOf('-'))
  $version = $extensionTrimmedName.SubString($extensionTrimmedName.LastIndexOf('-')+1)

  $map.Add($artifactId, $version)
}

# Start of script execution

# Holds artifacts from the older directory
$OldJarMap = @{}

# Holds artifacts from the newer directory
$NewJarMap = @{}

# Get all JAR files from the old directory and add them to the older map
foreach ( $jar in $(Get-ChildItem $OldDir -Name -Filter "*.jar") )
{
  AddJarToMap $jar $OldJarMap
}

# Get all JAR files from the new directory and add them to the newer map
foreach ( $jar in $(Get-ChildItem $NewDir -Name -Filter "*.jar") )
{
  AddJarToMap $jar $NewJarMap
}

# Holds the records for each comparison
$Records = @();

# Go through the old entries
foreach ( $key in $OldJarMap.Keys )
{
  if ( $NewJarMap.ContainsKey($key) )
  {
    if ( -Not ( $OldJarMap.Item($key) -eq $NewJarMap.Item($key) ) ) # Version changed
    {
      $Records += New-Object PSCustomObject -Property @{
        "ArtifactId" = $key
        "OldVersion" = $OldJarMap.Item($key)
        "NewVersion" = $NewJarMap.Item($key)
        "Remarks" = "Change"
      }
    }
    else # Version intact
    {
      $Records += New-Object PSCustomObject -Property @{
        "ArtifactId" = $key
        "OldVersion" = $OldJarMap.Item($key)
        "NewVersion" = $NewJarMap.Item($key)
        "Remarks" = "Intact"
      }
    }
  }
  else # Removed JAR
  {
    $Records += New-Object PSCustomObject -Property @{
      "ArtifactId" = $key
      "OldVersion" = $OldJarMap.Item($key)
      "NewVersion" = $NewJarMap.Item($key)
      "Remarks" = "Remove"
    }
  }
}

# Go through the new entries
foreach ( $key in $NewJarMap.Keys )
{
  if ( -Not $OldJarMap.ContainsKey($key) ) # New JAR
  {
    $Records += New-Object PSCustomObject -Property @{
      "ArtifactId" = $key
      "OldVersion" = $OldJarMap.Item($key)
      "NewVersion" = $NewJarMap.Item($key)
      "Remarks" = "New"
    }
  }
}

# Display report in alphabetical order by default
$Records | Select-Object ArtifactId, Remarks, OldVersion, NewVersion | Sort-Object ArtifactId, Remarks

# End of script execution
