// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Copy-IdenticalParamValues.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.298.2025
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



/*
<#
.SYNOPSIS
Copies parameter values from bound parameters to a new hashtable based on
another function's possible parameters.

.DESCRIPTION
This function creates a new hashtable containing only the parameter values that
match the parameters defined in the specified target function.
This can then be used to invoke the function using splatting.

Switch parameters are only included in the result if they were explicitly provided
and set to $true in the bound parameters. Non-present switch parameters are
excluded from the result to maintain proper parameter semantics.

.PARAMETER BoundParameters
The bound parameters from which to copy values, typically $PSBoundParameters.

.PARAMETER FunctionName
The name of the function whose parameter set will be used as a filter.

.PARAMETER DefaultValues
Default values for non-switch parameters that are not present in BoundParameters.

.EXAMPLE
function Test-Function {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $false)]
        [switch] $Recurse
    )

    $params = GenXdev.FileSystem\Copy-IdenticalParamValues -BoundParameters $PSBoundParameters `
        -FunctionName 'Get-ChildItem'

    Get-ChildItem @params
}

.NOTES
- Switch parameters are only included if explicitly set to $true
- Default values are only applied to non-switch parameters
- Common PowerShell parameters are automatically filtered out
#>
*/

using System.Collections;
using System.Collections.Concurrent;
using System.Management.Automation;

/// <summary>
/// Copies parameter values from bound parameters to a new hashtable based on
/// another function's possible parameters.
/// </summary>
[Cmdlet(VerbsCommon.Copy, "IdenticalParamValues")]
[OutputType(typeof(Hashtable))]
[System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly")]
public class CopyIdenticalParamValuesCommand : PSCmdlet
{
    #region Parameters

    /// <summary>
    /// The bound parameters from which to copy values, typically $PSBoundParameters.
    /// </summary>
    [Parameter(
        Mandatory = true,
        Position = 0,
        HelpMessage = "Source bound parameters to copy from")]
    [ValidateNotNull()]
    public object[] BoundParameters { get; set; }

    /// <summary>
    /// The name of the function whose parameter set will be used as a filter.
    /// </summary>
    [Parameter(
        Mandatory = true,
        Position = 1,
        HelpMessage = "Target function name to filter parameters")]
    [ValidateNotNullOrEmpty()]
    public string FunctionName { get; set; }

    /// <summary>
    /// Default values for non-switch parameters that are not present in BoundParameters.
    /// </summary>
    [Parameter(
        Mandatory = false,
        Position = 2,
        HelpMessage = "Default values for parameters")]
    public PSVariable[] DefaultValues { get; set; } = new PSVariable[0];

    #endregion

    #region Static Fields

    /// <summary>
    /// Common PowerShell parameters to filter out when copying parameters
    /// </summary>
    private static readonly string[] CommonParameterFilter;

    /// <summary>
    /// Cache for command info to avoid repeated PowerShell invocations
    /// Key: Function name, Value: CommandInfo object or null if not found
    /// </summary>
    private static readonly ConcurrentDictionary<string, CommandInfo> CommandInfoCache;

    #endregion

    #region Static Constructor

    /// <summary>
    /// Static constructor to initialize static fields
    /// </summary>
    static CopyIdenticalParamValuesCommand()
    {
        CommonParameterFilter = new string[]
        {
                "input",
                "MyInvocation",
                "null",
                "PSBoundParameters",
                "PSCmdlet",
                "PSCommandPath",
                "PSScriptRoot",
                "Verbose",
                "Debug",
                "ErrorAction",
                "ErrorVariable",
                "WarningAction",
                "WarningVariable",
                "InformationAction",
                "InformationVariable",
                "OutVariable",
                "OutBuffer",
                "PipelineVariable",
                "WhatIf",
                "Confirm",
                "OutVariable",
                "ProgressAction",
                "ErrorVariable",
                "Passthru",
                "PassThru"
        };

        // Initialize command info cache
        CommandInfoCache = new ConcurrentDictionary<string, CommandInfo>(StringComparer.OrdinalIgnoreCase);
    }

    #endregion

    #region Private Fields

    private Hashtable _results;
    private Hashtable _defaults;
    private CommandInfo _functionInfo;

    #endregion

    #region Cmdlet Lifecycle

    /// <summary>
    /// BeginProcessing - Initialize hashtables and get function information
    /// </summary>
    protected override void BeginProcessing()
    {
        // Initialize results hashtable
        _results = new Hashtable();

        // Create hashtable of default parameter values
        _defaults = CreateDefaultsHashtable();

        // Get function info for parameter validation (with caching)
        _functionInfo = GetCachedCommandInfo(FunctionName);

        if (_functionInfo?.Parameters == null)
        {
            var errorRecord = new ErrorRecord(
                new ArgumentException($"Function '{FunctionName}' not found"),
                "FunctionNotFound",
                ErrorCategory.ObjectNotFound,
                FunctionName);
            WriteError(errorRecord);
            return;
        }

        WriteVerbose($"Found function with {_functionInfo.Parameters.Count} parameters");
    }

    /// <summary>
    /// ProcessRecord - Main processing logic
    /// </summary>
    protected override void ProcessRecord()
    {
        if (_functionInfo?.Parameters == null)
            return;

        // Get the first bound parameters object (PowerShell passes as object[])
        var boundParamsObject = BoundParameters?.FirstOrDefault();
        if (boundParamsObject == null)
        {
            WriteObject(_results);
            return;
        }

        // Convert to hashtable-like access
        var boundParamsDict = ConvertToParameterDictionary(boundParamsObject);

        // Iterate through all parameters of the target function
        foreach (var parameterKvp in _functionInfo.Parameters)
        {
            var paramName = parameterKvp.Key;
            var paramInfo = parameterKvp.Value;

            // Check if parameter exists in bound parameters
            if (boundParamsDict.ContainsKey(paramName))
            {
                WriteVerbose($"Copying value for parameter '{paramName}'");
                var paramValue = boundParamsDict[paramName];

                // For switch parameters, only include if explicitly set to $true
                if (paramInfo.ParameterType == typeof(SwitchParameter))
                {
                    if (IsTrue(paramValue))
                    {
                        _results[paramName] = paramValue;
                        WriteVerbose($"Including switch parameter '{paramName}' (explicitly set to true)");
                    }
                    else
                    {
                        WriteVerbose($"Excluding switch parameter '{paramName}' (not set or false)");
                    }
                }
                else
                {
                    _results[paramName] = paramValue;
                }
            }
            else
            {
                // Only add default values for non-switch parameters
                if (paramInfo.ParameterType != typeof(SwitchParameter))
                {
                    var defaultValue = _defaults[paramName];
                    if (defaultValue != null)
                    {
                        _results[paramName] = defaultValue;

                        // Convert to JSON for verbose output, matching PowerShell behavior
                        var jsonValue = ConvertToJsonString(defaultValue);
                        WriteVerbose($"Using default value for '{paramName}': {jsonValue}");
                    }
                }
                else
                {
                    var defaultValue = _defaults[paramName];
                    if (IsTrue(defaultValue))
                    {
                        _results[paramName] = true;
                        WriteVerbose($"Using default value for '{paramName}': $True");
                    }
                }
            }
        }
    }

    /// <summary>
    /// EndProcessing - Output final results
    /// </summary>
    protected override void EndProcessing()
    {
        WriteVerbose($"Returning hashtable with {_results.Count} parameters");
        WriteObject(_results);
    }

    #endregion

    #region Private Helper Methods

    /// <summary>
    /// Gets command info with caching to improve performance
    /// </summary>
    /// <param name="functionName">Name of the function to get command info for</param>
    /// <returns>CommandInfo object or null if not found</returns>
    private CommandInfo GetCachedCommandInfo(string functionName)
    {
        // Try to get from cache first
        if (CommandInfoCache.TryGetValue(functionName, out var cachedInfo))
        {
            WriteVerbose($"Using cached command info for function '{functionName}'");
            return cachedInfo;
        }

        // Not in cache, retrieve from PowerShell
        WriteVerbose($"Getting command info for function '{functionName}'");

        var getCommandScript = $"Microsoft.PowerShell.Core\\Get-Command -Name '{functionName}' -ErrorAction SilentlyContinue";
        var commandResults = InvokeCommand.InvokeScript(getCommandScript);

        CommandInfo commandInfo = null;
        if (commandResults?.Any() == true)
        {
            commandInfo = commandResults.FirstOrDefault()?.BaseObject as CommandInfo;
        }

        // Cache the result (even if null) to avoid repeated lookups for non-existent functions
        CommandInfoCache.TryAdd(functionName, commandInfo);

        return commandInfo;
    }

    /// <summary>
    /// Creates the defaults hashtable from DefaultValues parameter
    /// </summary>
    private Hashtable CreateDefaultsHashtable()
    {
        var defaultsHash = new Hashtable();

        if (DefaultValues != null)
        {
            foreach (var variable in DefaultValues)
            {
                // Filter out variables with Options != None (matching PowerShell behavior)
                if (variable.Options == ScopedItemOptions.None)
                {
                    // Check if variable name is in filter list
                    if (Array.IndexOf(CommonParameterFilter, variable.Name) < 0)
                    {
                        // Skip null or whitespace string values
                        if (!(variable.Value is string strValue && string.IsNullOrWhiteSpace(strValue)))
                        {
                            if (variable.Value != null)
                            {
                                defaultsHash[variable.Name] = variable.Value;
                            }
                        }
                    }
                }
            }
        }

        return defaultsHash;
    }

    /// <summary>
    /// Converts bound parameters object to dictionary for easy access
    /// </summary>
    private Dictionary<string, object> ConvertToParameterDictionary(object boundParamsObject)
    {
        var result = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);

        if (boundParamsObject is IDictionary dict)
        {
            foreach (DictionaryEntry entry in dict)
            {
                if (entry.Key is string key)
                {
                    result[key] = entry.Value;
                }
            }
        }
        else if (boundParamsObject is PSObject psObj)
        {
            foreach (var property in psObj.Properties)
            {
                result[property.Name] = property.Value;
            }
        }

        return result;
    }

    /// <summary>
    /// Checks if a value represents boolean true (matching PowerShell semantics)
    /// </summary>
    private bool IsTrue(object value)
    {
        if (value == null)
            return false;

        if (value is bool boolValue)
            return boolValue;

        if (value is SwitchParameter switchParam)
            return switchParam.IsPresent;

        return false;
    }

    /// <summary>
    /// Converts object to JSON string for verbose output (mimicking PowerShell ConvertTo-Json behavior)
    /// </summary>
    private string ConvertToJsonString(object value)
    {
        try
        {
            // Use PowerShell's ConvertTo-Json for consistency
            var jsonScript = $"$input | Microsoft.PowerShell.Utility\\ConvertTo-Json -Depth 1 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue";
            var jsonResults = InvokeCommand.InvokeScript(jsonScript, new object[] { value });

            if (jsonResults?.Any() == true)
            {
                return jsonResults.FirstOrDefault()?.ToString() ?? value?.ToString() ?? "null";
            }
        }
        catch
        {
            // Fall back to simple string representation
        }

        return value?.ToString() ?? "null";
    }

    #endregion
}
