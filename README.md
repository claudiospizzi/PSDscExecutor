[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/PSDscExecutor?label=PowerShell%20Gallery&logo=PowerShell)](https://www.powershellgallery.com/packages/PSDscExecutor)
[![Gallery Downloads](https://img.shields.io/powershellgallery/dt/PSDscExecutor?label=Downloads&logo=PowerShell)](https://www.powershellgallery.com/packages/PSDscExecutor)
[![GitHub Release](https://img.shields.io/github/v/release/claudiospizzi/PSPSDscExecutor?label=Release&logo=GitHub&sort=semver)](https://github.com/claudiospizzi/PSPSDscExecutor/releases)
[![GitHub CI Build](https://img.shields.io/github/actions/workflow/status/claudiospizzi/PSPSDscExecutor/ci.yml?label=CI%20Build&logo=GitHub)](https://github.com/claudiospizzi/PSPSDscExecutor/actions/workflows/ci.yml)

# PSDscExecutor PowerShell Module

Create and execute PowerShell DSC configurations without using the LCM.

## Introduction

The PSDscExecutor uses the `Invoke-DscResource` cmdlet to invoke a DSC configuration without the need of manual compiling and invoking via a DSC LCM. This is especially useful, if DSC is used embedded in other controller scripts or to configure cloud services like Microsoft 365.

## Features

* **Get-DesiredState**  
  Get the current state of all resources in a configuration.

* **Test-DesiredState**  
  Test if all resources in a configuration are in the desired state.

* **Set-DesiredState**  
  Apply the desired state configuration to the targets once.

* **Invoke-DesiredState**  
  Perform get, set and test methods to bring the target system into the desired state. It will continue to test and set until the target system is in desired state.

## Restrictions

This module has some limitations that need to be considered when it is used.

* Windows PowerShell 5.1: Don't use the PSDscResources module, as it is in conflict with the built-in PSDesiredStateConfiguration 1.1.

## Versions

Please find all versions in the [GitHub Releases] section and the release notes in the [CHANGELOG.md] file.

## Installation

Use the following command to install the module from the [PowerShell Gallery], if the PackageManagement and PowerShellGet modules are available:

```powershell
# Download and install the module
Install-Module -Name 'PSDscExecutor'
```

Alternatively, download the latest release from GitHub and install the module manually on your local system:

1. Download the latest release from GitHub as a ZIP file: [GitHub Releases]
2. Extract the module and install it: [Installing a PowerShell Module]

## Requirements

The following minimum requirements are necessary to use this module, or in other words are used to test this module:

* Windows PowerShell 5.1
* PowerShell 7

## Contribute

Please feel free to contribute to this project. For the best development
experience, please us the following tools:

* [Visual Studio Code] with the [PowerShell Extension]
* [Pester], [PSScriptAnalyzer], [InvokeBuild], [PSDscExecutor] modules

[PowerShell Gallery]: https://psgallery.arcade.ch/feeds/powershell/ArcadeFramework
[CHANGELOG.md]: CHANGELOG.md

[Visual Studio Code]: https://code.visualstudio.com/
[PowerShell Extension]: https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell

[Pester]: https://www.powershellgallery.com/packages/Pester
[PSScriptAnalyzer]: https://www.powershellgallery.com/packages/PSScriptAnalyzer
[InvokeBuild]: https://www.powershellgallery.com/packages/InvokeBuild
[PSDscExecutor]: https://www.powershellgallery.com/packages/PSDscExecutor
