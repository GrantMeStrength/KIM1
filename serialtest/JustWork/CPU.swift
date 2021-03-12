//
//  CPU.swift
//  VirtualKim
//
//  Created by John Kennedy on 1/8/21.
//
// 6502 implementation with as few KIM-1 or iOS specific features as possible
//
// prn() function gathers debug information for optional output.
//
// Note: This 6502 not take the varying length of time of each opcode takes to execute into account.
// It should use a lookup table for each instruction, get the cycle count, and do a NOP or two (or 8)
// if required. However, it's unlikely this will ever be necessary.
//

// Debug phase 1.0
// ADC, SBC, ROR
// Addressing modes for ADC, ASC with larger wrapping numbers and special 0x80 case
// CMP seems ok
// BIT Fixed

import Foundation


// Registers and flags
private var PC : UInt16 = 0x1c22
private var SP : UInt8 = 0xfd
private var A : UInt8 = 0
private var X : UInt8 = 0
private var Y : UInt8 = 0
private var CARRY_FLAG : Bool = false
private var ZERO_FLAG : Bool = false
private var OVERFLOW_FLAG : Bool = false
private var INTERRUPT_DISABLE : Bool = false
private var DECIMAL_MODE : Bool = false
private var NEGATIVE_FLAG : Bool = false
private var BREAK_FLAG : Bool = false
private var RUNTIME_DEBUG_MESSAGES : Bool = false

private var kim_keyActive : Bool = false           // Used when providing KIM-1 keyboard support
private var kim_keyNumber : UInt8 = 0xff

private var memory = memory_64Kb()                  // Implemention of memory map, including RAM and ROM

private var dataToDisplay = false                   // Used by the SwiftUI wrapper
private var running = false                         // to know if we're running and if something needs displayed on the "LEDs"

private var statusmessage : String = "-"        // Debug information is built up per instruction in this string

var breakpoint = false

private var texttodisplay : String = ""


class CPU {
    
    //    Addressing modes explained: http://www.emulator101.com/6502-addressing-modes.html
    
    //    Interrupt vectors on the KIM-1 are mapped slightly differently than the 6502
    //    by the memory addressing hardware, as there isn't anything at 0xFFXX as there
    //    might be in an idealistic 6502 system.
    //    Quote: In the KIM-1 system, three address bits (AB13, AB14, ABl5) are not
    //    decoded at all.  Therefore, when the 6502 array generates a fetch from
    //    FFFC and FFFD in response to a RST input, these addresses will be read
    //    as 1FFC and 1FFD and the reset vector will be fetched from these locations.
    //    You now see that all interrupt vectors will be fetched from the top 6
    //    locations of the lowest 8K block of memory which is the only memory block
    //    decoded for the unexpanded KIM-1 system.
    
    // To make SST work, needs to know not to SST the ROM Monitor somehow or that would
    // be recursive and the world might end.
    
   
    
    func RESET()
    {
        // This is the 6502 Reset signal - RST
        // It's "turning it off and on again"
        A = 0
        X = 0
        Y = 0
        SP = 0xFD
        PC = getAddress(0x17FC) //PC = getAddress(0xFFFC)
        INTERRUPT_DISABLE = true
    }
    
    func IRQ()
    {
        // This is the 6502 Interrupt signal - see https://en.wikipedia.org/wiki/Interrupts_in_65xx_processors
        // IRQ is trigged on the 6502 bus and not by anything the KIM-1 does with standard hardware
        
        let h = UInt8(PC >> 8); push(h)
        let l = UInt8(PC & 0x00FF); push(l)
        push(GetStatusRegister())
        INTERRUPT_DISABLE = true
        //PC = getAddress(0xFFEE) if there was complete memory decoding
        PC = getAddress(0x17FE)
    }
    
    func NMI()
    {
        // This is the 6502 Non-maskable Interrupt signal - see https://en.wikipedia.org/wiki/Interrupts_in_65xx_processors
        // NMI is called when the user presses Stop and SST button
        
        let h = UInt8(PC >> 8); push(h)
        let l = UInt8(PC & 0x00FF); push(l)
        push(GetStatusRegister())
        INTERRUPT_DISABLE = true
        PC = getAddress(0x17FA)  //PC = getAddress(0xFFEA) if there was complete memory decoding
        MachineStatus()
        
    }
    
    func BRK()
    {
        // This is the 6502 BRK signal - see https://en.wikipedia.org/wiki/Interrupts_in_65xx_processors
        PC = PC + 1
        let h = UInt8(PC >> 8); push(h)
        let l = UInt8(PC & 0x00FF); push(l)
        push(GetStatusRegister())
        INTERRUPT_DISABLE = true
        PC = getAddress(0x17FA)
        prn("BRK")
    }
    
    func SetTTYMode(TTY : Bool)
    {
        if TTY // Console mode
        {
            Write(address: 0x1740, byte: 0x00)
            Write(address: 0x00ff, byte: 0x00)
        }
        else // HEX keypad and LEDs
        {
            Write(address: 0x1740, byte: 0xFF)
            Write(address: 0x00ff, byte: 0x01)
        }
    }
    
    
    func KIM_ROM_Code (address: UInt16)
    {
        // This is the KIM specfic part.
        
        // Detect when these routines are being called or jmp'd to and then
        // perform the action and skip to their exit point.
        
        switch (PC) {
        
    //  case 0x200 :
      //  kim_keyActive = true // When first launched, the last call to KEYGET resets this, but technically it's still on. Doing this makes an apps's random number thing work, but breaks other apps.
           
                  
        case 0x1F1F :
            prn("SCANDS"); // Also sets Z to 0 if a key is being pressed
           //     print("SCANDS:  " + String(format: "%02X",memory.ReadAddress(address: UInt16(0xFB))) + String(format: "%02X",memory.ReadAddress(address: UInt16(0xFA))) + String(format: "%02X",memory.ReadAddress(address: UInt16(0xF9))) + " Mode: " + String(format: "%02X",memory.ReadAddress(address: UInt16(0xFF))))
            dataToDisplay = true
            
            if (kim_keyActive)
            {
                ZERO_FLAG = false
            }
            else
            {
                ZERO_FLAG = true
            }
            
            PC = 0x1F45
            
        case 0x1C2A : // Test the input speed for the hardware for timing. We can fake it.
            self.prn("DETCPS")
            memory.WriteAddress(address: 0x17F3, value: 1)
            memory.WriteAddress(address: 0x17F2, value: 1)
            PC = 0x1C4F
            
        case 0x1EFE : // The AK call is a "is someone pressing my keyboard?"
            self.prn("AK")
            
            if memory.ReadAddress(address: 0xff) == 0 // LED mode
            {
                A = 0
            }
            else
            {
            if kim_keyActive
            {
                A = 0x1
            }
            else
            {
                A = 0xff // No key pressed . It gets OR'd with 80, XOR'd with FF -> 0 Z is set
            }
            }
            
            PC = 0x1F14;
            
            
        case 0x1F6A :  // intercept GETKEY (get key from hex keyboard)
            self.prn("GETKEY \(kim_keyNumber)")
          
            if kim_keyActive
            {
                A = kim_keyNumber
                SetFlags(value: A)
            }
            else
            {
                A = 0xFF
                SetFlags(value: A)
            }
            
            kim_keyNumber = 0
            kim_keyActive = false
    
            
            PC = 0x1F90
            
        case 0x1EA0 : // intercept OUTCH (send char to serial) and display on "console"
            self.prn("OUTCH")
            
            if A >= 13
            {
                texttodisplay.append(String(format: "%c", A))
            }
            Y = 0xFF
            A = 0xFF
            PC = 0x1ED3
            
            
        case 0x1E65 : //   //intercept GETCH (get char from serial). used to be 0x1E5A, but intercept *within* routine just before get1 test
            self.prn("GETCH")
            
            memory.WriteAddress(address: 0xFD, value: X)
            
            A = GetAKey()
            
            if (A==0) {
                PC=0x1E60;    // cycle through GET1 loop for character start, let the 6502 runs through this loop in a fake way
                break
            }
            
            X = memory.ReadAddress(address: 0xFD) // x is saved in TMPX by getch routine, we need to get it back in x;
            Y = 0xFF
            PC = 0x1E87
            
            
        default : break
            
        }
    }
    
    
    func Init(ProgramName : String)
    {
        PC = 0x1c22                                         // PC default - can be changed in UI code for debugging purposes
        SP = 0xFD                                           // Stack Pointer initial value
        memory.InitMemory(SoftwareToLoad: ProgramName)     // Create 64K of memory and populate it with ROM images. 
    }
    
    // Execute one instruction - called by both single-stepping AND by running from the UI code.
    
    func Step() -> (address : UInt16, Break : Bool, opcode : String, display : Bool)
    {
        
        memory.RIOT_Timer_Click()
        
        dataToDisplay = false // Not sure I like this, but will think of a better way later.. if this is true at one point, there are numbers to draw
        
     

        // Intercept some KIM-1 Specific things
        KIM_ROM_Code(address: PC)
        
        // Execute the instruction at PC
        if !Execute()
        {
            PC = 0xffff
        }
        //RUNTIME_DEBUG_MESSAGES = true
        // Optional - display debug information using RUNTIME_DEBUG_MESSAGES to trigger debug information display
        if RUNTIME_DEBUG_MESSAGES
        {
            if PC < 0x1c00
            {
                DisplayDebugInformation()
            }
        }
        
        // Special case = if a garbage instructinon PC will be 0xffff
        return (PC, breakpoint, statusmessage, dataToDisplay)
    }
    
    // Serial terminal version
    func StepSerial() -> (address : UInt16, Break : Bool, terminalOutput : String)
    {
        
        memory.RIOT_Timer_Click()
        
        //RUNTIME_DEBUG_MESSAGES = true <- if you want debugging
        
        // Intercept some KIM-1 Specific things
        KIM_ROM_Code(address: PC)
        
        // Execute the instruction at PC
        Execute()
        
        let returnString = texttodisplay
        texttodisplay = ""
        
        return (PC, breakpoint, returnString)
    }
    
    
    
    
    func GetAKey() -> UInt8
    {
        // if no key pressed, return 0xFF
        // else return ASCII code (upper case) and switch off key
        
        if !kim_keyActive
        {
            return 0xff
        }
        
        kim_keyActive = false
        return kim_keyNumber
        
    }
    
    
    func Read(address : UInt16) -> UInt8
    {
        return memory.ReadAddress(address: address)
    }
    
    func Write(address : UInt16, byte : UInt8)
    {
        memory.WriteAddress(address: address, value: byte)
    }
    
    
    func printStatusToDebugWindow(_ regs: String, _ flags: String) {
        print(statusmessage, terminator:"")
        print("  " + regs, terminator:"")
        print("  " + flags)
    }
    
    func getA() -> UInt8
    {
        return A
    }
    
    func getX() -> UInt8
    {
        return X
    }
    
    func getY() -> UInt8
    {
        return Y
    }
    
    func NotInROM() -> Bool
    {
        // Used by the SST to skip over ROM code
        
        if PC<0x1C00
        {
            return true
        }
        else
        {
            return false
        }
        
    }
    
    func Dump(opcode : UInt8)
    {
        
        let regs =  String("OP:\(String(format: "%02X",opcode)) PC:\(String(format: "%04X", PC)) A:\(String(format: "%02X",A)) X:\(String(format: "%02X",X)) Y:\(String(format: "%02X",Y)) SP:\(String(format: "%02X",SP))")
        
        var flags = ""
        if NEGATIVE_FLAG { flags="N" } else {flags="n"}
        if OVERFLOW_FLAG { flags = flags + "V" } else { flags = flags + "v" }
        flags = flags + "_"
        if BREAK_FLAG { flags = flags + "B" } else { flags = flags + "b" }
        if DECIMAL_MODE { flags = flags + "D" } else { flags = flags + "d" }
        if INTERRUPT_DISABLE { flags = flags + "I" } else {flags = flags + "i"}
        if ZERO_FLAG { flags = flags + "Z"} else {flags = flags + "z"}
        if CARRY_FLAG { flags = flags + "C"} else {flags = flags + "c"}
        
        print(regs, flags)
        
    }
    
    func DisplayDebugInformation()
    {
        
        var flags = ""
        if NEGATIVE_FLAG { flags="N" } else {flags="n"}
        if OVERFLOW_FLAG { flags = flags + "V" } else { flags = flags + "v" }
        flags = flags + "_"
        if BREAK_FLAG { flags = flags + "B" } else { flags = flags + "b" }
        if DECIMAL_MODE { flags = flags + "D" } else { flags = flags + "d" }
        if INTERRUPT_DISABLE { flags = flags + "I" } else {flags = flags + "i"}
        if ZERO_FLAG { flags = flags + "Z"} else {flags = flags + "z"}
        if CARRY_FLAG { flags = flags + "C"} else {flags = flags + "c"}
        
        let regs =  String("\(String(format: "%04X",Read(address: PC)))  PC:\(String(format: "%04X", PC)) A:\(String(format: "%02X",A)) X:\(String(format: "%02X",X)) Y:\(String(format: "%02X",Y)) SP:\(String(format: "%02X",SP))  AC:\(String(format: "%02X",memory.ReadAddress(address: 0x62)))  AC:\(String(format: "%02X",memory.ReadAddress(address: 0x63)))  AC:\(String(format: "%02X",memory.ReadAddress(address: 0x64)))")
        
        printStatusToDebugWindow(regs, flags)
        
        
    }
    
    
    func MachineStatus()
    {
        // a unique kim feature that copies the registers into memory
        // to be examined later by the user if they so wish.
        
        
        memory.WriteAddress(address: 0xEF, value: UInt8(PC & 255))
        memory.WriteAddress(address: 0xF0, value: UInt8(PC >> 8))
        memory.WriteAddress(address: 0xF1, value: GetStatusRegister())
        memory.WriteAddress(address: 0xF2, value: SP)
        memory.WriteAddress(address: 0xF3, value: A)
        memory.WriteAddress(address: 0xF4, value: Y)
        memory.WriteAddress(address: 0xF5, value: X)
    }
    
    func SetStatusRegister(reg : UInt8)
    {
        CARRY_FLAG = (reg & 1) == 1
        ZERO_FLAG = (reg & 2) == 2
        INTERRUPT_DISABLE = (reg & 4) == 4
        DECIMAL_MODE = (reg & 8) == 8
        BREAK_FLAG = (reg & 16) == 16
        OVERFLOW_FLAG = (reg & 64) == 64
        NEGATIVE_FLAG = (reg & 64) == 128
    }
    
    func GetStatusRegister() -> UInt8
    {
        var sr : UInt8 = 0
        
        if CARRY_FLAG { sr = 1}
        if ZERO_FLAG { sr = sr + 2}
        if INTERRUPT_DISABLE { sr = sr + 4}
        if DECIMAL_MODE { sr = sr + 8}
        if BREAK_FLAG { sr = sr + 16}
        if OVERFLOW_FLAG { sr = sr + 64}
        if NEGATIVE_FLAG { sr = sr + 128}
        
        return sr
    }
    
    
    func SetPC(ProgramCounter: UInt16)
    {
        PC = ProgramCounter
    }
    
    func GetPC() -> UInt16
    {
        return PC
    }
    
    func Execute() -> Bool
    {
        // Use the PC to read the instruction (and other data if required) and
        // execute the instruction.
        
        let ins = memory.ReadAddress(address: PC)
        
        PC = PC + 1
        
        //Dump(opcode: ins) // Debugging information.
        
       return ProcessInstruction(instruction: ins)
    }
    
    func ProcessInstruction(instruction : UInt8) -> Bool
    {
        
        switch instruction {
        
        case 0: BRK() ;
        case 1: OR_indexed_indirect_x()
            
        case 5: OR_z()
        case 06: ASL_z()
            
        case 8: PHP()
        case 9: OR_i()
        case 0x0A : ASL_i()
            
        case 0x0D : OR_a()
        case 0x0E : ASL_a()
            
        case 0x10 : BPL()
        case 0x11 : OR_indirect_indexed_y()
            
        case 0x15 : OR_zx()
        case 0x16 : ASL_zx()
        case 0x18 : CLC()
        case 0x19 : OR_indexed_y()
            
        case 0x1D : OR_indexed_x()
        case 0x1E : ASL_indexed_x()
            
        case 0x20 : JSR()
        case 0x21 : AND_indexed_indirect_x()
            
        case 0x24 : BIT_z()
        case 0x25 : AND_z()
        case 0x26 : ROL_z()
            
            
        case 0x28 : PLP()
        case 0x29 : AND_i()
        case 0x2A : ROL_i()
            
        case 0x2C : BIT_a()
        case 0x2D : AND_a()
        case 0x2E : ROL_a()
            
        case 0x30 : BMI()
        case 0x31: AND_indirect_indexed_y()
            
        case 0x35: AND_zx()
        case 0x36 : ROL_zx()
            
        case 0x38 : SEC()
        case 0x39 : AND_indexed_y()
            
        case 0x3D : AND_indexed_x()
        case 0x3E : ROL_indexed_x()
            
        case 0x40 : RTI()
        case 0x41 : EOR_indexed_indirect_x()
            
        case 0x45 : EOR_z()
        case 0x46 : LSR_z()
            
        case 0x48 : PHA()
        case 0x49 : EOR_i()
        case 0x4A : LSR_i()
            
            
        case 0x4C : JMP_ABS()
        case 0x4D : EOR_a()
        case 0x4E : LSR_a()
            
        case 0x50 : BVC()
        case 0x51 : EOR_indirect_indexed_y()
            
        case 0x55 : EOR_zx()
        case 0x56 : LSR_zx()
            
        case 0x58 : CLI()
        case 0x59 : EOR_indexed_y()
            
        case 0x5A : PHY()
            
        case 0x5D : EOR_indexed_x()
        case 0x5E : LSR_indexed_x()
            
            
        case 0x60 : RTS()
        case 0x61 : ADC_indexed_indirect_x()
            
        case 0x65 : ADC_z()
        case 0x66 : ROR_z()
            
        case 0x68 : PLA()
        case 0x69 : ADC_i()
        case 0x6A : ROR_i()
            
        case 0x6D : ADC_a()
        case 0x6E : ROR_a()
            
        case 0x70 : BVS()
        case 0x71 : ADC_indirect_indexed_y()
            
        case 0x75 : ADC_zx()
        case 0x76 : ROR_zx()
            
        case 0x78 : SEI()
        case 0x79 : ADC_indexed_x()
        case 0x7A : PLY()
            
        case 0x7D : ADC_indexed_y()
        case 0x7E : ROR_indexed_x()
            
        case 0x6C: JMP_REL()
            
        case 0x72: ADC_indirect_indexed_y()
            
        case 0x80 : BRA() // 65C02
        case 0x81 : STA_indexed_indirect_x()
            
        case 0x84 : STY_z()
        case 0x85 : STA_z()
        case 0x86 : STX_z()
            
        case 0x88: DEY()
            
       // case 0x89: BIT() 6502c only
       
        
        
        case 0x8A : TXA()
            
        case 0x8C : STY_a()
        case 0x8D : STA_a()
        case 0x8E : STX_a()
            
        case 0x90: BCC()
        case 0x91 : STA_indirect_indexed_y()
            
        case 0x94 : STY_xa()
        case 0x95 : STA_zx()
        case 0x96 : STX_ya()
            
        case 0x98 : TYA()
        case 0x99 : STA_indexed_y()
        case 0x9A : TXS()
            
        case 0x9D : STA_indexed_x()
            
        case 0xA0 : LDY_i()
        case 0xA1 : LDA_indexed_indirect_x()
        case 0xA2 : LDX_i()
            
        case 0xA4 : LDY_z()
        case 0xA5 : LDA_z()
        case 0xA6 : LDX_z()
            
        case 0xA8 : TAY()
        case 0xA9 : LDA_i()
            
        case 0xAA : TAX()
            
        case 0xAC : LDY_a()
        case 0xAD : LDA_a()
        case 0xAE : LDX_a()
            
        case 0xB0 : BCS()
        case 0xB1 : LDA_indirect_indexed_y()
            
        case 0xB4 : LDY_zx()
        case 0xB5 : LDA_zx()
        case 0xB6 : LDX_zy()
            
        case 0xB8 : CLV()
        case 0xB9 : LDA_indexed_y()
        case 0xBA : TSX()
            
        case 0xBC : LDX_indexed_x()
        case 0xBD : LDA_indexed_x()
        case 0xBE : LDX_indexed_y()
            
            
        case 0xC0 : CPY_i()
        case 0xC1 : CMP_indexed_indirect_x()
            
        case 0xC4 : CPY_z()
        case 0xC5 : CMP_z()
        case 0xC6 : DEC_z()
            
        case 0xC8 : INY()                           // Incorrect in Assembly Lines book (gasp)
        case 0xC9 : CMP_i()
        case 0xCA : DEX()
            
        case 0xCC : CPY_A()
        case 0xCD : CMP_a()
        case 0xCE : DEC_a()
            
        case 0xD0 : BNE()
        case 0xD1 : CMP_indirect_indexed_y()
            
        case 0xD5 : CMP_zx()
        case 0xD6 : DEC_zx()
            
        case 0xD8 : CLD()
        case 0xD9 : CMP_indexed_y()
        case 0xDA : PHX()
            
        case 0xDD : CMP_indexed_x()
        case 0xDE : DEC_ax()
            
        case 0xE0 : CPX_i()
        case 0xE1 : SBC_indexed_indirect_x()
            
        case 0xE4 : CPX_z()
        case 0xE5 : SBC_z()
        case 0xE6 : INC_z()
            
        case 0xE8 : INX()
        case 0xE9 : SBC_i()
        case 0xEA : NOP()
            
        case 0xEC : CPX_A()
        case 0xED : SBC_a()
        case 0xEE : INC_a()
            
        case 0xF0 : BEQ()
        case 0xF1 : SBC_indirect_indexed_y()
            
        case 0xF5 : SBC_zx()
        case 0xF6 : INC_zx()
            
        case 0xF8 : SED()
        case 0xF9 : SBC_indexed_y()
        case 0xFA : PLX()
            
        case 0xFD : SBC_indexed_x()
        case 0xFE : INC_ax()
            
        default : /*print("**********************      Unknown instruction (or garbage): " + String(  format: "%02X", instruction) + " at " + String(  format: "%04X", PC) + "   **********************");*/  return false
            
        }
        
        return true
    }
    
    
    
    
    
    // Implement the 6502 instruction set
    //
    // Addressing modes - http://www.obelisk.me.uk/6502/addressing.html
    //
    // # Immediate e.g. LDA #10 (put 10 into A)
    // Zero page e.g. LDA $00 (put contents of memory address 00 into A)
    // Zero page X e.g. STY $10,X (put contents of Y into address (10+X)
    // Zero page X e.g. STY $10,X (put contents of Y into address (10+X)
    // Indirect Indexed e.g. LDA ($40), Y (load into A the byte at address made from contents of $40 added to Y
    
    
    func RTI()
    {
        // Used in the KIM-1 to launch user app
        
        SetStatusRegister(reg: pop())
        
        let l = UInt16(pop())
        let h = UInt16(pop())
        PC = (h<<8) + l
        prn("RTI")
    }
    func NOP() // EA
    {
        prn("NOP")
    }
    
    
    // Accumulator BIT test - needs proper testing
    
     
    func  BIT_z() // 24 
    {
        let ad = memory.ReadAddress(address: PC) ;  PC = PC + 1
        let v = memory.ReadAddress(address: UInt16(ad))
        let t = (A & v) //& 0xFF
        ZERO_FLAG = (t == 0) ? true : false
        NEGATIVE_FLAG = (v & 128) == 128
        OVERFLOW_FLAG = (v & 64) == 64
      
      //  if (((A ^ v) & 0x80) == 0x80)  && (((A ^ UInt8(v & 0x00FF)) & 0x80) == 0x80) {
       //     OVERFLOW_FLAG = true} else {OVERFLOW_FLAG = false}
        
        prn("BIT $"+String(format: "%02X",ad))
    }
    
    
    func  BIT_a() // 2C
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: UInt16(ad))
        let t = (A & v) & 0xFF
        ZERO_FLAG = (t == 0) ? true : false
        NEGATIVE_FLAG = (v & 128) == 128
        OVERFLOW_FLAG = (v & 64) == 64
        
        
     //   if (((A ^ v) & 0x80) == 0x80)  && (((A ^ UInt8(v & 0x00FF)) & 0x80) == 0x80) {OVERFLOW_FLAG = true} else {OVERFLOW_FLAG = false}
        prn("BIT $"+String(format: "%04X",ad))
    }
    
    // Accumulator Addition
    
    func  ADC_i() // 69
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        A = addC(A,v, carry: CARRY_FLAG)
        prn("ADC #$"+String(format: "%02X",v))
    }
    
    func  ADC_z() // 65
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        let v = memory.ReadAddress(address: UInt16(ad))
        
        //print("Zero page addition. Adding contents of \(ad) which is \(v) to A \(A_REGISTER)")
        
        A = addC(A,v, carry: CARRY_FLAG)
        prn("ADC $"+String(format: "%04X",v))
    }
    
    func  ADC_zx() // 75
    {
        let zp = memory.ReadAddress(address: PC) ; PC = PC + 1
        let ad = (UInt16(zp) + UInt16(X)) & 0xff
        let v = memory.ReadAddress(address: ad)
        
        //let oldA = A
        
        
        A = addC(A,v, carry: CARRY_FLAG)
        
        //print("Zero page indexed addition. Adding contents of \(ad) which is \(v) taken from at \(zp) + \(X) to A \(oldA) to get \(A)")
       
        
        prn("ADC $"+String(zp, radix: 16)+",X")
    }
    
    func  ADC_a() // 6D
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: UInt16(ad))
        A = addC(A,v, carry: CARRY_FLAG)
        prn("ADC $"+String(ad, radix: 16))
    }
    
    func  ADC_indexed_x() // 7d
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(X) + ad))
        A = addC(A,v, carry: CARRY_FLAG)
        prn("ADC $"+String(ad, radix: 16)+",X")
    }
    
    func  ADC_indexed_y() // 79
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(Y) + ad))
        A = addC(A,v, carry: CARRY_FLAG)
        prn("ADC $"+String(ad, radix: 16)+",Y")
    }
    
    func  ADC_indirect_indexed_y() // 71
    {
        let zp = UInt16(memory.ReadAddress(address: PC));
        let v = memory.ReadAddress(address: getIndirectIndexedBase())
        A = addC(A,v, carry: CARRY_FLAG)
        // test
        //A = 0x59
        prn("ADC ($"+String(format: "%02X",zp)+"),Y")
    }
    
    
    func  ADC_indexed_indirect_x() // 61
    {
        let za = memory.ReadAddress(address: PC);
        let v = get_indexed_indirect()
        A = addC(A,v, carry: CARRY_FLAG)
        prn("ADC ($"+String(format: "%02X",za)+",X)")
    }
    
    // Accumulator Subtraction
    
    func  SBC_i() // E9
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        A = subC(A,v)
        prn("SBC #$"+String(format: "%02X",v))
    }
    
    func SBC_z() // E5
    {
        let zero_page_address = memory.ReadAddress(address: PC) ; PC = PC + 1
        let v = memory.ReadAddress(address: UInt16(zero_page_address))
        A = subC(A,v)
        
        prn("SBC $"+String(String(format: "%02X",zero_page_address)))
    }
    
    func  SBC_zx() // F5
    {
        let ad = memory.ReadAddress(address: PC) ;  PC = PC + 1
        let v = memory.ReadAddress(address: (UInt16(X) + UInt16( ad) & 0xff))
        A = subC(A,v)
        prn("SBC $"+String(format: "%02X",ad)+",X")
    }
    
    func  SBC_a() // ed
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: UInt16(ad))
        A = subC(A,v)
        SetFlags(value: A)
        prn("SBC $"+String(format: "%04X",ad))
    }
    
    func  SBC_indexed_x() // fd
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(X) + ad))
        A = subC(A,v)
        //SetFlags(value: A)
        prn("SBC $"+String(format: "%04X",ad)+",X")
    }
    
    func  SBC_indexed_y() // F9
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(Y) + ad))
        A = addC(A,v, carry: CARRY_FLAG)
        //SetFlags(value: A)
        prn("SBC $"+String(format: "%04X",ad)+",Y")
    }
    
    func  SBC_indirect_indexed_y() // F1
    {
        let za = memory.ReadAddress(address: PC);
        let v = memory.ReadAddress(address: getIndirectIndexedBase())
        A = subC(A,v)
        prn("SBC ($"+String(format: "%04X",za)+"),Y")
    }
    
    func SBC_indexed_indirect_x() // E1
    {
        let za = memory.ReadAddress(address: PC );
        let v = get_indexed_indirect()
        A = subC(A,v)
        prn("SBC ($"+String(format: "%04X",za)+",X)")
    }
    
    // X Comparisons
    
    func CPX_i() // E0
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        let result = Int16(X) - Int16(v)
        if X >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if X == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        
        prn("CPX #$"+String(format: "%02X",v))
    }
    
    func CPX_z() // E4
    {
        let ad = memory.ReadAddress(address: PC) ;  PC = PC + 1
        let v = memory.ReadAddress(address: UInt16(ad))
        let result = Int16(X) - Int16(v)
        if X >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if X == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CPX $"+String(format: "%02X",ad))
    }
    
    func CPX_A() // EC
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: UInt16(ad))
        let result = Int16(X) - Int16(v)
        if X >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if X == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CPX $"+String(format: "%04X",ad))
        
    }
    
    // Y Comparisons
    
    func CPY_i() // C0
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        let result = Int16(Y) - Int16(v)
        if Y >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if Y == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        
        prn("CPY #$"+String(format: "%02X",v))
    }
    
    func CPY_z() // C4
    {
        let ad = memory.ReadAddress(address: PC) ;  PC = PC + 1
        let v = memory.ReadAddress(address: UInt16(ad))
        let result = Int16(Y) - Int16(v)
        if Y >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if Y == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CPY $"+String(format: "%02X",ad))
    }
    
    func CPY_A()
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: UInt16(ad))
        let result = Int16(Y) - Int16(v)
        if Y >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if Y == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CPY $"+String(format: "%04X",ad))
        
    }
    
    // Accumulator Comparison
    
    func CMP_i() // C9
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        let result = Int16(A) - Int16(v)
        if A >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if A == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        
        prn("CMP #$"+String(format: "%02X",v))
    }
    
    func CMP_z() // C5
    {
        let ad = memory.ReadAddress(address: PC) ;  PC = PC + 1
        let v = memory.ReadAddress(address: UInt16(ad))
        let result = Int16(A) - Int16(v)
        if A >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if A == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CMP $"+String(format: "%02X",ad))
    }
    
    func  CMP_zx() // D5
    {
        let ad = memory.ReadAddress(address: PC)
        let v = memory.ReadAddress(address: ((UInt16(X) + UInt16( ad)) & 0xff))
        PC = PC + 1
        let result = Int16(A) - Int16(v)
        if A >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if A == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CMP $"+String(format: "%02X",ad)+",X")
    }
    
    func CMP_a() // cd
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: UInt16(ad))
        let result = Int16(A) - Int16(v)
        if A >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if A == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CMP $"+String(format: "%04X",ad))
    }
    
    func  CMP_indexed_x() // dd
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(X) + ad))
        let result = Int16(A) - Int16(v)
        if A >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if A == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CMP $"+String(format: "%04X",ad)+",X")
    }
    
    func  CMP_indexed_y() // d9
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(Y) + ad))
        let result = Int16(A) - Int16(v)
        if A >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if A == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CMP $"+String(format: "%04X",ad)+",Y")
    }
    
    func CMP_indirect_indexed_y() // D1
    {
        let zp = UInt16(memory.ReadAddress(address: PC));
        let v = memory.ReadAddress(address: getIndirectIndexedBase())
        let result = Int16(A) - Int16(v)
        if A >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if A == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        // BUG setting the N flag wrong
        // Is there a special case when results is 0, or a bug in Oscar's Code?
        // Looking at the ASM80 results, I believe Oscar's Kim Uno Code is incorrect
        prn("CMP ($"+String(format: "%02X",zp)+"),Y")
    }
    
    func CMP_indexed_indirect_x()
    {
        let za = memory.ReadAddress(address: PC);
        let v = get_indexed_indirect()
        let result = Int16(A) - Int16(v)
        if A >= UInt8(v & 0xFF) { CARRY_FLAG = true } else { CARRY_FLAG = false }
        if A == UInt8(v & 0xFF) { ZERO_FLAG = true } else { ZERO_FLAG = false }
        if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true } else { NEGATIVE_FLAG = false }
        prn("CMP ($"+String(format: "%02X",za)+"),X")
    }
    
    
    // Accumulator Loading
    
    func  LDA_i() // A9
    {
        A = memory.ReadAddress(address: PC) ; PC = PC + 1
        SetFlags(value: A)
        prn("LDA #$"+String(format: "%02X",A))
    }
    
    func  LDA_z() // A5
    {
        let zero_page_ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        A = memory.ReadAddress(address: UInt16(zero_page_ad))
        // test
        //A = 1
        SetFlags(value: A)
        prn("LDA $"+String(format: "%02X",zero_page_ad))
    }
    
    func  LDA_zx() // B5
    {
        let ad = memory.ReadAddress(address: PC) ;  PC = PC + 1
        A = memory.ReadAddress(address: (UInt16(X) + UInt16(ad)) & 0xFF)
        // test
        //A = 1
        SetFlags(value: A)
        prn("LDA $"+String(format: "%02X",ad)+",X")
    }
    
    func LDA_a() // ad
    {
        let ad = getAddress()
        A = memory.ReadAddress(address: ad)
        SetFlags(value: A)
        prn("LDA $"+String(format: "%04X",ad))
    }
    
    func LDA_indexed_x() // bd
    {
        let ad = getAddress()
        A = memory.ReadAddress(address: (UInt16(X) + ad))
        SetFlags(value: A)
        prn("LDA $"+String(format: "%04X",ad)+",X")
    }
    
    func  LDA_indexed_y() // B9
    {
        
        let ad = getAddress()
        A = memory.ReadAddress(address: (UInt16(Y) + ad))
        SetFlags(value: A)
        prn("LDA $"+String(format: "%04X",ad)+",Y")
    }
    
    func  LDA_indirect_indexed_y() // B1
    {
        let za = memory.ReadAddress(address: PC)
        A = memory.ReadAddress(address: getIndirectIndexedBase())
        // test
        //A = 1
        SetFlags(value: A)
        prn("LDA ($"+String(format: "%02X",za)+"),Y")
    }
    
    func  LDA_indexed_indirect_x() // A1
    {
        let za = memory.ReadAddress(address: PC);
        A = get_indexed_indirect()
        // test
        //A = 0x01
        SetFlags(value: A)
        prn("LDA ($"+String(za, radix: 16)+",X)")
    }
    
    // Accumulator Storing
    
    func  STA_z() // 85
    {
        let zero_page_add = memory.ReadAddress(address: PC) ; PC = PC + 1
        memory.WriteAddress(address: UInt16(zero_page_add), value: A)
        prn("STA $"+String(format: "%02X",zero_page_add))
    }
    
    func  STA_zx() // 95
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        let ad = (UInt16(v) + UInt16(X)) & 0xff
        memory.WriteAddress(address: ad, value: A)
        prn("STA $"+String(format: "%02X",v)+",X")
    }
    
    func STA_a() // 8D
    {
        let v = getAddress()
        memory.WriteAddress(address: v, value: A)
        prn("STA #$" + String(format: "%04X",v))
    }
    
    
    func  STA_indexed_x() // 9d
    {
        let v = getAddress() + UInt16(X)
        memory.WriteAddress(address: v, value: A)
        prn("STA #$" + String(format: "%04X",v)+",X")
    }
    
    func STA_indexed_y() // 99
    {
        let v = getAddress() + UInt16(Y)
        memory.WriteAddress(address: v, value: A)
        prn("STA #$" + String(format: "%04X",v)+",Y")
    }
    
    func  STA_indirect_indexed_y() // 91
    {
        let za = memory.ReadAddress(address: PC)
        memory.WriteAddress(address: getIndirectIndexedBase(), value: A)
        prn("STA ($"+String(format: "%02X",za)+"),Y")
    }
    
    func  STA_indexed_indirect_x() // 81
    {
        let za = memory.ReadAddress(address: PC);
        let ad = UInt16((UInt16(za) + UInt16(X)) & 0x00ff)
        let lowadr = UInt16(memory.ReadAddress(address: ad))
        let highadr = UInt16(memory.ReadAddress(address: ad+1))
        let fullad = highadr << 8 + lowadr
        memory.WriteAddress(address: fullad, value: A)
        prn("STA ($"+String(format: "%02X",za)+"),X")
    }
    
    
    // Register X Loading
    
    func  LDX_i() // A2
    {
        X = memory.ReadAddress(address: PC) ; PC = PC + 1
        SetFlags(value: X)
        prn("LDX #$"+String(format: "%02X",X))
    }
    
    func  LDX_z() // A6
    {
        let zero_page_address = memory.ReadAddress(address: PC) ; PC = PC + 1
        X = memory.ReadAddress(address: UInt16(zero_page_address))
        // Test
        //X = 1
        SetFlags(value: X)
        prn("LDX $"+String(format: "%02X",zero_page_address))
    }
    
    func  LDX_zy() // B6
    {
        let ad = memory.ReadAddress(address: PC) ;  PC = PC + 1
        X = memory.ReadAddress(address: UInt16(Y + ad))
        SetFlags(value: X)
        prn("LDX $"+String(format: "%02X",ad)+",Y")
    }
    
    func LDX_a() // ae
    {
        let ad = getAddress()
        X = memory.ReadAddress(address: ad)
        SetFlags(value: X)
        prn("LDX $"+String(format: "%04X",ad))
    }
    
    func  LDX_indexed_y() // BE
    {
        let ad = getAddress()
        X = memory.ReadAddress(address: (UInt16(Y) + ad))
        SetFlags(value: X)
        prn("LDX $"+String(format: "%04X",ad)+",Y")
    }
    
    // Register Y Loading
    
    func  LDY_i() // A0
    {
        Y = memory.ReadAddress(address: PC) ; PC = PC + 1
        SetFlags(value: Y)
        prn("LDY #$"+String(format: "%02X",Y))
    }
    
    func  LDY_z() // A4
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        Y = memory.ReadAddress(address: UInt16(ad))
        // test
        //Y = 1
        SetFlags(value: Y)
        prn("LDY $"+String(format: "%02X",Y))
    }
    
    func  LDY_zx() // B4
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        Y = memory.ReadAddress(address: (UInt16(X) + UInt16(ad)) & 0xff)
        // test
        //Y = 01
        SetFlags(value: Y)
        prn("LDY $"+String(format: "%02X",ad)+",X")
    }
    
    func LDY_a() // AC
    {
        let ad = getAddress()
        Y = memory.ReadAddress(address: UInt16(ad))
        SetFlags(value: Y)
        prn("LDY $"+String(format: "%04X",ad))
    }
    
    func  LDX_indexed_x() // BC
    {
        let ad = getAddress()
        Y = memory.ReadAddress(address: (UInt16(X) + ad))
        SetFlags(value: Y)
        prn("LDY $"+String(format: "%04X",ad)+",X")
    }
    
    
    
    // Accumulator AND
    
    func  AND_i() // 29
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        A = A & v
        SetFlags(value: A)
        prn("AND #$"+String(format: "%02X",v))
    }
    
    func  AND_z() // 25
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        let v = memory.ReadAddress(address: UInt16(ad))
        A = A & v
        SetFlags(value: A)
        prn("AND $"+String(format: "%02X",ad))
    }
    
    func  AND_zx() // 35
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        let v = memory.ReadAddress(address: ((UInt16(X) + UInt16( ad)) & 0xff))
        A = A & v
        SetFlags(value: A)
        prn("AND $"+String(v, radix: 16)+",X")
    }
    
    func  AND_a() // 2d
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: UInt16(ad))
        A = A & v
        SetFlags(value: A)
        prn("AND $"+String(format: "%04X",ad))
    }
    
    func  AND_indexed_x() // 3d
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(X) + ad))
        A = A & v
        SetFlags(value: A)
        prn("AND $"+String(format: "%04X",ad)+",X")
    }
    
    func  AND_indexed_y() // 39
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(Y) + ad))
        A = A & v
        SetFlags(value: A)
        prn("AND $"+String(format: "%04X",ad)+",Y")
    }
    
    func  AND_indexed_indirect_x() // 21
    {
        let za = memory.ReadAddress(address: PC);
        let v = get_indexed_indirect()
        A = A & v
        SetFlags(value: A)
        prn("AND ($"+String(format: "%02X",za)+",X)")
    }
    
    func  AND_indirect_indexed_y() // 31
    {
        let za = memory.ReadAddress(address: PC)
        let v = memory.ReadAddress(address: getIndirectIndexedBase())
        A = A & v
        SetFlags(value: A)
        prn("AND ($"+String(format: "%02X",za)+"),Y")
    }
    
    // LSR
    
    func  LSR_i() // 4A
    {
        CARRY_FLAG = (A & 1) == 1
        A = A >> 1
        SetFlags(value: A)
        prn("LSR")
    }
    
    func  LSR_z() // 46
    {
        let ad = memory.ReadAddress(address: PC)
        var v = memory.ReadAddress(address: UInt16(ad))
        CARRY_FLAG = ((v & 1) == 1)
        v = v >> 1
        memory.WriteAddress(address: UInt16(ad), value: v)
        PC = PC + 1
        SetFlags(value: v)
        prn("LSR $"+String(format: "%02X",ad))
    }
    
    func  LSR_zx() // 56
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        var v = memory.ReadAddress(address: ((UInt16(X) + UInt16( ad)) & 0xff))
        CARRY_FLAG = (v & 1) == 1
        v = v >> 1
        memory.WriteAddress(address: (UInt16(X) + UInt16( ad) & 0xff), value: v)
        SetFlags(value: v)
        prn("LSR $"+String(format: "%02X",ad)+",X")
    }
    
    func  LSR_a() // 4E
    {
        let ad = getAddress()
        var v = memory.ReadAddress(address: UInt16(ad))
        CARRY_FLAG = (v & 1) == 1
        v = v >> 1
        memory.WriteAddress(address: ad, value: v)
        SetFlags(value: v)
        prn("LSR $"+String(format: "%04X",ad))
    }
    
    func  LSR_indexed_x() // 5E
    {
        let ad = getAddress()
        var v = memory.ReadAddress(address: (UInt16(X) + ad))
        CARRY_FLAG = (v & 1) == 1
        v = v >> 1
        memory.WriteAddress(address: (UInt16(X) + ad) , value: v)
        SetFlags(value: v)
        prn("LSR $"+String(format: "%04X",ad)+",X")
    }
    
    
    // Accumulator OR
    
    func  OR_i() // 09
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        A = A | v
        SetFlags(value: A)
        prn("OR #$"+String(format: "%02X",v))
    }
    
    func  OR_z() // 5
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        let v = memory.ReadAddress(address: UInt16(ad))
        A = A | v
        SetFlags(value: A)
        prn("OR $"+String(format: "%02X",ad))
    }
    
    func  OR_zx() // 15
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        let v = memory.ReadAddress(address: ((UInt16(X) + UInt16( ad)) & 0xff))
        A = A | v
        SetFlags(value: A)
        prn("OR $"+String(v, radix: 16)+",X")
    }
    
    func  OR_a() // 0d
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: UInt16(ad))
        A = A | v
        SetFlags(value: A)
        prn("OR $"+String(format: "%04X",ad))
    }
    
    func  OR_indexed_x() // 1d
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(X) + ad))
        A = A | v
        SetFlags(value: A)
        prn("OR $"+String(format: "%04X",ad)+",X")
    }
    
    func  OR_indexed_y() // 19
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(Y) + ad))
        A = A | v
        SetFlags(value: A)
        prn("OR $"+String(format: "%04X",ad)+",Y")
    }
    
    func  OR_indexed_indirect_x() // 01
    {
        let za = memory.ReadAddress(address: PC);
        let v = get_indexed_indirect()
        A = A | v
        SetFlags(value: A)
        prn("OR ($"+String(format: "%02X",za)+",X)")
    }
    
    func  OR_indirect_indexed_y() // 11
    {
        let za = memory.ReadAddress(address: PC)
        let v = memory.ReadAddress(address: getIndirectIndexedBase() )
        A = A | v
        SetFlags(value: A)
        prn("OR ($"+String(format: "%02X",za)+"),Y")
    }
    
    // Accumulator EOR
    
    func  EOR_i() // 49
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        A = A ^ v
        SetFlags(value: A)
        prn("EOR #$"+String(format: "%02X",v))
    }
    
    func  EOR_z() // 45
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        let v = memory.ReadAddress(address: UInt16(ad))
        A = A ^ v
        SetFlags(value: A)
        prn("EOR $"+String(ad, radix: 16))
    }
    
    func  EOR_zx() // 55
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        let v = memory.ReadAddress(address: ((UInt16(X) + UInt16(ad)) & 0xff))
        A = A ^ v
        SetFlags(value: A)
        prn("EOR $"+String(ad, radix: 16)+",X")
    }
    
    func  EOR_a() // 4D
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: UInt16(ad))
        A = A ^ v
        SetFlags(value: A)
        prn("EOR $"+String(format: "%04X",ad))
    }
    
    func  EOR_indexed_x() // 5d
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(X) + ad))
        A = A ^ v
        SetFlags(value: A)
        prn("EOR $"+String(format: "%04X",ad)+",X")
    }
    
    func  EOR_indexed_y() // 59
    {
        let ad = getAddress()
        let v = memory.ReadAddress(address: (UInt16(Y) + ad))
        A = A ^ v
        SetFlags(value: A)
        prn("EOR $"+String(format: "%04X",ad)+",Y")
    }
    
    func  EOR_indexed_indirect_x() // 41
    {
        let za = memory.ReadAddress(address: PC );
        let v = get_indexed_indirect()
        A = A ^ v
        SetFlags(value: A)
        prn("EOR ($"+String(format: "%02X",za)+",X)")
    }
    
    func  EOR_indirect_indexed_y() // 51
    {
        let za = memory.ReadAddress(address: PC)
        let v = memory.ReadAddress(address: getIndirectIndexedBase())
        A = A ^ v
        // test
        // A = 0x20
        SetFlags(value: A)
        prn("EOR ($"+String(format: "%02X",za)+"),Y")
    }
    
    
    
    // ASL
    
    func  ASL_i() // 0A
    {
        CARRY_FLAG = ((A & 128) == 128)
        A = A << 1
        SetFlags(value: A)
        prn("ASL")
    }
    
    func  ASL_z() // 06
    {
        let za = memory.ReadAddress(address: PC)
        var v = memory.ReadAddress(address: UInt16(za))
        CARRY_FLAG = ((v & 128) == 128)
        v = v << 1
        memory.WriteAddress(address: UInt16(za), value: v)
        PC = PC + 1
        SetFlags(value: v)
        prn("ASL $"+String(format: "%02X",za))
    }
    
    func  ASL_zx() // 16
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        var v = memory.ReadAddress(address: ((UInt16(X) + UInt16( ad)) & 0xff))
        CARRY_FLAG = ((v & 128) == 128)
        v = v << 1
        memory.WriteAddress(address: (UInt16(X) + UInt16( ad) & 0xff), value: v)
        SetFlags(value: v)
        prn("ASL $"+String(format: "%02X",ad)+",X")
    }
    
    func  ASL_a() // 0E
    {
        let ad = getAddress()
        var v = memory.ReadAddress(address: UInt16(ad))
        CARRY_FLAG = ((v & 128) == 128)
        v = v << 1
        memory.WriteAddress(address: ad, value: v)
        SetFlags(value: v)
        prn("ASL $"+String(format: "%04X",ad))
    }
    
    func  ASL_indexed_x() // 1E
    {
        let ad = getAddress()
        var v = memory.ReadAddress(address: (UInt16(X) + ad))
        CARRY_FLAG = ((v & 128) == 128)
        v = v << 1
        memory.WriteAddress(address: (UInt16(X) + ad), value: v)
        SetFlags(value: v)
        prn("ASL $"+String(format: "%04X",ad)+",X")
    }
    
  
    
    // ROL
    
    func  ROL_i() // 2a
    {
        let msb = ((A & 128) == 128)
        A = A << 1
        A = A | (CARRY_FLAG ? 1 : 0)
        SetFlags(value: A)
        CARRY_FLAG = msb
        prn("ROL A")
    }
    
    func  ROL_z() // 26
    {
        let ad = memory.ReadAddress(address: PC); PC = PC + 1
        var v = memory.ReadAddress(address: UInt16(ad))
        let msb = ((v & 128) == 128)
        v = v << 1
        v = v | (CARRY_FLAG ? 1 : 0)
        memory.WriteAddress(address: UInt16(ad), value: v)
        SetFlags(value: v)
        CARRY_FLAG = msb
        prn("ROL $"+String(format: "%02X",ad))
    }
    
    func  ROL_zx() // 36
    {
        let ad = memory.ReadAddress(address: PC); PC = PC + 1
        var v = memory.ReadAddress(address: ((UInt16(X) + UInt16( ad)) & 0xff))
        let msb = ((v & 128) == 128)
        v = v << 1
        v = v | (CARRY_FLAG ? 1 : 0)
        memory.WriteAddress(address: (UInt16(X) + UInt16( ad) & 0xff), value: v)
        SetFlags(value: v)
        CARRY_FLAG = msb
        prn("ROL $"+String(format: "%02X",ad)+",X")
    }
    
    func  ROL_a() // 2E
    {
        let ad = getAddress()
        var v = memory.ReadAddress(address: UInt16(ad))
        let msb = ((v & 128) == 128)
        v = v << 1
        v = v | (CARRY_FLAG ? 1 : 0)
        memory.WriteAddress(address: ad, value: v)
        SetFlags(value: v)
        CARRY_FLAG = msb
        prn("ROL $"+String(format: "%04X",ad))
    }
    
    func  ROL_indexed_x() // 3E
    {
        let ad = getAddress()
        var v = memory.ReadAddress(address: (UInt16(X) + ad))
        let msb = ((v & 128) == 128)
        v = v << 1
        v = v | (CARRY_FLAG ? 1 : 0)
        memory.WriteAddress(address: (UInt16(X) + ad), value: v)
        SetFlags(value: v)
        CARRY_FLAG = msb
        prn("ROL $"+String(format: "%04X",ad)+",X")
    }
    
    // ROR
    
    func  ROR_i() // 6A
    {
        let lsb = ((A & 1) == 1)
        A = A >> 1
        A = A | (CARRY_FLAG ? 128 : 0)
        SetFlags(value: A)
        CARRY_FLAG = lsb
        prn("ROR A")
    }
    
    func  ROR_z() // 66
    {
        let ad = memory.ReadAddress(address: PC); PC = PC + 1
        var v = memory.ReadAddress(address: UInt16(ad))
        let lsb = ((v & 1) == 1)
        v = v >> 1
        v = v | (CARRY_FLAG ? 128 : 0)
        memory.WriteAddress(address: UInt16(ad), value: v)
        SetFlags(value: v)
        CARRY_FLAG = lsb
        prn("ROR $"+String(format: "%02X",ad))
    }
    
    func  ROR_zx() // 76
    {
        let ad = memory.ReadAddress(address: PC); PC = PC + 1
        var v = memory.ReadAddress(address: ((UInt16(X) + UInt16( ad)) & 0xff))
        let lsb = ((v & 1) == 1)
        v = v >> 1
        v = v | (CARRY_FLAG ? 128 : 0)
        memory.WriteAddress(address: (UInt16(X) + UInt16( ad) & 0xff), value: v)
        SetFlags(value: v)
        CARRY_FLAG = lsb
        prn("ROR $"+String(format: "%02X",ad)+",X")
    }
    
    func  ROR_a() // 6E
    {
        let ad = getAddress()
        var v = memory.ReadAddress(address: UInt16(ad))
        let lsb = ((v & 1) == 1)
        v = v >> 1
        v = v | (CARRY_FLAG ? 128 : 0)
        memory.WriteAddress(address: ad, value: v)
        SetFlags(value: v)
        CARRY_FLAG = lsb
        prn("ROR $"+String(format: "%04X",ad))
    }
    
    func  ROR_indexed_x() // 7E
    {
        let ad = getAddress()
        var v = memory.ReadAddress(address: (UInt16(X) + ad))
        let lsb = ((v & 1) == 1)
        v = v >> 1
        v = v | (CARRY_FLAG ? 128 : 0)
        memory.WriteAddress(address: (UInt16(X) + ad), value: v)
        SetFlags(value: v)
        CARRY_FLAG = lsb
        prn("ROR $"+String(format: "%04X",ad)+",X")
    }
    
    
    
    // Store registers in memory
    
    func STX_z() // 86
    {
        let zero_page_address = memory.ReadAddress(address: PC) ; PC = PC + 1
        memory.WriteAddress(address: UInt16(zero_page_address), value: X)
        prn("STX $" + String(String(format: "%02X",zero_page_address)))
    }
    
    func STX_a() // 8e
    {
        let ad = getAddress()
        memory.WriteAddress(address: UInt16(ad), value: X)
        prn("STX $" + String(ad, radix: 16))
    }
    
    func STX_ya() // 96
    {
        let ad = memory.ReadAddress(address: PC) ; PC = PC + 1
        memory.WriteAddress(address: ((UInt16(ad) + UInt16(Y)) & 0xff), value: X)
        prn("STX $#" + String(ad, radix: 16) + ",Y")
    }
    
    
    func STY_z() // 84
    {
        let zero_page_address = memory.ReadAddress(address: PC) ; PC = PC + 1
        memory.WriteAddress(address: UInt16(zero_page_address), value: Y)
        prn("STY $" + String(String(format: "%02X",zero_page_address)))
    }
    
    func STY_a() // 8c
    {
        let ad = getAddress()
        memory.WriteAddress(address: UInt16(ad), value: Y)
        prn("STY $" + String(ad, radix: 16))
    }
    
    func STY_xa() // 94 // SUS
    {
      //  let ad = memory.ReadAddress(address: PC); PC = PC + 1
      //  memory.WriteAddress(address: UInt16(ad + X), value: Y)
        
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        let ad = (UInt16(v) + UInt16(X)) & 0xff
        memory.WriteAddress(address: ad, value: Y)
       
        prn("STY $#" + String(ad, radix: 16) + ",X")
    }
    
    
    
    
    
    
    // Swapping between registers
    
    
    func TXA() // 8A
    {
        A = X
        SetFlags(value: A)
        prn("TXA")
    }
    
    func TYA() // 98
    {
        A = Y
        SetFlags(value: A)
        prn("TYA")
    }
    
    
    func TAX() // AA
    {
        X = A
        SetFlags(value: X)
        prn("TAX")
    }
    
    func TAY() // A8
    {
        Y = A
        SetFlags(value: Y)
        prn("TAY")
    }
    
    func TSX() //BA
    {
        X = SP
        SetFlags(value: X)
        prn("TSX")
    }
    
    func TXS() //9A
    {
        SP = X
        //SetFlags(value: SP) // No flags here
        prn("TXS")
    }
    
    // Stack
    
    //  ....pushes
    
    func PHA() // 48
    {
        push(A)
        prn("PHA")
    }
    
    func PHP() // 08
    {
        let r = GetStatusRegister()
        push(r | (BREAK_FLAG ? 0x10 : 0))  // 6502 quirk - push the BREAK_FLAG but don't set it
        prn("PHP")
    }
    
    func PHX() // DA
    {
        push(X)
        prn("PHX")
    }
    
    func PHY() // 5A
    {
        push(Y)
        prn("PHY")
    }
    
    
    // .....pulls
    
    func PLA() // 68
    {
        A = pop()
        SetFlags(value: A)
        prn("PLA")
    }
    
    
    func PLP() // 28
    {
        SetStatusRegister(reg: pop())
        prn("PLP")
    }
    
    
    func PLX() // FA
    {
        X = pop()
        SetFlags(value: X)
        prn("PLX")
    }
    
    func PLY() // 7A
    {
        Y = pop()
        SetFlags(value: Y)
        prn("PLY")
    }
    
    
    // Flags
    
    func CLI() // 58
    {
        INTERRUPT_DISABLE = false
        prn("CLI")
    }
    
    func SEC() // 38
    {
        CARRY_FLAG = true
        prn("SEC")
    }
    
    func SED() // F8
    {
        DECIMAL_MODE = true
        prn("SED")
    }
    
    func SEI() //78
    {
        INTERRUPT_DISABLE = true
        prn("SEI")
    }
    
    
    func CLC()
    {
        CARRY_FLAG = false
        prn("CLC")
    }
    
    func CLV() // B8
    {
        OVERFLOW_FLAG = false
        prn("CLV")
    }
    
    func CLD() // d8
    {
        DECIMAL_MODE = false
        prn("CLD")
    }
    
    // Increment & Decrement - they don't care about Decimal Mode
    
    func INY() // CB
    {
        if Y == 255
        {
            Y = 0
        }
        else
        {
            Y = Y + 1
        }
        SetFlags(value: Y)
        prn("INY")
    }
    
    func INX() // E8
    {
        if X == 255
        {
            X = 0
        }
        else
        {
            X = X + 1
        }
        SetFlags(value: X)
        prn("INX")
    }
    
    func DEX() // CA
    {
        if X == 0
        {
            X = 255
        }
        else
        {
            X = X - 1
        }
        SetFlags(value: X)
        prn("DEX")
    }
    
    func DEY() // 88
    {
        if Y == 0
        {
            Y = 255
        }
        else
        {
            Y = Y - 1
        }
        SetFlags(value: Y)
        prn("DEY")
    }
    
    
    // Memory dec and inc
    
    func  DEC_z() // C6
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        var t = memory.ReadAddress(address: UInt16(v))
        if t == 0 { t = 255 } else { t = t - 1 }
        memory.WriteAddress(address: UInt16(v), value: t)
        SetFlags(value: t)
        prn("DEC $"+String(format: "%02X",v))
    }
    
    func  DEC_zx() // D6
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        var t = memory.ReadAddress(address: (UInt16(v) + UInt16(X)) & 0xFF)
        if t == 0 { t = 255 } else { t = t - 1 }
        memory.WriteAddress(address: (UInt16(v) + UInt16(X)) & 0xFF, value: t)
        SetFlags(value: t)
        prn("DEC $"+String(format: "%02X",v)+",X")
    }
    
    func DEC_a() // CE
    {
        let v = getAddress()
        var t = memory.ReadAddress(address: v)
        if t == 0 { t = 255 } else { t = t - 1 }
        memory.WriteAddress(address: v, value: t)
        SetFlags(value: t)
        prn("DEC $"+String(format: "%02X",v))
    }
    
    func DEC_ax() // DE
    {
        let v = getAddress()
        var t = memory.ReadAddress(address: v + UInt16(X))
        if t == 0 { t = 255 } else { t = t - 1 }
        memory.WriteAddress(address: v + UInt16(X), value: t)
        SetFlags(value: t)
        prn("DEC $"+String(format: "%04X",v)+",X")
    }
    
    
    func  INC_z() // E6
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        var t = memory.ReadAddress(address: UInt16(v))
        if t == 255 { t = 0 } else { t = t + 1 }
        memory.WriteAddress(address: UInt16(v), value: t)
        SetFlags(value: t)
        prn("INC $"+String(format: "%02X",v))
    }
    
    func  INC_zx() // F6
    {
        let v = memory.ReadAddress(address: PC) ; PC = PC + 1
        var t = memory.ReadAddress(address: (UInt16(v) + UInt16(X)) & 0xFF)
        if t == 255 { t = 0 } else { t = t + 1 }
        memory.WriteAddress(address: (UInt16(v) + UInt16(X)) & 0xFF, value: t)
        SetFlags(value: t)
        prn("INC $"+String(format: "%02X",v)+",X")
    }
    
    func INC_a() // EE
    {
        let v = getAddress()
        var t = memory.ReadAddress(address: v)
        if t == 255 { t = 0 } else { t = t + 1 }
        memory.WriteAddress(address: v, value: t)
        SetFlags(value: t)
        prn("INC $"+String(format: "%04X",v))
    }
    
    func INC_ax() // FE
    {
        let v = getAddress()
        var t = memory.ReadAddress(address: v + UInt16(X))
        if t == 255 { t = 0 } else { t = t + 1 }
        memory.WriteAddress(address: v + UInt16(X), value: t)
        SetFlags(value: t)
        prn("INC $"+String(format: "%04X",v)+",X")
    }
    
    
    // Branching
    
    func PerformRelativeAddress( jump : UInt8)
    {
        var t = UInt16(jump)
        var addr = Int(PC) + Int(t)
        if (t & 0x80 == 0x80) { t = 0x100 - t; addr = Int(PC) - Int(t) }
        PC = UInt16(addr & 0xffff)
    }
    
    
    func BRA() // 80
    {
        let t = memory.ReadAddress(address: PC); PC = PC + 1
        
        PerformRelativeAddress(jump: t)
        
        prn("BRA $" + String(t, radix: 16))
        
    }
    
    func BPL() // 10
    {
        let t = memory.ReadAddress(address: PC) ; PC = PC + 1
        
        if NEGATIVE_FLAG == false
        {
            PerformRelativeAddress(jump: t)
        }
        
        prn("BPL $" + String(format: "%02X",t) + ":" + String(format: "%04X",PC) )
        
    }
    
    func BMI() // 30
    {
        let t = memory.ReadAddress(address: PC) ; PC = PC + 1
        
        if NEGATIVE_FLAG == true
        {
            PerformRelativeAddress(jump: t)
        }
        
        prn("BMI $" + String(format: "%02X",t) + ":" + String(format: "%04X",PC) )
        
    }
    
    func BVC() // 50
    {
        let t = (memory.ReadAddress(address: PC)) ; PC = PC + 1
        
        if !OVERFLOW_FLAG
        {
            PerformRelativeAddress(jump: t)
        }
        
        prn("BVC $" + String(t, radix: 16))
        
    }
    
    func BVS() // 70
    {
        let t = (memory.ReadAddress(address: PC)) ; PC = PC + 1
        
        if OVERFLOW_FLAG
        {
            
            PerformRelativeAddress(jump: t)
            
        }
        
        prn("BVS $" + String(t, radix: 16))
        
    }
    
    func BCC() // 90
    {
        let t = (memory.ReadAddress(address: PC)) ; PC = PC + 1
        
        
        if !CARRY_FLAG
        {
            PerformRelativeAddress(jump: t)
        }
        
        prn("BCC $" + String(format: "%02X",t))
        
    }
    
    func BCS() // B0
    {
        let t = (memory.ReadAddress(address: PC)) ; PC = PC + 1
        
        if CARRY_FLAG
        {
            PerformRelativeAddress(jump: t)
        }
        
        prn("BCS $" + String(format: "%02X",t))
        
    }
    
    func BEQ() // F0
    {
        
        let t = (memory.ReadAddress(address: PC)) ; PC = PC + 1
        
        if ZERO_FLAG
        {
            PerformRelativeAddress(jump: t)
        }
        
        prn("BEQ $" + String(format: "%02X",t))
        
    }
    
    func BNE() // D0
    {
        
        let t = (memory.ReadAddress(address: PC)) ; PC = PC + 1
        
        
        if !ZERO_FLAG
        {
            PerformRelativeAddress(jump: t)
        }
        
        prn("BNE $" + String(format: "%02X",t))
        
    }
    
    
    // Jumping
    
    func JMP_ABS() // 4c
    {
        let ad = getAddress()
        PC = ad
        prn("JMP $" + String(format: "%04X",ad))
    }
    
    func JMP_REL() // 6c
    {
        // Not sure how this works, could it be this simple?
        let ad = getAddress()
        let target = getAddress(ad)
        PC = target
        prn("JMP $" + String(PC, radix: 16))
        
    }
    
    func JSR() // 20
    {
        // updated to push the H byte first, as per actual 6502!
        
        let h = (PC+2) >> 8
        let l = (PC+2) & 0xff
        
        let target = getAddress()
        
        push(UInt8(h))
        push(UInt8(l))
        
        
        PC = target
        
        //   print("                  JSR to " + String(format: "%04X",target) + " and returning to " + String(format: "%04X",(h<<8) + l))
        
        prn("JSR $" + String(format: "%04X",target))
    }
    
    func RTS() // 60
    {
        
        let l = UInt16(pop())
        let h = UInt16(pop())
        PC = (h<<8) + l
        
        //    print("                 RET to " + String(format: "%04X",PC) )
        
        prn("RTS")
    }
    
    // Utilities called by various opcodes
    
    func getIndirectIndexedBase() -> UInt16
    {
        /*
         This mode is only used with the Y register. It differs in the order that Y is applied to the indirectly fetched address. An example instruction that uses indirect index addressing is LDA ($86),Y . To calculate the target address, the CPU will first fetch the address stored at zero page location $86. That address will be added to register Y to get the final target address. For LDA ($86),Y, if the address stored at $86 is $4028 (memory is 0086: 28 40, remember little endian) and register Y contains $10, then the final target address would be $4038. Register A will be loaded with the contents of memory at $4038.
         */
        
        let zp = UInt16(memory.ReadAddress(address: PC)); PC = PC + 1
        let target = zp + UInt16(Y)
        let addr = getAddress(target)
        return addr
        
//        let zp = UInt16(memory.ReadAddress(address: PC)); PC = PC + 1
//        let lowezp =  memory.ReadAddress(address: zp);
//        let highzp = memory.ReadAddress(address: zp + 1);
//        let adr = UInt16(highzp) << 8 + UInt16(lowezp)
//        return adr
    }
    
    func get_indexed_indirect() -> UInt8
    {
        /* This mode is only used with the X register. Consider a situation where the instruction is LDA ($20,X), X contains $04, and memory at $24 contains 0024: 74 20, First, X is added to $20 to get $24. The target address will be fetched from $24 resulting in a target address of $2074. Register A will be loaded with the contents of memory at $2074.
         
         If X + the immediate byte will wrap around to a zero-page address. So you could code that like targetAddress = (X + opcode[1]) & 0xFF .
         
         */
        
        let za = memory.ReadAddress(address: PC + UInt16(X)); PC = PC + 1
        let ad = UInt16((UInt16(za) + UInt16(X)) & 0x00ff)
        let lowadr = UInt16(memory.ReadAddress(address: ad))
        let highadr = UInt16(memory.ReadAddress(address: ad+1))
        let fullad = highadr << 8 + lowadr
        return memory.ReadAddress(address: fullad)
        
    }
    
    
    func push(_ v : UInt8)
    {
        memory.WriteAddress(address: UInt16(0x100 + UInt16(SP)), value: v)
        if SP == 0
        {
            SP = 255
        }
        else
        {
            SP = SP - 1
        }
    }
    
    func pop() -> UInt8
    {
        
        if SP == 0xff
        {
            SP = 0
            return 0
        }
        else
        {
            SP = SP + 1
        }
        let v = memory.ReadAddress(address: UInt16(0x100 + UInt16(SP)))
        
        return v
    }
    
    
    
    func addC(_ n1 : UInt8, _ n2: UInt8, carry : Bool) -> UInt8
    {
        
        let c : UInt16 = (CARRY_FLAG == true) ? 1 : 0
        let value = UInt16(n2)
        
        
        if !DECIMAL_MODE
        {
            let result = UInt16(A) + value + c
            
            if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true} else {NEGATIVE_FLAG = false}
            if (result & 0xFF) == 0x00 {ZERO_FLAG = true} else {ZERO_FLAG = false}
            if (result < 0x100) {CARRY_FLAG = false} else  {CARRY_FLAG = true}
            
            let p1 = (result ^ UInt16(A))
            let p2 = (result ^ UInt16(n2))
            
            if (p1 & p2) & 0x0080 == 0x80
            {OVERFLOW_FLAG = true} else {OVERFLOW_FLAG = false}
            
            
            return UInt8(result & 0xFF)
            
        }
        else // decimal mode
        {
            let value = UInt16(n2)
            
            let t1 = (UInt16(n1 & 0x0f))
            let t2 = UInt16((value & 0x0f))
            let t3 = Int(t1) + Int(t2) + Int(c)
            var lxx = UInt16(t3 & 0x00ff)
            if ((lxx & 0xff) > 0x09) {lxx = lxx + 6}
            
            let t4 = (UInt16(n1) >> 4)
            let t5 = (value >> 4)
            let t6 = ((lxx > 0x0F) ? 1 : 0)
            let t7 = Int(t4) + Int(t5) + Int(t6)
            var hxx =  UInt16(t7)
            
            if ((hxx & 0xFF) > 9) {hxx = hxx + 6 }
            
            var result = (lxx & 0x0f)
            
            result = result + (hxx << 4)
            
           //print("Adding \(A) and \(value) and getting \(result)")
           
            if (hxx > 15) {CARRY_FLAG = true} else {CARRY_FLAG = false}
            if (result & 0xFF) == 0x00 {ZERO_FLAG = true} else {ZERO_FLAG = false}
            NEGATIVE_FLAG = false // clearsign();    // negative flag never set for decimal mode. That's a simplification, see http://www.6502.org/tutorials/decimal_mode.html
            OVERFLOW_FLAG = false // clearoverflow();    // overflow never set for decimal mode BS it sure does
            
            // the overflow flag does get set if the result is 0x80
            
            if UInt8(result & 0xFF) == 0x80 {
                OVERFLOW_FLAG = true
            }
        
            return UInt8(result & 0xFF)
        }
        
    }
    
    // Feel good about it.
    func subC(_ n1 : UInt8, _ n2: UInt8) -> UInt8
    {
        
        let c : UInt16 = (CARRY_FLAG == true) ? 0 : 1
        
        if !DECIMAL_MODE
        {
            
            let value : UInt16 = UInt16(n2) ^ 0x00FF
           // let result = UInt16(n1) + value + c
            
            
            let r1 = Int(n1) - Int(n2)  - Int(c)
            let result = UInt16(r1 & 0xffff)
            
            if (result & 0x80) == 0x80 {NEGATIVE_FLAG = true} else {NEGATIVE_FLAG = false}
            if (result & 0xFF) == 0x00 {ZERO_FLAG = true} else {ZERO_FLAG = false}
           //if (result < 0x100) {CARRY_FLAG = false} else  {CARRY_FLAG = true}
            
            if (r1 < 0x00) {CARRY_FLAG = false} else  {CARRY_FLAG = true}
            
            if (((n1 ^ n2) & 0x80) == 0x80)  && (((n1 ^ UInt8(value & 0x00FF)) & 0x80) == 0x80) {OVERFLOW_FLAG = true} else {OVERFLOW_FLAG = false}
            return UInt8(result & 0xFF)
            
        }
        else // decimal mode
        {
           
            let value = UInt16(n2)
            
            let t1 =  (UInt16(n1 & 0x0f))
            let t2 = UInt16((value & 0x0f))
            let t3 = Int(t1) - Int(t2) - Int(c)
            var lxx = UInt16(t3 & 0x00ff)
            
            if ((lxx & 0x10) != 0) {lxx = lxx - 6}
            
          //  print(c, t1, t2, t3, lxx)
            
            
            let t4 = (UInt16(n1) >> 4)
            let t5 = (value >> 4)
            let t6 = ((lxx & 0x10) != 0 ? 1 : 0)
            let t7 = Int(t4) - Int(t5) - Int(t6)
            var hxx =  UInt16(t7 & 0x00ff)
            
           // print(t4, t5, t6, t7, hxx)
           
            
            if ((hxx & 0x10) != 0) {hxx = hxx - 6 }
            
            var result = (lxx & 0x0f)
            
           // print(result)
            
            result = result + (hxx << 4);
            
            result = (lxx & 0x0f) | (hxx << 4)
            
            if ((hxx & 0xff) < 0x0f) {CARRY_FLAG = true} else {CARRY_FLAG = false}
            if (result & 0xFF) == 0x00 {ZERO_FLAG = true} else {ZERO_FLAG = false}
            NEGATIVE_FLAG = false // clearsign();    // negative flag never set for decimal mode. That's a simplification, see http://www.6502.org/tutorials/decimal_mode.html
            OVERFLOW_FLAG = false // clearoverflow();    // overflow never set for decimal mode.
            result = result & 0xff
            return UInt8(result & 0xFF)
        }
    }
    
    
    func getAddress() -> UInt16
    {
        // Get 16 bit address from current PC
        let l = UInt16(memory.ReadAddress(address: PC))
        PC = PC + 1
        let h = UInt16(memory.ReadAddress(address: PC))
        PC = PC + 1
        return  UInt16(h<<8 + l)
    }
    
    func getAddress(_ addr : UInt16) -> UInt16
    {
        // Get 16 bit address stored at the supplied address
        let l = UInt16(memory.ReadAddress(address: addr))
        let h = UInt16(memory.ReadAddress(address: UInt16((Int(addr) + 1) & 0xffff)))
        let ad = Int(h<<8 + l)
        return  UInt16(ad & 0xffff)
    }
    
    func SetFlags(value : UInt8)
    {
        
        if value == 0
        {
            ZERO_FLAG = true
        }
        else
        {
            ZERO_FLAG = false
        }
        
        if (value & 0x80) == 0x80
        {
            NEGATIVE_FLAG = true
        }
        else
        {
            NEGATIVE_FLAG = false
        }
        
    }
    
    // Called by the UI to pass on keyboard status
    // so that the CPU could query it.
    
    func SetKeypress(keyPress : Bool, keyNum : UInt8)
    {
        kim_keyActive = keyPress
        kim_keyNumber = keyNum
    }
    
    // Debug message utility
    func prn(_ message : String)
    {
        let ins = String(message).padding(toLength: 12, withPad: " ", startingAt: 0)
        
        statusmessage = ins
    }
    
    
}

