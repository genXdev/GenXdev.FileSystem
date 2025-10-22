// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Move-ItemWithTracking.cs
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
using System.Diagnostics;
using System.IO;
using System.Management.Automation;
using System.Runtime.InteropServices;
using Microsoft.CodeAnalysis;

namespace GenXdev.FileSystem
{
    /// <summary>
    /// <para type="synopsis">
    /// Moves files and directories while preserving filesystem links and references.
    /// </para>
    ///
    /// <para type="description">
    /// Uses the Windows MoveFileEx API to move files and directories with link tracking
    /// enabled. This ensures that filesystem references, symbolic links, and hardlinks
    /// are maintained. If the source path is under Git control, it attempts to use `git mv`
    /// to track the rename in Git. Falls back to MoveFileEx if Git is not available or
    /// the git mv operation fails. The function is particularly useful for tools like Git
    /// that need to track file renames.
    /// </para>
    ///
    /// <para type="description">
    /// PARAMETERS
    /// </para>
    ///
    /// <para type="description">
    /// -Path &lt;string&gt;<br/>
    /// The source path of the file or directory to move. Accepts pipeline input and
    /// aliases to FullName for compatibility with Get-ChildItem output.<br/>
    /// - <b>Aliases</b>: FullName<br/>
    /// - <b>Position</b>: 0<br/>
    /// - <b>Mandatory</b>: true<br/>
    /// </para>
    ///
    /// <para type="description">
    /// -Destination &lt;string&gt;<br/>
    /// The target path where the file or directory should be moved to. Must be a valid
    /// filesystem path.<br/>
    /// - <b>Position</b>: 1<br/>
    /// - <b>Mandatory</b>: true<br/>
    /// </para>
    ///
    /// <para type="description">
    /// -Force &lt;SwitchParameter&gt;<br/>
    /// If specified, allows overwriting an existing file or directory at the
    /// destination path.<br/>
    /// - <b>Default</b>: false<br/>
    /// </para>
    ///
    /// <example>
    /// <para>Example 1: Move a file while preserving links and Git tracking</para>
    /// <para>Moves a file while preserving any existing filesystem links or Git tracking</para>
    /// <code>
    /// Move-ItemWithTracking -Path "C:\temp\oldfile.txt" -Destination "D:\newfile.txt"
    /// </code>
    /// </example>
    ///
    /// <example>
    /// <para>Example 2: Move a directory with force overwrite</para>
    /// <para>Moves a directory, overwriting destination if it exists, with Git tracking if applicable</para>
    /// <code>
    /// "C:\temp\olddir" | Move-ItemWithTracking -Destination "D:\newdir" -Force
    /// </code>
    /// </example>
    /// </summary>
    [Cmdlet(VerbsCommon.Move, "ItemWithTracking")]
    [OutputType(typeof(bool))]
    public partial class MoveItemWithTrackingCommand : PSGenXdevCmdlet
    {
        /// <summary>
        /// The source path of the file or directory to move
        /// </summary>
        [Parameter(
            Mandatory = true,
            Position = 0,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = true,
            HelpMessage = "Source path of file/directory to move")]
        [ValidateNotNullOrEmpty]
        [Alias("FullName")]
        public string Path { get; set; }

        /// <summary>
        /// The target path where the file or directory should be moved to
        /// </summary>
        [Parameter(
            Mandatory = true,
            Position = 1,
            HelpMessage = "Destination path to move to")]
        [ValidateNotNullOrEmpty]
        public string Destination { get; set; }

        /// <summary>
        /// Allows overwriting an existing file or directory at the destination
        /// </summary>
        [Parameter(
            HelpMessage = "Overwrite destination if it exists")]
        public SwitchParameter Force { get; set; }

        // P/Invoke declaration for MoveFileEx
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern bool MoveFileEx(
            string lpExistingFileName,
            string lpNewFileName,
            int dwFlags);

        /// <summary>
        /// Begin processing - initialization logic
        /// </summary>
        protected override void BeginProcessing()
        {
            // No initialization needed beyond P/Invoke declaration
        }

        /// <summary>
        /// Process record - main cmdlet logic
        /// </summary>
        protected override void ProcessRecord()
        {
            try
            {
                // Convert relative paths to absolute filesystem paths
                string fullSourcePath = ExpandPath(Path);
                string fullDestPath = ExpandPath(Destination);

                // Verify the source path exists before attempting move
                if (File.Exists(fullSourcePath) || Directory.Exists(fullSourcePath))
                {
                    // Check if user wants to proceed with the operation
                    if (ShouldProcess(fullSourcePath, $"Move to {fullDestPath}"))
                    {
                        // Check if git is available
                        bool gitAvailable = IsGitAvailable();

                        if (gitAvailable)
                        {
                            // Check if the source path is under Git control
                            if (IsGitRepository(fullSourcePath))
                            {
                                WriteVerbose("Source path is under Git control, attempting git mv");

                                // Attempt git mv
                                if (TryGitMove(fullSourcePath, fullDestPath, Force.ToBool()))
                                {
                                    WriteVerbose("Git mv completed successfully");

                                    // Verify the move occurred
                                    if (!File.Exists(fullSourcePath) && !Directory.Exists(fullSourcePath) &&
                                        (File.Exists(fullDestPath) || Directory.Exists(fullDestPath)))
                                    {
                                        WriteObject(true);
                                        return;
                                    }
                                    else
                                    {
                                        WriteVerbose("Git mv reported success but move not confirmed, falling back to MoveFileEx");
                                    }
                                }
                                else
                                {
                                    WriteVerbose("Git mv failed, falling back to MoveFileEx");
                                }
                            }
                        }

                        // Fallback to MoveFileEx logic
                        WriteVerbose($"Moving {fullSourcePath} to {fullDestPath} using MoveFileEx");

                        // Configure move operation flags
                        const int MOVEFILE_WRITE_THROUGH = 0x8;
                        const int MOVEFILE_REPLACE_EXISTING = 0x1;

                        int flags = MOVEFILE_WRITE_THROUGH;
                        if (Force.ToBool())
                        {
                            flags |= MOVEFILE_REPLACE_EXISTING;
                        }

                        bool result = MoveFileEx(fullSourcePath, fullDestPath, flags);

                        if (!result)
                        {
                            // Get detailed error information on failure
                            int errorCode = Marshal.GetLastWin32Error();
                            throw new InvalidOperationException($"Move failed from '{fullSourcePath}' to '{fullDestPath}'. Error: {errorCode}");
                        }

                        WriteVerbose("Move completed successfully with link tracking");
                        WriteObject(true);
                    }
                    else
                    {
                        WriteObject(false);
                    }
                }
                else
                {
                    WriteWarning($"Source path not found: {fullSourcePath}");
                    WriteObject(false);
                }
            }
            catch (Exception ex)
            {
                WriteError(new ErrorRecord(ex, "MoveItemWithTrackingError", ErrorCategory.InvalidOperation, null));
                WriteObject(false);
            }
        }

        /// <summary>
        /// End processing - cleanup logic
        /// </summary>
        protected override void EndProcessing()
        {
            // No cleanup needed
        }

        /// <summary>
        /// Check if git command is available
        /// </summary>
        private bool IsGitAvailable()
        {
            return InvokeScript<bool>("if (git.exe --version) { $true } else { $false }");
        }

        /// <summary>
        /// Check if the path is inside a Git repository
        /// </summary>
        private bool IsGitRepository(string path)
        {
            string sourceDir = System.IO.Path.GetDirectoryName(path);
            string originalDir = Directory.GetCurrentDirectory();

            try
            {
                Directory.SetCurrentDirectory(sourceDir);

                using (Process process = new Process())
                {
                    bool r = InvokeScript<string>("git.exe rev-parse --is-inside-work-tree").Trim() == "true";
                    return process.ExitCode == 0 && r;
                }
            }
            catch
            {
                return false;
            }
            finally
            {
                Directory.SetCurrentDirectory(originalDir);
            }
        }

        /// <summary>
        /// Attempt to move using git mv
        /// </summary>
        private bool TryGitMove(string sourcePath, string destPath, bool force)
        {
            try
            {
                var script = ScriptBlock.Create("param($sourcePath, $destPath) git.exe mv -f $sourcePath $destPath");
                script.Invoke(sourcePath, destPath);
                return !System.IO.File.Exists(sourcePath) &&
                    System.IO.File.Exists(destPath);
            }
            catch
            {
                return false;
            }
        }
    }
}