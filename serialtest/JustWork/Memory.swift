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
        
        // Some KIM-1 specifics
        
        // Cheat.. this is a RIOT timer, but here being used as a random number generator to make some apps work.
        // It's mapped to 0x17xx where xx is any number with bit 0 = 0, bit 2 = 1
        
        let hAddr = address >> 8
        let lAddr = address & 0x00ff
        
        if (hAddr == 0x17) &&
            (lAddr & 1 == 0 && lAddr & 4 == 4)
        {
           return UInt8.random(in: 0..<255)
            
        }
       
        if address == 0x1706 {
            
            clock_interrupt_active = false
            
            if clock_went_under_zero
            {
                clock_divide_ratio = prevous_clock_divide_ratio
            }
                return UInt8(clock_counter)
        }
        
        if address == 0x170E {
            
            clock_interrupt_active = true
            
            if clock_went_under_zero
            {
                clock_divide_ratio = prevous_clock_divide_ratio
            }
                return UInt8(clock_counter)
        }
        
         
        if address == 0x1707 {
            
            if clock_went_under_zero
            {
                return 0x80
            }
            else
            {
                return 0x00
            }
        }
                    
        return MEMORY[Int(MaskMemory(address))].cell
    }
    
    func WriteAddress  (address : UInt16, value : UInt8)
    {
        // Clock I/O
        
      
        
        if address == 0x1704 { clock_counter = Int(value); clock_divide_ratio = 1; prevous_clock_divide_ratio = 1; clock_interrupt_active = false;  clock_went_under_zero = false; return }
        if address == 0x1705 { clock_counter = Int(value); clock_divide_ratio = 8; prevous_clock_divide_ratio = 8; clock_interrupt_active = false; clock_went_under_zero = false;return }
        if address == 0x1706 { clock_counter = Int(value); clock_divide_ratio = 64; prevous_clock_divide_ratio = 64; clock_interrupt_active = false; clock_went_under_zero = false;return }
        if address == 0x1707 { clock_counter = Int(value); clock_divide_ratio = 1024; prevous_clock_divide_ratio = 1024; clock_interrupt_active = false; clock_went_under_zero = false;return }
        if address == 0x170C { clock_counter = Int(value); clock_divide_ratio = 1; prevous_clock_divide_ratio = 1; clock_interrupt_active = true; clock_went_under_zero = false;return }
        if address == 0x170D { clock_counter = Int(value); clock_divide_ratio = 8; prevous_clock_divide_ratio = 8; clock_interrupt_active = true; clock_went_under_zero = false; return }
        if address == 0x170E { clock_counter = Int(value); clock_divide_ratio = 64; prevous_clock_divide_ratio = 64; clock_interrupt_active = true;  clock_went_under_zero = false;return}
        if address == 0x170F { clock_counter = Int(value); clock_divide_ratio = 1024; prevous_clock_divide_ratio = 1024; clock_interrupt_active = true; clock_went_under_zero = false; return}
        
        if !MEMORY[Int(MaskMemory(address))].ROM
        {
            MEMORY[Int(MaskMemory(address))].cell = value
        }
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
    
    
    
    
}
