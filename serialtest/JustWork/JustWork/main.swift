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
private let TEST_SUITE = true
private let KIM_TEST_SUITE = false      // Run the tests side by side on the KIM-1

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
        
        
        // The Test Suite - Run on virtual 6502 only
        
        if TEST_SUITE
        {
            print("Poke test suite")
            LoadTest()
            
            PROGRAM_COUNTER = 0x16fb // 0x0400
            var OLD_PROGRAM_COUNTER = PROGRAM_COUNTER
            
            while HIT_BRK == false  {
                
                if KIM_TEST_SUITE
                {
                if (JIT)
                {
                    Poke(address:PROGRAM_COUNTER, value: MOS6502.Read(address: PROGRAM_COUNTER))
                    Poke(address:PROGRAM_COUNTER+1, value: MOS6502.Read(address: PROGRAM_COUNTER+1))
                    Poke(address:PROGRAM_COUNTER+1, value: MOS6502.Read(address: PROGRAM_COUNTER+1))
                    
                }}
                
                
                
                print()
                print("Program counter: ",String(format: "%04X   ", PROGRAM_COUNTER), terminator: "")
                
                if KIM_TEST_SUITE
                {
                RunCode(address: PROGRAM_COUNTER) ; GetStatus() ; PrintStatus()
                }
                    PROGRAM_COUNTER = RunCodeVirtual(address: PROGRAM_COUNTER)
                 
                if KIM_TEST_SUITE
                {
                _ = DiffStatus()
                }
                else
                {
                print("v"+vResult)
                }
                if OLD_PROGRAM_COUNTER == PROGRAM_COUNTER
                {
                    print(String(format: "BUG    %04X   ", PROGRAM_COUNTER))
                    HIT_BRK = true
                }
                
              
                
                OLD_PROGRAM_COUNTER = PROGRAM_COUNTER
            }
            
            
        }
        
        print()
        print("--------------------------------------------------------")
        print()
        
        
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
    aResult = "A: " + String(format: "%02X",A_REGISTER) + "  X: " + String(format: "%02X",X_REGISTER) + "  Y: " + String(format: "%02X",Y_REGISTER) + "  Flags: " + StatusFlagToString(reg: STATUS_REGISTER) + " PC: " + String(format: "%04X",PC_REGISTER) + " SP: " + String(format: "%02X",SP_REGISTER) + "  Memory: " + String(format: "%02X",Peek(address: 0x0206)) + "  " + String(format: "%02X",Peek(address: 0x032))
        
        
        
      
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
    
    vResult =  "A: " + String(format: "%02X",MOS6502.getA()) + "  X: " + String(format: "%02X",MOS6502.getX()) + "  Y: " + String(format: "%02X",MOS6502.getY()) + "  Flags: " + StatusFlagToString(reg: MOS6502.GetStatusRegister()) + " PC: " + String(format: "%04X",opcode.address) + " SP: " + String(format: "%02X",opcode.stack) + "  Memory: " + String(format: "%02X",MOS6502.Read(address: 0x026)) + "  " + String(format: "%02X",MOS6502.Read(address: 0x032))
    
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
            
            print(address,pairD);

                 }
    }
    print("")
    print("")
}


func LoadTest()
{
    print("Loading test suite")
    let filepath = "/Volumes/Promise Disk/Retro computers/KIM1/serialtest/JustWork/JustWork/test.bin"
   
    let bData = try! Data(contentsOf: URL(fileURLWithPath: filepath))
  
    for i in Range(0...bData.count-1)
    {
        MOS6502.Write(address: UInt16(i + 10), byte: bData[i])
    }

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
