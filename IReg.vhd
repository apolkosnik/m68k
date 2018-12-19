-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;
use work.auxiliary.all;

entity IReg is
    generic (
      delay   :     time);
    port (
      -- Operation selection:
      Instruccion: out std_logic_vector(15 downto 0);
      Opcode   : out std_logic_vector(3 downto 0);
      OpCodeExt: out std_logic_vector(3 downto 0);

      -- Register selection:
      RS1IRsel  : out std_logic_vector(3 downto 0);
      RS2IRsel  : out std_logic_vector(3 downto 0);
      RDIRsel   : out std_logic_vector(3 downto 0);

      -- Inputs/outpus of buses 
      busd      : in  std_logic_vector(31 downto 0);
      bus2      : out std_logic_vector(31 downto 0);
      
      -- Load order and enables to output information to bus2
      LoadIReg   : in  std_logic;
      EnableImmed: in  std_logic;
      EnableDisp : in  std_logic;

  	reset : in std_logic;
      clock : in std_logic);
  end entity;

architecture normal of IReg is
    signal IRval: std_logic_vector(15 downto 0);
  begin
    
  Loading: process(clock, reset)
  begin
    if reset = '0' then IRval <= (others =>'W') after delay;
    elsif rising_edge(clock) and LoadIReg = '1' then
      IRval <= busd(15 downto 0) and AllOnes16 after delay;
    end if;
  end process;


---- Ajustar el tipo de instruccion del 68000 aqui. CAMBIAR!!!!!! -----------------

--  ADD:
    -- 1101 Register(---)Opmode(---)ModeEffectiveAddress(---)Register(---)
--  MOVE:
    -- 00 Size(--)Destination(---,---)Source(---,---).

  Opcode    <= IRval(15 downto 12);
  RS1IRSel(2 downto 0)  <= IRval(11 downto 9);
  --Opmode    <= IRval(8 downto 6):
  RS2IRSel(2 downto 0)  <= IRval(2 downto 0);
  --AddrMode  <= IRval(5 downto 3) 
  RDIRSel(2 downto 0)   <= IRval(2 downto 0);
 
  OpCodeExt <= IRval(3 downto 0);
  Instruccion <= IRval(15 downto 0);

-- Crear proceso para instrucciones que requieran enviar un dato inmediato por la ALU hacia memoria/registro. TODO.


TheOutput: process(IRval, EnableImmed, EnableDisp)
  constant ManyZeros: std_logic_vector(7 downto 0):= (others => '0');
  constant ManyOnes: std_logic_vector(7 downto 0):= (others => '1');
  variable ImmediateInstType: std_logic_vector(1 downto 0);
begin 
  if EnableDisp = '1' then 
	  bus2(31 downto 0) <= "000000000000000000000000" & IRval(7 downto 0); 
  elsif EnableImmed = '1' then 
    ImmediateInstType:= IRval(1) & IRval(0);
    case ImmediateInstType is	
      when LDIL => bus2(15 downto 0) <= ManyZeros & IRval(9 downto 2);
      when LDIX | ADDI => 
			 if IRval(9)='1' then 
				bus2(15 downto 0) <= ManyOnes & IRval(9 downto 2);
                         elsif IRval(9)='0' then 
				bus2(15 downto 0) <= ManyZeros & IRval(9 downto 2);
			 else 
				bus2 <= (others => 'X');
                         end if;
      when ORIM => bus2(15 downto 0) <= IRval(9 downto 2) & ManyZeros;
      when others => bus2 <= (others => 'X');
    end case;
  else bus2<= HighImpedance;
  end if;
end process;


end normal;

