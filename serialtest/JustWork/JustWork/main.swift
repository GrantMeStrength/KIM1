//
//  main.swift
//  JustWork
//
//  Created by John Kennedy on 2/22/21.
//

import Foundation

let serialPort: SerialPort = SerialPort(path: "/dev/cu.usbserial-AC00I4ST")

var STATUS_REGISTER : UInt8 = 0
var A_REGISTER : UInt8 = 0
var X_REGISTER : UInt8 = 0
var Y_REGISTER : UInt8 = 0


private var MOS6502 = CPU()

let code : [UInt8] = [
    
    
    // Set everything to a known state
    
    0xA9,0x0,0,0,      // LDA #$0
    0xA2,0x0,0,0,      // LDX #$0
    0xA0,0x0,0,0,      // LDY #$0
    0x18,0,0,0,         // CLC
    0xd8,0,0,0,         // CLD
    0xb8,0,0,0,         // CLV
    0xA9,1,0,0,
    0x6A,0,0,0,
    0,0,0,0,
    
    
    // BIT
    
    0xA9,0xAA,0,0,      // LDA #$0
    0x85,01,0,0,        // STA a
    
    0xA9,0x0,0,0,      // LDA #$0
    0x85,02,0,0,        // STA a
    
    0xA9,0xff,0,0,      // LDA #$0
    0x85,03,0,0,        // STA a
   
    0xA9,0x55,0,0,      // LDA #$0
    0x85,04,0,0,        // STA a
   
    
    
    0x18,0,0,0,          // CLC
    0xb8,0,0,0,
    
    0x24,01,0,0,
    0x24,02,0,0,
    0x24,03,0,0,
    0x24,04,0,0,
    
    
    
    // Stack fun - there is no PLY, PLX etc on 6502! ok
    0xd8, 0,0,0,        // CLD // Not Decimal mode
    0xA2,0xff,0,0,      // LDA #$0
    0x9A,0x0,0,0,      // LDA #$0
    0xA9,0x3,0,0,      // LDA #$0
  
    0x48,0x0,0,0,      // LDA #$0
    0xBA,0x0,0,0,      // LDA #$0
    0xA9,0x99,0,0,      // LDA #$0
   
    0x68,0x0,0,0,      // LDA #$0
   0xBA,0x0,0,0,      // LDA #$0
 
    
    // CMP ok 
    
    0xd8, 0,0,0,        // CLD // Not Decimal mode
    0xA9,0x10,0,0,      // LDA #$0
    0x85,0x01,0,0,      // LDA #$0
    0xC9,0x20,0,0,      // LDA #$0
    0xC9,0x10,0,0,      // LDA #$0
    0xC9,0x5,0,0,      // LDA #$0
    0xC9,0x0,0,0,      // LDA #$0
    0xC5,0x1,0,0,      // LDA #$0
   
    
    
    // More addition with big wrapping values

    0xf8, 0,0,0,        // SED // Decimcal Mode
    0xA9,0x60,0,0,      // LDA #$0
    0x18,0,0,0,          // CLC
    0x69,0xA,0,0,      // ADC #$1
    0x18,0,0,0,          // CLC
    0x69,0xA,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0xA,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0xA,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0xA,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0xA,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0xA,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$10x18,0,0,0,          // CLC
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$10x18,0,0,0,          // CLC
   
    
    0x69,0x2,0,0,      // ADC #$1
    0x69,0x2,0,0,      // ADC #$1
    
    
    0xd8, 0,0,0,        // CLD // Not Decimal mode
    0xA9,0x60,0,0,      // LDA #$0
    0x18,0,0,0,          // CLC
    0x69,0x20,0,0,      // ADC #$1
    0x69,0x20,0,0,      // ADC #$1
    0x69,0x20,0,0,      // ADC #$1
    
    
    
    
    // And and OR
    
    0xA2,01,0,0,        // LDX 1
    0xA9,0x55,0,0,        // LDA 2
    0x85,02,0,0,        // LDY 2
    0xA9,70,0,0,        // LDY 2
    0x29,50,0,0,        // LDY 2
    0x35,01,0,0,        // LDY 2
    0x3D,01,0,0,        // LDY 2
    0xA9,70,0,0,        // LDY 2
    0x09,50,0,0,        // LDY 2
    0x15,01,0,0,        // LDY 2
    0x1D,01,0,0,        // LDY 2
    
    // put 1,2,3,4 into 0x30..
    0xd8,0,0,0,         // CLD
    0xA9,02,0,0,        // LDA 2
    0xA2,01,0,0,        // LDX 1
    0xA0,02,0,0,        // LDY 2
    0x18,0,0,0,         // CLC
    0x69,0x5,0,0,      // ADC #12
    0x18,0,0,0,         // CLC
    0x65,0,0,0,      // ADC #12
    0x18,0,0,0,         // CLC
    0x75,0x05,0,0,      // ADC #12
    0x18,0,0,0,         // CLC
    0x7D,0,0,0,      // ADC #12
    0x18,0,0,0,         // CLC
    0x79,0,0,0,      // ADC #12
   
    0x18,0,0,0,         // CLC
   
    
    
    
    // TEST SBC ADC
   // 0xd8, 0,0,0,        // CLD // Not Decimal mode
    0xf8, 0,0,0,        // SED // Decimcal Mode
    0xA9,0x1,0,0,      // LDA #$0
  
    0x38,0,0,0,          // SEC
    0xE9,0x1,0,0,      // SBC #$0
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$1
    0x38,0,0,0,          // SEC
    0xE9,0x2,0,0,      // SBC #$2
    0x38,0,0,0,          // SEC
    0xE9,0x2,0,0,      // SBC #$2
    0x38,0,0,0,          // SEC
    0xE9,0x2,0,0,      // SBC #$2
    0x38,0,0,0,          // SEC
    0xE9,0x2,0,0,      // SBC #$2
    0x38,0,0,0,          // SEC
    0xE9,0x2,0,0,      // SBC #$2
    0xA9,0x64,0,0,      // LDA #$0
    0x38,0,0,0,          // SEC
    0xE9,0x20,0,0,      // SBC #$2
    0x38,0,0,0,          // SEC
    0xE9,0x20,0,0,      // SBC #$2
    0x38,0,0,0,          // SEC
    0xE9,0x20,0,0,      // SBC #$2
    0x38,0,0,0,          // SEC
    0xE9,0x20,0,0,      // SBC #$2
  
    
    
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$1
    
    0xf8, 0,0,0,        // SED // Decimcal Mode
    0xA9,0x1,0,0,      // LDA #$0
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$1
    0x38,0,0,0,          // SEC
    0xE9,0x1,0,0,      // SBC #$0
    0x18,0,0,0,          // CLC
    0x69,0x1,0,0,      // ADC #$1
    0x38,0,0,0,          // SEC
    0xE9,0x2,0,0,      // SBC #$2
   
    
   
    
   
    
   
    
    0,0,0,0,      // Stop
   
    
    0xA9,0x57,0,0,       // LDA #$57
    0x2A,0,0,0,         // ROL
    0x2A,0,0,0,         // ROL
    0x2A,0,0,0,         // ROL
    0x6A,0,0,0,         // ROR
    0x6A,0,0,0,         // ROR
    0x2A,0,0,0,         // ROL
    0x2A,0,0,0,         // ROL
    0x2A,0,0,0,         // ROL
    0xAA,0,0,0,         // TAX
    0xE8,0,0,0,         // INX
    0xE8,0,0,0,         // INX
    0xCA,0,0,0,         // DEX
    0x8A,0,0,0,         // TXA
    0xA8,0,0,0,         // TAY
    0xC8,0,0,0,         // INY
    0xC8,0,0,0,         // INY
    0xC8,0,0,0,         // INY
    0x88,0,0,0,         // DEY
    0x98,0,0,0,         // TYA
    0xA9,0x40,0,0,      // LDA #$40
    0x69,0x10,0,0,      // ADC #$10
    0xe9,0x10,0,0,      // SBC #$20
    0x69,0x10,0,0,      // ADC #$10
    0xe9,0x05,0,0,      // SBC #$05
    0x69,0x50,0,0,      // ADC #$50
    0xe9,0x55,0,0,      // SBC #$55
    0x69,0x50,0,0,      // ADC #$50
    0xe9,0x55,0,0,      // SBC #$55
    0xA9,0x00,0,0,      // LDA #$00
    0xe9,0x1,0,0,       // SBC #$1
    0x69,0x1,0,0,       // ADC #$1
    0x69,0x1,0,0,       // ADC #$1
    0xe9,0x1,0,0,       // SBC #$1
    0x69,0x1,0,0,       // ADC #$1
    0x69,0x1,0,0,       // ADC #$1
    0xf8,0x18, 0xb8,0,   // CLC SED CLV
    0xA9,0x40,0,0,      // LDA #$40
    0x69,0x10,0,0,      // ADC #$10
    0xe9,0x10,0,0,      // SBC #$20
    0x69,0x10,0,0,      // ADC #$10
    0xe9,0x05,0,0,      // SBC #$05
    0x69,0x50,0,0,      // ADC #$50
    0xe9,0x55,0,0,      // SBC #$55
    0x69,0x50,0,0,      // ADC #$50
    0xe9,0x55,0,0,      // SBC #$55
    0xA9,0x00,0,0,      // LDA #$00
    0xe9,0x1,0,0,       // SBC #$1
    0x69,0x1,0,0,       // ADC #$1
    0x69,0x1,0,0,       // ADC #$1
    0xe9,0x1,0,0,       // SBC #$1
    0x69,0x1,0,0,       // ADC #$1
    0x69,0x1,0,0,       // ADC #$1
    
    
    
   
    0,0,0,0
            
                      
]

print("Setting up virtual CPU")
MOS6502.Init(ProgramName: "Tester") // One instruction at a time, stepping four bytes
    

do {

    print("Attempting to open port")
    try serialPort.openPort()
    print("Serial port opened successfully.")
    defer {
        
        print("Stuff done so closing port")
        serialPort.closePort()
        print("defer Port Closed")
    }

    serialPort.setSettings(receiveRate: .baud1200,
                           transmitRate: .baud1200,
                           minimumBytesToRead: 1)
    usleep(200000)
    
    // Run code
    
    //Prepare()
    
    if (Peek(address: 0x17FF) != 0x1c)
    {
        print("Setting vectors")
        SetVectors()
    }
    print("Setting initial values")
    
    Poke(address: 0x201, value: 0)
    Poke(address: 0x202, value: 0)
    Poke(address: 0x203, value: 0)
   
  
    
    MOS6502.Write(address: 0x201, byte: 0)
    MOS6502.Write(address: 0x202, byte: 0)
    MOS6502.Write(address: 0x203, byte: 0)
    
    print("Copying Zero Page contents")
    
    for i:UInt16 in Range(0...16)
    {
       
        let b = Peek(address : i)
        MOS6502.Write(address: 0x0, byte: b)
        print(i , " ", terminator: "")
    }
    
    Poke(address: 0x0, value: 0)
    Poke(address: 0x1, value: 0)
    Poke(address: 0x2, value: 0)
    
    MOS6502.Write(address: 0x0, byte: 0)
    MOS6502.Write(address: 0x1, byte: 0)
    MOS6502.Write(address: 0x2, byte: 0)
   
    
    // run the tests
    print("Running the tests")
    
    for step in Range(0...5)
    {
        _ = LoadCode(offset : step)
        _ = RunCodeVirtual(address: 0x200)
        RunCode(address: 0x200) ; GetStatus() ; PrintStatus()
    }
    
    print("Fuzzing")
    for _ in Range(0...256)
    {
    
        _ = LoadCodeFuzz()
      // _ = LoadCode(offset : step)
        
        // Only try running the instruction if it is value i.e. the virtual CPU knows it exists
        if  RunCodeVirtual(address: 0x200)
        {
            RunCode(address: 0x200) ; GetStatus() ; PrintStatus()
        }
    }
    
    // Poke in the new values
    /*
    Poke(address: 0x200, value: 10)
    Poke(address: 0x201, value: 20)
    Poke(address: 0x202, value: 30)
    
    // Peek them back out to confirm
    
    _ = Peek(address: 0x0200)
    usleep(200000)
    _ = Peek(address: 0x0201)
    usleep(200000)
    _ = Peek(address: 0x0202)
    usleep(200000)
   */
    print("End")
   
} catch PortError.failedToOpen {
    print("Serial port failed to open. You might need root permissions.")
} catch {
    print("Error: \(error)")
}


func PrintStatus()
{
    print("rA: " + String(format: "%02X",A_REGISTER) + "  X: " + String(format: "%02X",X_REGISTER) + "  Y: " + String(format: "%02X",Y_REGISTER) + "  Flags: " + StatusFlagToString(reg: STATUS_REGISTER))
    
}

func LoadCode(offset : Int) -> Bool
{
    // Copy bytes from the test data store into virtual CPU and actual CPU
    
    let base = (offset * 4)
    
    if code[base] == 0
    {
        return false
    }
    
    for i  in Range(0...3)
    {
        let b = code[base + i]
        MOS6502.Write(address: 0x200 + UInt16(i), byte: b)
        Poke(address: 0x0200 + UInt16(i), value: b)
    }
    
    return true
}

func LoadCodeFuzz() -> Bool
{
    // Pick an instruction at random and run it and see what happens
    // Need to set flags and registers to known values to have a chance at
    // this working, and probably memory too.
    
  
    let n1 = UInt8.random(in: 0..<255)
    // let n2 = 0// UInt8.random(in: 0..<255)
    // let n3 = 0// UInt8.random(in: 0..<255)
    
    MOS6502.Write(address: 0x200, byte: n1)
    Poke(address: 0x0200, value: n1)
  
   // MOS6502.Write(address: 0x201, byte: n2)
   // Poke(address: 0x0201, value: n2)
  
   // MOS6502.Write(address: 0x202, byte: n3)
   // Poke(address: 0x0202, value: n3)
  
   // MOS6502.Write(address: 0x203, byte: 0)
   // Poke(address: 0x0203, value: 0)
  
    
    return true
}


func RunCodeVirtual(address: UInt16) -> Bool
{
    MOS6502.SetPC(ProgramCounter: address)
    let opcode = MOS6502.Step()
    
    if opcode.address == 0xffff
    {
        return false
    }
    
    print(opcode.opcode, String(format: "%02X",MOS6502.Read(address: address)) )
    print("vA: " + String(format: "%02X",MOS6502.getA()) + "  X: " + String(format: "%02X",MOS6502.getX()) + "  Y: " + String(format: "%02X",MOS6502.getY()) + "  Flags: " + StatusFlagToString(reg: MOS6502.GetStatusRegister()))
    
   return true
}



func SetVectors()
{
    Poke(address: 0x17FA, value: 0x00)
    Poke(address: 0x17FB, value: 0x1C)
    
    Poke(address: 0x17FC, value: 0x22)
    Poke(address: 0x17FD, value: 0x1C)
    
    Poke(address: 0x17FE, value: 0x00)
    Poke(address: 0x17FF, value: 0x1C)
}

func Prepare()
{
    Poke(address: 0x0200, value: 0x00)
    Poke(address: 0x0201, value: 0x00)
    Poke(address: 0x0202, value: 0x00)
    Poke(address: 0x0203, value: 0x00)
    Poke(address: 0x0204, value: 0x00)

}

func GetStatus()
{
    STATUS_REGISTER = Peek(address: 0x00F1)
    A_REGISTER = Peek(address: 0x00F3)
    X_REGISTER = Peek(address: 0x00F5)
    Y_REGISTER = Peek(address: 0x00F4)
    
}

func RunCode(address: UInt16)
{
    // Send a G and wait for response
    
   // print("Run Code at \(address)")
    
    let addr = String(format: "%04X", address).map { String($0) }

    do {
        
        
    _ = try serialPort.writeString(addr[0]) ; usleep(100000)
    _ = try serialPort.writeString(addr[1]) ; usleep(100000)
    _ = try serialPort.writeString(addr[2]) ; usleep(100000)
    _ = try serialPort.writeString(addr[3]) ; usleep(100000)
    _ = try serialPort.writeString(" ") ;
    
    
    _ = try serialPort.readString(ofLength: 21)
        
        usleep(100000)
        
    _ = try serialPort.writeString("G")
        
    _ = try serialPort.readString(ofLength: 28)
        

    
    } catch {
        print("Error: \(error)")
    
}
    
}


func Poke(address : UInt16, value : UInt8)
{
    // Send address, space
    // Send value, .
    
   //print("Poke \(value) into \(address)");
    
    do {
        
    let addr = String(format: "%04X", address).map { String($0) }
    let byte = String(format: "%02X", value).map { String($0) }
        
       
        _ = try serialPort.writeString(addr[0]) ; usleep(100000)
        _ = try serialPort.writeString(addr[1]) ; usleep(100000)
        _ = try serialPort.writeString(addr[2]) ; usleep(100000)
        _ = try serialPort.writeString(addr[3]) ; usleep(100000)
        _ = try serialPort.writeString(" ") ; usleep(200000)
        
        let _ = try serialPort.readString(ofLength: 21)
        
        _ = try serialPort.writeString(byte[0]) ; usleep(100000)
        _ = try serialPort.writeString(byte[1]) ; usleep(100000)
        _ = try serialPort.writeString(".") ; usleep(200000)
        

       let _ = try serialPort.readString(ofLength: 19)
        
        usleep(200000)
         
    }  catch {
        print("Error: \(error)")
    }
    
}


func Peek(address : UInt16) -> UInt8
{
    
    var dec : UInt8 = 0
    
    do {
        
    let addr = String(format: "%04X", address).map { String($0) }
        
       
        _ = try serialPort.writeString(addr[0]) ; usleep(100000)
        _ = try serialPort.writeString(addr[1]) ; usleep(100000)
        _ = try serialPort.writeString(addr[2]) ; usleep(100000)
        _ = try serialPort.writeString(addr[3]) ; usleep(100000)
        _ = try serialPort.writeString(" ") ;
        
        
        let s = try serialPort.readString(ofLength: 21)
        
        let parts = s.components(separatedBy: " ")
        
      
         dec = UInt8(parts[2], radix: 16)!
              
    }  catch {
        print("Error: \(error)")
    }
    
    //print("Peek \(dec) from \(address)");
    
    
    return dec
}

func StatusFlagToString(reg : UInt8) -> String
{
  
        let CARRY_FLAG = (reg & 1) == 1
        let ZERO_FLAG = (reg & 2) == 2
        let INTERRUPT_DISABLE = (reg & 4) == 4
        let DECIMAL_MODE = (reg & 8) == 8
        let BREAK_FLAG = false; // (reg & 16) == 16
        let OVERFLOW_FLAG = (reg & 64) == 64
        let NEGATIVE_FLAG = (reg & 64) == 128
    
    var flags = ""
    if NEGATIVE_FLAG { flags="N" } else {flags="n"}
    if OVERFLOW_FLAG { flags = flags + "V" } else { flags = flags + "v" }
    flags = flags + "_"
    if BREAK_FLAG { flags = flags + "B" } else { flags = flags + "b" }
    if DECIMAL_MODE { flags = flags + "D" } else { flags = flags + "d" }
    if INTERRUPT_DISABLE { flags = flags + "I" } else {flags = flags + "i"}
    if ZERO_FLAG { flags = flags + "Z"} else {flags = flags + "z"}
    if CARRY_FLAG { flags = flags + "C"} else {flags = flags + "c"}
    
    return flags
}


/*
 
 //
 //        for i in Range(0...27)
 //        {
 //            let c = try serialPort.readChar()
 //            print(i, c)
 //        }
 //
 //
 //
 */
