-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.auxiliary.all;

use std.textio.all;

entity Memory is
 port (
    addr     : in    std_logic_vector(23 downto 0); -- En la documentacion (Section 3 Signal Description) en MC68000 pone A23-A1. CUIDADO CON ESTO!
    data     : inout std_logic_vector(31 downto 0);
    ReadMem     : in    std_logic;    -- Activa a nivel alto.
    WriteMem : in    std_logic;    -- Activa a nivel alto.      
    mhold    : out   std_logic;    -- Contestacion de memoria: a cero pide mas tiempo
    printmem : in    boolean;
    clock    : in    std_logic );  -- El flanco activo es el de subida para la CPU.
end entity Memory;

-- Although many memory chips are basically asynchronous, the clock signal is
-- quite handy, because it tells us in which moments we may look at the buses
-- and at the control signals. The CPU is a sequential system triggered by the
-- rising edge of the clock, so in the falling edges the signals must be stable
-- (we are considering the possibility of simulating the CPU with some delays,
-- and we do not want to convert the memory in a simple synchronous system).
-- Besides, if we put the information on the data bus with the falling edge of
-- the clock, when the next rising edge arrives, the CPU will have no problem
-- in getting it. We have not done it in this model, but we may even introduce
-- some delay in the buses. What has indeed been done is that every time the
-- CPU asks for a memory access, the memory wants one more clock cycle to
-- complete the operation.

-- We cannot declare the memory positions as signals, because that would give an
-- unmanegeable number of signals. Hence we have used variables. This means
-- that if we want to see the memory contents, the easiest way is to dump them
-- on an external file. Whenever there is an event on the signal PrintMem the
-- contents of all memory cells modified since the last event on that signal
-- are prineted on an external file "MEMORYDUMP.txt".


architecture functional of Memory is
  signal Dtack: std_logic; -- internal version of mhold.
  constant ADDRSIZE : natural:= 24; -- tamanyo de direcciones de 24 bits
  constant MEMSIZE  : natural:= 2**ADDRSIZE; -- total de direcciones: 2^24 = 16384k words de 16 bits
  constant WORDSIZE : natural:= 32; -- es 32 bits o 16 bits de palabra en memoria?
begin

Acknowledge: process(clock, ReadMem, WriteMem)
variable PresentValue: std_logic:= '1';
-- This is a model of slow model. We are going to force always the CPu to wait
-- one whole clock cycle.
begin
  if falling_edge(clock) and (ReadMem = '1' or WriteMem = '1') then
    PresentValue := not PresentValue;
  end if;
  Dtack <= PresentValue;
end process;

mhold<= Dtack;

----------------------- MAIN PART OF THE MAIN MEMORY -----------------------------

MainMemory: process(addr, data, Dtack, ReadMem, WriteMem, printmem, clock)

-- Every memory position:
type Position is record
  -- When we are asked to dump in the file MEMORYDUMP.txt the words which have
  -- been modified, we need the information about which are them: 
   modified: boolean; 
   contents: bit_vector(WORDSIZE -1 downto 0); -- BITS: we want to save space.
end record; 

-- 16384k words de 16 bits: 
  
type Matrix is array(0 to MEMSIZE -1) of Position; 
variable MyMemory: Matrix;

variable Initial : boolean:= true;  -- Not to read twice (or more) the input file.

-- Variables para la lectura de ficheros
variable name: LINE;
variable prompt: LINE;
variable OneLine: LINE; 
variable instruction: bit_vector(WORDSIZE -1 downto 0);
file program : TEXT;
file DumpFile: TEXT;
variable OneChar: character;
variable Indication: string(1 to 3);

variable AddrDefined : boolean;
variable address: natural:= 0;
variable InfRead: std_logic_vector(WORDSIZE -1 downto 0); -- What we read from
                                                          -- memory

BEGIN  -- Beginning of the MainMemory process

-- Initialization of the memory from an external file provided by the user.
-- First we make sure that the "modified" field is initialized to false. It
-- shouldn't be necessary, but costs nothing to make sure. The variable Initial
-- has been initialized to true in its declaration.


----------------------- INICIALIZATION OF THE MEMORY ------------------------
INICIALIZACION: if Initial then
  for k in MyMemory'range loop  
    MyMemory(k).modified:= false;
  end loop;
  
  prompt:= new string'("Name of the instructions file?");
  name := new string(1 to 1); -- Name of the LowRisk program file
  WRITELINE(OUTPUT, prompt);
  READLINE(INPUT, name);
  FILE_OPEN(program, name.all, read_mode);
 
  ReadingFileLoop: while not ENDFILE(program) loop
    READLINE(program,OneLine);
    Caution: next ReadingFileLoop when OneLine.all="";
    if OneLine(1) = 'O' then
      read(OneLine, Indication); 
      read(OneLine, address);
      assert((0 <= address) and (address<MEMSIZE))
	  report "The address which has been read is outside the available memory range."
        severity FAILURE;
    elsif OneLine(1) = '#' then     -- A comment might be introduced beginning
                                    -- with a line with a hash character (#).
       Read(OneLine, OneChar);      -- We just suppress it and finally the rest of the
                                    -- line       
    else
	Read(OneLine, instruction);
          AssignLoop: for j in WORDSIZE -1 downto 0 loop
            if instruction(j) = '1' then 
              MyMemory(address).contents(j) := '1';
            else
              MyMemory(address).contents(j) := '0';
            end if;       
          end loop AssignLoop;
          MyMemory(address).modified:= true; 
          address:= address+1;
    end if;
    EliminateComments: while not(OneLine.all = "") loop  -- we eliminate the
                                                         -- rest of OneLine
      Read(OneLine, OneChar); 
    end loop EliminateComments;
  end loop ReadingFileLoop;
  FILE_CLOSE(program);
  -- We have finished initializing memory: 
  -- Everything which was inside the "If Initial" won't be executed again.
  Initial := false; 
end if;
------------------------- INITIALIZATION FINISHED ------------------------


-- We must disable the outputs whenever a reading operation is not asked 
if ReadMem = '0' then 
  data <= HighImpedance; 
end if;

------------------------- ADDRESS CHECK -----------------------------
-- Let us see if the address is correctly defined:
AddrDefined:= true;
for i in ADDRSIZE -1 downto 0 loop
  AddrDefined := AddrDefined and (addr(i) = '1' or addr(i) = '0');
end loop;
if AddrDefined then
  address:= TO_INTEGER(UNSIGNED(addr));
end if;
-------------------------CHECK FINISHED ------------------------------------


--------------- MAIN SECTION OF THE MEMORY ACCESS CODE --------------------
-- We get what comes from the busses on the falling edge of the clock
-- If the internal Dtack is zero it means we have not finished the operation yet.
if falling_edge(clock) and Dtack = '0' and (ReadMem = '1' or WriteMem = '1') then 
     assert(AddrDefined)
     report "address indefinida al acceder a memoria"
     severity WARNING;
   -- Reading case:
  if ReadMem = '1' and AddrDefined then
	InfRead := To_StdLogicVector(MyMemory(address).contents);
      data <= InfRead;
  -- Writing case:
  elsif WriteMem ='1' and AddrDefined then
    MyMemory(address).modified:= true;
    MyMemory(address).contents := TO_BITVECTOR(Data);
  end if;
end if; 
-------------------------THE MAIN SECTION IS FINISHED -------------------------




------------------------ FILE DUMP OF THE MEMORY -----------------------------
-- We want to dump in an external file the contents of those memory positions
-- which have been accessed between two consecutive events on printmem:
if printmem'event then
  FILE_OPEN(DumpFile, "MEMORYDUMP.txt", append_mode);
  OneLine.all:= ""; -- Inizialiazation de "OneLine" to an empty line 
  WRITE(OneLine,string'("Present time of simulation: "));
  WRITE(OneLine,now);
  WRITELINE(DumpFile,OneLine);
  WRITE(OneLine,string'("address          Contents"));
  WRITELINE(DumpFile,OneLine);
  TheWriting: for i in MyMemory'range loop
    if MyMemory(i).modified = true then
      WRITE(L =>OneLine,VALUE =>i, JUSTIFIED => LEFT, FIELD => ADDRSIZE + 1);    
      WRITE(L=>OneLine,VALUE=>MyMemory(i).contents);
      WRITELINE(DumpFile,OneLine);
      MyMemory(i).modified := false;
    end if;       
  end loop TheWriting;
  WRITE(OneLine,string'("    "));
  WRITELINE(DumpFile,OneLine);
  FILE_CLOSE(DumpFile); 
end if;
	
end process;

end functional;
