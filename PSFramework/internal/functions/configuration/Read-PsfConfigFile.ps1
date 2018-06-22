﻿function Read-PsfConfigFile
{
<#
	.SYNOPSIS
		Reads a configuration file and parses it.
	
	.DESCRIPTION
		Reads a configuration file and parses it.
	
	.PARAMETER Path
		The path to the file to parse.
	
	.EXAMPLE
		PS C:\> Read-PsfConfigFile -Path config.json
	
		Reads the config.json file and returns interpreted configuration objects.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Path')]
		[string]
		$Path,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Weblink')]
		[string]
		$Weblink,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'RawJson')]
		[string]
		$RawJson
	)
	
	#region Utility Function
	function New-ConfigItem
	{
		[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
		[CmdletBinding()]
		param (
			$FullName,
			
			$Value,
			
			$Type,
			
			[switch]
			$KeepPersisted,
			
			[switch]
			$Enforced,
			
			[switch]
			$Policy
		)
		
		[pscustomobject]@{
			FullName	    = $FullName
			Value		    = $Value
			Type		    = $Type
			KeepPersisted   = $KeepPersisted
			Enforced	    = $Enforced
			Policy		    = $Policy
		}
	}
	#endregion Utility Function
	
	if ($Path)
	{
		if (-not (Test-Path $Path)) { return }
		$data = Get-Content -Path $Path -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
	}
	if ($Weblink)
	{
		$data = Invoke-WebRequest -UseBasicParsing -Uri $Weblink | ConvertFrom-Json -ErrorAction Stop
	}
	if ($RawJson)
	{
		$data = $RawJson | ConvertFrom-Json -ErrorAction Stop
	}
	
	foreach ($item in $data)
	{
		#region No Version
		if (-not $item.Version)
		{
			New-ConfigItem -FullName $item.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value, $item.Type))
		}
		#endregion No Version
		
		#region Version One
		if ($item.Version -eq 1)
		{
			if ($item.Style -eq "Simple") { New-ConfigItem -FullName $item.FullName -Value $item.Data }
			else
			{
				if ($item.Type -eq "Object")
				{
					New-ConfigItem -FullName $item.FullName -Value $item.Data -Type "Object" -KeepPersisted
				}
				else
				{
					New-ConfigItem -FullName $item.FullName -Value ([PSFramework.Configuration.ConfigurationHost]::ConvertFromPersistedValue($item.Value, $item.Type))
				}
			}
		}
		#endregion Version One
	}
}