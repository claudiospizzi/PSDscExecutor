[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/PSDscExecutor?label=PowerShell%20Gallery&logo=PowerShell)](https://www.powershellgallery.com/packages/PSDscExecutor)
[![Gallery Downloads](https://img.shields.io/powershellgallery/dt/PSDscExecutor?label=Downloads&logo=PowerShell)](https://www.powershellgallery.com/packages/PSDscExecutor)
[![GitHub Release](https://img.shields.io/github/v/release/claudiospizzi/PSPSDscExecutor?label=Release&logo=GitHub&sort=semver)](https://github.com/claudiospizzi/PSPSDscExecutor/releases)
[![GitHub CI Build](https://img.shields.io/github/actions/workflow/status/claudiospizzi/PSPSDscExecutor/ci.yml?label=CI%20Build&logo=GitHub)](https://github.com/claudiospizzi/PSPSDscExecutor/actions/workflows/ci.yml)

# PSDscExecutor PowerShell Module

Create and execute PowerShell DSC configurations without managing the LCM.

## Introduction

The PSDscExecutor uses the `Invoke-DscResource` cmdlet to invoke a DSC configuration without the need of manual compiling and invoking via a DSC LCM. This is especially useful, if DSC is used embedded in other controller scripts or to configure cloud services like Microsoft 365.

### Why PSDscExecutor?

But why should you use the **PSDscExecutor** over the built-in `Invoke-DscResource` cmdlet?

* Use PowerShell DSC configurations instead of single resources, including all benefits like auto-completion
* Detect and install all PowerShell modules dependencies on the target systems
* Use a local ad-hoc encryption certificate to protect secrets in the DSC configurations
* On the fly compiling to MOF and interpreting the compiled MOF
* Handle reboot with multiple options: always reboot, never reboot and continue, never reboot and quit or as the user.
* Option to execute only the **get** method for all resources to get the current state (as objects) by using `Get-DesiredState`
* Option to execute only the **test** method for all resources to check the desired state without applying it by using `Test-DesiredState`
* Option to execute only the **set** method for all resources to invoke the desired state but not checking it by using `Set-DesiredState` (maybe not so useful)
* **Invoke** the DSC configurations by using `Invoke-DesiredState` to bring it to the desired state by executing the **test** and **set** methods, if required in a loop, until the resource is in desired state

### Are there some limitations in PSDscExecutor?

Yes, the module is designed to execute the commands locally or on a single remote system.

* Multiple remote systems (nodes in the DSC configuration) are not supported
* It's required to use Windows PowerShell 5.1 because of a bug in the DSC configuration compilation in PowerShell 6/7
* Administrator permissions are required if invoked against the local system because in the background the `Invoke-DscResource` cmdlet is used which interacts with the LCM and the system wide module store

## Features

* **Get-DesiredState**  
  Get the current state of all resources in a configuration.

* **Test-DesiredState**  
  Test if all resources in a configuration are in the desired state.

* **Set-DesiredState**  
  Apply the desired state configuration to the targets once.

* **Invoke-DesiredState**  
  Perform get, set and test methods to bring the target system into the desired state. It will continue to test and set until the target system is in desired state.

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

## Contribute

Please feel free to contribute to this project. For the best development experience, please us the following tools:

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
