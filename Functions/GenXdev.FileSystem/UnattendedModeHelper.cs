// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : UnattendedModeHelper.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 1.300.2025
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



using System.Management.Automation;

namespace GenXdev.FileSystem
{

    /// <summary>
    /// Provides methods to detect if the process runs in unattended or automated
    /// mode.
    /// </summary>
    public static class UnattendedModeHelper
    {

        /// <summary>
        /// Detects if the current process is running in unattended/automated mode.
        /// </summary>
        /// <param name="callersInvocation">Optional: The caller's InvocationInfo
        /// for pipeline and automation detection.</param>
        /// <returns>True if running in unattended/automated mode, otherwise
        /// false.</returns>
        public static bool IsUnattendedMode(InvocationInfo callersInvocation = null)
        {

            // define environment variables indicating automation
            string[] automationEnvVars = new[]
            {
                "JENKINS_URL", "GITHUB_ACTIONS", "TF_BUILD", "CI", "BUILD_ID",
                "RUNNER_OS", "SYSTEM_TEAMPROJECT", "TEAMCITY_VERSION", "TRAVIS",
                "APPVEYOR", "CIRCLECI", "GITLAB_CI", "AZURE_PIPELINES"
            };

            // check for any automation environment variable
            bool hasAutomationEnv = automationEnvVars.Any(envVar =>
                !string.IsNullOrEmpty(System.Environment.GetEnvironmentVariable(envVar)));

            // return true if automation detected
            if (hasAutomationEnv)
                return true;

            // check console input/output redirection
            try
            {

                // detect redirected streams
                if (Console.IsInputRedirected || Console.IsOutputRedirected)
                    return true;
            }
            catch { /* Ignore */ }

            // check for non-interactive environment
            try
            {

                // detect non-interactive mode
                if (!System.Environment.UserInteractive)
                    return true;
            }
            catch { /* Ignore */ }

            // check for no console window
            try
            {

                // detect zero width as no window
                if (Console.WindowWidth == 0)
                    return true;
            }
            catch
            {

                // assume no window on access failure
                return true;
            }

            // analyze pipeline if invocation provided
            if (callersInvocation != null)
            {

                // get pipeline position
                int pipelineInfo = callersInvocation.PipelinePosition;

                // get pipeline length
                int pipelineLength = callersInvocation.PipelineLength;

                // check if in pipeline
                bool isInPipeline = pipelineLength > 1;

                // check if not at pipeline end
                bool isNotPipelineEnd = pipelineInfo < pipelineLength;

                // check if from script file
                bool isFromScript = !string.IsNullOrEmpty(callersInvocation.ScriptName);

                // get command line text
                string commandLine = callersInvocation.Line ?? string.Empty;

                // detect automated command patterns
                bool isAutomatedCommand =
                    System.Text.RegularExpressions.Regex.IsMatch(commandLine, @"^\s*(foreach|%|\||;|&)") ||
                    System.Text.RegularExpressions.Regex.IsMatch(commandLine, @"\$?[\S_]+\s*=\s*");

                // return true if automated
                if (isAutomatedCommand) return true;

                // detect interactive function call
                bool isInteractiveFunction = pipelineLength == 1 && string.IsNullOrEmpty(callersInvocation.ScriptName);

                // return true if in pipeline and not interactive
                if (isInPipeline && !isInteractiveFunction)
                    return true;

                // return true if not end and not interactive
                if (isNotPipelineEnd && !isInteractiveFunction)
                    return true;

                // return true if automated and not interactive
                if (isAutomatedCommand && !isInteractiveFunction)
                    return true;
            }

            // assume interactive if no indicators
            return false;
        }
    }
}