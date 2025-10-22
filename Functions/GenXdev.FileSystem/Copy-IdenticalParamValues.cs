// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : Copy-IdenticalParamValues.cs
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



using System.Collections;
using System.Collections.Concurrent;
using System.Management.Automation;

/// <summary>
/// Copies parameter values from bound parameters to a new hashtable based on
/// another function's possible parameters.
/// </summary>
/// <remarks>
/// This function creates a new hashtable containing only the parameter values
/// that match the parameters defined in the specified target function.
/// This can then be used to invoke the function using splatting.
///
/// Switch parameters are only included in the result if they were explicitly
/// provided and set to $true in the bound parameters. Non-present switch
/// parameters are excluded from the result to maintain proper parameter
/// semantics.
/// </remarks>
/// <example>
/// <code>
/// function Test-Function {
///     [CmdletBinding()]
///     param(
///         [Parameter(Mandatory = $true)]
///         [string] $Path,
///         [Parameter(Mandatory = $false)]
///         [switch] $Recurse
///     )
///
///     $params = GenXdev.FileSystem\Copy-IdenticalParamValues `
///         -BoundParameters $PSBoundParameters `
///         -FunctionName 'Get-ChildItem'
///
///     Get-ChildItem @params
/// }
/// </code>
/// </example>
[Cmdlet(VerbsCommon.Copy, "IdenticalParamValues")]
[OutputType(typeof(Hashtable))]
[System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1704:IdentifiersShouldBeSpelledCorrectly")]
public class CopyIdenticalParamValuesCommand : PSGenXdevCmdlet
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
    /// Accepts PSVariable[], Hashtable, PSCmdlet instances, or other dictionary types.
    /// </summary>
    [Parameter(
        Mandatory = false,
        Position = 2,
        HelpMessage = "Default values for parameters")]
    public object DefaultValues { get; set; }

    #endregion

    #region Static Fields

    /// <summary>
    /// Common PowerShell parameters to filter out when copying parameters
    /// </summary>
    private static readonly string[] CommonParameterFilter;

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

        // CommandInfoCache is now shared with GenXdevCmd
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
        _defaults = CreateDefaultsHashtable2();

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

            if (Array.IndexOf(CommonParameterFilter, paramName) >= 0) continue;

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
                        _results[paramName] = true;
                        WriteVerbose($"Including switch parameter '{paramName}' (explicitly set to true)");
                    }
                }
                else
                {
                    _results[paramName] = paramValue;
                }
            }
            else if (_defaults.ContainsKey(paramName) && _defaults[paramName] != null)
            {
                // Only add default values for non-switch parameters
                if (paramInfo.ParameterType == typeof(SwitchParameter))
                {
                    var defaultValue = _defaults[paramName];
                    if (IsTrue(defaultValue))
                    {
                        _results[paramName] = true;
                        WriteVerbose($"Using default value for '{paramName}': $True");
                    }
                }
                else
                {
                    var defaultValue = _defaults[paramName];
                    _results[paramName] = defaultValue;

                    // Convert to JSON for verbose output, matching PowerShell behavior
                    var jsonValue = ConvertToJsonString(defaultValue);
                    WriteVerbose($"Using default value for '{paramName}': {jsonValue}");
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
        if (PSGenXdevCmdlet.CommandInfoCache.TryGetValue(functionName, out var cachedInfo))
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
        PSGenXdevCmdlet.CommandInfoCache.TryAdd(functionName, commandInfo);

        return commandInfo;
    }

    /// <summary>
    /// Creates the defaults hashtable from DefaultValues parameter
    /// </summary>
    private Hashtable CreateDefaultsHashtable2()
    {
        var defaultsHash = new Hashtable();

        if (DefaultValues == null)
            return defaultsHash;

        if (DefaultValues is PSObject dv)
        {
            DefaultValues = dv.BaseObject;
        }

        if (DefaultValues is Hashtable hash)
        {
            foreach (DictionaryEntry entry in hash)
            {
                if (entry.Key is string key)
                {
                    defaultsHash[key] = entry.Value;
                }
            }
        }
        // Handle PSCmdlet instances
        else if (DefaultValues is PSCmdlet cmdlet)
        {
            var cmdletType = cmdlet.GetType();

            try
            {
                // Create a new instance to get default values
                var newInstance = System.Activator.CreateInstance(cmdletType);

                foreach (var property in cmdletType.GetProperties(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance))
                {
                    // Only consider properties that are cmdlet parameters
                    if (property.CanRead && property.CanWrite &&
                        System.Attribute.IsDefined(property, typeof(ParameterAttribute)))
                    {
                        try
                        {
                            var value = property.GetValue(newInstance);
                            // Only include non-null values for default parameters
                            if (value != null)
                            {
                                defaultsHash[property.Name] = value;
                            }
                        }
                        catch (Exception ex)
                        {
                            WriteVerbose($"Failed to get value for parameter property {property.Name}: {ex.Message}");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                WriteWarning($"Failed to extract default values from cmdlet {cmdletType.Name}: {ex.Message}");
            }
        }
        // Handle other dictionary types
        else if (DefaultValues is IDictionary dict)
        {
            foreach (DictionaryEntry entry in dict)
            {
                if (entry.Key is string key)
                {
                    defaultsHash[key] = entry.Value;
                }
            }
        }
        else if (DefaultValues is IEnumerable variables && !(DefaultValues is string))
        {
            foreach (var variable in variables)
            {
                var v = variable;
                if (variable is PSObject) { v = ((PSObject)v).BaseObject; }

                PSVariable psv = v as PSVariable;

                if (psv == null || psv.Value == null) continue;

                // Filter out variables with Options != None (matching PowerShell behavior)
                if (psv.Options == ScopedItemOptions.None)
                {
                    // Check if variable name is in filter list
                    if (Array.IndexOf(CommonParameterFilter, psv.Name) < 0)
                    {
                        // Skip null or whitespace string values
                        if (!(psv.Value is string strValue && string.IsNullOrWhiteSpace(strValue)))
                        {
                            if (psv.Value != null)
                            {
                                defaultsHash[psv.Name] = psv.Value;
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
    /// Converts object to JSON string for verbose output (mimicking PowerShell ConvertTo-Json behavior)
    /// </summary>
    private string ConvertToJsonString(object value)
    {
        try
        {
            // Use base class ConvertToJson method
            return ConvertToJson(value, 1);
        }
        catch
        {
            // Fall back to simple string representation
        }

        return value?.ToString() ?? "null";
    }

    #endregion
}
