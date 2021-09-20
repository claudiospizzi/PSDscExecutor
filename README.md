[![PowerShell Gallery - PSDscExecutor](https://img.shields.io/badge/PowerShell_Gallery-PSDscExecutor-0072C6.svg)](https://www.powershellgallery.com/packages/PSDscExecutor)
[![GitHub - Release](https://img.shields.io/github/release/claudiospizzi/PSDscExecutor.svg)](https://github.com/claudiospizzi/PSDscExecutor/releases)

# PSDscExecutor PowerShell Module

Create and execute PowerShell DSC configurations without using the LCM.

## Introduction

The PSDscExecutor uses the `Invoke-DscResource` cmdlet to invoke a DSC
configuration without the need of manual compiling and invoking via a DSC LCM.
This is especially useful, if DSC is used to configure cloud services like
Microsoft 365.

## Features

* **Get-DesiredState**  
  Get the current state of all resources in a configuration.

* **Test-DesiredState**  
  Test if all resources in a configuration are in the desired state.

* **Set-DesiredState**  
  Apply the desired state configuration to the targets.

## Versions

Please find all versions in the [GitHub Releases] section and the release notes
in the [CHANGELOG.md] file.

## Installation

Use the following command to install the module from the [PowerShell Gallery],
if the PackageManagement and PowerShellGet modules are available:

```powershell
# Download and install the module
Install-Module -Name 'PSDscExecutor'
```

Alternatively, download the latest release from GitHub and install the module
manually on your local system:

1. Download the latest release from GitHub as a ZIP file: [GitHub Releases]
2. Extract the module and install it: [Installing a PowerShell Module]

## Requirements

The following minimum requirements are necessary to use this module, or in other
words are used to test this module:

* Windows PowerShell 5.1
* PowerShell 7

In addition, the experimental feature to get the `Invoke-DscResource` must be
enabled if PowerShell 7 is used:

```powershell
Enable-ExperimentalFeature PSDesiredStateConfiguration.InvokeDscResource
```

## Contribute

Please feel free to contribute to this project. For the best development
experience, please us the following tools:

* [Visual Studio Code] with the [PowerShell Extension]
* [Pester], [PSScriptAnalyzer], [InvokeBuild], [InvokeBuildHelper] modules

[PowerShell Gallery]: https://psgallery.arcade.ch/feeds/powershell/ArcadeFramework
[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell

[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[InvokeBuild]: https://www.powershellgallery.com/packages/InvokeBuild
[InvokeBuildHelper]: https://www.powershellgallery.com/packages/InvokeBuildHelper
