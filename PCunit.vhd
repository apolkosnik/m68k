-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;
use work.auxiliary.all;

entity PCunit is
  generic (
      delay :       time);
    port (
      Bus1     : out std_logic_vector(31 downto 0);
      Busd     : in  std_logic_vector(31 downto 0);  -- for address loading 
      PCop     : in  std_logic_vector(1 downto 0);
      -- 00    : Do nothing.
      -- 01    : RTI - Rutina de tratamiento de interrupcion (en fichero de programa)
      -- 10    : Normal increment: PC  <- PC + 1;
      -- 11    : Paralle load: PC <- busd;
      EnablePC : in    std_logic;     
      reset    : in std_logic;
      clock    : in std_logic);
end PCunit;

architecture simple of PCunit is
  signal PCval: std_logic_vector(23 downto 0);

begin

Storing: process(clock, reset)
 variable carry: std_logic_vector(24 downto 0) :="0000000000000000000000001";
 begin
 if reset = '0' then PCval <= (others =>'0') after delay;
 elsif rising_edge(clock) then
	case PCop is
    when INCRPC => 
      for i in 0 to 23 loop
        PCval(i) <= PCval(i) xor carry(i);
	      carry(i+1) := carry(i) and PCval(i);
      end loop; 
	  when LOADPC => 
      PCval <= Busd(23 downto 0) and AllOnes24;
    when RTIPC =>
      PCval <= "000000000000000000100000" and AllOnes24;
    when others =>
		  PCval <= PCval;
    end case;
  end if;
end process Storing;

Bus1 <= "00000000" & PCval when EnablePC = '1' else HighImpedance;

end simple; 
