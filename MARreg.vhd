-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;
use work.auxiliary.all;

entity MARreg is
    generic (
      delay    : time);
    port (       
      Busd       : in std_logic_vector(31 downto 0);   
      addr       : out std_logic_vector(23 downto 0); -- bus de 24 bits.
      LoadMAR    : in std_logic;
      reset      : in std_logic;
      clock      : in std_logic);
 end entity;

architecture basic of MARreg is

begin 
 

 -- Las direcciones deben ser de 24 bits.
LoadRreg: process(clock, reset)
begin
if reset = '0' then
   addr <= (others => '0');
elsif rising_edge(clock) and LoadMAR = '1' then
   addr <= Busd(23 downto 0)  after delay; --Busd and AllOnes after delay;  ---> ORIGINAL
end if; 
end process;

end basic;
    
