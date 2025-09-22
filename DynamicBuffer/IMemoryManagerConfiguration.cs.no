/*
 * All intellectual rights of this framework, including this source file belong to Appicacy, René Vaessen.
 * Customers of Appicacy, may copy and change it, as long as this header remains.
 * 
 */

namespace GenXdev.Configuration
{
    public interface IMemoryManagerConfiguration
    {
        #region Memory
        
        // reserved service memory
        int ReservedServerMemory { get; }

        // receive buffer size
        int ReceiveBufferSize { get; }

        // send buffer size
        int SendBufferSize { get; }

        // dynamic buffer fragment size
        int DynamicBufferFragmentSize { get; }

        #endregion
    }
}
