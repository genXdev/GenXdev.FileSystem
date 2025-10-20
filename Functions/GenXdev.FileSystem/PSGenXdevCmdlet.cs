// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : PSGenXdevCmdlet.cs
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
using System.Management.Automation;
using System.Net;
using Microsoft.PowerShell.Commands;
using System.Text.Json;
using System.Text;
using System.IO;

public abstract partial class PSGenXdevCmdlet : PSCmdlet
{
    internal static readonly ConcurrentDictionary<string, CommandInfo> CommandInfoCache = new ConcurrentDictionary<string, CommandInfo>(StringComparer.OrdinalIgnoreCase);

    private static readonly ScriptBlock WriteJsonAtomicScript = ScriptBlock.Create(@"
param(
    [string]$FilePath,
    [hashtable]$Data,
    [int]$MaxRetries,
    [int]$RetryDelayMs
)
GenXdev.FileSystem\WriteJsonAtomic `
    -FilePath $FilePath `
    -Data $Data `
    -MaxRetries $MaxRetries `
    -RetryDelayMs $RetryDelayMs
");

    private static readonly ScriptBlock ReadJsonWithRetryScript = ScriptBlock.Create(@"
param(
    [string]$FilePath,
    [int]$MaxRetries,
    [int]$RetryDelayMs,
    [switch]$AsHashtable
)
GenXdev.FileSystem\ReadJsonWithRetry `
    -FilePath $FilePath `
    -MaxRetries $MaxRetries `
    -RetryDelayMs $RetryDelayMs `
    -AsHashtable:$AsHashtable
");

    protected Hashtable CopyIdenticalParamValues(string CmdletName)
    {
        // Get command info for the target function
        var functionInfo = GetCachedCommandInfo(CmdletName);
        if (functionInfo?.Parameters == null)
        {
            throw new ArgumentException($"Function '{CmdletName}' not found");
        }

        var results = new Hashtable();
        var defaults = CreateDefaultsHashtable();

        // Convert bound parameters to dictionary
        var boundParamsDict = ConvertToParameterDictionary(this.MyInvocation.BoundParameters);

        // Process each parameter of the target function
        foreach (var parameterKvp in functionInfo.Parameters)
        {
            var paramName = parameterKvp.Key;
            var paramInfo = parameterKvp.Value;

            if (boundParamsDict.ContainsKey(paramName))
            {
                var paramValue = boundParamsDict[paramName];

                // Handle switch parameters
                if (paramInfo.ParameterType == typeof(SwitchParameter))
                {
                    if (IsTrue(paramValue))
                    {
                        results[paramName] = paramValue;
                    }
                }
                else
                {
                    results[paramName] = paramValue;
                }
            }
            else
            {
                // Use default values
                if (paramInfo.ParameterType != typeof(SwitchParameter))
                {
                    var defaultValue = defaults[paramName];
                    if (defaultValue != null)
                    {
                        results[paramName] = defaultValue;
                    }
                }
                else
                {
                    var defaultValue = defaults[paramName];
                    if (IsTrue(defaultValue))
                    {
                        results[paramName] = true;
                    }
                }
            }
        }

        return results;
    }

    /// <summary>
    /// Convert object to JSON using System.Text.Json
    /// </summary>
    protected string ConvertToJson(object obj, int depth = 20)
    {
        var options = new JsonSerializerOptions
        {
            WriteIndented = true,
            MaxDepth = depth
        };
        return JsonSerializer.Serialize(obj, options);
    }

    /// <summary>
    /// Convert JSON to object array using System.Text.Json
    /// </summary>
    protected object[] ConvertFromJson(string json)
    {
        var options = new JsonSerializerOptions { MaxDepth = 20 };
        var obj = JsonSerializer.Deserialize<object>(json, options);
        return new object[] { obj };
    }

    /// <summary>
    /// Convert JSON to typed array using System.Text.Json
    /// </summary>
    protected T[] ConvertFromJson<T>(string json)
    {
        var options = new JsonSerializerOptions { MaxDepth = 20 };
        var obj = JsonSerializer.Deserialize<T>(json, options);
        return new T[] { obj };
    }

    /// <summary>
    /// Writes data to a JSON file atomically
    /// </summary>
    protected void WriteJsonAtomic(string filePath, Hashtable data, int maxRetries = 10, int retryDelayMs = 200)
    {
        WriteJsonAtomicScript.Invoke(filePath, data, maxRetries, retryDelayMs);
    }

    /// <summary>
    /// Reads JSON file with retry logic
    /// </summary>
    protected object ReadJsonWithRetry(string filePath, int maxRetries = 10, int retryDelayMs = 200, bool asHashtable = false)
    {
        Collection<PSObject> results = ReadJsonWithRetryScript.Invoke(
            filePath,
            maxRetries,
            retryDelayMs,
            new SwitchParameter(asHashtable)
        );

        if (results == null || results.Count == 0)
        {
            return asHashtable ? new Hashtable() : null;
        }

        return results[0]?.BaseObject;
    }


    /// <summary>
    /// Executes a PowerShell script and returns the result of type T, handling
    /// any errors that occur.
    /// </summary>
    /// <param name="script">The script to execute.</param>
    /// <returns>The result as type T.</returns>
    protected T InvokeScript<T>(string script, params object[] args)
    {
        // execute the PowerShell script and collect all output objects
        Collection<PSObject> results = InvokeCommand.InvokeScript(script, args);

        // check if the entire results collection is of type T
        // handles cases where script returns a single collection
        if (results is T)
        {
            return (T)(object)results;
        }

        // check if first result's base object is of type T
        // handles cases where script returns wrapped PSObjects
        if (results.Count > 0 && results[0].BaseObject is T)
        {
            return (T)results[0].BaseObject;
        }

        // return default value if no matching type found
        return default(T);
    }

    protected IEnumerable<T> InvokeCmdlet<T>(
        string Cmdlet,
        Hashtable parameters = null,
        bool includeIdenticalParamValues = false,
        params string[] paramsToExclude
    )
    {
        StringBuilder script = new StringBuilder();
        script.AppendLine("param($invocationArgs)");
        script.AppendLine("function go {");
        script.AppendLine("  param(");
        bool first = true;
        parameters = parameters ?? new Hashtable();

        if (includeIdenticalParamValues)
        {
            var old = parameters;
            parameters = CopyIdenticalParamValues(Cmdlet);
            foreach (DictionaryEntry entry in old)
            {
                parameters[entry.Key] = entry.Value;
            }
        }

        // filter parameters collection
        if (paramsToExclude != null && paramsToExclude.Length > 0)
        {
            var filtered = new Hashtable();

            foreach (DictionaryEntry entry in parameters)
            {
                if (!Array.Exists(paramsToExclude, p => p.Equals(entry.Key.ToString(), StringComparison.OrdinalIgnoreCase)))
                {
                    filtered[entry.Key] = entry.Value;
                }
            }

            parameters = filtered;
        }

        foreach (DictionaryEntry entry in parameters)
        {
            if (!first)
            {
                script.AppendLine(", ");
            }
            script.AppendFormat("${0}", entry.Key);
            first = false;
        }

        script.AppendLine(") ");
        script.AppendFormat("{0} ", Cmdlet);
        first = true;

        foreach (DictionaryEntry entry in parameters)
        {
            if (!first)
            {
                script.Append(" ");
            }
            script.AppendFormat("-{0}:${0}", entry.Key);
            first = false;
        }

        script.AppendLine(" ; ");
        script.AppendLine("} ");
        script.AppendLine("go @invocationArgs ; ");

        var scriptBlock = ScriptBlock.Create(script.ToString());

        foreach (var result in scriptBlock.Invoke(parameters))
        {
            if (result is T obj1)
            {
                yield return obj1;
            }
            else if (result?.BaseObject is T obj2)
            {
                yield return obj2;
            }
        }
    }
    protected T InvokeCmdletSingle<T>(
       string Cmdlet,
       Hashtable parameters = null,
       bool includeIdenticalParamValues = false,
       params string[] paramsToExclude
   )
    {
        foreach (var result in InvokeCmdlet<T>(Cmdlet, parameters, includeIdenticalParamValues, paramsToExclude))
        {
            return result;
        }
        return default(T);
    }

    protected System.Collections.Generic.List<T> InvokeCmdletList<T>(
       string Cmdlet,
       Hashtable parameters = null,
       bool includeIdenticalParamValues = false,
       params string[] paramsToExclude
   )
    {
        var list = new List<T>();
        foreach (var result in InvokeCmdlet<T>(Cmdlet, parameters, includeIdenticalParamValues, paramsToExclude))
        {
            list.Add(result);
        }
        return list;
    }

    #region Private
    protected CommandInfo GetCachedCommandInfo(string functionName)
    {
        if (CommandInfoCache.TryGetValue(functionName, out var cachedInfo))
        {
            return cachedInfo;
        }

        var getCommandScript = $"Microsoft.PowerShell.Core\\Get-Command -Name '{functionName}' -ErrorAction SilentlyContinue";
        var commandResults = InvokeCommand.InvokeScript(getCommandScript);

        CommandInfo commandInfo = null;
        if (commandResults?.Any() == true)
        {
            commandInfo = commandResults.FirstOrDefault()?.BaseObject as CommandInfo;
        }

        CommandInfoCache.TryAdd(functionName, commandInfo);
        return commandInfo;
    }

    protected string ExpandPath(string Path,
    bool CreateDirectory = false,
    bool CreateFile = false,
    bool DeleteExistingFile = false,
    bool FileMustExist = false,
    bool DirectoryMustExist = false)
    {
        // Build the Expand-Path command with conditional parameters
        var scriptBuilder = new System.Text.StringBuilder();
        scriptBuilder.Append("param($Path) GenXdev.FileSystem\\Expand-Path -FilePath $Path");
        if (CreateDirectory)
        {
            scriptBuilder.Append(" -CreateDirectory");
        }
        if (CreateFile)
        {
            scriptBuilder.Append(" -CreateFile");
        }
        if (DeleteExistingFile)
        {
            scriptBuilder.Append(" -DeleteExistingFile");
        }
        if (FileMustExist)
        {
            scriptBuilder.Append(" -FileMustExist");
        }
        if (DirectoryMustExist)
        {
            scriptBuilder.Append(" -DirectoryMustExist");
        }
        var expandPathScript = ScriptBlock.Create(scriptBuilder.ToString());
        var result = expandPathScript.Invoke(Path);
        if (result?.Count > 0 && result[0]?.BaseObject != null)
        {
            return result[0].BaseObject.ToString();
        }
        return Path;
    }

    /// <summary>
    /// Confirms user consent for installing third-party software
    /// </summary>
    protected bool ConfirmInstallationConsent(string applicationName, string source, string description = null, string publisher = null, bool forceConsent = false, bool consentToThirdPartySoftwareInstallation = false)
    {
        var scriptBuilder = new System.Text.StringBuilder();
        scriptBuilder.Append("param($ApplicationName, $Source, $Description, $Publisher, $ForceConsent, $ConsentToThirdPartySoftwareInstallation) ");
        scriptBuilder.Append("GenXdev.FileSystem\\Confirm-InstallationConsent ");
        scriptBuilder.Append("-ApplicationName $ApplicationName ");
        scriptBuilder.Append("-Source $Source");
        if (!string.IsNullOrEmpty(description))
        {
            scriptBuilder.Append(" -Description $Description");
        }
        if (!string.IsNullOrEmpty(publisher))
        {
            scriptBuilder.Append(" -Publisher $Publisher");
        }
        if (forceConsent)
        {
            scriptBuilder.Append(" -ForceConsent");
        }
        if (consentToThirdPartySoftwareInstallation)
        {
            scriptBuilder.Append(" -ConsentToThirdPartySoftwareInstallation");
        }
        var confirmConsentScript = ScriptBlock.Create(scriptBuilder.ToString());
        var result = confirmConsentScript.Invoke(
            applicationName,
            source,
            description ?? "This software is required for certain features in the GenXdev modules.",
            publisher ?? "Third-party vendor",
            forceConsent,
            consentToThirdPartySoftwareInstallation
        );
        if (result?.Count > 0 && result[0]?.BaseObject != null)
        {
            return (bool)result[0].BaseObject;
        }
        return false;
    }

    protected Hashtable CreateDefaultsHashtable()
    {
        var defaultsHash = new Hashtable();
        var cmdletType = this.GetType();

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
                        if (value != null)
                        {
                            defaultsHash[property.Name] = value;
                        }
                    }
                    catch
                    {
                        // Skip properties that can't be accessed
                    }
                }
            }
        }
        catch
        {
            // If we can't create instance or access properties, return empty defaults
        }

        return defaultsHash;
    }

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

    protected bool IsTrue(object value)
    {
        if (value == null) return false;
        if (value is bool boolValue) return boolValue;
        if (value is SwitchParameter switchParam) return switchParam.ToBool();
        return false;
    }

    protected string GetGenXdevAppDataPath(string additional = null)
    {
        if (string.IsNullOrWhiteSpace(additional))
        {
            return ExpandPath(
                Path.Combine(
                    Environment.GetEnvironmentVariable("LOCALAPPDATA"),
                    "GenXdev.PowerShell"
                ) + "\\",
                CreateDirectory: true,
                DeleteExistingFile: true
            );
        }

        return ExpandPath(
            Path.Combine(
                Environment.GetEnvironmentVariable("LOCALAPPDATA"),
                "GenXdev.PowerShell",
                additional
            ) + "\\",
            CreateDirectory: true,
            DeleteExistingFile: true
        );
    }

    protected string GetGenXdevModuleBase(string ModuleName)
    {
        return ExpandPath((
            System.IO.Path.GetDirectoryName(
                InvokeScript<string>("(Get-Module '" + ModuleName + "').Path")
            ) + "\\"),
            CreateDirectory: true,
            DeleteExistingFile: true
        );
    }

    protected string GetGenXdevModulesBase()
    {
        return ExpandPath(
            Path.Combine(
                GetGenXdevModuleBase("GenXdev.FileSystem"),
                "..",
                ".."
            ) + "\\",
            CreateDirectory: true,
            DeleteExistingFile: true
        );
    }

    protected string GetPowerShellProfilePath()
    {
        return ExpandPath(
            System.IO.Path.GetDirectoryName(
                InvokeScript<string>("$Profile")

            ) + "\\",
            CreateDirectory: true,
            DeleteExistingFile: true
        );
    }

    protected string GetPowerShellScriptsPath()
    {
        return ExpandPath(
            Path.Combine(
                GetPowerShellProfilePath(),
                "Scripts"
            ) + "\\",
            CreateDirectory: true,
            DeleteExistingFile: true
        );
    }

    /// <summary>
    /// Sets a global variable in the PowerShell session
    /// </summary>
    /// <param name="name">Variable name</param>
    /// <param name="value">Variable value</param>
    protected void SetGlobalVariable(string name, object value)
    {

        var setVariableScript = ScriptBlock.Create(
            "param($name, $value) " +
            "Microsoft.PowerShell.Utility\\Set-Variable " +
            "-Scope Global -Name $name -Value $value");

        setVariableScript.Invoke(name, value);
    }

    #endregion
}