// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : PSGenXdevCmdlet.Preferences.cs
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



using System.Collections;
using System.Collections.Concurrent;
using System.Management.Automation;
using Microsoft.PowerShell.Commands;

public abstract partial class PSGenXdevCmdlet : PSCmdlet
{
    protected string GetGenXdevPreference(string Name, string DefaultValue, string PreferencesDatabasePath, bool SessionOnly, bool ClearSession, bool SkipSession)
    {
        string globalVariableName = "GenXdevPreference_" + Name;

        if (ClearSession)
        {
            if (ShouldProcess("GenXdev.Data Module Configuration", "Clear session preference setting (Global variable)"))
            {
                // Use parameterized script to avoid escaping issues
                var clearVarScript = ScriptBlock.Create("param($VarName) Microsoft.PowerShell.Utility\\Set-Variable -Name $VarName -Value $null -Scope Global -Force");
                clearVarScript.Invoke(globalVariableName);

                WriteVerbose("Cleared session preference setting: " + globalVariableName);
            }
        }

        if (!SkipSession)
        {
            WriteVerbose("Checking session storage for preference '" + Name + "'");

            // Get global variable using Get-Variable cmdlet
            var getVarScript = ScriptBlock.Create("param($VarName) Microsoft.PowerShell.Utility\\Get-Variable -Name $VarName -Scope Global -ValueOnly -ErrorAction SilentlyContinue");
            var globalResult = getVarScript.Invoke(globalVariableName);

            if (globalResult.Count > 0 && globalResult[0] != null && !string.IsNullOrWhiteSpace(globalResult[0].ToString()))
            {
                string value = globalResult[0].ToString();
                WriteVerbose("Returning session value: " + value);
                return value;
            }
        }

        if (SessionOnly)
        {
            WriteVerbose("Using provided default value: " + DefaultValue);
            return DefaultValue;
        }

        var preferencesDatabasePath = GetPreferencesDatabasePath(PreferencesDatabasePath, SessionOnly, ClearSession, SkipSession);

        WriteVerbose("Using database path: " + preferencesDatabasePath);

        try
        {
            WriteVerbose("Checking local store for preference '" + Name + "'");

            string value = GetValueByKeyFromStore("GenXdev.PowerShell.Preferences", Name, null, "Local", preferencesDatabasePath)?.ToString();

            if (string.IsNullOrEmpty(value))
            {
                WriteVerbose("Preference not found locally, checking defaults store");
                value = GetValueByKeyFromStore("GenXdev.PowerShell.Preferences", Name, null, "Defaults", preferencesDatabasePath)?.ToString();
            }

            if (!string.IsNullOrEmpty(value))
            {
                WriteVerbose("Returning persistent value: " + value);
                return value;
            }
        }
        catch (Exception ex)
        {
            WriteVerbose("Error accessing preference stores: " + ex.Message);
        }

        WriteVerbose("Using provided default value: " + DefaultValue);
        return DefaultValue;
    }

    protected void SetGenXdevPreference(string Name, string Value, string PreferencesDatabasePath, bool SessionOnly, bool ClearSession, bool SkipSession)
    {
        string globalVariableName = "GenXdevPreference_" + Name;

        if (ClearSession)
        {
            if (ShouldProcess(Name, "Clear session variable"))
            {
                // Use parameterized script to avoid escaping issues
                var removeVarScript = ScriptBlock.Create("param($VarName) Microsoft.PowerShell.Utility\\Remove-Variable -Name $VarName -Scope Global -ErrorAction SilentlyContinue");
                removeVarScript.Invoke(globalVariableName);
            }
            return;
        }

        if (SessionOnly)
        {
            if (ShouldProcess(Name, "Set session-only preference"))
            {
                // Use parameterized script to avoid escaping issues
                var setVarScript = ScriptBlock.Create("param($VarName, $VarValue) Microsoft.PowerShell.Utility\\Set-Variable -Name $VarName -Value $VarValue -Scope Global -Force");
                setVarScript.Invoke(globalVariableName, Value);

                WriteVerbose("Set session-only preference: " + globalVariableName + " = " + Value);
            }
            return;
        }

        PreferencesDatabasePath = GetPreferencesDatabasePath(PreferencesDatabasePath, SessionOnly, ClearSession, SkipSession);

        WriteVerbose("Using database path: " + PreferencesDatabasePath);

        if (string.IsNullOrWhiteSpace(Value))
        {
            if (ShouldProcess(Name, "Remove preference from persistent storage"))
            {
                RemoveGenXdevPreference(Name, false, PreferencesDatabasePath, SessionOnly, ClearSession, true);
                WriteVerbose("Successfully removed preference '" + Name + "'");
            }
            return;
        }

        if (ShouldProcess(Name, "Set preference"))
        {
            SetValueByKeyInStore("GenXdev.PowerShell.Preferences", Name, Value, "Local", PreferencesDatabasePath);
            WriteVerbose("Successfully configured preference '" + Name + "' in GenXdev.Data module: [" + Value + "]");
        }
    }

    protected void RemoveGenXdevPreference(string Name, bool RemoveDefault, string PreferencesDatabasePath, bool SessionOnly, bool ClearSession, bool SkipSession)
    {
        string globalVariableName = "GenXdevPreference_" + Name;

        PreferencesDatabasePath = GetPreferencesDatabasePath(PreferencesDatabasePath, SessionOnly, ClearSession, SkipSession);

        WriteVerbose("Using database path: " + PreferencesDatabasePath);
        WriteVerbose("Starting preference removal for: " + Name);

        if (ClearSession)
        {
            if (ShouldProcess(Name, "Clear session variable"))
            {
                // Use parameterized script to avoid escaping issues
                var removeVarScript = ScriptBlock.Create("param($VarName) Microsoft.PowerShell.Utility\\Remove-Variable -Name $VarName -Scope Global -ErrorAction SilentlyContinue");
                removeVarScript.Invoke(globalVariableName);
            }
        }

        if (SessionOnly)
        {
            if (ShouldProcess(Name, "Remove session-only preference"))
            {
                // Use parameterized script to avoid escaping issues
                var removeVarScript = ScriptBlock.Create("param($VarName) Microsoft.PowerShell.Utility\\Remove-Variable -Name $VarName -Scope Global -ErrorAction SilentlyContinue");
                removeVarScript.Invoke(globalVariableName);
            }
            return;
        }

        if (ShouldProcess(Name, "Remove preference"))
        {
            if (!SkipSession)
            {
                // Use parameterized script to avoid escaping issues
                var removeVarScript = ScriptBlock.Create("param($VarName) Microsoft.PowerShell.Utility\\Remove-Variable -Name $VarName -Scope Global -ErrorAction SilentlyContinue");
                removeVarScript.Invoke(globalVariableName);
            }

            WriteVerbose("Removing preference " + Name + " from local store");
            RemoveKeyFromStore("GenXdev.PowerShell.Preferences", Name, "Local", PreferencesDatabasePath);

            if (RemoveDefault)
            {
                WriteVerbose("Removing preference " + Name + " from default store");
                RemoveKeyFromStore("GenXdev.PowerShell.Preferences", Name, "Defaults", PreferencesDatabasePath);
                SyncKeyValueStore("Defaults", PreferencesDatabasePath);
            }
        }
    }

    protected string GetPreferencesDatabasePath(string PreferencesDatabasePath, bool SessionOnly, bool ClearSession, bool SkipSession)
    {
        if (ClearSession)
        {
            if (ShouldProcess("GenXdev.Data Module Configuration", "Clear session database path setting (Global variable)"))
            {
                // Use parameterized script to avoid escaping issues
                var clearVarScript = ScriptBlock.Create("Microsoft.PowerShell.Utility\\Set-Variable -Name 'PreferencesDatabasePath' -Value $null -Scope Global -Force");
                clearVarScript.Invoke();

                WriteVerbose("Cleared session database path setting: PreferencesDatabasePath");
            }
        }

        string resolvedDatabasePath = null;

        if (!string.IsNullOrWhiteSpace(PreferencesDatabasePath))
        {
            // Remove .db extension if present using native string operation
            string cleanPath = PreferencesDatabasePath.EndsWith(".db", StringComparison.OrdinalIgnoreCase)
                ? PreferencesDatabasePath.Substring(0, PreferencesDatabasePath.Length - 3)
                : PreferencesDatabasePath;

            resolvedDatabasePath = ExpandPath(cleanPath, true);
            WriteVerbose("Using provided database path: " + resolvedDatabasePath);
            return resolvedDatabasePath;
        }

        if (!SkipSession)
        {
            // Get global variable using Get-Variable cmdlet
            var getVarScript = ScriptBlock.Create("Microsoft.PowerShell.Utility\\Get-Variable -Name 'PreferencesDatabasePath' -Scope Global -ValueOnly -ErrorAction SilentlyContinue");
            var globalResult = getVarScript.Invoke();

            if (globalResult.Count > 0 && globalResult[0] != null && !string.IsNullOrWhiteSpace(globalResult[0].ToString()))
            {
                resolvedDatabasePath = ExpandPath(globalResult[0].ToString(), true);
                WriteVerbose("Using session database path: " + resolvedDatabasePath);
                return resolvedDatabasePath;
            }
        }

        if (!SessionOnly)
        {
            string defaultPath = System.IO.Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData), "GenXdev", "Preferences");
            resolvedDatabasePath = ExpandPath(defaultPath, true);
            WriteVerbose("Using default database path: " + resolvedDatabasePath);
            return resolvedDatabasePath;
        }

        string fallbackPath = System.IO.Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.LocalApplicationData), "GenXdev", "Preferences");
        resolvedDatabasePath = ExpandPath(fallbackPath, true);
        WriteVerbose("Using fallback database path: " + resolvedDatabasePath);
        return resolvedDatabasePath;
    }

    protected void SetPreferencesDatabasePath(string PreferencesDatabasePath, bool SkipSession, bool SessionOnly, bool ClearSession)
    {
        if (ClearSession)
        {
            if (ShouldProcess("GenXdev.Data Module Configuration", "Clear session database path setting (Global variable)"))
            {
                // Use parameterized script to avoid escaping issues
                var clearVarScript = ScriptBlock.Create("Microsoft.PowerShell.Utility\\Set-Variable -Name 'PreferencesDatabasePath' -Value $null -Scope Global -Force");
                clearVarScript.Invoke();

                WriteVerbose("Cleared session database path setting: PreferencesDatabasePath");
            }
            return;
        }

        if (string.IsNullOrWhiteSpace(PreferencesDatabasePath))
        {
            throw new ArgumentException("PreferencesDatabasePath parameter is required when not using -ClearSession");
        }

        PreferencesDatabasePath = ExpandPath(PreferencesDatabasePath, true);
        WriteVerbose("Setting database path for GenXdev.Data module: [" + PreferencesDatabasePath + "]");

        if (ShouldProcess("GenXdev.Data Module Configuration", "Set database path to: [" + PreferencesDatabasePath + "]"))
        {
            // Use parameterized script to avoid escaping issues
            var setVarScript = ScriptBlock.Create("param($PathValue) Microsoft.PowerShell.Utility\\Set-Variable -Name 'PreferencesDatabasePath' -Value $PathValue -Scope Global -Force");
            setVarScript.Invoke(PreferencesDatabasePath);

            WriteVerbose("Set database path: PreferencesDatabasePath = " + PreferencesDatabasePath);
        }
    }

    protected void SetGenXdevDefaultPreference(string Name, string Value, string PreferencesDatabasePath, bool SessionOnly, bool ClearSession, bool SkipSession)
    {
        PreferencesDatabasePath = GetPreferencesDatabasePath(PreferencesDatabasePath, SessionOnly, ClearSession, SkipSession);

        WriteVerbose("Using database path: " + PreferencesDatabasePath);
        WriteVerbose("Starting Set-GenXdevDefaultPreference for '" + Name + "'");

        if (string.IsNullOrWhiteSpace(Value))
        {
            WriteVerbose("Removing default preference '" + Name + "' as value is empty");

            if (ShouldProcess(Name, "Remove default preference"))
            {
                RemoveGenXdevPreference(Name, true, PreferencesDatabasePath, SessionOnly, ClearSession, SkipSession);
            }
            return;
        }

        WriteVerbose("Setting default preference '" + Name + "' to: " + Value);

        if (ShouldProcess(Name, "Set default preference"))
        {
            SetValueByKeyInStore("GenXdev.PowerShell.Preferences", Name, Value, "Defaults", PreferencesDatabasePath);
            SyncKeyValueStore("Defaults", PreferencesDatabasePath);
            WriteVerbose("Successfully stored and synchronized preference '" + Name + "'");
        }
    }

    protected string[] GetGenXdevPreferenceNames(string PreferencesDatabasePath, bool SessionOnly, bool ClearSession, bool SkipSession)
    {
        var allKeys = new System.Collections.Generic.List<string>();

        if (ClearSession)
        {
            if (ShouldProcess("GenXdev.Data Module Configuration", "Clear session preference variables"))
            {
                // Use wildcard pattern for removing multiple variables
                var clearScript = ScriptBlock.Create("Microsoft.PowerShell.Utility\\Get-Variable -Name 'GenXdevPreference_*' -Scope Global -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\\Remove-Variable -Force");
                clearScript.Invoke();

                WriteVerbose("Cleared session preference variables");
            }
        }

        if (!SkipSession)
        {
            WriteVerbose("Retrieving session variables for preference names");

            // Get variable names directly from Get-Variable
            var sessionVarsScript = ScriptBlock.Create("Microsoft.PowerShell.Utility\\Get-Variable -Name 'GenXdevPreference_*' -Scope Global -ErrorAction SilentlyContinue | Microsoft.PowerShell.Utility\\Select-Object -ExpandProperty Name");
            var sessionVars = sessionVarsScript.Invoke();

            var sessionKeys = new System.Collections.Generic.List<string>();
            foreach (var pvar in sessionVars)
            {
                string varName = pvar?.ToString();
                if (!string.IsNullOrEmpty(varName) && varName.StartsWith("GenXdevPreference_"))
                {
                    // Extract the preference name after the prefix
                    string key = varName.Substring("GenXdevPreference_".Length);
                    sessionKeys.Add(key);
                }
            }

            if (sessionKeys.Count > 0)
            {
                WriteVerbose("Found " + sessionKeys.Count + " preference names in session storage");
                allKeys.AddRange(sessionKeys);
            }
        }

        if (!SessionOnly)
        {
            WriteVerbose("Retrieving preference names from database stores");
            PreferencesDatabasePath = GetPreferencesDatabasePath(PreferencesDatabasePath, SessionOnly, ClearSession, SkipSession);

            WriteVerbose("Retrieving keys from local preferences store");
            var localKeys = GetStoreKeys("GenXdev.PowerShell.Preferences", "Local", PreferencesDatabasePath);
            if (localKeys != null && localKeys.Length > 0)
            {
                allKeys.AddRange(localKeys);
            }

            WriteVerbose("Retrieving keys from default preferences store");
            var defaultKeys = GetStoreKeys("GenXdev.PowerShell.Preferences", "Defaults", PreferencesDatabasePath);
            if (defaultKeys != null && defaultKeys.Length > 0)
            {
                allKeys.AddRange(defaultKeys);
            }
        }

        WriteVerbose("Merging and deduplicating keys from all sources");
        var uniqueKeys = allKeys.Distinct().OrderBy(key => key).ToArray();
        WriteVerbose("Found " + uniqueKeys.Length + " unique preference names");

        return uniqueKeys;
    }
}
