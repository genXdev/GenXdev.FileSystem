// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Set-LocationParent2.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.308.2025
// ################################################################################
// Copyright (c)  René Vaessen / GenXdev
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// ################################################################################



using System.Management.Automation;

namespace GenXdev.FileSystem
{
    /// <summary>
    /// <para type="synopsis">
    /// Navigates up two directory levels in the file system hierarchy.
    /// </para>
    ///
    /// <para type="description">
    /// Changes the current working directory to the grandparent directory (two levels up)
    /// and displays the contents of the resulting directory.
    /// </para>
    ///
    /// <para type="description">
    /// PARAMETERS
    /// </para>
    ///
    /// <para type="description">
    /// This cmdlet has no parameters.
    /// </para>
    ///
    /// <example>
    /// <para>Example 1: Navigate up two directory levels</para>
    /// <para>Changes to the grandparent directory and displays its contents.</para>
    /// <code>
    /// Set-LocationParent2
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Example 2: Using the alias</para>
    /// <para>Same as above using the '...' alias.</para>
    /// <code>
    /// ...
    /// </code>
    /// </example>
    /// </summary>
    [Cmdlet(VerbsCommon.Set, "LocationParent2", SupportsShouldProcess = true)]
    [Alias("...")]
    [OutputType(typeof(PSObject))]
    public class SetLocationParent2Command : PSGenXdevCmdlet
    {
        /// <summary>
        /// Begin processing - initialization logic
        /// </summary>
        protected override void BeginProcessing()
        {
            // Output verbose information about current location
            WriteVerbose("Current location: " + SessionState.Path.CurrentLocation.Path);
        }

        /// <summary>
        /// Process record - main cmdlet logic for navigating up directories
        /// </summary>
        protected override void ProcessRecord()
        {
            // Loop through two levels of navigation
            for (int i = 1; i <= 2; i++)
            {
                // Get the parent directory of current location
                var parentResult = InvokeCommand.InvokeScript(
                    "Microsoft.PowerShell.Management\\Split-Path -Path " +
                    "(Microsoft.PowerShell.Management\\Get-Location) -Parent");

                // Check if parent is null (at root level)
                if (parentResult.Count == 0 || parentResult[0] == null)
                {
                    // Write verbose message when cannot go up further
                    WriteVerbose("Cannot go up further - at root level");
                    break;
                }

                // Get the parent path as string
                string parentPath = parentResult[0].ToString();

                // Prepare target description for ShouldProcess
                string target = $"from '{SessionState.Path.CurrentLocation.Path}' to " +
                    $"'{parentPath}' (level {i} of 2)";

                // Only navigate if ShouldProcess returns true
                if (ShouldProcess(target, "Change location"))
                {
                    // Change to the parent directory
                    InvokeCommand.InvokeScript(
                        $"Microsoft.PowerShell.Management\\Set-Location -LiteralPath '{parentPath}'");
                }
                else
                {
                    // Exit the loop if user declined
                    break;
                }
            }

            // Check WhatIf preference
            bool whatIfPreference = (bool)(SessionState.PSVariable.GetValue("WhatIfPreference") ?? false);

            // Show contents of the new current directory if not in WhatIf mode and on FileSystem provider
            if (!whatIfPreference && SessionState.Path.CurrentLocation.Provider.Name == "FileSystem")
            {
                // Get child items and output them
                var childItems = InvokeCommand.InvokeScript("Microsoft.PowerShell.Management\\Get-ChildItem");
                WriteObject(childItems, true);
            }
        }

        /// <summary>
        /// End processing - cleanup logic
        /// </summary>
        protected override void EndProcessing()
        {
            // Output verbose information about final directory location
            WriteVerbose("Navigation completed to: " + SessionState.Path.CurrentLocation.Path);
        }
    }
}