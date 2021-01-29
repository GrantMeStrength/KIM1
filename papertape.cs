using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PaperTape
{
    class Program
    {
        
        static void Main(string[] args)
        {

            // Convert a string of hex to a PTP file
            var sample = GetPPTFromHex(0x200, "201F1F206A1FC560F0F68560C90A9029C913F018C912D0E8F818A2FDB5FC756595FC9565E830F58661D810D4A9008561A20295F9CA10FB30C7A461D00FE66148A202B5F9956294F9CA10F7680A0A0A0AA2040A26F926FA26FBCAD0F6F0A2");
            Console.WriteLine(sample);

            // Load a PTP file and make it into a string of hex
            ConvertPTPtoSring(@"Addition.ptp");
            
        }

        public static string GetPPTFromHex(int address, string hexstring)
        {
            // Given a string of hex bytes and an address, generate the necessary
            // papertape format to load into a KIM-1.
            // The file containts a set of records, one per line, containing:
            // 1. output header ; [number of bytes] [address]
            // 2. output data
            // 3. output checksum CR LR 
            // 4. output eof
            // There is one final line containing the number of records and a checksum.

            var l = hexstring.Length / 2;       // Number of bytes in input string
            var s = (int)(l / 0x18);            // Number of records, assuming max length of record
            var baseAddress = address;
            var lineLimit = 0;                  // The number of hex pairs to be outout on a given line
            var digitCount = 0;                 // Track the digits within the input string
            var papertape = "";                 // Store the complete PTP file.
           
            for (int i=0; i<=s; i++)
            {
                var outputLine = "";

                if (i == s)
                    lineLimit = (l % 0x18);
                else
                    lineLimit = 0x18;

                outputLine = ";" + (String.Format("{0:x2}", lineLimit)) + String.Format("{0:x4}", baseAddress);

                for (int j = 0; j< lineLimit; j++)
                {
                    var d = hexstring.Substring(digitCount, 2);
                    digitCount += 2;
                    outputLine += d;
                }

                var check = 0;
                for (int j=1; j< outputLine.Length-1; j+=2)
                {
                    check += int.Parse(outputLine.Substring(j, 2), System.Globalization.NumberStyles.HexNumber);
                }

                baseAddress += lineLimit;
                outputLine += String.Format("{0:x4}", (UInt16)check).ToUpper() + "\r\n";
                papertape += outputLine;
            }

            var lastLine = ";00" + String.Format("{0:x4}", (UInt16)(s+1)).ToUpper();
            var lastcheck = int.Parse(lastLine.Substring(1, 2), System.Globalization.NumberStyles.HexNumber) + int.Parse(lastLine.Substring(3, 2), System.Globalization.NumberStyles.HexNumber);
            lastLine += String.Format("{0:x4}", (UInt16)lastcheck).ToUpper();

            papertape += lastLine;

            return papertape;
        }

        public static string GetHexFromByteArray(byte[] array)
        {
            String hex = "";

            for (int i = 0; i < array.Length; i += 2)
            {
                char a = (char)array[i];
                char b = (char)array[i + 1];

                hex = hex + String.Format("0x{0}{1}, ", a, b);
            }

            return hex;
        }

        public static string StripCheckSum(String line )
        {
            // Remove 7 chars at start, and 4 and end
            String newline = line.Substring(7);
            return newline.Substring(0, newline.Length - 4);

        }

        public static void ConvertPTPtoSring(String filename)
        {
            // Take the contents of a PTP file,
            // strip out the start bytes and checksum

            Console.WriteLine(filename);
            Console.WriteLine();

            string[] lines = System.IO.File.ReadAllLines(filename);

            // Display the file contents by using a foreach loop.
            foreach (string line in lines)
            {
                String bytestring = StripCheckSum(line);
                byte[] array = Encoding.ASCII.GetBytes(bytestring);
                Console.WriteLine(GetHexFromByteArray(array));
            }


        }

        public static string ByteArrayToString(byte[] ba)
        {
            StringBuilder hex = new StringBuilder(ba.Length * 2);
            foreach (byte b in ba)
                hex.AppendFormat("{0:x2}", b);
            return hex.ToString();
        }

    }
}
