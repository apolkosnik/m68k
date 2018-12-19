-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;


entity Test is
end entity Test;


architecture Expected of Test is

signal addr     : std_logic_vector(23 downto 0);  -- bus de datos de 24 bits. o es de 23 bits?
signal data     : std_logic_vector(31 downto 0);
signal mhold    : std_logic;
signal ReadMem  : std_logic;
signal WriteMem : std_logic;
signal PrintMem : boolean:= false;
signal clock    : std_logic:= '0';
signal reset    : std_logic;

constant delay: time:= 0 ns;
begin	

TheCPU: entity work.CPU2017(minimum) 
  generic map(
            delay => delay)
  port map( 
		addr => addr,
		data => data,
		ReadMem => ReadMem,
		WriteMem => WriteMem,
		mhold => mhold,
		PrintMem => PrintMem,
		clock => clock,
		reset => reset);    


MemorySystem: entity work.Memory(functional) 
  port map(
    		addr => addr,
    		data => data,
    		ReadMem => ReadMem,
    		WriteMem => WriteMem,
		PrintMem => PrintMem,      
    		mhold => mhold,
    		clock => clock );

clock <= not clock after 5 ns; -- Clock cycle of 10 ns
reset <= '0', '1' after 10 ns;

end architecture;
