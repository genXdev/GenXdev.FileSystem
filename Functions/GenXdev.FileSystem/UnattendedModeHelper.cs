// ################################################################################
// Part of PowerShell module : GenXdev.FileSystem
// Original cmdlet filename  : UnattendedModeHelper.cs
// Original author           : René Vaessen / GenXdev
// Version                   : 2.1.2025
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
using System.Linq;
using System.Management.Automation;

namespace GenXdev.FileSystem
{

    /// <summary>
    /// <para type="synopsis">Provides methods to detect unattended or automated execution modes.</para>
    /// <para type="description">This static class contains utility methods for determining whether the current process is running in an unattended or automated environment. This detection is crucial for scripts and applications that need to adjust their behavior based on whether they are running interactively or in automated systems like CI/CD pipelines.</para>
    /// </summary>
    public static class UnattendedModeHelper
    {

        /// <summary>
        /// <para type="synopsis">Detects if the current process is running in unattended/automated mode.</para>
        /// <para type="description">This method analyzes various indicators to determine if the process is running in an automated environment. It checks for common CI/CD environment variables, console redirection, interactive mode flags, and pipeline execution patterns.</para>
        /// <para type="description">PARAMETERS</para>
        /// <para type="description">-CallersInvocation &lt;InvocationInfo&gt;<br/>
        /// Optional: The caller's InvocationInfo for pipeline and automation detection.<br/>
        /// - <b>Position</b>: Named<br/>
        /// - <b>Default</b>: null<br/>
        /// </para>
        /// </summary>
        /// <param name="callersInvocation">Optional: The caller's InvocationInfo for pipeline and automation detection.</param>
        /// <returns>True if running in unattended/automated mode, otherwise false.</returns>
        public static bool IsUnattendedMode(InvocationInfo callersInvocation = null)
        {

            // Define environment variables that indicate automation environments
            string[] automationEnvVars = new[]
            {
                "JENKINS_URL", "GITHUB_ACTIONS", "TF_BUILD", "CI", "BUILD_ID",
                "RUNNER_OS", "SYSTEM_TEAMPROJECT", "TEAMCITY_VERSION", "TRAVIS",
                "APPVEYOR", "CIRCLECI", "GITLAB_CI", "AZURE_PIPELINES"
            };

            // Check if any automation environment variable is set
            bool hasAutomationEnv = automationEnvVars.Any(envVar =>
                !string.IsNullOrEmpty(System.Environment.GetEnvironmentVariable(envVar)));

            // Return true if automation environment detected
            if (hasAutomationEnv)
                return true;

            // Check for console input/output redirection
            try
            {

                // Detect if standard input or output streams are redirected
                if (Console.IsInputRedirected || Console.IsOutputRedirected)
                    return true;
            }
            catch { /* Ignore exceptions during console checks */ }

            // Check for non-interactive environment
            try
            {

                // Detect if the environment is non-interactive
                if (!System.Environment.UserInteractive)
                    return true;
            }
            catch { /* Ignore exceptions during environment checks */ }

            // Check for absence of console window
            try
            {

                // Detect if console window width is zero, indicating no window
                if (Console.WindowWidth == 0)
                    return true;
            }
            catch
            {

                // Assume no console window if access fails
                return true;
            }

            // Analyze pipeline execution if invocation information is provided
            if (callersInvocation != null)
            {

                // Retrieve pipeline position and length from invocation info
                int pipelineInfo = callersInvocation.PipelinePosition;

                int pipelineLength = callersInvocation.PipelineLength;

                // Determine if command is part of a pipeline
                bool isInPipeline = pipelineLength > 1;

                // Determine if command is not at the end of the pipeline
                bool isNotPipelineEnd = pipelineInfo < pipelineLength;

                // Determine if command originates from a script file
                bool isFromScript = !string.IsNullOrEmpty(callersInvocation.ScriptName);

                // Retrieve the command line text
                string commandLine = callersInvocation.Line ?? string.Empty;

                // Detect patterns indicative of automated command execution
                bool isAutomatedCommand =
                    System.Text.RegularExpressions.Regex.IsMatch(commandLine, @"^\s*(foreach|%|\||;|&)") ||
                    System.Text.RegularExpressions.Regex.IsMatch(commandLine, @"\$?[\S_]+\s*=\s*");

                // Return true if automated command pattern detected
                if (isAutomatedCommand) return true;

                // Determine if this is an interactive function call
                bool isInteractiveFunction = pipelineLength == 1 && string.IsNullOrEmpty(callersInvocation.ScriptName);

                // Return true if in pipeline but not interactive
                if (isInPipeline && !isInteractiveFunction)
                    return true;

                // Return true if not at pipeline end and not interactive
                if (isNotPipelineEnd && !isInteractiveFunction)
                    return true;

                // Return true if automated command and not interactive
                if (isAutomatedCommand && !isInteractiveFunction)
                    return true;
            }

            // Assume interactive mode if no unattended indicators found
            return false;
        }
    }
}