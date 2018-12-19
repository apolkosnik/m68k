-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;

package auxiliary is
  type ALUops is (NONE, PASSA, PASSB, ADD, ANDLOG, ORLOG, NORLOG, XORLOG,
                  SUBS, ADDN2, ANDN2, ORN2, NORN2, XORN2, UNDEF, SUB, INCR, DECR);
  type MultipleRegs is array (NATURAL range <>) of std_logic_vector(31 downto 0); -- 32 bits cada registro de proposito general
  constant HighImpedance : std_logic_vector(31 downto 0):= (others => 'Z');
  constant AllOnes : std_logic_vector(31 downto 0) := (others=>'1');
  constant AllOnes24 : std_logic_vector(23 downto 0) := (others=>'1');
  constant AllOnes16 : std_logic_vector(15 downto 0) := (others=>'1');
  
  -- Orders to the ALU (values admitted by the signal ALUcontrol).
  -- It is important to know their values, whether you use or not
  -- these constants directly in the code. All these values are 
  -- also used by the ALU.vhd file:
  constant PASS_A   : std_logic_vector(4 downto 0):= "00000";
  constant PASS_B   : std_logic_vector(4 downto 0):= "00001";
  constant ALU_SUB  : std_logic_vector(4 downto 0):= "00010";	
  constant ALU_ADD  : std_logic_vector(4 downto 0):= "00011";
  constant ALU_AND  : std_logic_vector(4 downto 0):= "00100";
  constant ALU_OR   : std_logic_vector(4 downto 0):= "00101";
  constant ALU_NOR  : std_logic_vector(4 downto 0):= "00110";
  constant ALU_XOR  : std_logic_vector(4 downto 0):= "00111";

  constant DECR_BYTE: std_logic_vector(4 downto 0):= "10000";
  constant DECR_WORD: std_logic_vector(4 downto 0):= "10001";
  constant DECR_LONG: std_logic_vector(4 downto 0):= "10010";
  constant INCR_BYTE: std_logic_vector(4 downto 0):= "10011";
  constant INCR_WORD: std_logic_vector(4 downto 0):= "10100";
  constant INCR_LONG: std_logic_vector(4 downto 0):= "10101";

  -- The following orders are what their name mean. The difference from some
  -- of the previous ones is that the second operand is complemented before
  -- performing the operation, so the difference in the values is just the
  -- highest weight bit, which is now '1' instead of '0'. 
  constant ALU_ADDN2 : std_logic_vector(4 downto 0):= "01011";
  constant ALU_ANDN2 : std_logic_vector(4 downto 0):= "01100";
  constant ALU_ORN2  : std_logic_vector(4 downto 0):= "01101";
  constant ALU_NORN2 : std_logic_vector(4 downto 0):= "01110";
  constant ALU_XORN2 : std_logic_vector(4 downto 0):= "01111";
  constant ALU_UNDEF : std_logic_vector(4 downto 0):= "XXXXX";
  
  -- Orders to the program counter:		
  constant INCRPC: std_logic_vector(1 downto 0):= "10";
  constant LOADPC: std_logic_vector(1 downto 0):= "11";
  constant SAMEPC: std_logic_vector(1 downto 0):= "00";
  constant RTIPC: std_logic_vector(1 downto 0):= "01";

  -- Operation codes of the instructions:
  constant STOPCODE   : std_logic_vector(3 downto 0):= "0000";
  constant LOADCODE   : std_logic_vector(3 downto 0):= "0001";
  constant STORECODE  : std_logic_vector(3 downto 0):= "1111";
  constant ADDCODE    : std_logic_vector(3 downto 0):= "1011";
  constant OPLOGCODE  : std_logic_vector(3 downto 0):= "1000";
  constant JMPCCODE   : std_logic_vector(3 downto 0):= "1010";
  constant BRANCHCODE : std_logic_vector(3 downto 0):= "1100";
  constant OPICODE    : std_logic_vector(3 downto 0):= "1110";
  
  constant MOVEBCODE    : std_logic_vector(3 downto 0):= "0001";
  constant MOVEWCODE    : std_logic_vector(3 downto 0):= "0011";
  constant MOVELCODE    : std_logic_vector(3 downto 0):= "0010";


  -- The different types of logical operations:
   constant OPAND   : std_logic_vector(1 downto 0):= "00"; 
   constant OPOR    : std_logic_vector(1 downto 0):= "01";
   constant OPNOR   : std_logic_vector(1 downto 0):= "10";
   constant OPXOR   : std_logic_vector(1 downto 0):= "11";
  
 -- The operation code extensions of the OPI instructions:
  constant LDIL : std_logic_vector(1 downto 0) := "00";
  constant LDIX : std_logic_vector(1 downto 0) := "01";
  constant ORIM : std_logic_vector(1 downto 0) := "10";
  constant ADDI : std_logic_vector(1 downto 0) := "11";
  
end package auxiliary;
