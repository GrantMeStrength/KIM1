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

var vResult = ""
var aResult = ""


let TESTING = false

private var PROGRAM_COUNTER : UInt16 = 0x200
private var HIT_BRK = false


private var MOS6502 = CPU()

let code : [UInt8] = [
    
    
    // Address mode checks
    
    
    
    
    // Set everything to a known state
    
    0x18,0,0,0,         // CLC
    0xd8,0,0,0,         // CLD
    0xb8,0,0,0,         // CLV
    
    
    0xD8,0,0,0,
    0xA2,0x02,0,0,
    0xA9,0x10,0,0,
    0xA0,0x01,0,0,
    
    0x85,0x00,0,0,
    0xA9,0x01,0,0,
    0x85,0x01,0,0,
    0xA9,0x20,0,0,
    0x85,0x02,0,0,
    0xA9,0x01,0,0,
    0x85,0x03,0,0,
    0xA9,0x42,0,0,
    0x85,0x10,0,0,
    0xA9,0x69,0,0,
    0x85,0x11,0,0,
    0xA9,0x99,0,0,
    0x85,0x12,0,0,
    0xA9,0x18,0,0,
    0x8D,0x11,0x01,0,
    0xA9,0x21,0,0,
    0x8D,0x20,0x01,0,
    0xA9,0x00,0,0,
    0xA5,0x10,0,0,
    0xA5,0x11,0,0,
    
    0xB5,0x10,0,0,
    0xAD,0x10,0x00,0,
    0xBD,0x10,0x00,0,
  
    0xB9,0x10,0x00,0,
    0xA1,0x00,0,0,
    0xB1,0x00,0,0,
    0xA1,0x00,0,0,
    0xB1,0x00,0,0,
    0xA1,0x00,0,0,
    0xB1,0x00,0,0,
    0x00,0,0,0,

    
    0xA9,0x50,0,0,      // LDA #$99
    0xA2,0x0,0,0,      // LDX #$0
    0xA0,0x0,0,0,      // LDY #$0
    0x38,0,0,0,         // SEC
  
    
    // More ADC/SBC flag shennanighans
    
    0xf8, 0,0,0,        // SED // Decimcal Mode
    
    /*
    0x69,0x14,0,0,
    0x69,0x11,0,0,
    0x69,0x10,0,0,
    0x69,0x14,0,0,
    0x69,0x11,0,0,
    0x69,0x10,0,0,
    0x69,0x9,0,0,
    0x69,0x8,0,0,
    0x69,0x7,0,0,
    0x69,0x5,0,0,
    0x69,0x4,0,0,
    0x69,0x3,0,0,
    0x69,0x2,0,0,
    0x69,0x1,0,0,
    0x69,0x1,0,0,
    0x69,0x14,0,0,
    0x69,0x11,0,0,
    */
    
    0xe9,0x1,0,0,
    0xe9,0x1,0,0,
    0xe9,0x1,0,0,
    0xe9,0x1,0,0,
    0xe9,0x11,0,0,
    0xe9,0x10,0,0,
    0xe9,0x9,0,0,
    0xe9,0x8,0,0,
    0xe9,0x7,0,0,
    0xe9,0x5,0,0,
    0xe9,0x4,0,0,
    0xe9,0x3,0,0,
    0xe9,0x2,0,0,
    0xe9,0x1,0,0,
    0xe9,0x1,0,0,
    0xe9,0x14,0,0,
    0xe9,0x11,0,0,
    0xe9,0x10,0,0,
    0xe9,0x9,0,0,
    0xe9,0x8,0,0,
    0xe9,0x7,0,0,
    0xe9,0x5,0,0,
    0xe9,0x4,0,0,
    0xe9,0x3,0,0,
    0xe9,0x2,0,0,
    0xe9,0x1,0,0,
    0xe9,0x1,0,0,
    0xe9,0x14,0,0,
    0xe9,0x11,0,0,
    0xe9,0x10,0,0,
    0xe9,0x14,0,0,
    0xe9,0x11,0,0,
    0xe9,0x10,0,0,
    0xe9,0x9,0,0,
    0xe9,0x8,0,0,
    0xe9,0x7,0,0,
    0xe9,0x5,0,0,
    0xe9,0x4,0,0,
    0xe9,0x3,0,0,
    0xe9,0x2,0,0,
    0xe9,0x1,0,0,
    0xe9,0x1,0,0,
    0xe9,0x14,0,0,
    0xe9,0x11,0,0,
    0xe9,0x10,0,0,
    0xe9,0x14,0,0,
    0xe9,0x11,0,0,
    0xe9,0x10,0,0,
    0xe9,0x9,0,0,
    0xe9,0x8,0,0,
    0xe9,0x7,0,0,
    0xe9,0x5,0,0,
    0xe9,0x4,0,0,
    0xe9,0x3,0,0,
    0x69,0x2,0,0,
    0x69,0x1,0,0,
    0x69,0x1,0,0,
    0x69,0x14,0,0,
    0x69,0x11,0,0,
    0x69,0x10,0,0,
    0x69,0x9,0,0,
    0x69,0x8,0,0,
    0x69,0x7,0,0,
    0x69,0x5,0,0,
    0x69,0x4,0,0,
    0x69,0x3,0,0,
    0x69,0x2,0,0,
    0x69,0x1,0,0,
    0x69,0x1,0,0,
 
    
   // 0xe9,0x01,0,0,
   // 0xe9,0x01,0,0,
   // 0xe9,0x01,0,0,
   
   
   // 0x69,0x01,0,0,
   
    0x00,00,00,00,
    
    // Test indexed-indirect
    0xA2,0x2,0,0,      // LDX #$2
    0xA1,0x10,0,0,      // LDA (#$10,X)
   
    
    
   
    
   
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

let pre_program : [UInt8] = [
    0x18,        // CLC
    0xd8,         // CLD
    0xb8,         // CLV
    
    0xA9,0x0,      // LDA #$0
    0xA2,0x0,     // LDX #$0
    0xA0,0x0,      // LDY #$0
    
    0x0,            // brk
]

let program : [UInt8] = [
    
    // little loop inc x
    0xa9, 0x00, 0xa0, 0x04, 0xa2, 0x04, 0x69, 0x01, 0xca, 0xd0, 0xfb, 0x88, 0xd0, 0xf6, 0x00
                          
                          
    ]

let program22 : [UInt8] = [0x20, 0x1F, 0x1F, 0x20, 0x6A, 0x1F, 0xC5, 0x60, 0xF0, 0xF6, 0x85, 0x60, 0xC9, 0x0A, 0x90, 0x29, 0xC9, 0x13, 0xF0, 0x18, 0xC9, 0x12, 0xD0, 0xE8,
                         0xF8, 0x18, 0xA2, 0xFD, 0xB5, 0xFC, 0x75, 0x65, 0x95, 0xFC, 0x95, 0x65, 0xE8, 0x30, 0xF5, 0x86, 0x61, 0xD8, 0x10, 0xD4, 0xA9, 0x00, 0x85, 0x61,
                         0xA2, 0x02, 0x95, 0xF9, 0xCA, 0x10, 0xFB, 0x30, 0xC7, 0xA4, 0x61, 0xD0, 0x0F, 0xE6, 0x61, 0x48, 0xA2, 0x02, 0xB5, 0xF9, 0x95, 0x62, 0x94, 0xF9,
                         0xCA, 0x10, 0xF7, 0x68, 0x0A, 0x0A, 0x0A, 0x0A, 0xA2, 0x04, 0x0A, 0x26, 0xF9, 0x26, 0xFA, 0x26, 0xFB, 0xCA, 0xD0, 0xF6, 0xF0, 0xA2] //



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
    
    if TESTING
    {
        
    
    
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
    
//    print("Copying Zero Page contents")
//
//    for i:UInt16 in Range(0...16)
//    {
//
//        let b = Peek(address : i)
//        MOS6502.Write(address: 0x0, byte: b)
//        print(i , " ", terminator: "")
//    }
    
//    Poke(address: 0x10, value: 0x40)
//    Poke(address: 0x11, value: 0x50)
//    Poke(address: 0x12, value: 0x60)
//
//    Poke(address: 0x40, value: 0x1)
//    Poke(address: 0x50, value: 0x2)
//    Poke(address: 0x60, value: 0x3)
//
//    MOS6502.Write(address: 0x10, byte: 0x40)
//    MOS6502.Write(address: 0x11, byte: 0x50)
//    MOS6502.Write(address: 0x12, byte: 0x60)
//
//    MOS6502.Write(address: 0x40, byte: 0x1)
//    MOS6502.Write(address: 0x50, byte: 0x2)
//    MOS6502.Write(address: 0x60, byte: 0x3)
//
    
    // run the tests
    print()
    print("Running the tests")
    
    for step in Range(0...128)
    {
        _ = LoadCode(offset : step)
        _ = RunCodeVirtual(address: 0x200)
        RunCode(address: 0x200) ; GetStatus() ; PrintStatus()
    
        _ = DiffStatus()
    
    }
    
    print("Fuzzing")
    for _ in Range(0...1024)
    {
    
        _ = LoadCodeFuzz()
      // _ = LoadCode(offset : step)
        
        // Only try running the instruction if it is value i.e. the virtual CPU knows it exists
        if  0xffff != RunCodeVirtual(address: 0x200)
        {
            RunCode(address: 0x200) ; GetStatus() ; PrintStatus()
            
         if   !DiffStatus()
         {
            // Error occured - can reset flags and regs
            
            print("Resetting")
            for step in Range(0...5)
            {
                _ = LoadCode(offset : step)
                _ = RunCodeVirtual(address: 0x200)
                RunCode(address: 0x200) ; GetStatus() ; PrintStatus()
                print(5-step , " ", terminator: "")
            
            }
            
            print()
            
            
         }
            
            
            
        }
    }
        
    }
    else
    {
        
        print("Executing")
        
        // Load the pre-program to get to known state
        
        
        for step in 0..<pre_program.count
        {
            print(pre_program.count-step)
            Poke(address: UInt16(0x200 + step), value: pre_program[step])
            MOS6502.Write(address: UInt16(0x200 + step), byte: pre_program[step])
        }
        
        print("Pre program")
        PROGRAM_COUNTER = 0x200
        while HIT_BRK == false  {
    
        print("Program counter: ",String(format: "%04X", PROGRAM_COUNTER))
        RunCode(address: PROGRAM_COUNTER) ; GetStatus() ; PrintStatus()
        PROGRAM_COUNTER = RunCodeVirtual(address: PROGRAM_COUNTER)
           
        _ = DiffStatus()
        
      
        }
        
       
        print("The program ")
        
        HIT_BRK = false
        PROGRAM_COUNTER = 0x200
       // for step in 0..<16
        for step in 0..<program.count
        {
            print(program.count-step)
             Poke(address: UInt16(0x200 + step), value: program[step])
             MOS6502.Write(address: UInt16(0x200 + step), byte: program[step])
        }
      
        while HIT_BRK == HIT_BRK  {
    
            print("Program counter: ",String(format: "%04X", PROGRAM_COUNTER))
            RunCode(address: PROGRAM_COUNTER) ; GetStatus() ; PrintStatus()
            PROGRAM_COUNTER = RunCodeVirtual(address: PROGRAM_COUNTER)
          
            
        _ = DiffStatus()
        
      
        }
        
    }
  
    print("End")
   
} catch PortError.failedToOpen {
    print("Serial port failed to open. You might need root permissions.")
} catch {
    print("Error: \(error)")
}

func DiffStatus() -> Bool
{
    
    if (aResult == vResult)
    {
        print("a"+aResult)
        print("v"+vResult)
        print()
        return true
    }
    else
    {
        print("a"+aResult)
        print("v"+vResult + "⚠️")
        print()
        return false
    }
    
}

func PrintStatus()
{
    aResult = "A: " + String(format: "%02X",A_REGISTER) + "  X: " + String(format: "%02X",X_REGISTER) + "  Y: " + String(format: "%02X",Y_REGISTER) + "  Flags: " + StatusFlagToString(reg: STATUS_REGISTER)
    
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
        var b = code[base + i]
        
        // Random value for ADC/SBC
        if code[base] == 0xe9 && i == 1
        {
            b = UInt8.random(in: 0...255)
        }
        
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
    
    // Let's try family of instructions
    
    
    let n1 = UInt8.random(in: 0..<255)
    
    // Naw sucks - always a branch or something to mess
    // things up.
   

    
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


func RunCodeVirtual(address: UInt16) -> UInt16
{
    MOS6502.SetPC(ProgramCounter: address)
    let opcode = MOS6502.Step()
    
    if opcode.address == 0xffff
    {
        return opcode.address
    }
    
    if opcode.Break == true
    {
        HIT_BRK = true
    }
    
    print(opcode.opcode, String(format: "%02X",MOS6502.Read(address: address)) )
    
    vResult =  "A: " + String(format: "%02X",MOS6502.getA()) + "  X: " + String(format: "%02X",MOS6502.getX()) + "  Y: " + String(format: "%02X",MOS6502.getY()) + "  Flags: " + StatusFlagToString(reg: MOS6502.GetStatusRegister())
    
   return opcode.address
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
   // if INTERRUPT_DISABLE { flags = flags + "I" } else {flags = flags + "i"}
    flags = flags + "i"
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

/*
 ; Test all addressing modes
0200                          .ORG   $200
0200   D8                     CLD
0201                             ; Put some default values into memory - also test immediate
0201   A9 10                  LDA   #$10
0203   85 00                  STA   $0
0205   A9 01                  LDA   #$01
0207   85 01                  STA   $1
0209   A9 20                  LDA   #$20
020B   85 02                  STA   $2
020D   A9 01                  LDA   #$01
020F   85 03                  STA   $3
0211   A9 42                  LDA   #$42
0213   85 10                  STA   $10
0215   A9 69                  LDA   #$69
0217   85 11                  STA   $11
0219   A9 99                  LDA   #$99
021B   85 12                  STA   $12
021D   A9 18                  LDA   #$18
021F   8D 11 01               STA   $0111
0222   A9 21                  LDA   #$21
0224   8D 20 01               STA   $0120
0227                             ; Start loading A using different addressing modes
0227   A9 00                  LDA   #$0   ; Load A with 0
0229                             ; Zero Page
0229   A5 10                  LDA   $10   ; Load A with contents of (10) which is 42
022B   A5 11                  LDA   $11   ; Load A with contents of (11) which is 69
022D                             ; Zero page, indexed
022D   A2 02                  LDX   #$02
022F   B5 10                  LDA   $10,X   ; Load A with contents of (10 + X) which is 99
0231                             ; Absolute
0231   AD 10 00               DB   $AD,$10,$00   ; Load A with contents of (0010) which is 42
0234                             ; Absolute X
0234   BD 10 00               DB   $BD,$10,$00   ; Load A with contents of (0010 + X) which 99
0237                             ; Absolute Y
0237   A0 01                  LDY   #$1
0239   B9 10 00               LDA   $0010,Y   ; Load A with contents of (0010 + Y) which is 69
023C                             ; (Indirect, X)
023C   A1 00                  LDA   ($0000,X)   ; Base addr = ($0000 + X). Load A with (addr) = 21
023E                             ; (Indirect),Y
023E   B1 00                  LDA   ($0000),Y   ; Base addr = contents of (0000) )Load a with (addr+Y) = 18
0240   00                     BRK


 */
