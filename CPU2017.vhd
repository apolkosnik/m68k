-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;
use work.auxiliary.all;

entity CPU2017 is
  generic (
    delay  :       time);
  port (
    -- The interface with memory:
    addr     : out   std_logic_vector(23 downto 0);  -- bus de direccion de 24 bits, o 23?.
    data     : inout std_logic_vector(31 downto 0);
    ReadMem  : out   std_logic;         
    WriteMem : out   std_logic;     
    mhold    : in    std_logic;	    -- zero means memory needs more time.
    PrintMem : out   boolean;	    -- It is not a physical signal. It is used
                                    -- to print the memory in an external file
    reset    : in std_logic;        -- Low level active.
    clock    : in std_logic         -- Rising edge triggered
    );
end CPU2017;

architecture minimum of CPU2017 is
  
-- ALU related signals:
  --signal AluInputASel    : std_logic; -- selector de input 1 de la ALU (0 1)
  --signal AluInputBSel    : std_logic; -- selector de input 1 de la ALU (0 1)
  signal Bus1            : std_logic_vector(31 downto 0);
  signal Bus2            : std_logic_vector(31 downto 0);
  signal Busd            : std_logic_vector(31 downto 0);
  signal BusAux1         : std_logic_vector(31 downto 0);
  signal BusAux2         : std_logic_vector(31 downto 0);
  signal ALUcontrol      : std_logic_vector(4 downto 0);
  signal cin             : std_logic;
  signal EnableALU       : std_logic;
  signal SelectAInputALU : std_logic;
  signal SelectBInputALU : std_logic;
  signal DCCR            : std_logic_vector(3 downto 0);
-- Register Aux file related signals:
  signal EnableAux1      : std_logic;
  signal EnableAux2      : std_logic;
  signal LoadAux1        : std_logic;
  signal LoadAux2        : std_logic;
-- Register file related signals:
  signal RS1Sel          : std_logic_vector(3 downto 0);
  signal RS2Sel          : std_logic_vector(3 downto 0);
  signal RDSel           : std_logic_vector(3 downto 0);
  signal EnableRS1       : std_logic;
  signal EnableRS2       : std_logic;
  signal LoadRD          : std_logic;
-- Program counter (PCunit) related signals:
  signal PCop            : std_logic_vector(1 downto 0);
  signal EnablePC        : std_logic;
-- Condition code register (CCR) related signals:
  signal ZNVC            : std_logic_vector(3 downto 0);
  signal Intr            : std_logic;
  signal LoadCCR         : std_logic;
  signal LoadSR          : std_logic;
  signal EnableSR        : std_logic;
-- Instruction register (IRreg) related signals:
  signal Instruccion     : std_logic_vector(15 downto 0);
  signal Opcode          : std_logic_vector(3 downto 0);
  signal OpCodeExt       : std_logic_vector(3 downto 0);
  signal RS1IRsel        : std_logic_vector(3 downto 0);
  signal RS2IRsel        : std_logic_vector(3 downto 0);
  signal RDIRsel         : std_logic_vector(3 downto 0);
  signal LoadIReg        : std_logic;
  signal EnableImmed     : std_logic;
  signal EnableDisp      : std_logic;
 -- Buf3state related signals:
  signal DriveMem        : std_logic;
  signal DriveCPU        : std_logic;
-- MARreg related signals:
  signal LoadMAR          : std_logic;
-- The output of the auxiliary multiplexer JumpSelect
  signal YesJump          : std_logic;

-- This signal is non-physical: it has been added just to be able to understand more easily 
-- the simulations. Its type is defined in the Auxiliary.vhd file.
  signal ALUop : ALUops;
  
begin  -- minimum

  The_ALU: entity work.ALU(functional)
    generic map (
      delay    => delay)
    port map (
      AluInputASel => SelectAInputALU,
      AluInputBSel => SelectBInputALU,
      Ainput     => Bus1,
      A2input    => BusAux1,   -- segundo Input A de la ALU, esta conectado a BusAux1. 
      Binput     => Bus2,
      B2input    => BusAux2,   -- segundo Input B de la ALU, esta conectado a BusAux2. 
      ALUout     => Busd,
      ALUcontrol => ALUcontrol,
      cin        => cin,
      EnableALU  => EnableALU,
      DCCR       => DCCR
      );

  RegisterAux: entity work.RegAux(RegAuxArch)
    generic map (
      delay   => delay)
    port map(
      BusAux1       => BusAux1,
      BusAux2       => BusAux2,
      Busd          => Busd,
      EnableAux1    => EnableAux1,
      EnableAux2    => EnableAux2,
      LoadAux1      => LoadAux1,
      LoadAux2      => LoadAux2,
      reset         => reset,
      clock         => clock
    );

  RegisterBank: entity work.RegisterFile(VerySimple)
    generic map (
      delay   => delay)
    port map (
      RS1Sel    => RS1Sel,
      RS2Sel    => RS2Sel,
      RDSel     => RDSel,
      Bus1      => Bus1,
      Bus2      => Bus2,
      Busd      => Busd,
      EnableRS1 => EnableRS1,
      EnableRS2 => EnableRS2,
      LoadRD    => LoadRD,
      reset     => reset,
      clock     => clock);

  
  The_PC: entity work.PCunit(Simple)
    generic map (
      delay     => delay)
    port map (
      Bus1        => Bus1,
      Busd        => Busd,
      PCop        => PCop,
      EnablePC    => EnablePC,
      reset       => reset,
      clock       => clock);

  
  CondCodes: entity work.CondCodeRegister(FourBits)
    generic map (
      delay         => delay)
    port map (
      Busd            => Busd, 
      ZNVC            => ZNVC,
      DCCR            => DCCR,
      LoadCCR         => LoadCCR,
      LoadSR          => LoadSR,
      EnableSR        => EnableSR,
      reset           => reset,
      clock           => clock);

  
  The_IR : entity work.IReg(normal)
    generic map (
      delay   => delay)
    port map (
      Instruccion => Instruccion,
      Opcode     => Opcode,
      OpCodeExt  => OpCodeExt,    
      RS1IRSel   => RS1IRSel,
      RS2IRSel   => RS2IRSel,
      RDIRSel    => RDIRSel,  
      Busd       => Busd,
      Bus2       => Bus2,
      LoadIReg   => LoadIReg,
      EnableImmed=> EnableImmed,
      EnableDisp => EnableDisp,
      reset      => reset,
      clock      => clock);

  Bus_Interface: entity work.Bufs3state(Tristate)
    generic map (
      delay    => delay)
    port map (
      data       => data, 
      Busd       => Busd,
      DriveMem   => DriveMem,
      DriveCPU   => DriveCPU);

  MAR: entity work.MARreg(basic)
    generic map (
      delay   => delay)
    port map (
      Busd       => Busd,
      addr       => addr,
      LoadMAR    => LoadMAR,
      reset      => reset,
      clock      => clock);


  ControlUnit: entity work.Control(Student)
    generic map (
      delay        => delay)
    port map(
       -- Related to the ALU:
      AluInputASel    => SelectAInputALU,
      AluInputBSel    => SelectBInputALU,
      ALUcontrol      => ALUcontrol,
      cin 	          => cin,          
      EnableALU       => EnableALU,
      --  related to aux register file:
      LoadAux1        => LoadAux1,
      LoadAux2        => LoadAux2,
      EnableAux1      => EnableAux1,  
      EnableAux2      => EnableAux2,
      --  Related to the register file:
      RS1sel 	      => RS1sel,        
      RS2sel          => RS2Sel,
      RDSel           => RDSel,
      EnableRS1       => EnableRS1,
      EnableRS2       => EnableRS2,
      LoadRD          => LoadRD,
      -- Related to the program counter:
      PCop            => PCop,
      EnablePC        => EnablePC,
      --  Related to the condition code register:
      ZNVC            => ZNVC,
      Intr            => Intr,
      LoadCCR         => LoadCCR,
      LoadSR          => LoadSR,
      EnableSR        => EnableSR,
      YesJump         => YesJump,
      --  Related to the instruction register:
      Instruccion     => Instruccion,
      Opcode          => Opcode,
      OpCodeExt       => OpCodeExt,
      RS1IRsel        => RS1IRsel,
      RS2IRsel        => RS2IRsel,
      RDIRsel         => RDIRsel, 
      LoadIReg        => LoadIReg,
      EnableImmed     => EnableImmed,
      EnableDisp      => EnableDisp,
      --  Related to the tristate buffers interfacing memory:
      DriveMem        => DriveMem,
      DriveCPU        => DriveCPU,
      -- Related to the external memory:
      ReadMem         => ReadMem,
      WriteMem        => WriteMem,
      mhold           => mhold,
      PrintMem        => PrintMem,
      LoadMAR         => LoadMAR,
      -- General:
      reset           => reset,
      clock           => clock);

JumpSelect: process(OpCodeExt, ZNVC)

  variable selection: std_logic_vector(3 downto 0);
  variable MuxOutput: std_logic;
  begin
    selection:= Instruccion(11 downto 8); ---OpCodeExt(2 downto 0); -- Cambiar por el equivalente del 68k.
    case selection is         -- Aqui va la condicion del Bcc, de entre todas las posibilidades (Viene en el manual.)
      when "0000" =>  -- CC(HI) Carry Clear
        MuxOutput := not ZNVC(0); -- not C
      when "0001" =>  -- CS(LO) Carry Set 
        MuxOutput :=  ZNVC(0);  -- C
      when "0010" =>  -- EQ Equal 
        MuxOutput :=  ZNVC(3);  -- Z
      when "0011" =>  -- GE Greater or Equal
        MuxOutput := (ZNVC(2) and ZNVC(1)) or ((not ZNVC(2)) and  (not ZNVC(1))); -- (N and V) or (not N and not V) 
      when "0100" =>  -- GT Greater Than
        MuxOutput := ((ZNVC(2) and ZNVC(1)) and (not ZNVC(3) )) or (( (not ZNVC(2)) and (not ZNVC(1))) and (not ZNVC(3) )); -- (N and V and not Z) or (not N and not V and not Z)  
      when "0101" =>  -- HI High
        MuxOutput :=  (not ZNVC(0)) and  (not ZNVC(3)); -- not C and not Z
      when "0110" =>  -- LE Less or Equal
        MuxOutput := ( (ZNVC(3)) or (ZNVC(2) and (not ZNVC(1))) ) or ((not ZNVC(2)) and ZNVC(1)); -- Z or (N and not V) or (not N and V)
      when "0111" =>  -- LS Low or Same 
        MuxOutput :=  ZNVC(0) or ZNVC(3); -- C or Z
      when "1000" =>  -- LT Less Than
        MuxOutput :=  (ZNVC(2) and (not ZNVC(1)) ) or ((not ZNVC(2)) and ZNVC(1)); -- (N and not V) or (not N and V)
      when "1001" =>  -- MI Minus
        MuxOutput :=  ZNVC(2); -- N
      when "1010" =>  -- NE Not Equal
        MuxOutput :=  not ZNVC(3); -- not Z
      when "1011" =>  -- PL Plus
        MuxOutput :=  not ZNVC(2); -- Not N
      when "1100" =>  -- VC Overflow Clear
        MuxOutput :=  not ZNVC(1);
      when "1101" =>  -- VS Overflow Set
        MuxOutput :=  ZNVC(1);
      when "1110" =>  -- TRUE T
        MuxOutput := '1'; 
      when "1111" =>  -- FALSE F
        MuxOutput := '0';
      when others =>  -- En otros casos, desconocido.
        MuxOutput := 'X';
      -- when "000" => 
      --   MuxOutput:= '0';      -- 0. Never (0000)
      -- when "001" =>
      --   MuxOutput := ZNVC(3); -- Z = 1. Equals (0001) 
      -- when "010" =>
      --   MuxOutput:= (ZNVC(2) xor ZNVC(1)) or ZNVC(3); -- N xor V or Z = 1. Less or Equal than (0010)
      -- when "011" =>
      --   MuxOutput:= ZNVC(2) xor ZNVC(1);            -- N xor Overflow = 1. Less than (0011).
      -- when "100" =>
      --   MuxOutput := ZNVC(0);                       -- C = 1. Bigger or equal  (0100)
      -- when "101" =>
      --   MuxOutput:= ZNVC(0) and (not ZNVC(3));      -- C * ¬Z = 1. Bigger (0101) 
      -- when "110" =>
      --   MuxOutput := ZNVC(2);                       -- N = 1. Negative (0110) 
      -- when "111" =>
      --   MuxOutput:= ZNVC(1);                        -- V = 1.  Overflow. (0111)
      -- when others =>
      --   MuxOutput := 'X';
    end case;

    YesJump <= MuxOutput;  -- Primer bit del codigo de operacion del BRANCH.
end process; 

Clarifier: process(ALUcontrol, cin, EnableALU)
  begin
    if enableALU ='0' then
      ALUop <= NONE;
    elsif enableALU='1' then
      case ALUcontrol is
        when PASS_A  => ALUop <= PASSA;
        when PASS_B  => ALUop <= PASSB;
        when ALU_ADD  => ALUop <= ADD;
        when ALU_SUB  => ALUop <= SUB;
        when DECR_WORD => ALUop <= DECR;
        when INCR_WORD => ALUop <= INCR;
        when ALU_AND => ALUop <= ANDLOG;
        when ALU_OR => ALUop <=  ORLOG;
        when ALU_NOR => ALUop <= NORLOG;
        when ALU_XOR => ALUop <= XORLOG;
        when ALU_ADDN2 =>
          if cin = '1' then
            ALUop <=  SUBS;
          else
             ALUop <= ADDN2;
          end if;
        when ALU_ANDN2 => ALUop <=  ANDN2;
        when ALU_ORN2 => ALUop <=  ORN2;
        when ALU_NORN2 => ALUop <=  NORN2;                  
        when ALU_XORN2 => ALUop <= XORN2;                 
        when others =>  ALUop <= UNDEF;
      end case;
      else
        ALUop <= UNDEF;
    end if;
  end process;
  
end minimum;
