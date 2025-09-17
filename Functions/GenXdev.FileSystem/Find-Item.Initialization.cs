// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Find-Item.Initialization.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.274.2025
// ################################################################################
// MIT License
//
// Copyright 2021-2025 GenXdev
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// ################################################################################



using StreamRegex.Extensions.Core;
using StreamRegex.Extensions.RegexExtensions;
using System.Collections.Concurrent;
using System.Collections.ObjectModel;
using System.Data.Common;
using System.Diagnostics;
using System.Management;
using System.Management.Automation;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using Windows.ApplicationModel.Calls;

/// <summary>
/// Handles initialization for the FindItem cmdlet.
/// </summary>
public partial class FindItem : PSCmdlet
{

    /// <summary>
    /// Sets up the pattern matcher for content search.
    /// </summary>
    protected void InitializePatternMatcher()
    {

        // check if custom pattern provided
        HavePattern = ".*" != Pattern;

        // set base regex options
        // Configure regex options based on case sensitivity
        var regexOptions = RegexOptions.Compiled | RegexOptions.CultureInvariant;

        // add ignore case if not sensitive
        if (!CaseSensitivePattern)
        {
            regexOptions |= RegexOptions.IgnoreCase;
        }

        // create regex matcher
        PatternMatcher = new Regex(Pattern, regexOptions);

        // log creation if verbose
        if (UseVerboseOutput)
        {
            VerboseQueue.Enqueue($"Pattern matcher created with options: {regexOptions}");
        }
    }

    /// <summary>
    /// Sets up cancellation token with optional timeout.
    /// </summary>
    protected void InitializeCancellationToken()
    {

        // create token source
        // Set up cancellation with optional timeout
        cts = new CancellationTokenSource();

        // apply timeout if specified
        if (TimeoutSeconds.HasValue)
        {
            cts.CancelAfter(TimeSpan.FromSeconds(TimeoutSeconds.Value));

            // log timeout if verbose
            if (UseVerboseOutput)
            {
                VerboseQueue.Enqueue($"Search timeout set to {TimeoutSeconds.Value} seconds");
            }
        }
    }

    /// <summary>
    /// Configures buffering for pattern matching.
    /// </summary>
    protected void InitializeBufferingConfiguration()
    {

        // calculate max file size from ram
        // Calculate max file size based on available RAM to prevent memory
        // issues
        var baseBufferLength = Math.Max(1024 * 1024, Math.Min(Int32.MaxValue - 1, Convert.ToInt64(Math.Round((GetFreeRamInBytes() / 10d) / Convert.ToDouble(MaxDegreeOfParallelism), 0))));

        // set overlap size
        int overlapSize = (int)Math.Max(1024 * 1024 * 5, Math.Min(baseBufferLength / 3, 1024 * 1024 * 2));

        // set buffer size
        PatternMatcherOptions.BufferSize = overlapSize * 3;

        // set overlap
        PatternMatcherOptions.OverlapSize = overlapSize;

        // disable value capture
        PatternMatcherOptions.DelegateOptions.CaptureValues = false;

        // log sizes if verbose
        if (UseVerboseOutput)
        {
            VerboseQueue.Enqueue($"Pattern matcher buffer size: {PatternMatcherOptions.BufferSize:N0} bytes");
            VerboseQueue.Enqueue($"Pattern matcher overlap size: {PatternMatcherOptions.OverlapSize:N0} bytes");
        }
    }

    /// <summary>
    /// Resolves the relative base directory.
    /// </summary>
    protected void InitializeRelativeBaseDir()
    {

        // declare base dir
        string baseDir;

        // check if base path provided
        if (!string.IsNullOrEmpty(RelativeBasePath))
        {

            // use full path if rooted
            if (Path.IsPathRooted(RelativeBasePath))
            {
                baseDir = Path.GetFullPath(RelativeBasePath);
            }
            else
            {

                // combine with current if relative
                baseDir = Path.GetFullPath(Path.Combine(CurrentDirectory, RelativeBasePath));
            }
        }
        else
        {

            // default to current
            baseDir = Path.GetFullPath(CurrentDirectory);
        }

        // set relative base
        RelativeBasePath = baseDir;
    }

    /// <summary>
    /// Sets the current directory safely.
    /// </summary>
    protected void InitializeCurrentDirectory()
    {

        // get powershell location
        // Get current PowerShell location for base directory
        var psLocation = InvokeScript<string>("(Get-Location).Path");

        // declare safe dir
        string safeDir = null;

        // declare validity
        bool isValid = false;

        // try to validate
        try
        {

            // get full path
            // Validate and get full path
            safeDir = Path.GetFullPath(psLocation);

            // check existence
            isValid = System.IO.Directory.Exists(safeDir);
        }
        catch
        {

            // log invalid if verbose
            if (UseVerboseOutput)
            {
                VerboseQueue.Enqueue($"Invalid current directory path: {psLocation}");
            }

            // set invalid
            isValid = false;
        }

        // use if valid
        if (isValid)
        {
            CurrentDirectory = safeDir;

            // log if verbose
            if (UseVerboseOutput)
            {
                VerboseQueue.Enqueue($"Using current directory: {CurrentDirectory}");
            }
        }
        else
        {

            // default to profile
            // Default to user profile if current directory invalid
            CurrentDirectory = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);

            // log default if verbose
            if (UseVerboseOutput)
            {
                VerboseQueue.Enqueue($"Defaulted to user profile directory: {CurrentDirectory}");
            }
        }
    }

    /// <summary>
    /// Sets up exclude patterns for wildcards.
    /// </summary>
    protected void InitializeExcludePatterns()
    {

        // set options based on casing
        this.CurrentWildCardOptions = CaseSearchMaskMatching == MatchCasing.PlatformDefault ? (
                     // windows or linux based?
                     Environment.OSVersion.Platform == PlatformID.Win32NT ?
                     WildcardOptions.IgnoreCase |
                     WildcardOptions.CultureInvariant : WildcardOptions.CultureInvariant
                ) : CaseSearchMaskMatching == MatchCasing.CaseInsensitive ? (
                   WildcardOptions.IgnoreCase |
                   WildcardOptions.CultureInvariant
                ) : WildcardOptions.CultureInvariant;

        // create file exclude patterns
        FileExcludePatterns = Exclude.Select(
            p => WildcardPattern.Get(p, CurrentWildCardOptions)
        ).ToArray();

        // create dir exclude patterns
        DirectoryExcludePatterns = Exclude.Select(
            p => WildcardPattern.Get(p.EndsWith("\\") ? p.TrimEnd('\\') : p, CurrentWildCardOptions)
        ).ToArray();

        // default git exclusion if none
        if (DirectoryExcludePatterns.Length == 0)
        {
            DirectoryExcludePatterns = new WildcardPattern[1] { new WildcardPattern("*\\.git", CurrentWildCardOptions) };
        }

    }

    /// <summary>
    /// Initializes wildcard matcher and deduplicates excludes.
    /// </summary>
    protected void InitializeWildcardMatcher()
    {

        // deduplicate excludes if present
        if (Exclude != null && Exclude.Length > 0)
        {
            Exclude = Exclude.Distinct().ToArray();
        }
        else
        {

            // set empty if none
            Exclude = Array.Empty<string>();
        }
    }

    /// <summary>
    /// Sets up visited nodes dictionary with appropriate comparer.
    /// </summary>
    protected void InitializeVisitedNodes()
    {

        // create dictionary with casing comparer
        VisitedNodes = new ConcurrentDictionary<string, bool>(
            comparer: (
                   this.CaseSearchMaskMatching == MatchCasing.PlatformDefault ?
                   (
                        // windows or linux based?
                        Environment.OSVersion.Platform == PlatformID.Win32NT ?
                        StringComparer.OrdinalIgnoreCase :
                        StringComparer.Ordinal
                   ) : (

                        this.CaseSearchMaskMatching == MatchCasing.CaseInsensitive ?
                            StringComparer.OrdinalIgnoreCase :
                            StringComparer.Ordinal
                   )
                )
        );
    }

    /// <summary>
    /// Initializes verbose output setting
    /// </summary>
    protected void InitializeVerboseOutput()
    {

        // attempt to set verbose
        try
        {

            // check verbose switch
            // Check for -Verbose switch
            bool verboseSwitch = MyInvocation.BoundParameters.ContainsKey("Verbose");

            // check preference if no switch
            // Fall back to VerbosePreference if no switch
            if (!verboseSwitch)
            {

                // get preference value
                var verbosePref = InvokeScript<string>("Write-Output ($VerbosePreference)");

                // evaluate preference
                verboseSwitch = !string.IsNullOrEmpty(verbosePref) &&
                               !verbosePref.Equals("SilentlyContinue", StringComparison.OrdinalIgnoreCase);
            }

            // set flag
            UseVerboseOutput = verboseSwitch;
        }
        catch
        {

            // default to false on error
            UseVerboseOutput = false;
        }
    }

    /// <summary>
    /// Prepares search directory from mask.
    /// </summary>
    /// <param name="searchMask">The search mask.</param>
    protected void InitializeSearchDirectory(string searchMask)
    {

        // normalize separators
        // Normalize separators to backslashes for consistency
        searchMask = searchMask.Replace("/", "\\");

        // normalize path
        // Normalize the path part for processing
        var normPath = NormalizePathForNonFileSystemUse(searchMask);

        // adjust trailing recurse
        // Adjust for trailing recursive patterns
        if (RecurseEndPatternWithSlashAtStartMatcher.IsMatch(normPath))
        {
            normPath += "\\";
        }

        // determine path types
        // Determine path type for correct handling
        bool isRooted = Path.IsPathRooted(normPath);
        bool isUncPath = normPath.StartsWith(@"\\");
        bool needsCurrentDir = !isUncPath && isRooted && (normPath.Length < 3 || normPath[2] != '\\');
        bool isRelative = !isRooted && !isUncPath;

        // remove leading dot
        // Remove leading .\ for clean path
        if (normPath.StartsWith(".\\"))
        {
            normPath = normPath.Substring(2);
        }

        // normalize duplicates in unc
        // Normalize duplicate separators
        if (isUncPath)
        {

            // find first separator after unc
            int i = normPath.IndexOf('\\', 2);

            // combine parts
            normPath = normPath.Substring(0, i) +
                        normPath.Substring(i).Replace("\\.\\", "\\").Replace("\\\\", "\\");
        }
        else
        {

            // normalize local
            normPath = normPath.Replace("\\.\\", "\\").Replace("\\\\", "\\");
        }

        // get drives to search
        var drives = GetDrivesToSearch().ToArray();

        // handle no specific drives
        // Handle search without specific drives
        if (drives.Length == 0)
        {
            ProcessSingleDriveSearch(normPath, isRelative, needsCurrentDir);
            return;
        }

        // process each drive
        // Process search for each specified drive
        foreach (var drive in drives)
        {
            ProcessDriveSearch(drive, normPath, isRelative, isRooted, isUncPath, needsCurrentDir);
        }
    }

    /// <summary>
    /// Processes search for single drive.
    /// </summary>
    /// <param name="searchMask">Mask.</param>
    /// <param name="isRelative">If relative.</param>
    /// <param name="needsCurrentDir">If needs current.</param>
    protected void ProcessSingleDriveSearch(string searchMask, bool isRelative, bool needsCurrentDir)
    {

        // check ending separator
        bool endsWithSeperator = searchMask.EndsWith("\\");

        // set final path
        var finalPath = searchMask;

        // handle relative
        if (isRelative)
        {

            // combine with current
            // Combine with current directory for relative paths
            finalPath = Path.Combine(CurrentDirectory, searchMask);
        }
        else if (needsCurrentDir)
        {

            // get drive current path
            // Get current path for the drive
            var currentPath = InvokeScript<string>($@"(Microsoft.PowerShell.Management\Get-Location -PSDrive {searchMask.Substring(0, 1)}).Path");

            // combine
            finalPath = Path.Combine(currentPath, searchMask.Substring(2));
        }

        // add separator if needed
        if (endsWithSeperator && !finalPath.EndsWith("\\"))
        {
            finalPath += "\\";
        }

        // add to queue
        AddToSearchQueue(finalPath);
    }

    /// <summary>
    /// Processes search for specific drive.
    /// </summary>
    /// <param name="drive">Drive info.</param>
    /// <param name="normPath">Normalized path.</param>
    /// <param name="isRelative">If relative.</param>
    /// <param name="isRooted">If rooted.</param>
    /// <param name="isUncPath">If UNC.</param>
    /// <param name="needsCurrentDir">If needs current.</param>
    protected void ProcessDriveSearch(DriveInfo drive, string normPath, bool isRelative, bool isRooted, bool isUncPath, bool needsCurrentDir)
    {

        // try processing
        try
        {

            // check root existence
            if (System.IO.Directory.Exists(drive.RootDirectory.FullName))
            {

                // set final path
                var finalPath = normPath;

                // handle relative
                if (isRelative)
                {
                    finalPath = Path.Combine(drive.RootDirectory.FullName, normPath);
                }
                else if (isRooted)
                {

                    // handle unc
                    if (isUncPath)
                    {

                        // find separator
                        int i = normPath.IndexOf('\\', 2);

                        // combine
                        finalPath = Path.Combine(drive.RootDirectory.FullName, normPath.Substring(i + 1));
                    }
                    else
                    {

                        // handle needs current
                        if (needsCurrentDir)
                        {
                            finalPath = drive.RootDirectory.FullName.Substring(0, 3) + normPath.Substring(2);
                        }
                        else
                        {
                            finalPath = drive.RootDirectory.FullName.Substring(0, 2) + normPath.Substring(2);
                        }
                    }
                }

                // add to queue
                AddToSearchQueue(finalPath);
            }
        }
        catch
        {

            // queue verbose skip
            VerboseQueue.Enqueue($"Skipping drive {drive.Name} due to access issues.");
        }
    }
}