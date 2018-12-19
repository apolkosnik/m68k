-- author: Salvador Gonzalez

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.auxiliary.all;

entity RegAux is
    generic (
      delay   :     time);
    port (
      BusAux1      : out std_logic_vector(31 downto 0); -- 32 bits de bus de datos
      BusAux2      : out std_logic_vector(31 downto 0); -- 32 bits de bus de datos
      Busd      : in  std_logic_vector(31 downto 0); -- 32 bits de bus de datos
      EnableAux1 : in  std_logic;
      EnableAux2 : in  std_logic;
      LoadAux1    : in  std_logic;
      LoadAux2    : in  std_logic;
      reset : in std_logic;             -- Low level active
      clock : in std_logic);            -- Rising edge triggered
end entity; 

architecture RegAuxArch of RegAux is
 signal Aux1Val: std_logic_vector(31 downto 0);
 signal Aux2Val: std_logic_vector(31 downto 0);
 constant Allzeros : std_logic_vector(31 downto 0):= (others => '0');
begin

Sequential1: process(clock, reset)     --carga el registro Aux1
begin
if reset = '0' then 
     Aux1Val <= Allzeros;
elsif rising_edge(clock) then
  if (LoadAux1 = '1') then
      Aux1Val <= busd and Allones;
  end if;
end if;
end process;

Sequential2: process(clock, reset)     --carga el registro Aux1
begin
if reset = '0' then 
     Aux2Val <= Allzeros;
elsif rising_edge(clock) then
  if (LoadAux2 = '1') then
      Aux2Val <= busd and Allones;
  end if;
end if;
end process;

BusAux1Output: process(EnableAux1, Aux1Val)   -- enable Aux1
begin
  if EnableAux1 = '1'  then BusAux1 <= Aux1Val after delay;
  else BusAux1 <= HighImpedance after delay;
  end if;
end process;

BusAux2Output: process(EnableAux2, Aux2Val)   -- enable Aux1
begin
  if EnableAux2 = '1'  then BusAux2 <= Aux2Val after delay;
  else BusAux2 <= HighImpedance after delay;
  end if;
end process;

end RegAuxArch;





