// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : PSGenXdevCmdlet.Utilities.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.302.2025
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



using System.Collections;
using System.Collections.Concurrent;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Management;
using System.Management.Automation;
using System.Runtime.InteropServices;
using Microsoft.PowerShell.Commands;

public abstract partial class PSGenXdevCmdlet : PSCmdlet
{
    /// <summary>
    /// Normalizes paths by removing long path prefixes for non-filesystem use.
    /// </summary>
    /// <param name="path">The path to normalize.</param>
    /// <returns>The normalized path.</returns>
    protected string NormalizePathForNonFileSystemUse(string path)
    {
        // force paths internally to have backslashes
        path = path.Replace("/", "\\");

        // path references user home directory?
        if (path == "~" || path.StartsWith("~\\"))
        {
            string home = this.SessionState.Path.GetResolvedPSPathFromPSPath("~")[0].Path;
            path = path == "~" ? home : Path.Combine(home, path.Substring(2));
        }

        // check for unc long path prefix
        if (path.StartsWith(@"\\?\UNC\", StringComparison.InvariantCultureIgnoreCase))
        {

            // remove prefix and adjust
            string result = @"\\" + path.Substring(8);

            return result;
        }

        // check for local long path prefix
        if (path.StartsWith(@"\\?\"))
        {
            // remove prefix
            string result = path.Substring(4);

            return result;
        }

        // check for alternate unc prefix
        if (path.StartsWith(@"\??\UNC\", StringComparison.InvariantCultureIgnoreCase))
        {

            // remove prefix and adjust
            string result = @"\\" + path.Substring(8);

            return result;
        }

        // check for alternate local prefix
        if (path.StartsWith(@"\??\"))
        {

            // remove prefix
            string result = path.Substring(4);

            return result;
        }

        // return unchanged if no prefix
        return path;
    }

    /// <summary>
    /// Gets the number of physical cores for default parallelism
    /// </summary>
    /// count of physical cores.</returns>
    public int GetCoreCount()
    {
        // initialize core count accumulator
        int totalPhysicalCores = 0;

        // query WMI for accurate physical core counts per processor
        using (var searcher = new ManagementObjectSearcher("SELECT NumberOfCores FROM Win32_Processor"))
        {
            // iterate through each processor and sum physical cores
            // handles multi-socket systems correctly
            foreach (var item in searcher.Get())
            {
                totalPhysicalCores += Convert.ToInt32(item["NumberOfCores"]);
            }
        }

        // return total physical cores across all processors
        return totalPhysicalCores;
    }

    /// <summary>
    /// Gets available RAM in bytes for resource calculations
    /// </summary>
    /// bytes of RAM.</returns>
    protected long GetFreeRamInBytes()
    {
        try
        {
            // Use direct Windows API call for better performance
            if (NativeMethods.GlobalMemoryStatusEx(out MEMORYSTATUSEX memStatus))
            {
                return (long)memStatus.ullAvailPhys;
            }
        }
        catch
        {
            // Fall back to managed approach if P/Invoke fails
        }

        // Fallback: Use GC for approximate available memory
        // This is less accurate but has no external dependencies
        try
        {
            GC.Collect(0, GCCollectionMode.Optimized);
            long totalMemory = GC.GetTotalMemory(false);

            // Estimate available memory based on process working set
            using (var process = Process.GetCurrentProcess())
            {
                long workingSet = process.WorkingSet64;
                long maxWorkingSet = process.MaxWorkingSet.ToInt64();

                // Conservative estimate: assume we can use up to 80% of remaining working set
                return (long)((maxWorkingSet - workingSet) * 0.8);
            }
        }
        catch
        {
            // Ultimate fallback: return conservative estimate
            return 1024 * 1024 * 512; // 512 MB
        }
    }

    /// <summary>
    /// Memory status structure for Windows API calls.
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    private struct MEMORYSTATUSEX
    {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;

        public MEMORYSTATUSEX()
        {
            dwLength = (uint)Marshal.SizeOf<MEMORYSTATUSEX>();
            dwMemoryLoad = 0;
            ullTotalPhys = 0;
            ullAvailPhys = 0;
            ullTotalPageFile = 0;
            ullAvailPageFile = 0;
            ullTotalVirtual = 0;
            ullAvailVirtual = 0;
            ullAvailExtendedVirtual = 0;
        }
    }
    /// <summary>
    /// Native Windows API methods for memory information.
    /// </summary>
    private static class NativeMethods
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool GlobalMemoryStatusEx(out MEMORYSTATUSEX lpBuffer);
    }
}