-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;
use work.auxiliary.all;

entity Bufs3state is
    generic (
      delay    :       time);
    port (
      data       : inout std_logic_vector(31 downto 0);
      Busd       : inout std_logic_vector(31 downto 0);
      DriveMem   : in    std_logic;
      DriveCPU   : in    std_logic);
end Bufs3state;

architecture Tristate of Bufs3state is

begin 

ToMemory: process(busd, DriveMem)
begin
   if DriveMem = '1' then data <= Busd and AllOnes;
   else data <= HighImpedance;
   end if;
end process;
 
ToCPU: process(data, DriveCPU)
begin
   if DriveCPU= '1' then Busd <= data and AllOnes after delay;
   else Busd <= HighImpedance after delay;
   end if;
end process;

end Tristate;
