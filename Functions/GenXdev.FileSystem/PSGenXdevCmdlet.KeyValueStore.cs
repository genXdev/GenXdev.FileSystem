// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : PSGenXdevCmdlet.KeyValueStore.cs
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
using Microsoft.PowerShell.Commands;

public abstract partial class PSGenXdevCmdlet : PSCmdlet
{
    protected string[] GetKeyValueStoreNames(string SynchronizationKey = "%", string DatabasePath = null)
    {
        // Determine base path
        string basePath = string.IsNullOrWhiteSpace(DatabasePath) ? GetGenXdevAppDataPath("KeyValueStore") : DatabasePath;

        WriteVerbose($"Using KeyValueStore directory: {basePath}");

        // Ensure store directory structure exists
        if (!System.IO.Directory.Exists(basePath))
        {
            WriteVerbose("Store directory not found, initializing...");
            InitializeKeyValueStores(DatabasePath);
        }

        // Perform synchronization for non-local stores
        if (SynchronizationKey != "Local" && SynchronizationKey != "%")
        {
            WriteVerbose($"Synchronizing non-local store: {SynchronizationKey}");
            SyncKeyValueStore(SynchronizationKey, DatabasePath);
        }

        WriteVerbose($"Scanning for stores with sync key pattern: {SynchronizationKey}");

        // Get all JSON files in the store directory
        var jsonFiles = new System.Collections.Generic.List<string>();
        try
        {
            var files = System.IO.Directory.GetFiles(basePath, "*.json");
            foreach (var file in files)
            {
                jsonFiles.Add(System.IO.Path.GetFileName(file));
            }
        }
        catch (System.IO.DirectoryNotFoundException)
        {
            // Directory doesn't exist, return empty list
        }

        // Create dictionary to collect unique store names
        var storeNames = new System.Collections.Generic.Dictionary<string, bool>();

        // Parse filenames to extract store names
        foreach (var fileName in jsonFiles)
        {
            // Filename format: SyncKey_StoreName.json
            var match = System.Text.RegularExpressions.Regex.Match(fileName, @"^(.+?)_(.+?)\.json$");
            if (match.Success)
            {
                // Extract the synchronization key from the filename
                var fileSyncKey = match.Groups[1].Value;
                // Extract the store name from the filename
                var fileStoreName = match.Groups[2].Value;

                // Check if synchronization key matches pattern
                if (SynchronizationKey == "%" || fileSyncKey == SynchronizationKey)
                {
                    // Add to unique store names collection
                    if (!storeNames.ContainsKey(fileStoreName))
                    {
                        // Mark the store name as found
                        storeNames[fileStoreName] = true;
                    }
                }
            }
        }

        // Return sorted unique store names
        return storeNames.Keys.OrderBy(name => name).ToArray();
    }

    protected string GetKeyValueStorePath(string SynchronizationKey, string StoreName, string BasePath = null)
    {
        // Use default path if not provided
        if (string.IsNullOrWhiteSpace(BasePath))
        {
            BasePath = GetGenXdevAppDataPath("KeyValueStore");
        }

        WriteVerbose($"Constructing store file path for store '{StoreName}' with sync key '{SynchronizationKey}'");

        // Sanitize the sync key to remove invalid filename characters
        string safeSyncKey = System.Text.RegularExpressions.Regex.Replace(SynchronizationKey, @"[\\/:*?""<>|]", "_");

        // Sanitize the store name to remove invalid filename characters
        string safeStoreName = System.Text.RegularExpressions.Regex.Replace(StoreName, @"[\\/:*?""<>|]", "_");

        // Construct the filename by combining safe sync key and store name
        string filename = $"{safeSyncKey}_{safeStoreName}.json";

        // Return the full path by combining base path with filename
        return System.IO.Path.Combine(BasePath, filename);
    }

    protected string[] GetStoreKeys(string StoreName, string SynchronizationKey = "%", string DatabasePath = null)
    {
        // Determine base path
        string basePath = string.IsNullOrWhiteSpace(DatabasePath) ? GetGenXdevAppDataPath("KeyValueStore") : DatabasePath;

        WriteVerbose($"Using KeyValueStore directory: {basePath}");

        // Ensure store directory structure exists
        if (!System.IO.Directory.Exists(basePath))
        {
            WriteVerbose("Store directory not found, initializing...");
            InitializeKeyValueStores(DatabasePath);
        }

        // Synchronize non-local stores
        if (SynchronizationKey != "Local" && SynchronizationKey != "%")
        {
            WriteVerbose($"Syncing non-local store with key: {SynchronizationKey}");
            SyncKeyValueStore(SynchronizationKey, DatabasePath);
        }

        var keys = new System.Collections.Generic.List<string>();

        if (SynchronizationKey == "%")
        {
            // Handle wildcard synchronization key - search all matching files
            string safeStoreName = System.Text.RegularExpressions.Regex.Replace(StoreName, @"[\\/:*?""<>|]", "_");
            string filePattern = $"*{safeStoreName}.json";

            WriteVerbose($"Searching for files matching pattern: {filePattern}");

            // Collect unique keys from all matching store files
            var allKeys = new System.Collections.Generic.Dictionary<string, bool>();

            try
            {
                var files = System.IO.Directory.GetFiles(basePath, filePattern);
                foreach (var file in files)
                {
                    var storeData = (Hashtable)ReadJsonWithRetry(file, asHashtable: true);

                    // Collect active (non-deleted) key names
                    foreach (string keyName in storeData.Keys)
                    {
                        var entry = storeData[keyName];

                        // Check if entry has metadata structure
                        if (entry is Hashtable hashtable && hashtable.ContainsKey("deletedDate"))
                        {
                            // Entry has metadata, check if not deleted
                            if (hashtable["deletedDate"] == null)
                            {
                                allKeys[keyName] = true;
                            }
                        }
                        else
                        {
                            // Legacy format without metadata, add key name
                            allKeys[keyName] = true;
                        }
                    }
                }
            }
            catch (System.IO.DirectoryNotFoundException)
            {
                // Directory doesn't exist, return empty
            }

            keys.AddRange(allKeys.Keys);
        }
        else
        {
            // Specific synchronization key - get single file
            string storeFilePath = GetKeyValueStorePath(SynchronizationKey, StoreName, basePath);

            WriteVerbose($"Querying keys from store file: {storeFilePath}");

            // Read the JSON store data with retry logic
            var storeData = (Hashtable)ReadJsonWithRetry(storeFilePath, asHashtable: true);

            // Return active (non-deleted) key names
            foreach (string keyName in storeData.Keys)
            {
                var entry = storeData[keyName];

                // Check if entry has metadata structure
                if (entry is Hashtable hashtable && hashtable.ContainsKey("deletedDate"))
                {
                    // Entry has metadata, check if not deleted
                    if (hashtable["deletedDate"] == null)
                    {
                        keys.Add(keyName);
                    }
                }
                else
                {
                    // Legacy format without metadata, return key name
                    keys.Add(keyName);
                }
            }
        }

        return keys.ToArray();
    }

    protected object GetValueByKeyFromStore(string StoreName, string KeyName, string DefaultValue = null, string SynchronizationKey = "Local", string DatabasePath = null)
    {
        // Determine base path
        string basePath = string.IsNullOrWhiteSpace(DatabasePath) ? GetGenXdevAppDataPath("KeyValueStore") : DatabasePath;

        WriteVerbose($"Using KeyValueStore directory: {basePath}");

        // Check if store directory structure exists
        if (!System.IO.Directory.Exists(basePath))
        {
            WriteVerbose("Store directory not found, initializing...");
            InitializeKeyValueStores(DatabasePath);
        }

        // Synchronize with external store when not using local scope
        if (SynchronizationKey != "Local")
        {
            WriteVerbose($"Syncing store with key: {SynchronizationKey}");
            SyncKeyValueStore(SynchronizationKey, DatabasePath);
        }

        // Get JSON file path for this store
        string storeFilePath = GetKeyValueStorePath(SynchronizationKey, StoreName, basePath);

        // Log the query operation details
        WriteVerbose($"Querying store '{StoreName}' for key '{KeyName}' at: {storeFilePath}");

        // Read the JSON store data with retry logic
        var storeData = (Hashtable)ReadJsonWithRetry(storeFilePath, asHashtable: true);

        // Check if key exists and is not deleted
        if (storeData.ContainsKey(KeyName))
        {
            var entry = storeData[KeyName];

            // Check if entry has metadata structure
            if (entry is Hashtable hashtable && hashtable.ContainsKey("deletedDate"))
            {
                // Entry has metadata, check if deleted
                if (hashtable["deletedDate"] == null || hashtable["deletedDate"].ToString() == "")
                {
                    // Log successful value retrieval
                    WriteVerbose("Value found");

                    // Return the value from the entry
                    return hashtable["value"];
                }
            } else if (entry is Hashtable hashtable2)
            {
                // Return the value from the entry
                return hashtable2["value"];
            }
            else
            {
                // Legacy format without metadata, return directly
                WriteVerbose("Value found (legacy format)");
                return entry;
            }
        }

        // Log fallback to default value
        WriteVerbose("No value found, returning default");

        // Return the specified default value
        return DefaultValue;
    }

    protected void InitializeKeyValueStores(string DatabasePath = null)
    {
        // Determine base path using provided path or default
        string basePath = string.IsNullOrWhiteSpace(DatabasePath) ? GetGenXdevAppDataPath("KeyValueStore") : DatabasePath;

        // Expand the base path using ExpandPath
        basePath = ExpandPath(basePath);

        // Output verbose message showing selected base path
        WriteVerbose($"Using KeyValueStore directory: {basePath}");

        // Determine the path for OneDrive synchronized store directory
        string shadowPath = ExpandPath(@"~\OneDrive\GenXdev.PowerShell.SyncObjects\KeyValueStore");

        // Output verbose message for shadow path
        WriteVerbose($"Using OneDrive sync directory: {shadowPath}");

        // Iterate through both directory paths to ensure they exist
        foreach (string storePath in new[] { basePath, shadowPath })
        {
            // Check if directory exists using Directory.Exists
            if (!System.IO.Directory.Exists(storePath))
            {
                // Output verbose message about directory creation
                WriteVerbose($"Creating KeyValueStore directory at: {storePath}");

                // Create directory structure using ExpandPath
                ExpandPath(storePath);
            }

            // Make the OneDrive sync folder hidden to prevent user interference
            if (storePath == shadowPath)
            {
                // Ensure directory exists before setting attributes
                if (System.IO.Directory.Exists(storePath))
                {
                    System.IO.DirectoryInfo folder = new System.IO.DirectoryInfo(storePath);
                    folder.Attributes |= System.IO.FileAttributes.Hidden;
                }
            }
        }
    }

    protected void RemoveKeyFromStore(string StoreName, string KeyName, string SynchronizationKey = "Local", string DatabasePath = null)
    {
        // Determine base path
        string basePath = string.IsNullOrWhiteSpace(DatabasePath) ? GetGenXdevAppDataPath("KeyValueStore") : DatabasePath;

        WriteVerbose($"Using KeyValueStore directory: {basePath}");

        // Ensure store directory structure exists
        if (!System.IO.Directory.Exists(basePath))
        {
            WriteVerbose("Store directory not found, initializing...");
            InitializeKeyValueStores(DatabasePath);
        }

        WriteVerbose($"Processing delete operation with sync key: {SynchronizationKey}");

        // Get current user info for audit trail
        string computerName = Environment.GetEnvironmentVariable("COMPUTERNAME");
        string userName = Environment.GetEnvironmentVariable("USERNAME");
        string lastModifiedBy = $"{computerName}\\{userName}";

        WriteVerbose($"Preparing to remove key '{KeyName}' from store '{StoreName}'");

        // Get JSON file path for this store
        string storeFilePath = GetKeyValueStorePath(SynchronizationKey, StoreName, basePath);

        // Read existing store data with retry logic
        var storeData = (Hashtable)ReadJsonWithRetry(storeFilePath, asHashtable: true);

        // Check if key exists
        if (storeData.ContainsKey(KeyName))
        {
            // Mark as deleted for all stores
            WriteVerbose("Marking key as deleted");

            var keyValue = storeData[KeyName];
            if (keyValue is Hashtable keyHashtable)
            {
                keyHashtable["deletedDate"] = DateTime.UtcNow.ToString("o");
                keyHashtable["lastModified"] = DateTime.UtcNow.ToString("o");
                keyHashtable["lastModifiedBy"] = lastModifiedBy;
            }
            else
            {
                // Legacy format, convert to new format with deletion
                var newValue = new Hashtable
                {
                    ["value"] = keyValue,
                    ["lastModified"] = DateTime.UtcNow.ToString("o"),
                    ["lastModifiedBy"] = lastModifiedBy,
                    ["deletedDate"] = DateTime.UtcNow.ToString("o")
                };
                storeData[KeyName] = newValue;
            }

            // Write updated store data atomically with retry logic
            WriteJsonAtomic(storeFilePath, storeData);

            // Trigger synchronization for non-local operations
            if (SynchronizationKey != "Local")
            {
                WriteVerbose("Triggering synchronization...");
                SyncKeyValueStore(SynchronizationKey, DatabasePath);
            }
        }
        else
        {
            WriteVerbose($"Key '{KeyName}' not found in store '{StoreName}'");
        }
    }

    protected void RemoveKeyValueStore(string StoreName, string SynchronizationKey = "Local", string DatabasePath = null)
    {
        // Determine base path
        string basePath = string.IsNullOrWhiteSpace(DatabasePath) ? GetGenXdevAppDataPath("KeyValueStore") : DatabasePath;

        WriteVerbose($"Using KeyValueStore directory: {basePath}");

        // Ensure store directory structure exists
        if (!System.IO.Directory.Exists(basePath))
        {
            WriteVerbose("Store directory not found, initializing...");
            InitializeKeyValueStores(DatabasePath);
        }

        // Get JSON file path for this store
        string storeFilePath = GetKeyValueStorePath(SynchronizationKey, StoreName, basePath);

        if (SynchronizationKey == "Local")
        {
            // For local stores, physically remove the file
            if (System.IO.File.Exists(storeFilePath))
            {
                WriteVerbose($"Permanently deleting local store file: {storeFilePath}");
                System.IO.File.Delete(storeFilePath);
            }
        }
        else
        {
            // For synchronized stores, mark all keys as deleted
            WriteVerbose($"Marking all keys as deleted in synchronized store: {storeFilePath}");

            // Get current user info for audit trail
            string computerName = Environment.GetEnvironmentVariable("COMPUTERNAME");
            string userName = Environment.GetEnvironmentVariable("USERNAME");
            string lastModifiedBy = $"{computerName}\\{userName}";

            // Read existing store data
            var storeData = (Hashtable)ReadJsonWithRetry(storeFilePath, asHashtable: true);

            // Mark all entries as deleted
            foreach (string key in storeData.Keys)
            {
                var entry = storeData[key];
                if (entry is Hashtable hashtable)
                {
                    hashtable["deletedDate"] = DateTime.UtcNow.ToString("o");
                    hashtable["lastModified"] = DateTime.UtcNow.ToString("o");
                    hashtable["lastModifiedBy"] = lastModifiedBy;
                }
                else
                {
                    // Legacy format, convert to new format with deletion
                    var newValue = new Hashtable
                    {
                        ["value"] = entry,
                        ["lastModified"] = DateTime.UtcNow.ToString("o"),
                        ["lastModifiedBy"] = lastModifiedBy,
                        ["deletedDate"] = DateTime.UtcNow.ToString("o")
                    };
                    storeData[key] = newValue;
                }
            }

            // Write updated store data
            WriteJsonAtomic(storeFilePath, storeData);

            // Trigger synchronization
            SyncKeyValueStore(SynchronizationKey, DatabasePath);
        }
    }

    protected void SetValueByKeyInStore(string StoreName, string KeyName, string Value, string SynchronizationKey = "Local", string DatabasePath = null)
    {
        // Determine base path
        string basePath = string.IsNullOrWhiteSpace(DatabasePath) ? GetGenXdevAppDataPath("KeyValueStore") : DatabasePath;

        WriteVerbose("Using KeyValueStore directory: " + basePath);

        // Ensure store directory structure exists
        if (!System.IO.Directory.Exists(basePath))
        {
            WriteVerbose("Store directory not found. Initializing...");
            InitializeKeyValueStores(DatabasePath);
        }

        // Get current user identity for audit trail purposes
        string lastModifiedBy = Environment.MachineName + "\\" + Environment.UserName;

        WriteVerbose("Setting value as user: " + lastModifiedBy);

        WriteVerbose("Executing upsert for key '" + KeyName + "' in store '" + StoreName + "'");

        // Get JSON file path for this store
        string storeFilePath = GetKeyValueStorePath(SynchronizationKey, StoreName, basePath);

        // Read existing store data with retry logic
        var storeData = (Hashtable)ReadJsonWithRetry(storeFilePath, asHashtable: true);

        // Create or update the entry with metadata
        var entry = new Hashtable
        {
            ["value"] = Value,
            ["lastModified"] = DateTime.UtcNow.ToString("o"),
            ["lastModifiedBy"] = lastModifiedBy,
            ["deletedDate"] = null
        };

        storeData[KeyName] = entry;

        // Write updated store data atomically with retry logic
        WriteJsonAtomic(storeFilePath, storeData);

        // Handle synchronization for non-local stores
        if (SynchronizationKey != "Local")
        {
            WriteVerbose("Synchronizing non-local store: " + SynchronizationKey);
            SyncKeyValueStore(SynchronizationKey, DatabasePath);
        }
    }

    protected void SyncKeyValueStore(string SynchronizationKey = "Local", string DatabasePath = null)
    {
        // Determine base path
        string basePath = string.IsNullOrWhiteSpace(DatabasePath) ? GetGenXdevAppDataPath("KeyValueStore") : DatabasePath;

        // Construct path to onedrive shadow directory for synchronization
        string shadowPath = ExpandPath(@"~\OneDrive\GenXdev.PowerShell.SyncObjects\KeyValueStore");

        // Log the beginning of sync operation for troubleshooting
        WriteVerbose("Starting key-value store sync with key: " + SynchronizationKey);

        // Skip synchronization for local-only records to avoid unnecessary work
        if (SynchronizationKey == "Local")
        {
            WriteVerbose("Skipping sync for local-only key");
            return;
        }

        // Log store directory paths for debugging and verification purposes
        WriteVerbose("Local path: " + basePath);
        WriteVerbose("Shadow path: " + shadowPath);

        // Verify both directories exist before attempting synchronization
        if (!(System.IO.Directory.Exists(basePath) && System.IO.Directory.Exists(shadowPath)))
        {
            WriteVerbose("Initializing missing store directories");
            InitializeKeyValueStores(DatabasePath);
        }

        // Get all JSON files from both directories matching the sync key pattern
        string safeSyncKey = System.Text.RegularExpressions.Regex.Replace(SynchronizationKey, @"[\\/:*?""<>|]", "_");
        string filePattern = $"{safeSyncKey}_*.json";

        WriteVerbose("Syncing files matching pattern: " + filePattern);

        // Collect all matching store files from both locations
        var localFiles = new System.Collections.Generic.Dictionary<string, string>();
        var shadowFiles = new System.Collections.Generic.Dictionary<string, string>();

        try
        {
            foreach (var file in System.IO.Directory.GetFiles(basePath, filePattern))
            {
                localFiles[System.IO.Path.GetFileName(file)] = file;
            }
        }
        catch (System.IO.DirectoryNotFoundException) { }

        try
        {
            foreach (var file in System.IO.Directory.GetFiles(shadowPath, filePattern))
            {
                shadowFiles[System.IO.Path.GetFileName(file)] = file;
            }
        }
        catch (System.IO.DirectoryNotFoundException) { }

        // Get union of all filenames
        var allFilenames = new System.Collections.Generic.HashSet<string>();
        foreach (var key in localFiles.Keys) allFilenames.Add(key);
        foreach (var key in shadowFiles.Keys) allFilenames.Add(key);

        // Sync each store file
        foreach (string filename in allFilenames)
        {
            WriteVerbose("Syncing store file: " + filename);

            string localFilePath = System.IO.Path.Combine(basePath, filename);
            string shadowFilePath = System.IO.Path.Combine(shadowPath, filename);

            // Read both store versions
            var localData = (Hashtable)ReadJsonWithRetry(localFilePath, asHashtable: true);
            var shadowData = (Hashtable)ReadJsonWithRetry(shadowFilePath, asHashtable: true);

            // Merge stores based on last modified timestamps
            var mergedData = new Hashtable();

            // Add all local keys
            foreach (string key in localData.Keys)
            {
                mergedData[key] = localData[key];
            }

            // Merge shadow keys, keeping newer versions
            foreach (string key in shadowData.Keys)
            {
                var shadowEntry = shadowData[key];

                DateTime? shadowDeletedDate = null;
                if (shadowEntry is Hashtable shadHashtable)
                {
                    if (shadHashtable.ContainsKey("deletedDate") && shadHashtable["deletedDate"] is DateTime shaddeletedDate)
                    {
                        shadowDeletedDate = shaddeletedDate;
                    }
                    else
                    {
                        DateTime d;
                        if (DateTime.TryParse((string)shadHashtable["deletedDate"], System.Globalization.CultureInfo.InvariantCulture, out d))
                        {
                            shadowDeletedDate = d;
                        }
                    }
                }

                if (mergedData.ContainsKey(key))
                {
                    var localEntry = mergedData[key];

                    DateTime? localDeletedDate = null;
                    if (localEntry is Hashtable locHashtable)
                    {
                        if (locHashtable.ContainsKey("deletedDate") && locHashtable["deletedDate"] is DateTime locdeletedDate)
                        {
                            localDeletedDate = locdeletedDate;
                        }
                        else
                        {
                            DateTime d;
                            if (DateTime.TryParse((string)locHashtable["deletedDate"], System.Globalization.CultureInfo.InvariantCulture, out d))
                            {
                                localDeletedDate = d;
                            }
                        }
                    }

                    // Compare timestamps if both have metadata
                    if (localEntry is Hashtable localHashtable &&
                        shadowEntry is Hashtable shadowHashtable &&
                        localHashtable.ContainsKey("lastModified") &&
                        shadowHashtable.ContainsKey("lastModified"))
                    {
                        DateTime localTime;
                        DateTime shadowTime;

                        // Handle both string and DateTime types for lastModified
                        if (localHashtable["lastModified"] is string localTimeStr)
                        {
                            localTime = DateTime.Parse(localTimeStr, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.AssumeUniversal | System.Globalization.DateTimeStyles.AdjustToUniversal);
                        }
                        else if (localHashtable["lastModified"] is DateTime localDateTime)
                        {
                            localTime = localDateTime.ToUniversalTime();
                        }
                        else
                        {
                            // Fallback: keep shadow version
                            mergedData[key] = shadowEntry;
                            continue;
                        }

                        if (shadowHashtable["lastModified"] is string shadowTimeStr)
                        {
                            shadowTime = DateTime.Parse(shadowTimeStr, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.AssumeUniversal | System.Globalization.DateTimeStyles.AdjustToUniversal);
                        }
                        else if (shadowHashtable["lastModified"] is DateTime shadowDateTime)
                        {
                            shadowTime = shadowDateTime.ToUniversalTime();
                        }
                        else
                        {
                            // Fallback: keep shadow version
                            mergedData[key] = shadowEntry;
                            continue;
                        }

                        localTime = !localDeletedDate.HasValue ? localTime : DateTime.FromBinary(Math.Max(localTime.ToBinary(), localDeletedDate.Value.ToBinary()));
                        shadowTime = !shadowDeletedDate.HasValue ? shadowTime : DateTime.FromBinary(Math.Max(shadowTime.ToBinary(), shadowDeletedDate.Value.ToBinary()));

                        // Keep newer version
                        if (shadowTime > localTime)
                        {
                            mergedData[key] = shadowEntry;
                        }
                    }
                    else
                    {
                        // No metadata, keep shadow version
                        mergedData[key] = shadowEntry;
                    }
                }
                else
                {
                    // Key only exists in shadow, add it
                    if (!shadowDeletedDate.HasValue)
                    {
                        mergedData[key] = shadowEntry;
                    }
                }
            }

            // Write merged data to both locations
            WriteJsonAtomic(localFilePath, mergedData);
            WriteJsonAtomic(shadowFilePath, mergedData);
        }

        // Log completion of sync operation for audit and troubleshooting
        WriteVerbose("Sync operation completed");
    }
}