//
//  main.swift
//  JustWork
//
//  Created by John Kennedy on 2/22/21.
//
// Tried to expand to Apple1 RC6502 system but it was quite
// unreliable, and lacks SST, so back to KIM_1
//


import Foundation


var STATUS_REGISTER : UInt8 = 0
var A_REGISTER : UInt8 = 0
var X_REGISTER : UInt8 = 0
var Y_REGISTER : UInt8 = 0
var PC_REGISTER : UInt16 = 0
var SP_REGISTER : UInt8 = 0

var vResult = ""
var aResult = ""


let SLEEP : UInt32 = 12000

private let TESTING = false

private var PROGRAM_COUNTER : UInt16 = 0x200
private var HIT_BRK = false
private let KIM = true                 // KIM or Apple 1 WozMon
private let JIT = true

let serialPort: SerialPort = SerialPort(path: "/dev/cu.usbserial-AC00I4ST")
//let serialPort: SerialPort = SerialPort(path: "/dev/cu.usbserial-3230")

private var MOS6502 = CPU()


let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)

let code : [UInt8] = [
    
    
    // Address mode checks
    
    
    
    
    
    
    // Set everything to a known state
    
    0x18,0xea,0xea,        // CLC
    0xd8,0xea,0xea,       // CLD
    0xb8,0xea,0xea,       // CLV
    
  
    
    
    0xa9,0,0,            //   ld a 0
    0x38,0,0,            //   set carry
    0xb0,02,0,            // bcs
    0xa9,2,0,
    0xa9,1,0,
    0xa9,3,0,
    0x18,0xea,0xea,        // CLC
    0x90, 0xf9, 0,          // branching
    0xb0, 0xf7, 0,          // branching
    0xeA,0,0,
    0xeA,0,0,
    0xeA,0,0,
    
    
    
    0xa9,0x42,0,          // lda 42
    0xa0,0x04,0,          // ldy 4
    0x91,0x80,0,          // sta (80),y
    
    0xA2,0xfD,0xea,
    0x9A,0xea,0xea,         // Set Stack
    0xA9,0x10,0xea,
    0xA0,0x01,0xea,
    
    0x85,0x00,0xea,
    0xA9,0x01,0xea,
    0x85,0x01,0xea,
    0xA9,0x20,0xea,
    0x85,0x02,0xea,
    0xA9,0x01,0xea,
    0x85,0x03,0xea,
    0xA9,0x42,0xea,
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
    0x8e,0x50,01,
    0x8e,0x4f,01,
    0x0,            // brk
]

let program : [UInt8] = [
    
    
    //  0x18,        // CLC
    //  0xd8,       // CLD
    //  0xb8,       // CLV
    
    0xa2,0x0,
    0x8e,0x50,01,
    0x8e,0x4F,01,
    0xa2,0x50,
    0x9a,
    0xa9,01,
    0x20,0x16,02,
    0xea,0xea,0xea,0xea,0xea,0xea,
    0xa9,02,
    0x60,
    0,0,0,0
    
    
    
//    0xa0,0x01,
//    0xb9,0x80, 0,
//    0x85,0x20,
//    0x24,0x20,
//    0xe6,0x20,
//    0x45,0x20,
//    0xb0,0xf8,
//    0x4c,0x07,0x02,
//    0xea
//
    
    /*
     0xa9,0,            //   ld a 0
     0x38,            //   set carry
     0xb0,02,            // bcs
     0xa9,2,
     0xa9,1,
     0xa9,3,
     0x18,       // CLC
     0x90, 0xf9,          // branching
     0xb0, 0xf7,           // branching
     0xeA,
     0xeA,
     0xeA,
     */
    /*
     0xe0, 0x03, 0xb0, 0x01, 0x88, 0x49, 0x7f, 0xc0, 0xc8, 0x7d, 0x20, 0x04,
     0x85, 0x06, 0x98, 0x20, 0x1c, 0x04, 0xe5, 0x06, 0x85, 0x06, 0x98, 0x4a,
     0x4a, 0x18, 0x65, 0x06, 0x69, 0x07, 0x90, 0xfc, 0x00, 0x01, 0x05, 0x06,
     0x03, 0x01, 0x05, 0x03, 0x00, 0x04, 0x02, 0x06, 0x04, 0x00, 0x00, 0x00,
     */
    
]

let program22: [UInt8] =  [

    0xa2,01,0x85,0x20,06,0x20,0xe6,0x20,0x66,0x20,0x66,0x20,0x8a,0x45,0x20,0xe6,0x20,0x26,0x20,0x8a,0x25,0x20,0xe6,0x20,0x05,0x20,0xca,0xd0,0xe9,0x8a,0x4c,0x04,0x02,0x0
    
    
    //0xa9,0xf0,0x0a,0x69,0x80,0x2a,0x0a,0x69,0x80,0x2a,0
] //



// Woz code STA, STX, STY, ST FLags in 50,51,52,53,54
let WozMonCode : [UInt8] = [0xEA, 0xEA, 0xEA,  0xEA, 0x08, 0x85, 0xF3, 0x86, 0xf5, 0x84, 0xf4, 0x68, 0x85, 0xf1, 0x4c, 0x1f, 0xff]

//


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
    
    if KIM {
        serialPort.setSettings(receiveRate: .baud1200,
                               transmitRate: .baud1200,
                               minimumBytesToRead: 1)
        usleep(200000)
    }
    else
    {
        serialPort.setSettings(receiveRate: .baud115200,
                               transmitRate: .baud115200,
                               minimumBytesToRead: 1)
        usleep(200000)
    }
    
    
    // Run code
    
    if TESTING
    {
        if !KIM {
            print("WozMon")
            ReadWozMonStartString()
            print(Peek(address: 0x0000))
            print(Peek(address: 0x0001))
            print(Peek(address: 0x0002))
            Poke(address: 0x0000, array: [0x1, 0x2, 0x3])
            print(Peek(address: 0x0000))
            print(Peek(address: 0x0001))
            print(Peek(address: 0x0002))
            
            print("WozMon OK")
        }
        
        
        //Prepare()
        
        
        print("Setting initial values")
        
        if (KIM)
        {
            if (Peek(address: 0x17FF) != 0x1c)
            {
                print("Setting vectors")
                SetVectors()
            }
        }
        else
        {
            // Poking WozStatus code
            
            Poke(address: UInt16(0), array: [0xEA, 0xEA, 0xEA,  0xEA, 0x08, 0x85, 0xF3, 0x86, 0xf5, 0x84, 0xf4, 0x68, 0x85, 0xf1, 0x4c, 0x1f, 0xff]);
            
            //            for i in Range(0...16)
            //               {
            //
            //                   let b = WozMonCode[i]
            //                    Poke(address: UInt16(i), value: b)
            //
            //            }
            print("WozCode Poked")
        }
        
        //    print("Copying Zero Page contents")
        //
        //    for i:UInt16 in Range(0...16)
        //    {
        //
        //        let b = Peek(address : i)
        //        MOS6502.Write(address: 0x0, byte: b)
        //        print(i , " ", terminator: "")
        //    }
        
        
        
        // run the tests
        print()
        print("Running the tests")
        
        if (KIM)
        {
            
          
            
            
            for step in Range(0...24)
            {
                _ = LoadCode(offset : step)
                _ = RunCodeVirtual(address: 0x200)
                RunCode(address: 0x200) ; GetStatus() ; PrintStatus()
                
                _ = DiffStatus()
                
            }
        }
        else
        {
            for step in Range(0...128)
            {
                _ = LoadCode(offset : step)
                _ = RunCodeVirtual(address: 0x0)
                RunCode(address: 0x0) ; GetStatus() ; PrintStatus()
                
                _ = DiffStatus()
            }
        }
        
        //        print("Peek the test data")
        //        print(Peek(address: 0x4000))
        //        print(Peek(address: 0x4004))
        //
        
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
            print(pre_program.count-step, terminator: "")
            Poke(address: UInt16(0x200 + step), value: pre_program[step])
            MOS6502.Write(address: UInt16(0x200 + step), byte: pre_program[step])
        }
        print()
        print("Pre program")
        
//        print("Poke in test data")
//        Poke(address: 0x80,value: 0x00)
//        Poke(address: 0x81,value: 0x40)
//
//        MOS6502.Write(address: UInt16(0x80), byte: 0)
//        MOS6502.Write(address: UInt16(0x81), byte: 0x40)
        
        PROGRAM_COUNTER = 0x200
        while HIT_BRK == false  {
            
            print("Program counter: ",String(format: "%04X", PROGRAM_COUNTER))
            RunCode(address: PROGRAM_COUNTER) ; GetStatus() ; PrintStatus()
            PROGRAM_COUNTER = RunCodeVirtual(address: PROGRAM_COUNTER)
            
            _ = DiffStatus()
            
            
        }
        
        
        print("The program ")
        
//        print("Poke in MS BASIC data")
//        LoadBasic();
//
        
        
        HIT_BRK = false
        PROGRAM_COUNTER = 0x200
        // for step in 0..<16
        for step in 0..<program.count
        {
            print(program.count-step, terminator: "")
            if (!JIT)
            {
                Poke(address: UInt16(0x200 + step), value: program[step])
            }
            MOS6502.Write(address: UInt16(0x200 + step), byte: program[step])
        }

        
        PROGRAM_COUNTER = 0x200 ;
        
        print()
        print("Running..")
        while HIT_BRK == HIT_BRK  {
            if (JIT)
            {
                Poke(address:PROGRAM_COUNTER, value: MOS6502.Read(address: PROGRAM_COUNTER))
                Poke(address:PROGRAM_COUNTER+1, value: MOS6502.Read(address: PROGRAM_COUNTER+1))
                Poke(address:PROGRAM_COUNTER+1, value: MOS6502.Read(address: PROGRAM_COUNTER+1))
                
            }
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
    // From Real Hardware
    aResult = "A: " + String(format: "%02X",A_REGISTER) + "  X: " + String(format: "%02X",X_REGISTER) + "  Y: " + String(format: "%02X",Y_REGISTER) + "  Flags: " + StatusFlagToString(reg: STATUS_REGISTER) + " PC: " + String(format: "%04X",PC_REGISTER) + " SP: " + String(format: "%02X",SP_REGISTER) + "  Memory: " + String(format: "%02X",Peek(address: 0x150)) + String(format: "%02X",Peek(address: 0x14f))
}

func LoadCode(offset : Int) -> Bool
{
    // Copy bytes from the test data store into virtual CPU and actual CPU
    
    let base = (offset * 3)
    
    if code[base] == 0
    {
        return false
    }
    
    for i  in Range(0...3)
    {
        let b = code[base + i]
        
        // Random value for ADC/SBC
        //        if code[base] == 0xe9 && i == 1
        //        {
        //            b = UInt8.random(in: 0...255)
        //        }
        
        if (KIM)
        {
            MOS6502.Write(address: 0x200 + UInt16(i), byte: b)
            Poke(address: 0x200 + UInt16(i), value: b)
        }
        else
        {
            MOS6502.Write(address: 0x0 + UInt16(i), byte: b)
            Poke(address: 0x00 + UInt16(i), value: b)
        }
    }
    
    return true
}

func LoadCodeFuzz() -> Bool
{
    // Pick an instruction at random and run it and see what happens
    // Need to set flags and registers to known values to have a chance at
    // this working, and probably memory too.
    
    
    let n1 = UInt8.random(in: 0..<255)
    
    
    MOS6502.Write(address: 0x200, byte: n1)
    Poke(address: 0x0200, value: n1)
    
    // Naw, not a good test.
    
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
    
    vResult =  "A: " + String(format: "%02X",MOS6502.getA()) + "  X: " + String(format: "%02X",MOS6502.getX()) + "  Y: " + String(format: "%02X",MOS6502.getY()) + "  Flags: " + StatusFlagToString(reg: MOS6502.GetStatusRegister()) + " PC: " + String(format: "%04X",opcode.address) + " SP: " + String(format: "%02X",opcode.stack) + "  Memory: " + String(format: "%02X",MOS6502.Read(address: 0x150)) + String(format: "%02X",MOS6502.Read(address: 0x14f))
    
    return opcode.address
}



func SetVectors()
{
    Poke(address: 0x17FA, value: 0x00); print ("*", terminator: "")
    Poke(address: 0x17FB, value: 0x1C); print ("*", terminator: "")
    
    Poke(address: 0x17FC, value: 0x22); print ("*", terminator: "")
    Poke(address: 0x17FD, value: 0x1C); print ("*", terminator: "")
    
    Poke(address: 0x17FE, value: 0x00); print ("*", terminator: "")
    Poke(address: 0x17FF, value: 0x1C) ;print ("*")
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
    let lb = UInt16(Peek(address: 0x00EF))
    let hb = UInt16(Peek(address: 0x00F0)) << 8
    PC_REGISTER =  lb | hb
    SP_REGISTER = Peek(address: 0x00F2)
    
    
}

func RunCode(address: UInt16)
{
    if KIM
    {
        RunCodeKim(address: address)
    }
    else
    {
        RunCodeWozMon(address: address)
    }
}


func RunCodeKim(address: UInt16)
{
    // Send a G and wait for response
    
    // print("Run Code at \(address)")
    
    let addr = String(format: "%04X", address).map { String($0) }
    
    do {
        
        
        _ = try serialPort.writeString(addr[0]) ; usleep(SLEEP)
        _ = try serialPort.writeString(addr[1]) ; usleep(SLEEP)
        _ = try serialPort.writeString(addr[2]) ; usleep(SLEEP)
        _ = try serialPort.writeString(addr[3]) ; usleep(SLEEP)
        _ = try serialPort.writeString(" ") ;
        
        
        _ = try serialPort.readString(ofLength: 21)
        
        usleep(SLEEP)
        
        _ = try serialPort.writeString("G")
        
        _ = try serialPort.readString(ofLength: 28)
        
        
        
    } catch {
        print("Error: \(error)")
        
    }
    
}

func RunCodeWozMon(address: UInt16)
{
    // Send a G and wait for response
    
    // print("Run Code at \(address)")
    
    let addr = String(format: "%04X", address).map { String($0) }
    
    do {
        
        
        _ = try serialPort.writeString(addr[0]) ; usleep(SLEEP)
        _ = try serialPort.writeString(addr[1]) ; usleep(SLEEP)
        _ = try serialPort.writeString(addr[2]) ; usleep(SLEEP)
        _ = try serialPort.writeString(addr[3]) ; usleep(SLEEP)
        _ = try serialPort.writeString("\r") ; usleep(SLEEP)
        
        let _ = try serialPort.readString(ofLength: 21)
        
        usleep(SLEEP)
        
        print("Running")
        _ = try serialPort.writeString("R")
        
        
        //        for i in Range(0...27)
        //                {
        //                    let c = try serialPort.readChar()
        //                    print(i, c)
        //                }
        //
        _ = try serialPort.readString(ofLength: 1)
        
        print("Ran")
        
    } catch {
        print("Error: \(error)")
        
    }
    
}



func Poke(address : UInt16, value : UInt8)
{
    // Send address, space
    // Send value, .
    
    //print("Poke \(value) into \(address)");
    
    if KIM {
        
        
        do {
            
            let addr = String(format: "%04X", address).map { String($0) }
            let byte = String(format: "%02X", value).map { String($0) }
            
            
            _ = try serialPort.writeString(addr[0]) ; usleep(SLEEP)
            _ = try serialPort.writeString(addr[1]) ; usleep(SLEEP)
            _ = try serialPort.writeString(addr[2]) ; usleep(SLEEP)
            _ = try serialPort.writeString(addr[3]) ; usleep(SLEEP)
            _ = try serialPort.writeString(" ") ; usleep(SLEEP)
            
            let _ = try serialPort.readString(ofLength: 21)
            
            _ = try serialPort.writeString(byte[0]) ; usleep(SLEEP)
            _ = try serialPort.writeString(byte[1]) ; usleep(SLEEP)
            _ = try serialPort.writeString(".") ; usleep(SLEEP)
            
            
            let _ = try serialPort.readString(ofLength: 19)
            
            usleep(SLEEP)
            
        }  catch {
            print("Error: \(error)")
        }
    }
    else
    {
        // WozMon
        do {
            
            print("Poking")
            let addr = String(format: "%04X", address).map { String($0) }
            let byte = String(format: "%02X", value).map { String($0) }
            
            
            _ = try serialPort.writeString(addr[0]) ; usleep(SLEEP)
            _ = try serialPort.writeString(addr[1]) ; usleep(SLEEP)
            _ = try serialPort.writeString(addr[2]) ; usleep(SLEEP)
            _ = try serialPort.writeString(addr[3]) ; usleep(SLEEP)
            _ = try serialPort.writeString(":") ; usleep(SLEEP)
            _ = try serialPort.writeString(byte[0]) ; usleep(SLEEP)
            _ = try serialPort.writeString(byte[1]) ; usleep(SLEEP)
            _ = try serialPort.writeString("\r") ; usleep(SLEEP)
            
            // let _ = try serialPort.readString(ofLength: 24)
            
            let _ = try serialPort.readBytes(into: buffer, size: 1024)
            
            usleep(SLEEP)
            
        }  catch {
            print("Error: \(error)")
        }
        
    }
}



func Poke(address : UInt16, array : [UInt8])
{
    // POke multiple values - Apple only
    
    
    // WozMon
    do {
        
        //print("Poking")
        let addr = String(format: "%04X", address).map { String($0) }
        
        
        _ = try serialPort.writeString(addr[0]) ; usleep(SLEEP)
        _ = try serialPort.writeString(addr[1]) ; usleep(SLEEP)
        _ = try serialPort.writeString(addr[2]) ; usleep(SLEEP)
        _ = try serialPort.writeString(addr[3]) ; usleep(SLEEP)
        _ = try serialPort.writeString(":") ; usleep(SLEEP)
        
        
        for i in Range(0...(array.count-1))
        {
            let byte = String(format: "%02X", array[i]).map { String($0) }
            _ = try serialPort.writeString(" ") ; usleep(SLEEP)
            _ = try serialPort.writeString(byte[0]) ; usleep(SLEEP)
            _ = try serialPort.writeString(byte[1]) ; usleep(SLEEP)
            
            
        }
        
        _ = try serialPort.writeString("\r") ; usleep(SLEEP)
        
        
        
        
        //   let s = try serialPort.readBytes(into: buffer, size: 1024)
        //  print(s)
        let _ = try serialPort.readString(ofLength: 10)
        
        usleep(SLEEP)
        
    }  catch {
        print("Error: \(error)")
        
    }
}


func ReadWozMonStartString()
{
    do {
        
        
        let ss = try serialPort.readBytes(into: buffer, size: 1024)
        
        print("Woz String: ", ss)
        
    }  catch {
        print("Error: \(error)")
    }
}

func Peek(address : UInt16) -> UInt8
{
    // print("Peeking")
    var dec : UInt8 = 0
    
    let addr = String(format: "%04X", address).map { String($0) }
    
    
    if KIM {
        
        do {
            
            
            
            _ = try serialPort.writeString(addr[0]) ; usleep(SLEEP)
            _ = try serialPort.writeString(addr[1]) ; usleep(SLEEP)
            _ = try serialPort.writeString(addr[2]) ; usleep(SLEEP)
            _ = try serialPort.writeString(addr[3]) ; usleep(SLEEP)
            _ = try serialPort.writeString(" ") ;
            
            
            let s = try serialPort.readString(ofLength: 21)
            
            let parts = s.components(separatedBy: " ")
            
            
            dec = UInt8(parts[2], radix: 16)!
            
        }  catch {
            print("Error: \(error)")
        }
        
        //print("Peek \(dec) from \(address)");
        
    }
    else
    {
        do {
            _ = try serialPort.writeString(addr[0]) ; usleep(5000)
            _ = try serialPort.writeString(addr[1]) ; usleep(5000)
            _ = try serialPort.writeString(addr[2]) ; usleep(5000)
            _ = try serialPort.writeString(addr[3]) ; usleep(5000)
            _ = try serialPort.writeString("\r") ;
            
            let s = try serialPort.readString(ofLength: 21)
            let parts = s.components(separatedBy: " ")
            let digits = parts[parts.count-1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if parts.count > 0
            {
                dec = UInt8(digits, radix: 16)!
            }
            //  let _ = try serialPort.readBytes(into: buffer, size: 1024)
            
            
            
        }  catch {
            print("Error: \(error)")
        }
        
    }
    
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


func LoadFile(input : String)
{
    let lines = input.components(separatedBy: "\n")
    
    for line in lines
    {
        var start = line.index(line.startIndex, offsetBy: 1)
        var end = line.index(line.startIndex, offsetBy: 3)
        var range = start..<end

        let number_of_bytes = line[range]

        start = line.index(line.startIndex, offsetBy: 3)
        end = line.index(line.startIndex, offsetBy: 7)
        range = start..<end

        let address = line[range]


        start = line.index(line.startIndex, offsetBy: 7)
        end = line.index(line.endIndex, offsetBy: -4)
        range = start..<end

        let _ = line[range]

      
        let number_of_bytesD = Int(UInt8((number_of_bytes), radix: 16)!)
        let addressD = Int(UInt16((address), radix: 16)!)

        if number_of_bytesD == 0
        {
            return
        }
        
        for pair in 0..<number_of_bytesD
        {
            start = line.index(line.startIndex, offsetBy: (7 + (pair * 2)))
            end = line.index(line.startIndex, offsetBy: (9 + (pair * 2)))
            range = start..<end
            let pairH = line[range]
            let pairD = UInt8((pairH), radix: 16)!
            
            
            MOS6502.Write(address: UInt16(addressD + pair), byte: pairD)

                 }
    }
    print("")
    print("")
}

/*
func LoadBasic()
{
    // Confirmed Basic
    
    LoadFile(input: ";182000E9260726C52B44288C2A9E2EB82AF128F127C9277428CA2609E1\n;182018D4271E288728E72697282A2718368B273B27B1310F368029078F\n;182030102778253B257D2A2025B13A443BD03A4B308131A231C23D07FB\n;182048E33E30383E3E1F3F263F6F3FD33F053673356632A43582350813\n;182060E334F73423352E35795536793E367B70387B89397FCB3D5009BD\n;182078062E46032E7D043E5A642D64332E454EC4464FD24E4558D40847\n;182090444154C1494E5055D44449CD524541C44C45D4474F54CF520AD8\n;1820A855CE49C6524553544F52C5474F5355C25245545552CE52450AAD\n;1820C0CD53544FD04FCE4E554CCC574149D44C4F41C4534156C5440BAB\n;1820D845C6504F4BC55052494ED4434F4ED44C4953D4434C4541D20B2E\n;1820F04745D44E45D7544142A854CF46CE535043A8544845CE4E4F0B82\n;182108D4535445D0ABADAAAFDE414EC44FD2BEBDBC5347CE494ED40DDE\n;1821204142D35553D24652C5504FD35351D2524EC44C4FC74558D00BA1\n;182138434FD35349CE5441CE4154CE504545CB4C45CE535452A4560AFD\n;18215041CC4153C3434852A44C454654A45249474854A44D4944A409DD\n;182168004E45585420574954484F555420464FD253594E5441D8520874\n;182180455455524E20574954484F555420474F5355C24F5554204F0822\n;1821984620444154C1494C4C4547414C205155414E544954D94F56088F\n;1821B04552464C4FD74F5554204F46204D454D4F52D9554E44454608D0\n;1821C827442053544154454D454ED44241442053554253435249500813\n;1821E0D4524544494D27442041525241D94449564953494F4E204208AF\n;1821F859205A4552CF494C4C4547414C204449524543D4545950450901\n;182210204D49534D415443C8535452494E4720544F4F204C4F4EC707F9\n;182228464F524D554C4120544F4F20434F4D504C45D843414E2754078F\n;18224020434F4E54494E55C5554E44454627442046554E4354494F0794\n;182258CE204552524F520020494E20000D0A4F4B0D0A000D0A42520554\n;18227045414B00BAE8E8E8E8BD0101C981D021A597D00ABD0201850C2A\n;18228896BD03018597DD0301D007A596DD0201F0078A186912AAD00A96\n;1822A0D86020F222857E847F38A5A7E5AC856FA8A5A8E5ADAAE8980F06\n;1822B8F023A5A738E56F85A7B003C6A838A5A5E56F85A5B008C6A60E4E\n;1822D09004B1A791A588D0F9B1A791A5C6A8C6A6CAD0F2600A69360F7A\n;1822E8B035856FBAE46F902E60C4819028D004C580902248A209980C79\n;18230048B5A4CA10FA202133A2F76895AEE830FA68A868C48190060CCD\n;182318D005C580B00160A24D461420BF2920382ABD692148297F2008A8\n;1823303A2AE86810F3205525A959A02220182AA487C8F003204E3C0972\n;1823484614A965A02220030020262486C784C820C000AAF0F3A2FF0AE1\n;182360868790062066244CA12620B828206624840C20F2249044A008DF\n;18237801B1AC8570A57A856FA5AD8572A5AC88F1AC18657A857A850D53\n;18239071A57B69FF857BE5ADAA38A5ACE57AA8B003E8C67218656F0E4F\n;1823A89003C67018B16F9171C8D0F9E670E672CAD0F2A51BF02FA50F35\n;1823C084A48585808481A57A85A7650C85A5A47B84A89001C884A60D66\n;1823D820A222A57EA47F857A847BA40C88B9170091AC8810F820370B67\n;1823F025A578A479856F847018A001B16FD0034C5123A004C8B16F0B6A\n;182408D0FBC898656FAAA000916FA5706900C8916F866F857090DA0D27\n;182420CA100520BF29A200205624C907F014C90DF020C92090F1C90A6C\n;1824387DB0EDC940F0E4C95FF0DDE047B005951BE8D0DCA907203A0E8A\n;1824502AD0D54CB929205A1EC90FD00848A51449FF85146860A6C70AE8\n;182468A0048410B500C920F03A850BC922F05824107030C93FD0040A17\n;182480A997D028C9309004C93C902084BEA000840C8886C7CAC8E80CF7\n;182498B500C920F0F938F98620F0F2C980D02F050CA4BEE8C899160E2E\n;1824B000B91600F03438E93AF004C949D002851038E954D0A6850B0B22\n;1824C8B500F0E0C50BF0DCC8991600E8D0F1A6C7E60CC8B98520100EDA\n;1824E0FAB98620D0B2B50010C0991800A91A85C760A578A679A0010C79\n;1824F885AC86ADB1ACF01FC8C8A51AD1AC9018F00388D009A519880E12\n;182510D1AC900CF00A88B1ACAA88B1ACB0D71860D0FDA900A891780DFA\n;182528C89178A5786902857AA5796900857B206B25A900D02CA5840AC2\n;182540A48585808481A57AA47B857C847D857E847F20CB26A266860C95\n;18255863688DFD01688DFE01A2FC9AA900858B85116018A57869FF0C63\n;18257085C7A57969FF85C8609006F004C9A5D0E920B82820F224200D33\n;182588C600F00CC9A5D09020C00020B828D0886868A519051AD0060B10\n;1825A0A9FF8519851AA001B1ACF03920DA2620BF29C8B1ACAAC8B10D59\n;1825B8ACC51AD004E419F002B022849620593CA920A496297F203A0AE9\n;1825D02AC8F011B1ACD010A8B1ACAAC8B1AC86AC85ADD0C14C48230EBD\n;1825E810E438E97FAA8496A0FFCAF008C8B9862010FA30F5C8B9860F3B\n;1826002030C7203A2AD0F5A980851120F228207422D0058A690FAA09CE\n;1826189A6868A90920E522205328189865C748A5C8690048A5874809EA\n;182630A58648A99E20902D20372C20342CA5B3097F25AF85AFA95109EA\n;182648A026856F84704CED2CA902A038201A3A20C600C9A3D0062009D8\n;182660C00020342C20A33A20E22CA59748A59648A9814820DA26A50A47\n;182678C7A4C8F006858A848BA000B1C7D03DA002B1C718F073C8B10E30\n;182690C78586C8B1C785879865C785C79002E6C820C00020AA264C0D58\n;1826A87426F02DE9809011C91DB0140AA8B9012048B90020484CC00A52\n;1826C0004CF228C93AF0D94C992D38A578E901A479B00188858E840C6E\n;1826D88F60A9012C401730F8A208A90318C903B00118D03DA5C7A40A7A\n;1826F0C8F00C858A848BA586A487858884896868A96CA022A200860D4F\n;1827081490034C3D234C4823D017A2D2A48BD0034C2123A58A85C709B9\n;18272084C8A588A4898586848760209535D0FAE8E0F2B004CA86150E02\n;182738604C4B30BA8612A93785F2A9FE8DF917A578A4798DF5178C0CEA\n;182750F617A57AA47B8DF7178CF8174C0018A6129AA970A0274C180B0A\n;1827682A4C4F414445440053415645440D0A0000000000000000000404\n;182780000000000000000000000000A578A4798DF5178CF617A9FF07D3\n;1827988DF917A9A6A027850184024C7318A2FF9AA948A0238501840B66\n;1827B002A969A02720182AAEED17ACEE178AD001EAEA867A847B4C0C09\n;1827C8EE23D0034C3725203E254CE927A90320E522A5C848A5C7480AAE\n;1827E0A58748A58648A98C4820C60020F2274C742620B8282056280A26\n;1827F8A587C51AB00B983865C7A6C89007E8B004A578A67920F6240D10\n;182810901EA5ACE90185C7A5ADE90085C860D0FDA9FF85962074220DB3\n;1828289AC98CF00BA2162CA25A4C21234C992D68688586688587680A8B\n;18284085C76885C8205328981865C785C79002E6C860A23A2CA2000B8E\n;182858860AA000840BA50BA60A850A860BB1C7F0E8C50BF0E4C8C90C5C\n;18287022D0F3F0E920482C20C600C988F005A9A120902DA5AED0050C7D\n;182888205628F0BB20C600B0034CF2274CAA2620953548C98CF0040AA6\n;1828A0C988D091C6B2D004684CAC2620C00020B828C92CF0EE68600CDF\n;1828B8A2008619861AB0F7E92F850AA51A856FC919B0D4A5190A260B2E\n;1828D06F0A266F65198519A56F651A851A0619261AA519650A85190796\n;1828E89002E61A20C0004CBE2820A92E85968497A9AC20902DA50F0ADF\n;18290048A50E4820482C682A203A2CD01868101220933A20C22FA00740\n;18291800A5B19196C8A5B29196604C483A68A002B1B1C5819017D00C73\n;1829300788B1B1C580900EA4B2C47B9008D00DA5B1C57AB007A5B10CF1\n;182948A4B24C6329A000B1B1207632A59DA49E85BC84BD207134A90BF5\n;182960AEA000859D849E20D234A000B19D9196C8B19D9196C8B19D0DC1\n;182978919660201B2A20C600F03CF058C99DF06CC9A0F068C92C180C8F\n;182990F04CC93BF07720482C240E30DE20693C208832A000B1B1180A05\n;1829A86516C517900320BF29201B2A20352AD0C5A000941BA21AA90908\n;1829C00D8516203A2AA90A203A2A8A48A615F008A900203A2ACAD008B0\n;1829D8FA861668AA60A516C518900620BF294C0D2A38E90EB0FC490AFE\n;1829F0FF6901D01308209235C929F0034C992D2890068AE51690050A3B\n;182A08AAE8CAD00620C0004C832920352AD0F2208832209D34AAA00AAA\n;182A2000E8CAF0B8B16F203A2AC8C90DD0F320CB294C222AA9202C0B62\n;182A38A93F2414301848C920900BA516C517D00320BF29E61668840908\n;182A500D20A01EA40D29FF60A512F0113004A0FFD004A58CA48D850AFC\n;182A688684874C992DA9B3A02B20182AA58AA48B85C784C86020A80BF4\n;182A8031A21CA000841CA94020BF2A604614C922D00B204E2DA93B08E2\n;182A9820902D201B2A20A831A92C851A20B02AA51BD012184CF72608A6\n;182AB020382A20352A4C2624A68EA48FA99885128690849120A92E09EA\n;182AC885968497A5C7A4C88519841AA690A49186C784C820C600D00E0E\n;182AE01B2412500B205A1E851BA21AA000D008307120382A20B02A0757\n;182AF886C784C820C000240E103124125009E886C7A900850AF00C0A1E\n;182B10850AC922F007A93A850AA92C18850BA5C7A4C869009001C80A4D\n;182B28208E3220DA352027294C3C2B206B3BA50F200F2920C600F00745\n;182B4007C92CF0034C592AA5C7A4C885908491A519A41A85C784C80C57\n;182B5820C600F02C208E2D4CC52A205328C8AAD012A22AC8B1C7F00B9E\n;182B7069C8B1C7858CC8B1C7C8858DB1C7AA204828E083D0DD4CFC0F91\n;182B882AA590A491A61210034CD526A000B190F007A9A2A02B4C180AC3\n;182BA02A603F45585452412049474E4F5245440D0A003F5245444F06D8\n;182BB82046524F4D2053544152540D0A00D004A000F00320A92E8507F7\n;182BD0968497207422F004A200F0699AE8E8E8E88AE8E8E8E8E8E8109D\n;182BE88671A001201A3ABABD090185B3A596A49720533620483AA00A51\n;182C000120D53ABA38FD0901F017BD0F018586BD10018587BD120108F6\n;182C1885C7BD110185C84C74268A6911AA9A20C600C92CD0F120C00B6E\n;182C300020CC2B20482C182438240E3003B00360B0FDA2A34C2123078D\n;182C48A6C7D002C6C8C6C7A20024488A48A90120E522202D2DA9000ABA\n;182C60859A20C60038E9AB9017C903B013C9012A4901459AC59A900AB7\n;182C7861859A20C0004C652CA69AD02CB07B69079077650ED0034C0A69\n;182C90343469FF856F0A656FA868D96820B06720372C4820CA2C680A47\n;182CA8A4981017AAF056D05F460E8A2AA6C7D002C6C8C6C7A01B850D10\n;182CC09AD0D7D96820B04890D9B96A2048B969204820DD2CA59A4C0CD0\n;182CD8532C4C992DA5B3BE6820A868856FE66F688570984820933A0BCE\n;182CF0A5B248A5B148A5B048A5AF48A5AE486C6F00A0FF68F023C90E03\n;182D0864F00320372C8498684A85136885B66885B76885B86885B90B1F\n;182D206885BA6885BB45B385BCA5AE60A900850E20C000B0034C6B0B26\n;182D383B20332FB067C92EF0F4C9A5F058C9A4F0E7C922D00FA5C70E5C\n;182D50A4C869009001C82088324CDA35C9A2D013A018D03B20C22F0B1A\n;182D68A5B249FFA8A5B149FF4C9531C99FD0034CF331C9AE90034C0DA5\n;182D80C52D208B2D20482CA9292CA9282CA92CA000D1C7D0034CC00A0A\n;182D9800A2104C2123A01568684CA42C20A92E85B184B2A60EF00109C8\n;182DB060A60F100DA000B1B1AAC8B1B1A88A4C95314C1A3A0A48AA0ADD\n;182DC820C000E0839020208B2D20482C208E2D20392C68AAA5B248097D\n;182DE0A5B1488A4820953568A88A484CF42D20822D68A8B9DE1F850BE8\n;182DF8A2B9DF1F85A320A1004C372CA0FF2CA000840C20C22FA5B10B90\n;182E10450C850AA5B2450C850B20743A20C22FA5B2450C250B450C0776\n;182E28A8A5B1450C250A450C4C9531203A2CB013A5BB097F25B78508E1\n;182E40B7A9B6A00020D33AAA4C7F2EA900850EC69A209D3485AE860B52\n;182E58AF84B0A5B9A4BA20A13486B984BAAA38E5AEF008A90190040D5A\n;182E70A6AEA9FF85B3A0FFE8C8CAD007A6B3300F18900CB1B9D1AF0F10\n;182E88F0EFA2FFB002A201E88A2A2513F002A9FF4CB43A208E2DAA0CD0\n;182EA020AE2E20C600D0F460A20020C600860D859220C60020332F0986\n;182EB8B0034C992DA200860E860F20C000900520332F900BAA20C008AA\n;182ED00090FB20332FB0F6C924D006A9FF850ED010C925D013A5110C2E\n;182EE8D0D0A980850F059285928A0980AA20C0008693380511E9280B4E\n;182F00D0034CD42FA9008511A57AA67BA00086AD85ACE47DD004C50BE6\n;182F187CF022A592D1ACD008A593C8D1ACF06C8818A5AC690790E10E24\n;182F30E8D0DCC9419005E95B38E9A5606848C9A7D00FBABD0201C90D56\n;182F482DD007A950A02F600000A57CA47D85AC84ADA57EA47F85A70BD1\n;182F6084A81869079001C885A584A620A222A5A5A4A6C8857C847D0C4A\n;182F78A000A59291ACC8A59391ACA900C891ACC891ACC891ACC8910F21\n;182F90ACC891ACA5AC186902A4AD9001C88594849560A50C0A69050BC1\n;182FA865ACA4AD9001C885A584A6609080000020C00020342CA5B30B26\n;182FC0300DA5AEC9909009A9B4A02F20D33AD07A4C133BA50D050F0A8C\n;182FD848A50E48A0009848A59348A5924820B82F688592688593680B4F\n;182FF0A8BABD020148BD010148A5B19D0201A5B29D0101C820C6000A42\n;183008C92CF0D2840C20882D68850E68850F297F850DA67CA57D860A67\n;183020AC85ADC57FD004E47EF039A000B1ACC8C592D006A593D1AC0E90\n;183038F016C8B1AC1865ACAAC8B1AC65AD90D7A26B2CA2354C21230CBC\n;183050A278A50DD0F720A32FA50CA004D1ACD0E74CEE3020A32F200C22\n;183068F222A900A885BFA205A59291AC1001CAC8A59391AC1002CA0C68\n;183080CA86BEA50CC8C8C891ACA20BA900240D500868186901AA680AF7\n;1830986900C891ACC88A91AC20503186BE85BFA46FC60CD0DC65A60DA2\n;1830B0B05D85A6A88A65A59003C8F05220F222857E847FA900E6BF0D91\n;1830C8A4BEF0058891A5D0FBC6A6C6BFD0F5E6A638A57EE5ACA00210C0\n;1830E091ACA57FC8E5AD91ACA50DD062C8B1AC850CA90085BE85BF0EEA\n;1830F8C868AA85B16885B2D1AC900ED006C88AD1AC90074C48304C0D56\n;1831101F23C8A5BF05BE18F00A2050318A65B1AA98A46F65B286BE0B8D\n;183128C60CD0CA85BFA205A5921001CAA5931002CACA8675A900200B7C\n;18314059318A65A585949865A68595A8A59460846FB1AC857588B10D41\n;183158AC8576A91085AAA200A0008A0AAA982AA8B0A406BE26BF900BA7\n;1831700B188A6575AA986576A8B093C6AAD0E360A50EF003209D340C62\n;18318820213338A580E57EA8A581E57FA200860E85AF84B0A2904C0C53\n;1831A0BC3AA416A900F0EDA687E8D0A2A2954C212320E03120A8310C97\n;1831B8208B2DA980851120A92E20372C20882DA9AC20902D48A595099B\n;1831D048A59448A5C848A5C7482045284C5032A99F20902D0980850AD9\n;1831E81120B02E859B849C4C372C20E031A59C48A59B4820822D200A60\n;183200372C68859B68859CA002A2E0B19BF09F8594AAC8B19B85950DAE\n;183218C8B194488810FAA495204C3AA5C848A5C748B19B85C7C8B10DA2\n;1832309B85C8A59548A5944820342C68859B68859C20C600F0034C0B1B\n;183248992D6885C76885C8A00068919B68C8919B68C8919B68C8910D6E\n;1832609B68C8919B6020372CA000206B3C6868A9FFA000F012A6B10B5C\n;183278A4B2869D849E20EF3286AF84B085AE60A222860A860B85BC0CC0\n;18329084BD85AF84B0A0FFC8B1BCF00CC50AF004C50BD0F3C922F00F84\n;1832A8011884AE9865BC85BEA6BD9001E886BFA5BDD00B982076320CF7\n;1832C0A6BCA4BD207F34A663E06FD005A2BF4C2123A5AE9500A5AF0CFA\n;1832D89501A5B09502A00086B184B288840E8664E8E8E8866360460CFC\n;1832F0104849FF386580A481B00188C47F9011D004C57E900B85800BF0\n;183308848185828483AA6860A24DA51030B8202133A980851068D00ACE\n;183320D0A684A58586808581A000849CA57EA67F85AC86ADA966A20DB8\n;18333800856F8670C563F00520C033F0F7A90785A0A57AA67B856F0C8D\n;1833508670E47DD004C57CF00520B633F0F385A586A6A90385A0A50DB4\n;183368A5A6A6E47FD007C57ED0034CFF33856F8670A000B16FAAC80D8E\n;183380B16F08C8B16F65A585A5C8B16F65A685A62810D38A30D0C80D8A\n;183398B16FA0000A6905656F856F9002E670A670E4A6D004C5A5F00C99\n;1833B0BA20C033F0F3B16F3035C8B16F1030C8B16FF02BC8B16FAA0DED\n;1833C8C8B16FC5819006D01EE480B01AC5AD9016D004E4AC9010860D95\n;1833E0AC85ADA56FA670859B869CA5A085A2A5A018656F856F90020D98\n;1833F8E670A670A00060A69CF0F7A5A229044AA885A2B19B65AC850E47\n;183410A7A5AD690085A8A580A68185A586A620A922A4A2C8A5A5910D61\n;1834289BAAE6A6A5A6C8919B4C2533A5B248A5B148202D2D20392C0B64\n;1834406885BC6885BDA000B1BC1871B19005A2B04C2123207632200A85\n;1834587134A59DA49E20A134208334A5BCA4BD20A13420C7324C620B17\n;1834702CA000B1BC48C8B1BCAAC8B1BCA868866F8470A8F00A48880DBC\n;183488B16F918298D0F86818658285829002E6836020392CA5B1A40CAF\n;1834A0B2856F847020D23408A000B16F48C8B16FAAC8B16FA868280C6E\n;1834B8D013C481D00FE480D00B4818658085809002E68168866F840C6E\n;1834D07060C465D00CC564D0088563E9038564A000602098358A480B6E\n;1834E8A901207E3268A00091AF68684CC732205635D19D989004B10B01\n;1835009DAA98488A48207E32A59DA49E20A13468A86818656F856F0AE7\n;1835189002E670982083344CC73220563518F19D49FF4CFD34A9FF0BBF\n;18353085B220C600C929F006208E2D209535205635CA8A4818A2000948\n;183548F19DB0B849FFC5B290B3A5B2B0AF20882D68A86885A268680E87\n;18356068AA68859D68859EA5A2489848A0008AF01D602079354CA40B98\n;18357831209A34A200860EA860207935F008A000B16FA84CA4314C09BD\n;1835904B3020C00020342C20BE2FA6B1D0F0A6B24CC600207935D00AE4\n;1835A8034CE336A6C7A4C886BE84BFA66F86C718656F8571A670860D9D\n;1835C0C89001E88672A000B17148A900917120C600206B3B68A0000AAF\n;1835D89171A6BEA4BF86C784C86020342C20EF35208E2D4C9535A50C41\n;1835F0B3309CA5AEC991B09620133BA5B1A4B28419851A6020EF350CA9\n;183608A000B119A84CA43120E3358AA00091196020E3358696A20009EB\n;18362020C600F00320E9358697A000B11945972596F0F860A999A00BCD\n;1836383D4C5336200439A5B349FF85B345BB85BCA5AE4C563620B70B10\n;18365037903C200439D0034C743AA6BD86A3A2B6A5B6A8F0CE38E50C8D\n;183668AEF024901284AEA4BB84B349FF6900A00084A3A2AED004A00D1E\n;1836800084BDC9F930C7A8A5BD560120D03724BC1057A0AEE0B6F00D6B\n;18369802A0B63849FF65A385BDB90400F50485B2B90300F50385B10BDF\n;1836B0B90200F50285B0B90100F50185AFB003206537A0009818A60A2E\n;1836C8AFD04AA6B086AFA6B186B0A6B286B1A6BD86B284BD6908C90F9C\n;1836E020D0E4A90085AE85B36065A385BDA5B265BA85B2A5B165B90EE1\n;1836F885B1A5B065B885B0A5AF65B785AF4C2237690106BD26B2260C97\n;183710B126B026AF10F238E5AEB0C749FF690185AE9040E6AEF0740DAC\n;183728A9009002A98046AF05AF85AFA9009002A98046B005B085B00AFC\n;183740A9009002A98046B105B185B1A9009002A98046B205B285B20B20\n;183758A9009002A98046BD05BD85BD60A5B349FF85B3A5AF49FF850D6B\n;183770AFA5B049FF85B0A5B149FF85B1A5B249FF85B2A5BD49FF851019\n;183788BDE6BDD00EE6B2D00AE6B1D006E6B0D002E6AF60A2454C210EA5\n;1837A023A272B40484BDB4039404B4029403B4019402A4B59401690A5D\n;1837B80830E8F0E6E908A8A5BDB03C48B5012980560115019501240AB2\n;1837D048A9009002A980560215029502A9009002A9805603150395083B\n;1837E803A9009002A98056041504950468084A2890020980C8D0C40903\n;18380018608100000000037F5E56CB7980139B0B6480763893168207B9\n;18381838AA3B20803504F334813504F334808000000080317217F80898\n;18383020A33AF00210034C4B30A5AEE97F48A98085AEA91CA038200A65\n;1838485336A921A038208739A902A038203C36A907A03820913EA908D8\n;18386026A03820533668200A3CA92BA038200439D0034C0339202F06D8\n;18387839A9008573857485758576A5BD209F38A5B2209F38A5B1200BAD\n;1838909F38A5B0209F38A5AF20A4384C073AD0034CA1374A0980A80A52\n;1838A8901918A57665BA8576A57565B98575A57465B88574A573650CCC\n;1838C0B78573A9009002A980467305738573A9009002A9804674050A6F\n;1838D8748574A9009002A980467505758575A9009002A9804676050A4D\n;1838F0768576A9009002A98046BD05BD85BD984AD0A460856F84700CBA\n;183908A004B16F85BA88B16F85B988B16F85B888B16F85BB45B3850D8C\n;183920BCA5BB098085B788B16F85B6A5AE60A5B6F01F1865AE90040D11\n;183938301D182C1014698085AED0034CE736A5BC85B360A5B349FF0B2F\n;183950300568684CE3364C9C3720843AAAF010186902B0F2A2008609FF\n;183968BC206336E6AEF0E760842000000020843AA971A039A200860A96\n;183980BC201A3A4C8A39200439F07620933AA90038E5AE85AE202F09B6\n;18399839E6AEF0BAA2FCA901A4B7C4AFD010A4B8C4B0D00AA4B9C41021\n;1839B0B1D004A4BAC4B2082A9009E89576F0321034A90128B00E060B14\n;1839C8BA26B926B826B7B0E630CE10E2A8A5BAE5B285BAA5B9E5B10FC4\n;1839E085B9A5B8E5B085B8A5B7E5AF85B7984CC739A940D0CE0A0A0F49\n;1839F80A0A0A0A85BD284C073AA2854C2123A57385AFA57485B0A50A5E\n;183A107585B1A57685B24CC336856F8470A004B16F85B288B16F850CB4\n;183A28B188B16F85B088B16F85B3098085AF88B16F85AE84BD60A20DC3\n;183A40A92CA2A4A000F004A696A49720933A866F8470A004A5B2910C1A\n;183A586F88A5B1916F88A5B0916F88A5B3097F25AF916F88A5AE910D7C\n;183A706F84BD60A5BB85B3A205B5B595ADCAD0F986BD6020933AA20E82\n;183A8806B5AD95B5CAD0F986BD60A5AEF0FB06BD90F7208D37D0F20FF0\n;183AA04C2437A5AEF009A5B32AA9FFB002A9016020A33A85AFA9000BA5\n;183AB885B0A288A5AF49FF2AA90085B285B186AE85BD85B34CBE360E33\n;183AD046B36085718472A000B171C8AAF0C4B17145B330C2E4AED00EBD\n;183AE821B1710980C5AFD019C8B171C5B0D012C8B171C5B1D00BC80EA7\n;183B00A97FC5BDB171E5B2F028A5B3900249FF4CA93AA5AEF04A380DF4\n;183B18E9A024B31009AAA9FF85B5206B378AA2AEC9F9100620B7370BF2\n;183B3084B560A8A5B3298046AF05AF85AF20D03784B560A5AEC9A00D1E\n;183B48B02020133B84BDA5B384B349802AA9A085AEA5B2850A4CBE0C08\n;183B603685AF85B085B185B2A860A000A20A94AACA10FB900FC92D0CBB\n;183B78D00486B4F004C92BD00520C000906FC92EF038C945D044200BD6\n;183B90C0009021C9A5F00EC92DF00AC9A4F012C92BF00ED011A9000C9B\n;183BA89002A98046AD05AD85AD20C000906624AD1018A90038E5AB0ACD\n;183BC04CD53BA9009002A98046AC05AC85AC24AC50AFA5AB38E5AA0C8D\n;183BD885ABF0121009207639E6ABD0F9F007205A39C6ABD0F9A5B40DDC\n;183BF03001604C053E4824AC1002E6AA205A396838E930200A3C4C083B\n;183C08823B4820843A6820B43AA5BB45B385BCA6AE4C5636A5ABC90B93\n;183C200A9009A96424AD30114C9C370A0A1865AB0A18A00071C73807C3\n;183C38E93085AB4CB23B9B3EBC1FFD9E6E6B27FD9E6E6B2800A9600C02\n;183C50A02220663CA587A68685AF86B0A2903820C13A20693C4C180A98\n;183C682AA001A92024B31002A92D99FF0085B384BEC8A930A6AED00BE6\n;183C80034C8C3DA900E080F002B009A949A03C206E38A9F785AAA90BAC\n;183C9844A03C20D33AF01E1012A93FA03C20D33AF002100E205A39091D\n;183CB0C6AAD0EE207639E6AAD0DC20353620133BA201A5AA18690A0BB3\n;183CC83009C90BB00669FFAAA90238E90285AB86AA8AF0021013A40B62\n;183CE0BEA92EC899FF008AF006A930C899FF0084BEA000A280A5B20E3D\n;183CF81879A13D85B2A5B179A03D85B1A5B0799F3D85B0A5AF799E0E1E\n;183D103D85AFE8B00410DE300230DA8A900449FF690A692FC8C8C80B65\n;183D28C88494A4BEC8AA297F99FF00C6AAD006A92EC899FF0084BE0E30\n;183D40A4948A49FF2980AAC024D0AAA4BEB9FF0088C930F0F8C92E0ECA\n;183D58F001C8A92BA6ABF02E1008A90038E5ABAAA92D990101A9450B3B\n;183D709900018AA22F38E8E90AB0FB693A9903018A990201A900990A20\n;183D880401F00899FF00A900990001A900A001608000000000FA0A07E3\n;183DA01F0000989680FFF0BDC0000186A0FFFFD8F0000003E8FFFF0E04\n;183DB8FF9C0000000AFFFFFFFF20843AA999A03D201A3AF070A5B60CDA\n;183DD0D0034CE536A29BA000204C3AA5BB100F20443BA99BA000200A04\n;183DE8D33AD00398A40A20763A9848203038A99BA000206E38203E09A3\n;183E003E684A900AA5AEF006A5B349FF85B3608138AA3B290771340AD4\n;183E18583E5674167EB31B772FEEE3857A1D841C2A7C6359580A7E09A5\n;183E3075FDE7C680317218108100000000A910A03E206E38A5BD690999\n;183E48509003209B3A85A320873AA5AEC9889003204C3920443BA5099F\n;183E600A186981F0F338E90148A205B5B6B4AE95AE94B6CA10F5A50D84\n;183E78A385BD203F3620053EA915A03E20A73EA90085BC682031390928\n;183E906085BE84BF20423AA9A4206E3820AB3EA9A4A0004C6E38850AE8\n;183EA8BE84BF203F3AB1BE85B4A4BEC898D002E6BF85BEA4BF206E0EAD\n;183EC038A5BEA4BF1869059001C885BE84BF205336A9A9A000C6B40C8E\n;183ED8D0E4609835447A6828B14620A33AAA3018A9D8A000201A3A0AD8\n;183EF08AF0E7A9DBA03E206E38A9DFA03E205336A6B2A5AF85B2860E47\n;183F08AFA90085B3A5AE85BDA98085AE20C336A2D8A0004C4C3AA90C8E\n;183F209BA03F20533620843AA9A0A03FA6BB207F3920843A20443B0956\n;183F38A90085BC203F36A9A5A03F203C36A5B348100D203536A5B3096D\n;183F503009A51349FF851320053EA9A5A03F20533668100320053E078F\n;183F68A9AAA03F4C913E20423AA900851320263FA29BA000201C3F08C6\n;183F80A9A4A000201A3AA90085B3A51320973FA99BA0004C87394809FF\n;183F984C583F81490FDAA283490FDAA27F000000000584E61A2D1B08CE\n;183FB0862807FBF88799688901872335DFE186A55DE72883490FDA0CAC\n;183FC8A2A6D3C1C8D4C8D5C4CECAA5B348100320053EA5AE48C9810E8B\n;183FE09007A902A038208739A903A04020913E68C9819007A99BA00AD9\n;183FF83F203C366810034C053E600B76B383BDD3791EF4A6F57B830AF5\n;184010FCB0107C0C1F67CA7CDE53CBC17D1464704C7DB7EA517A7D0C4C\n;1840286330887E7E9244993A7E4CCC91C77FAAAAAA1381000000000A3F\n;18404000E6C7D002E6C8AD60EAC93AB00AC920F0EF38E93038E9D00E83\n;18405860804FC75258A9DBA04120182AA2FF86879AA965A04085010BD3\n;184070840285048405A9C2A02F85068407A995A03185088409A94C09CE\n;1840888500850385A1A9488517A9388518A21CBD404095BFCAD0F80BFF\n;1840A08A85B585658515488514A90385A020BF29A2668663A9FBA00C2F\n;1840B84120182A20B02A86C784C820C000C941F094A8D021A961A00BF7\n;1840D0428519841AA000E619D002E61AA9929119D119D0150A91190A7F\n;1840E8D119D00EF0E920C60020B828A8F0034C992DA519A41A85840BF9\n;184100848585808481A907A04220182A20B02A86C784C820C000A80A7B\n;184118F01C20B828A51AD0E5A519C91090DF8517E90EB0FC49FFE90D67\n;1841300C1865178518A9C6A04120182A20B02A86C784C820C000A2098D\n;18414841A040C959F034C941F004C94ED0DFA24BA0308E54208C550C6C\n;18416020A2D3A03FC941F01AA24BA0308E4E208C4F208E52208C530AD4\n;184178208E50208C5120A21FA03F86788479A000989178E678D0020AF8\n;184190E679A578A47920F22220BF29A58438E578AAA585E57920590D27\n;1841A83CA916A04220182A202325A918A02A85048405A948A02385087E\n;1841C00184026C010057414E542053494E2D434F532D54414E2D4106E1\n;1841D8544E000D0A0C5752495454454E204259205745494C414E440702\n;1841F020262047415445530D0A004D454D4F52592053495A45005406C2\n;18420845524D494E414C205749445448002042595445532046524506AE\n;184220450D0A0D0A4D4F5320544543482036353032204241534943058F\n;1842382056312E310D0A434F505952494748542031393737204259061B\n;184250204D4943524F534F465420434F2E0D0A0008292520602AE5065C\n;084268E420662465AC04A403F9\n;0001700170")

}

*/
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
