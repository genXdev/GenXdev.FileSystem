using System;
using System.Threading;
using System.Threading.Tasks;

public static class TaskExtensions
{
    /// <summary>
    /// Safely fire-and-forget a Task, handling exceptions without awaiting.
    /// </summary>
    /// <param name="task">The task to run in the background.</param>
    /// <param name="errorHandler">Optional action to handle exceptions.</param>
    public static void FireAndForget(this Task task, Action<Exception> errorHandler = null)
    {
        ArgumentNullException.ThrowIfNull(task);

        task.ContinueWith(t =>
        {
            if (t.IsFaulted)
            {
                var ex = t.Exception?.InnerException ?? t.Exception;
                errorHandler?.Invoke(ex!);
                // Default handling if no custom handler (e.g., log)
                Console.Error.WriteLine($"Unhandled task exception: {ex?.Message}");
            }
            // Optional: Handle other states like canceled
        }, TaskScheduler.Current);
    }
}