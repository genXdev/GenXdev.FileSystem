// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Remove-OnReboot.cs
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



using System;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using Microsoft.Win32;

namespace GenXdev.FileSystem
{
    /// <summary>
    /// <para type="synopsis">
    /// Marks files or directories for deletion during the next system boot.
    /// </para>
    ///
    /// <para type="description">
    /// This function uses the Windows API to mark files for deletion on next boot.
    /// It handles locked files by first attempting to rename them to temporary names
    /// and tracks all moves to maintain file system integrity. If renaming fails,
    /// the -MarkInPlace parameter can be used to mark files in their original location.
    /// </para>
    ///
    /// <para type="description">
    /// PARAMETERS
    /// </para>
    ///
    /// <para type="description">
    /// -Path &lt;string[]&gt;<br/>
    /// One or more file or directory paths to mark for deletion. Accepts pipeline input.<br/>
    /// - <b>Aliases</b>: FullName<br/>
    /// - <b>Position</b>: 0<br/>
    /// - <b>Mandatory</b>: true<br/>
    /// </para>
    ///
    /// <para type="description">
    /// -MarkInPlace &lt;SwitchParameter&gt;<br/>
    /// If specified, marks files for deletion in their original location when renaming fails. This is useful for locked files that cannot be renamed.<br/>
    /// - <b>Position</b>: named<br/>
    /// - <b>Default</b>: false<br/>
    /// </para>
    ///
    /// <example>
    /// <para>Mark a file for deletion on reboot</para>
    /// <para>This example marks a locked file for deletion during the next system boot.</para>
    /// <code>
    /// Remove-OnReboot -Path "C:\temp\locked-file.txt"
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Mark multiple files for deletion with pipeline input</para>
    /// <para>This example marks multiple files for deletion, using MarkInPlace for any that can't be renamed.</para>
    /// <code>
    /// "file1.txt","file2.txt" | Remove-OnReboot -MarkInPlace
    /// </code>
    /// </example>
    /// </summary>
    [Cmdlet(VerbsCommon.Remove, "OnReboot")]
    [OutputType(typeof(bool))]
    public class RemoveOnRebootCommand : PSGenXdevCmdlet
    {
        /// <summary>
        /// One or more file or directory paths to mark for deletion. Accepts pipeline input.
        /// </summary>
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            HelpMessage = "Path(s) to files/directories to mark for deletion"
        )]
        [ValidateNotNullOrEmpty]
        [Alias("FullName")]
        public string[] Path { get; set; }

        /// <summary>
        /// If specified, marks files for deletion in their original location when renaming fails.
        /// </summary>
        [Parameter(
            Mandatory = false,
            HelpMessage = "Marks files for deletion without renaming"
        )]
        public SwitchParameter MarkInPlace { get; set; }

        private List<string> pendingRenames;
        private int originalPendingCount;

        /// <summary>
        /// Initialize the cmdlet by retrieving existing pending file rename operations from the registry.
        /// </summary>
        protected override void BeginProcessing()
        {
            pendingRenames = new List<string>();

            // Retrieve existing pending file rename operations from registry
            try
            {
                using (var key = Registry.LocalMachine.OpenSubKey(@"SYSTEM\CurrentControlSet\Control\Session Manager"))
                {
                    if (key != null)
                    {
                        var value = key.GetValue("PendingFileRenameOperations") as string[];
                        if (value != null)
                        {
                            pendingRenames.AddRange(value);
                        }
                    }
                }
            }
            catch
            {
                // If we can't read existing operations, start with empty list
            }

            originalPendingCount = pendingRenames.Count;
        }

        /// <summary>
        /// Process each path in the pipeline, attempting to delete or mark for deletion on reboot.
        /// </summary>
        protected override void ProcessRecord()
        {
            foreach (var item in Path)
            {
                // Expand the path using base class method to maintain exact PowerShell path resolution behavior
                string fullPath = ExpandPath(item);

                // Check if the path exists
                bool exists = System.IO.File.Exists(fullPath) || System.IO.Directory.Exists(fullPath);

                if (!exists)
                {
                    WriteWarning($"Path not found: {fullPath}");
                    continue;
                }

                if (ShouldProcess(fullPath, "Mark for deletion on reboot"))
                {
                    try
                    {
                        // Attempt immediate deletion using .NET methods
                        if (System.IO.File.Exists(fullPath))
                        {
                            System.IO.File.Delete(fullPath);
                        }
                        else if (System.IO.Directory.Exists(fullPath))
                        {
                            System.IO.Directory.Delete(fullPath, true);
                        }
                        WriteVerbose($"Successfully deleted: {fullPath}");
                        continue;
                    }
                    catch
                    {
                        WriteVerbose("Direct deletion failed, attempting rename...");

                        try
                        {
                            // Create a hidden temporary file name
                            var dir = System.IO.Path.GetDirectoryName(fullPath);
                            var newName = "." + Guid.NewGuid().ToString();
                            var newPath = System.IO.Path.Combine(dir, newName);

                            // Rename the file using PowerShell Rename-Item
                            var renameScript = ScriptBlock.Create("param($oldPath, $newName) Microsoft.PowerShell.Management\\Rename-Item -LiteralPath $oldPath -NewName $newName -Force");
                            renameScript.Invoke(fullPath, newName);

                            // Set the renamed file as hidden and system
                            System.IO.File.SetAttributes(newPath, System.IO.File.GetAttributes(newPath) | System.IO.FileAttributes.Hidden | System.IO.FileAttributes.System);

                            WriteVerbose($"Renamed to hidden system file: {newPath}");

                            // Add to pending renames with Windows API path format
                            var sourcePath = "\\??\\" + newPath;
                            pendingRenames.Add(sourcePath);
                            pendingRenames.Add("");

                            WriteVerbose($"Marked for deletion on reboot: {newPath}");
                        }
                        catch (Exception ex)
                        {
                            if (MarkInPlace.ToBool())
                            {
                                WriteVerbose("Marking original file for deletion");
                                var sourcePath = "\\??\\" + fullPath;
                                pendingRenames.Add(sourcePath);
                                pendingRenames.Add("");
                            }
                            else
                            {
                                WriteError(new ErrorRecord(ex, "RenameFailed", ErrorCategory.InvalidOperation, fullPath));
                                continue;
                            }
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Save any accumulated pending file operations to the registry and return success status.
        /// </summary>
        protected override void EndProcessing()
        {
            if (pendingRenames.Count > originalPendingCount)
            {
                try
                {
                    // Save pending operations to registry as MultiString value
                    Registry.SetValue(@"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager", "PendingFileRenameOperations", pendingRenames.ToArray(), RegistryValueKind.MultiString);
                    WriteObject(true);
                }
                catch (Exception ex)
                {
                    WriteError(new ErrorRecord(ex, "RegistryWriteFailed", ErrorCategory.InvalidOperation, null));
                    WriteObject(false);
                }
            }
            else
            {
                WriteObject(true);
            }
        }
    }
}