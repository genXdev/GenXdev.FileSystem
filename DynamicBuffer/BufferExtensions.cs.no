/*
 * All intellectual rights of this framework, including this source file belong to Appicacy, René Vaessen.
 * Customers of Appicacy, may copy and change it, as long as this header remains.
 * 
 */

namespace GenXdev.Buffers
{
    public static class BufferExtensions
    {
        public static int IndexOf(byte[] Buffer, byte[] SearchSequence, int StartPosition = 0)
        {
            int matchCount = 0;

            for (var i = StartPosition; i < Buffer.Length; i++)
            {
                if (Buffer[i] == SearchSequence[matchCount])
                {
                    matchCount++;

                    if (matchCount == SearchSequence.Length) return (i + 1) - SearchSequence.Length;
                }
                else
                {
                    matchCount = 0;
                }
            }

            return -1;
        }

        public static int IndexOf(byte[] Buffer, byte SearchValue, int StartPosition = 0)
        {
            for (var i = StartPosition; i < Buffer.Length; i++)
            {
                if (Buffer[i] == SearchValue)
                {
                    return i;
                }
            }

            return -1;
        }
    }
}
