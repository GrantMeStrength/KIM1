//
//  Memory.swift
//  VirtualKim
//
//  Created by John Kennedy on 1/8/21.
//
// Model the memory of the computers, including making memory read-only, loading some initial code, and wrapping addresses in a certain range (like the KIM-1 does)
//

import Foundation

struct Memory_Cell {
    var cell : UInt8
    var ROM : Bool
}

//var MODESELECT : Bool = false
private var MEMORY : [Memory_Cell] = []
private let MEMORY_MAX = 0xffff + 1

private var clock_divide_ratio = 1
private var clock_counter : Int = 0
private var clock_interrupt_active = false
private var clock_tick_counter = 0
private var clock_went_under_zero = false
private var prevous_clock_divide_ratio = 1

class memory_64Kb
{
    
    func MaskMemory(_ address : UInt16) -> UInt16
    {
        // Make memory loop around.. 2000 is the same as c000. New: Updated to 64K to try basic and other tools.
        // Not really 64Kb but KIM-1 accurate
        
     let add = address & 0xffff
       
        return add
    }
    
    func ReadAddress (address : UInt16) -> UInt8
    {
        
       
        return MEMORY[Int(MaskMemory(address))].cell
    }
    
    func WriteAddress  (address : UInt16, value : UInt8)
    {
        // Clock I/O
        
     
      //  if !MEMORY[Int(MaskMemory(address))].ROM
      //  {
            MEMORY[Int(MaskMemory(address))].cell = value
      //  }
//        else
//        {
//            print("Trying to store " + String(format: "%02X",value) + " into ROM address " + String(format: "%04X",address))
//        }
        
    }
    
    func RIOT_Timer_Click()
    {
        clock_tick_counter = clock_tick_counter + 1
        if clock_tick_counter < clock_divide_ratio { return }
        
        // clock ticker reached, so action is performed
        clock_tick_counter = 0
        clock_counter = clock_counter - 1
        
        
        if clock_counter < 0
        {
            // clock countdown reached
            clock_went_under_zero = true
            clock_divide_ratio = 1;
            MEMORY[Int(MaskMemory(0x1707))].cell = 0x80
            clock_counter = 0xff
            
        }

       
    }
    
    func InitMemory(SoftwareToLoad : String)
    {
        // Create RAM and Load any ROMS
        // For now, set all memory to be RAM reset to 0
        // This completely ignores the fact that the 6502 uses memory mapped IO!
        // So might need a flag for memory contents, read only, and IO
        // Or make sure the Read/Write routines can filter out addresses that are special
        
        
        print("Initializing memory..", terminator:"")
        
        MEMORY.reserveCapacity(MEMORY_MAX)
        MEMORY = [Memory_Cell](repeatElement(Memory_Cell(cell: 0, ROM: false), count: MEMORY_MAX))
        
       // LoadSoftware(name : SoftwareToLoad) // Any extra apps
        
        // Set the reset interrupt vectors to help the user
        
        // NMI - so SST/ST works
        MEMORY[0x17FA].cell = 0x00
        MEMORY[0x17FB].cell = 0x1C
        
        // RST
        MEMORY[0x17FC].cell = 0x22
        MEMORY[0x17FD].cell = 0x1C
        
        // IRQ - so BRK works
        MEMORY[0x17FE].cell = 0x00
        MEMORY[0x17FF].cell = 0x1C
        
        
        print("OK")
    }
    
    
//    func LoadSoftware(name : String)
//    {
//      
//            let code : [UInt8] = [0,0,0,0]
//            
//            for a in 0..<code.count { MEMORY[0x200 + a].cell = code[a] }
//            
//            print("Loading: " + name)
//            
//        
//    }
    
    
//    
//    func injectROM()
//    {
//        // 1024kb ROMs (two of them - first goes into 0x1c00, the second into 0x1800)
//        // Note: Entry address for ROMs is not their first byte in array as they
//        // include code for processing NMI and RST which does a PUSH etc etc
//        // so the stack will crash if you jump to 0x1C00 expecting anything fun - try 0x1c22 instead or  pc = (uint16_t)read6502(0xFFFC) | ((uint16_t)read6502(0xFFFD) << 8);
//        
//        let ROM_Part_1 : [UInt8]  = [0x85, 0xF3, 0x68, 0x85, 0xF1, 0x68, 0x85, 0xEF, 0x85, 0xFA, 0x68, 0x85,
//                                     0xF0, 0x85, 0xFB, 0x84, 0xF4, 0x86, 0xF5, 0xBA, 0x86, 0xF2, 0x20, 0x88,
//                                     0x1E, 0x4C, 0x4F, 0x1C, 0x6C, 0xFA, 0x17, 0x6C, 0xFE, 0x17, 0xA2, 0xFF,
//                                     0x9A, 0x86, 0xF2, 0x20, 0x88, 0x1E, 0xA9, 0xFF, 0x8D, 0xF3, 0x17, 0xA9,
//                                     0x01, 0x2C, 0x40, 0x17, 0xD0, 0x19, 0x30, 0xF9, 0xA9, 0xFC, 0x18, 0x69,
//                                     0x01, 0x90, 0x03, 0xEE, 0xF3, 0x17, 0xAC, 0x40, 0x17, 0x10, 0xF3, 0x8D,
//                                     0xF2, 0x17, 0xA2, 0x08, 0x20, 0x6A, 0x1E, 0x20, 0x8C, 0x1E, 0xA9, 0x01,
//                                     0x2C, 0x40, 0x17, 0xD0, 0x1E, 0x20, 0x2F, 0x1E, 0xA2, 0x0A, 0x20, 0x31,
//                                     0x1E, 0x4C, 0xAF, 0x1D, 0xA9, 0x00, 0x85, 0xF8, 0x85, 0xF9, 0x20, 0x5A,
//                                     0x1E, 0xC9, 0x01, 0xF0, 0x06, 0x20, 0xAC, 0x1F, 0x4C, 0xDB, 0x1D, 0x20,
//                                     0x19, 0x1F, 0xD0, 0xD3, 0xA9, 0x01, 0x2C, 0x40, 0x17, 0xF0, 0xCC, 0x20,
//                                     0x19, 0x1F, 0xF0, 0xF4, 0x20, 0x19, 0x1F, 0xF0, 0xEF, 0x20, 0x6A, 0x1F,
//                                     0xC9, 0x15, 0x10, 0xBB, 0xC9, 0x14, 0xF0, 0x44, 0xC9, 0x10, 0xF0, 0x2C,
//                                     0xC9, 0x11, 0xF0, 0x2C, 0xC9, 0x12, 0xF0, 0x2F, 0xC9, 0x13, 0xF0, 0x31,
//                                     0x0A, 0x0A, 0x0A, 0x0A, 0x85, 0xFC, 0xA2, 0x04, 0xA4, 0xFF, 0xD0, 0x0A,
//                                     0xB1, 0xFA, 0x06, 0xFC, 0x2A, 0x91, 0xFA, 0x4C, 0xC3, 0x1C, 0x0A, 0x26,
//                                     0xFA, 0x26, 0xFB, 0xCA, 0xD0, 0xEA, 0xF0, 0x08, 0xA9, 0x01, 0xD0, 0x02,
//                                     0xA9, 0x00, 0x85, 0xFF, 0x4C, 0x4F, 0x1C, 0x20, 0x63, 0x1F, 0x4C, 0x4F,
//                                     0x1C, 0x4C, 0xC8, 0x1D, 0xA5, 0xEF, 0x85, 0xFA, 0xA5, 0xF0, 0x85, 0xFB,
//                                     0x4C, 0x4F, 0x1C, 0x20, 0x5A, 0x1E, 0xC9, 0x3B, 0xD0, 0xF9, 0xA9, 0x00,
//                                     0x85, 0xF7, 0x85, 0xF6, 0x20, 0x9D, 0x1F, 0xAA, 0x20, 0x91, 0x1F, 0x20,
//                                     0x9D, 0x1F, 0x85, 0xFB, 0x20, 0x91, 0x1F, 0x20, 0x9D, 0x1F, 0x85, 0xFA,
//                                     0x20, 0x91, 0x1F, 0x8A, 0xF0, 0x0F, 0x20, 0x9D, 0x1F, 0x91, 0xFA, 0x20,
//                                     0x91, 0x1F, 0x20, 0x63, 0x1F, 0xCA, 0xD0, 0xF2, 0xE8, 0x20, 0x9D, 0x1F,
//                                     0xC5, 0xF6, 0xD0, 0x17, 0x20, 0x9D, 0x1F, 0xC5, 0xF7, 0xD0, 0x13, 0x8A,
//                                     0xD0, 0xB9, 0xA2, 0x0C, 0xA9, 0x27, 0x8D, 0x42, 0x17, 0x20, 0x31, 0x1E,
//                                     0x4C, 0x4F, 0x1C, 0x20, 0x9D, 0x1F, 0xA2, 0x11, 0xD0, 0xEE, 0xA9, 0x00,
//                                     0x85, 0xF8, 0x85, 0xF9, 0xA9, 0x00, 0x85, 0xF6, 0x85, 0xF7, 0x20, 0x2F,
//                                     0x1E, 0xA9, 0x3B, 0x20, 0xA0, 0x1E, 0xA5, 0xFA, 0xCD, 0xF7, 0x17, 0xA5,
//                                     0xFB, 0xED, 0xF8, 0x17, 0x90, 0x18, 0xA9, 0x00, 0x20, 0x3B, 0x1E, 0x20,
//                                     0xCC, 0x1F, 0x20, 0x1E, 0x1E, 0xA5, 0xF6, 0x20, 0x3B, 0x1E, 0xA5, 0xF7,
//                                     0x20, 0x3B, 0x1E, 0x4C, 0x64, 0x1C, 0xA9, 0x18, 0xAA, 0x20, 0x3B, 0x1E,
//                                     0x20, 0x91, 0x1F, 0x20, 0x1E, 0x1E, 0xA0, 0x00, 0xB1, 0xFA, 0x20, 0x3B,
//                                     0x1E, 0x20, 0x91, 0x1F, 0x20, 0x63, 0x1F, 0xCA, 0xD0, 0xF0, 0xA5, 0xF6,
//                                     0x20, 0x3B, 0x1E, 0xA5, 0xF7, 0x20, 0x3B, 0x1E, 0xE6, 0xF8, 0xD0, 0x02,
//                                     0xE6, 0xF9, 0x4C, 0x48, 0x1D, 0x20, 0xCC, 0x1F, 0x20, 0x2F, 0x1E, 0x20,
//                                     0x1E, 0x1E, 0x20, 0x9E, 0x1E, 0xA0, 0x00, 0xB1, 0xFA, 0x20, 0x3B, 0x1E,
//                                     0x20, 0x9E, 0x1E, 0x4C, 0x64, 0x1C, 0x20, 0x63, 0x1F, 0x4C, 0xAC, 0x1D,
//                                     0xA6, 0xF2, 0x9A, 0xA5, 0xFB, 0x48, 0xA5, 0xFA, 0x48, 0xA5, 0xF1, 0x48,
//                                     0xA6, 0xF5, 0xA4, 0xF4, 0xA5, 0xF3, 0x40, 0xC9, 0x20, 0xF0, 0xCA, 0xC9,
//                                     0x7F, 0xF0, 0x1B, 0xC9, 0x0D, 0xF0, 0xDB, 0xC9, 0x0A, 0xF0, 0x1C, 0xC9,
//                                     0x2E, 0xF0, 0x26, 0xC9, 0x47, 0xF0, 0xD5, 0xC9, 0x51, 0xF0, 0x0A, 0xC9,
//                                     0x4C, 0xF0, 0x09, 0x4C, 0x6A, 0x1C, 0x4C, 0x4F, 0x1C, 0x4C, 0x42, 0x1D,
//                                     0x4C, 0xE7, 0x1C, 0x38, 0xA5, 0xFA, 0xE9, 0x01, 0x85, 0xFA, 0xB0, 0x02,
//                                     0xC6, 0xFB, 0x4C, 0xAC, 0x1D, 0xA0, 0x00, 0xA5, 0xF8, 0x91, 0xFA, 0x4C,
//                                     0xC2, 0x1D, 0xA5, 0xFB, 0x20, 0x3B, 0x1E, 0x20, 0x91, 0x1F, 0xA5, 0xFA,
//                                     0x20, 0x3B, 0x1E, 0x20, 0x91, 0x1F, 0x60, 0xA2, 0x07, 0xBD, 0xD5, 0x1F,
//                                     0x20, 0xA0, 0x1E, 0xCA, 0x10, 0xF7, 0x60, 0x85, 0xFC, 0x4A, 0x4A, 0x4A,
//                                     0x4A, 0x20, 0x4C, 0x1E, 0xA5, 0xFC, 0x20, 0x4C, 0x1E, 0xA5, 0xFC, 0x60,
//                                     0x29, 0x0F, 0xC9, 0x0A, 0x18, 0x30, 0x02, 0x69, 0x07, 0x69, 0x30, 0x4C,
//                                     0xA0, 0x1E, 0x86, 0xFD, 0xA2, 0x08, 0xA9, 0x01, 0x2C, 0x40, 0x17, 0xD0,
//                                     0x22, 0x30, 0xF9, 0x20, 0xD4, 0x1E, 0x20, 0xEB, 0x1E, 0xAD, 0x40, 0x17,
//                                     0x29, 0x80, 0x46, 0xFE, 0x05, 0xFE, 0x85, 0xFE, 0x20, 0xD4, 0x1E, 0xCA,
//                                     0xD0, 0xEF, 0x20, 0xEB, 0x1E, 0xA6, 0xFD, 0xA5, 0xFE, 0x2A, 0x4A, 0x60,
//                                     0xA2, 0x01, 0x86, 0xFF, 0xA2, 0x00, 0x8E, 0x41, 0x17, 0xA2, 0x3F, 0x8E,
//                                     0x43, 0x17, 0xA2, 0x07, 0x8E, 0x42, 0x17, 0xD8, 0x78, 0x60, 0xA9, 0x20,
//                                     0x85, 0xFE, 0x86, 0xFD, 0x20, 0xD4, 0x1E, 0xAD, 0x42, 0x17, 0x29, 0xFE,
//                                     0x8D, 0x42, 0x17, 0x20, 0xD4, 0x1E, 0xA2, 0x08, 0xAD, 0x42, 0x17, 0x29,
//                                     0xFE, 0x46, 0xFE, 0x69, 0x00, 0x8D, 0x42, 0x17, 0x20, 0xD4, 0x1E, 0xCA,
//                                     0xD0, 0xEE, 0xAD, 0x42, 0x17, 0x09, 0x01, 0x8D, 0x42, 0x17, 0x20, 0xD4,
//                                     0x1E, 0xA6, 0xFD, 0x60, 0xAD, 0xF3, 0x17, 0x8D, 0xF4, 0x17, 0xAD, 0xF2,
//                                     0x17, 0x38, 0xE9, 0x01, 0xB0, 0x03, 0xCE, 0xF4, 0x17, 0xAC, 0xF4, 0x17,
//                                     0x10, 0xF3, 0x60, 0xAD, 0xF3, 0x17, 0x8D, 0xF4, 0x17, 0xAD, 0xF2, 0x17,
//                                     0x4A, 0x4E, 0xF4, 0x17, 0x90, 0xE3, 0x09, 0x80, 0xB0, 0xE0, 0xA0, 0x03,
//                                     0xA2, 0x01, 0xA9, 0xFF, 0x8E, 0x42, 0x17, 0xE8, 0xE8, 0x2D, 0x40, 0x17,
//                                     0x88, 0xD0, 0xF5, 0xA0, 0x07, 0x8C, 0x42, 0x17, 0x09, 0x80, 0x49, 0xFF,
//                                     0x60, 0xA0, 0x00, 0xB1, 0xFA, 0x85, 0xF9, 0xA9, 0x7F, 0x8D, 0x41, 0x17,
//                                     0xA2, 0x09, 0xA0, 0x03, 0xB9, 0xF8, 0x00, 0x4A, 0x4A, 0x4A, 0x4A, 0x20,
//                                     0x48, 0x1F, 0xB9, 0xF8, 0x00, 0x29, 0x0F, 0x20, 0x48, 0x1F, 0x88, 0xD0,
//                                     0xEB, 0x8E, 0x42, 0x17, 0xA9, 0x00, 0x8D, 0x41, 0x17, 0x4C, 0xFE, 0x1E,
//                                     0x84, 0xFC, 0xA8, 0xB9, 0xE7, 0x1F, 0xA0, 0x00, 0x8C, 0x40, 0x17, 0x8E,
//                                     0x42, 0x17, 0x8D, 0x40, 0x17, 0xA0, 0x7F, 0x88, 0xD0, 0xFD, 0xE8, 0xE8,
//                                     0xA4, 0xFC, 0x60, 0xE6, 0xFA, 0xD0, 0x02, 0xE6, 0xFB, 0x60, 0xA2, 0x21,
//                                     0xA0, 0x01, 0x20, 0x02, 0x1F, 0xD0, 0x07, 0xE0, 0x27, 0xD0, 0xF5, 0xA9,
//                                     0x15, 0x60, 0xA0, 0xFF, 0x0A, 0xB0, 0x03, 0xC8, 0x10, 0xFA, 0x8A, 0x29,
//                                     0x0F, 0x4A, 0xAA, 0x98, 0x10, 0x03, 0x18, 0x69, 0x07, 0xCA, 0xD0, 0xFA,
//                                     0x60, 0x18, 0x65, 0xF7, 0x85, 0xF7, 0xA5, 0xF6, 0x69, 0x00, 0x85, 0xF6,
//                                     0x60, 0x20, 0x5A, 0x1E, 0x20, 0xAC, 0x1F, 0x20, 0x5A, 0x1E, 0x20, 0xAC,
//                                     0x1F, 0xA5, 0xF8, 0x60, 0xC9, 0x30, 0x30, 0x1B, 0xC9, 0x47, 0x10, 0x17,
//                                     0xC9, 0x40, 0x30, 0x03, 0x18, 0x69, 0x09, 0x2A, 0x2A, 0x2A, 0x2A, 0xA0,
//                                     0x04, 0x2A, 0x26, 0xF8, 0x26, 0xF9, 0x88, 0xD0, 0xF8, 0xA9, 0x00, 0x60,
//                                     0xA5, 0xF8, 0x85, 0xFA, 0xA5, 0xF9, 0x85, 0xFB, 0x60, 0x00, 0x00, 0x00,
//                                     0x00, 0x00, 0x00, 0x0A, 0x0D, 0x4D, 0x49, 0x4B, 0x20, 0x13, 0x52, 0x52,
//                                     0x45, 0x20, 0x13, 0xBF, 0x86, 0xDB, 0xCF, 0xE6, 0xED, 0xFD, 0x87, 0xFF,
//                                     0xEF, 0xF7, 0xFC, 0xB9, 0xDE, 0xF9, 0xF1, 0xFF, 0xFF, 0xFF, 0x1C, 0x1C,
//                                     0x22, 0x1C, 0x1F, 0x1C]
//        
//        
//        let ROM_Part_2 : [UInt8]  = [ 0xA9, 0xAD, 0x8D, 0xEC, 0x17, 0x20, 0x32, 0x19, 0xA9, 0x27, 0x8D, 0x42,
//                                      0x17, 0xA9, 0xBF, 0x8D, 0x43, 0x17, 0xA2, 0x64, 0xA9, 0x16, 0x20, 0x7A,
//                                      0x19, 0xCA, 0xD0, 0xF8, 0xA9, 0x2A, 0x20, 0x7A, 0x19, 0xAD, 0xF9, 0x17,
//                                      0x20, 0x61, 0x19, 0xAD, 0xF5, 0x17, 0x20, 0x5E, 0x19, 0xAD, 0xF6, 0x17,
//                                      0x20, 0x5E, 0x19, 0xAD, 0xED, 0x17, 0xCD, 0xF7, 0x17, 0xAD, 0xEE, 0x17,
//                                      0xED, 0xF8, 0x17, 0x90, 0x24, 0xA9, 0x2F, 0x20, 0x7A, 0x19, 0xAD, 0xE7,
//                                      0x17, 0x20, 0x61, 0x19, 0xAD, 0xE8, 0x17, 0x20, 0x61, 0x19, 0xA2, 0x02,
//                                      0xA9, 0x04, 0x20, 0x7A, 0x19, 0xCA, 0xD0, 0xF8, 0xA9, 0x00, 0x85, 0xFA,
//                                      0x85, 0xFB, 0x4C, 0x4F, 0x1C, 0x20, 0xEC, 0x17, 0x20, 0x5E, 0x19, 0x20,
//                                      0xEA, 0x19, 0x4C, 0x33, 0x18, 0x0F, 0x19, 0xA9, 0x8D, 0x8D, 0xEC, 0x17,
//                                      0x20, 0x32, 0x19, 0xA9, 0x4C, 0x8D, 0xEF, 0x17, 0xAD, 0x71, 0x18, 0x8D,
//                                      0xF0, 0x17, 0xAD, 0x72, 0x18, 0x8D, 0xF1, 0x17, 0xA9, 0x07, 0x8D, 0x42,
//                                      0x17, 0xA9, 0xFF, 0x8D, 0xE9, 0x17, 0x20, 0x41, 0x1A, 0x4E, 0xE9, 0x17,
//                                      0x0D, 0xE9, 0x17, 0x8D, 0xE9, 0x17, 0xAD, 0xE9, 0x17, 0xC9, 0x16, 0xD0,
//                                      0xED, 0xA2, 0x0A, 0x20, 0x24, 0x1A, 0xC9, 0x16, 0xD0, 0xDF, 0xCA, 0xD0,
//                                      0xF6, 0x20, 0x24, 0x1A, 0xC9, 0x2A, 0xF0, 0x06, 0xC9, 0x16, 0xD0, 0xD1,
//                                      0xF0, 0xF3, 0x20, 0xF3, 0x19, 0xCD, 0xF9, 0x17, 0xF0, 0x0D, 0xAD, 0xF9,
//                                      0x17, 0xC9, 0x00, 0xF0, 0x06, 0xC9, 0xFF, 0xF0, 0x17, 0xD0, 0x9C, 0x20,
//                                      0xF3, 0x19, 0x20, 0x4C, 0x19, 0x8D, 0xED, 0x17, 0x20, 0xF3, 0x19, 0x20,
//                                      0x4C, 0x19, 0x8D, 0xEE, 0x17, 0x4C, 0xF8, 0x18, 0x20, 0xF3, 0x19, 0x20,
//                                      0x4C, 0x19, 0x20, 0xF3, 0x19, 0x20, 0x4C, 0x19, 0xA2, 0x02, 0x20, 0x24,
//                                      0x1A, 0xC9, 0x2F, 0xF0, 0x14, 0x20, 0x00, 0x1A, 0xD0, 0x23, 0xCA, 0xD0,
//                                      0xF1, 0x20, 0x4C, 0x19, 0x4C, 0xEC, 0x17, 0x20, 0xEA, 0x19, 0x4C, 0xF8,
//                                      0x18, 0x20, 0xF3, 0x19, 0xCD, 0xE7, 0x17, 0xD0, 0x0C, 0x20, 0xF3, 0x19,
//                                      0xCD, 0xE8, 0x17, 0xD0, 0x04, 0xA9, 0x00, 0xF0, 0x02, 0xA9, 0xFF, 0x85,
//                                      0xFA, 0x85, 0xFB, 0x4C, 0x4F, 0x1C, 0xAD, 0xF5, 0x17, 0x8D, 0xED, 0x17,
//                                      0xAD, 0xF6, 0x17, 0x8D, 0xEE, 0x17, 0xA9, 0x60, 0x8D, 0xEF, 0x17, 0xA9,
//                                      0x00, 0x8D, 0xE7, 0x17, 0x8D, 0xE8, 0x17, 0x60, 0xA8, 0x18, 0x6D, 0xE7,
//                                      0x17, 0x8D, 0xE7, 0x17, 0xAD, 0xE8, 0x17, 0x69, 0x00, 0x8D, 0xE8, 0x17,
//                                      0x98, 0x60, 0x20, 0x4C, 0x19, 0xA8, 0x4A, 0x4A, 0x4A, 0x4A, 0x20, 0x6F,
//                                      0x19, 0x98, 0x20, 0x6F, 0x19, 0x98, 0x60, 0x29, 0x0F, 0xC9, 0x0A, 0x18,
//                                      0x30, 0x02, 0x69, 0x07, 0x69, 0x30, 0x8E, 0xE9, 0x17, 0x8C, 0xEA, 0x17,
//                                      0xA0, 0x08, 0x20, 0x9E, 0x19, 0x4A, 0xB0, 0x06, 0x20, 0x9E, 0x19, 0x4C,
//                                      0x91, 0x19, 0x20, 0xC4, 0x19, 0x20, 0xC4, 0x19, 0x88, 0xD0, 0xEB, 0xAE,
//                                      0xE9, 0x17, 0xAC, 0xEA, 0x17, 0x60, 0xA2, 0x09, 0x48, 0x2C, 0x47, 0x17,
//                                      0x10, 0xFB, 0xA9, 0x7E, 0x8D, 0x44, 0x17, 0xA9, 0xA7, 0x8D, 0x42, 0x17,
//                                      0x2C, 0x47, 0x17, 0x10, 0xFB, 0xA9, 0x7E, 0x8D, 0x44, 0x17, 0xA9, 0x27,
//                                      0x8D, 0x42, 0x17, 0xCA, 0xD0, 0xDF, 0x68, 0x60, 0xA2, 0x06, 0x48, 0x2C,
//                                      0x47, 0x17, 0x10, 0xFB, 0xA9, 0xC3, 0x8D, 0x44, 0x17, 0xA9, 0xA7, 0x8D,
//                                      0x42, 0x17, 0x2C, 0x47, 0x17, 0x10, 0xFB, 0xA9, 0xC3, 0x8D, 0x44, 0x17,
//                                      0xA9, 0x27, 0x8D, 0x42, 0x17, 0xCA, 0xD0, 0xDF, 0x68, 0x60, 0xEE, 0xED,
//                                      0x17, 0xD0, 0x03, 0xEE, 0xEE, 0x17, 0x60, 0x20, 0x24, 0x1A, 0x20, 0x00,
//                                      0x1A, 0x20, 0x24, 0x1A, 0x20, 0x00, 0x1A, 0x60, 0xC9, 0x30, 0x30, 0x1E,
//                                      0xC9, 0x47, 0x10, 0x1A, 0xC9, 0x40, 0x30, 0x03, 0x18, 0x69, 0x09, 0x2A,
//                                      0x2A, 0x2A, 0x2A, 0xA0, 0x04, 0x2A, 0x2E, 0xE9, 0x17, 0x88, 0xD0, 0xF9,
//                                      0xAD, 0xE9, 0x17, 0xA0, 0x00, 0x60, 0xC8, 0x60, 0x8E, 0xEB, 0x17, 0xA2,
//                                      0x08, 0x20, 0x41, 0x1A, 0x4E, 0xEA, 0x17, 0x0D, 0xEA, 0x17, 0x8D, 0xEA,
//                                      0x17, 0xCA, 0xD0, 0xF1, 0xAD, 0xEA, 0x17, 0x2A, 0x4A, 0xAE, 0xEB, 0x17,
//                                      0x60, 0x2C, 0x42, 0x17, 0x10, 0xFB, 0xAD, 0x46, 0x17, 0xA0, 0xFF, 0x8C,
//                                      0x46, 0x17, 0xA0, 0x14, 0x88, 0xD0, 0xFD, 0x2C, 0x42, 0x17, 0x30, 0xFB,
//                                      0x38, 0xED, 0x46, 0x17, 0xA0, 0xFF, 0x8C, 0x46, 0x17, 0xA0, 0x07, 0x88,
//                                      0xD0, 0xFD, 0x49, 0xFF, 0x29, 0x80, 0x60, 0xA9, 0x27, 0x8D, 0x42, 0x17,
//                                      0xA9, 0xBF, 0x8D, 0x43, 0x17, 0x2C, 0x47, 0x17, 0x10, 0xFB, 0xA9, 0x9A,
//                                      0x8D, 0x44, 0x17, 0xA9, 0xA7, 0x8D, 0x42, 0x17, 0x2C, 0x47, 0x17, 0x10,
//                                      0xFB, 0xA9, 0x9A, 0x8D, 0x44, 0x17, 0xA9, 0x27, 0x8D, 0x42, 0x17, 0x4C,
//                                      0x75, 0x1A, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
//                                      0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x6B, 0x1A,
//                                      0x6B, 0x1A, 0x6B, 0x1A]
//        
//        
//        let ROM1_Start = 0x1C00
//        
//        for a in 0..<ROM_Part_1.count
//        {
//            MEMORY[ROM1_Start + a].cell = ROM_Part_1[a]
//            MEMORY[ROM1_Start + a].ROM = true
//        }
//        
//        let ROM2_Start = 0x1800
//        
//        for a in 0..<ROM_Part_2.count
//        {
//            MEMORY[ROM2_Start + a].cell = ROM_Part_2[a]
//            MEMORY[ROM2_Start + a].ROM = true
//        }
//        
//        
//    }
//    
    
}
