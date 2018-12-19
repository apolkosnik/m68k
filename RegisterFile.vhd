-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.auxiliary.all;

entity RegisterFile is
    generic (
      delay   :     time);
    port (
      RS1Sel    : in  std_logic_vector(3 downto 0); -- 8 registros de direcciones y 8 de datos
      RS2Sel    : in  std_logic_vector(3 downto 0); -- 8 registros de direcciones y 8 de datos
      RDSel     : in  std_logic_vector(3 downto 0); -- 8 registros de direcciones y 8 de datos
      Bus1      : out std_logic_vector(31 downto 0); -- 16 bits de bus de datos
      Bus2      : out std_logic_vector(31 downto 0); -- 16 bits de bus de datos
      Busd      : in  std_logic_vector(31 downto 0); -- 16 bits de bus de datos
      EnableRS1 : in  std_logic;
      EnableRS2 : in  std_logic;
      LoadRD    : in  std_logic;
      reset : in std_logic;             -- Low level active
      clock : in std_logic);            -- Rising edge triggered
end entity;

-- 0 000 D0
--   ...
-- 0 111 D7

-- 1 000 A0
--   ...
-- 1 111 A7

architecture VerySimple of RegisterFile is
 signal Bank: MultipleRegs(0 to 15);
 constant Allzeros : std_logic_vector(31 downto 0):= (others => '0');
begin

Sequential: process(clock, reset)
  variable index: natural;
begin
if reset = '0' then 
   for i in 0 to 15 loop
     Bank(i) <= Allzeros;
   end loop;
elsif rising_edge(clock) then
  if (LoadRD = '1') then
    index := TO_INTEGER(UNSIGNED(RDSel));
    if index /= 0 then 
      Bank(index) <= Busd and Allones;
     end if;
   end if;
end if;
end process;

-- meter condiciones para 3 sizes: Byte, word y long con 1 signal auxiliar en plan SizeBus 00, 01, 11.

Bus1Output: process(RS1Sel, EnableRS1, Bank)
  variable index: natural;
begin
  index:= TO_INTEGER(UNSIGNED(rs1Sel));
  if EnableRS1 = '1'  then Bus1 <= Bank(index) after delay;
  else Bus1 <= HighImpedance after delay;
  end if;
end process;

Bus2Output: process(RS2Sel, EnableRS2, Bank)
  variable index: natural;
begin
  index:= TO_INTEGER(UNSIGNED(rs2Sel));
  if EnableRS2 = '1'  then Bus2 <= Bank(index) after delay;
  else Bus2 <=HighImpedance after delay;
  end if;
end process;

end VerySimple;





