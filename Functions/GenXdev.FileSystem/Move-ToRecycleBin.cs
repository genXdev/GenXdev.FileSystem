// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Move-ToRecycleBin.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.304.2025
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
using System.IO;
using System.Management.Automation;
using System.Runtime.InteropServices;

namespace GenXdev.FileSystem
{
    /// <summary>
    /// <para type="synopsis">
    /// Moves files and directories to the Windows Recycle Bin safely.
    /// </para>
    ///
    /// <para type="description">
    /// Safely moves files or directories to the recycle bin using the Windows Shell API,
    /// even if they are currently in use. The function uses the Shell.Application COM
    /// object to perform the operation, ensuring proper recycling behavior and undo
    /// capability.
    /// </para>
    ///
    /// <para type="description">
    /// PARAMETERS
    /// </para>
    ///
    /// <para type="description">
    /// -Path &lt;string[]&gt;<br/>
    /// One or more paths to files or directories that should be moved to the recycle
    /// bin. Accepts pipeline input and wildcards. The paths must exist and be
    /// accessible.<br/>
    /// - <b>Aliases</b>: FullName<br/>
    /// - <b>Position</b>: 0<br/>
    /// - <b>Default</b>: None<br/>
    /// </para>
    ///
    /// <example>
    /// <para>Move a single file to the recycle bin</para>
    /// <para>Detailed explanation of the example.</para>
    /// <code>
    /// Move-ToRecycleBin -Path "C:\temp\old-report.txt"
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Move multiple files using pipeline and alias</para>
    /// <para>Detailed explanation of the example.</para>
    /// <code>
    /// "file1.txt","file2.txt" | recycle
    /// </code>
    /// </example>
    /// </summary>
    [Cmdlet(VerbsCommon.Move, "ToRecycleBin")]
    [OutputType(typeof(bool))]
    public class MoveToRecycleBinCommand : PSGenXdevCmdlet
    {
        /// <summary>
        /// One or more paths to files or directories that should be moved to the recycle
        /// bin. Accepts pipeline input and wildcards. The paths must exist and be
        /// accessible.
        /// </summary>
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Specify the path(s) to move to the recycle bin")]
        [ValidateNotNullOrEmpty]
        [Alias("FullName")]
        public string[] Path { get; set; }

        private bool success = true;
        private dynamic shellObj;

        /// <summary>
        /// Begin processing - initialize shell automation object for recycle bin operations
        /// </summary>
        protected override void BeginProcessing()
        {
            // initialize shell automation object for recycle bin operations
            shellObj = null;

            try
            {
                shellObj = Activator.CreateInstance(Type.GetTypeFromProgID("Shell.Application"));
                WriteVerbose("Created Shell.Application COM object for recycle operations");
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "ComObjectCreationFailed", ErrorCategory.ResourceUnavailable, null));
                success = false;
            }
        }

        /// <summary>
        /// Process record - main cmdlet logic for processing each path
        /// </summary>
        protected override void ProcessRecord()
        {
            if (shellObj == null)
            {
                return;
            }

            foreach (string itemPath in Path)
            {
                // convert relative or shorthand paths to full filesystem paths
                string fullPath = ExpandPath(itemPath);

                WriteVerbose($"Processing path: {fullPath}");

                try
                {
                    // check if the target path actually exists before attempting to recycle
                    if (File.Exists(fullPath) || Directory.Exists(fullPath))
                    {
                        // confirm the recycle operation with the user
                        if (ShouldProcess(fullPath, "Move to Recycle Bin"))
                        {
                            // split the path into directory and filename for shell operation
                            string dirName = System.IO.Path.GetDirectoryName(fullPath);
                            string fileName = System.IO.Path.GetFileName(fullPath);

                            // get shell folder object for the directory containing the item
                            dynamic folderObj = shellObj.Namespace(dirName);
                            dynamic fileObj = folderObj.ParseName(fileName);

                            // perform the recycle operation using shell verbs
                            fileObj.InvokeVerb("delete");
                            WriteVerbose($"Successfully moved to recycle bin: {fullPath}");
                        }
                    }
                    else
                    {
                        WriteWarning($"Path not found: {fullPath}");
                        success = false;
                    }
                }
                catch (Exception ex)
                {
                    WriteError(new ErrorRecord(ex, "RecycleOperationFailed", ErrorCategory.InvalidOperation, fullPath));
                    success = false;
                }
            }
        }

        /// <summary>
        /// End processing - cleanup the COM object and return success status
        /// </summary>
        protected override void EndProcessing()
        {
            // cleanup the COM object to prevent resource leaks
            if (shellObj != null)
            {
                try
                {
                    Marshal.ReleaseComObject(shellObj);
                    WriteVerbose("Released Shell.Application COM object");
                }
                catch (Exception ex)
                {
                    WriteWarning($"Failed to release COM object: {ex.Message}");
                }
            }

            WriteObject(success);
        }
    }
}