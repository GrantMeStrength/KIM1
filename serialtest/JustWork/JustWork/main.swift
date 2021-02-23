//
//  main.swift
//  JustWork
//
//  Created by John Kennedy on 2/22/21.
//

import Foundation

print("Hello, World!")

let serialPort: SerialPort = SerialPort(path: "/dev/cu.usbmodem32301")


do {

    print("Attempting to open port")
    try serialPort.openPort()
    print("Serial port opened successfully.")
    defer {
        
        print("Stuff done so closing port")
        serialPort.closePort()
        print("defer Port Closed")
    }

    serialPort.setSettings(receiveRate: .baud115200,
                           transmitRate: .baud115200,
                           minimumBytesToRead: 1)
    print("Writing to port")
    let bytesWritten = try serialPort.writeString("0200 ")
    print("Written")
    print(bytesWritten)
    
    print("Reading from port")
    
    for _ in 0..<100
    {
    
    let stringReceived = try serialPort.readLine()
    
    print(stringReceived)
    }

    print("End")
   
    
    /*
    print("Writing test string <\(testString)> of \(testString.count) characters to serial port")

    let bytesWritten = try serialPort.writeString(testString)

    print("Successfully wrote \(bytesWritten) bytes")
    print("Waiting to receive what was written...")

    let stringReceived = try serialPort.readString(ofLength: bytesWritten)

    if testString == stringReceived {
        print("Received string is the same as transmitted string. Test successful!")
    } else {
        print("Uh oh! Received string is not the same as what was transmitted. This was what we received,")
        print("<\(stringReceived)>")
    }


    print("Now testing reading/writing of \(numberOfMultiNewLineTest) lines")

    var multiLineString: String = ""


    for _ in 1...numberOfMultiNewLineTest {
        multiLineString += testString + "\n"
    }

    print("Now writing multiLineString")

    var _ = try serialPort.writeString(multiLineString)


    for i in 1...numberOfMultiNewLineTest {
        let stringReceived = try serialPort.readLine()
          
        if testString == stringReceived {
            print("Received string \(i) is the same as transmitted section. Moving on...")
        } else {
            print("Uh oh! Received string \(i) is not the same as what was transmitted. This was what we received,")
            print("<\(stringReceived)>")
            break
        }
    }
    */
    print("End of example");


} catch PortError.failedToOpen {
    print("Serial port failed to open. You might need root permissions.")
} catch {
    print("Error: \(error)")
}



