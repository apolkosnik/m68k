-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;
use work.auxiliary.all;

entity CondCodeRegister is
    generic (
      delay   :     time);
    -- Procesor State Register
    port (
      Busd            : inout std_logic_vector(31 downto 0);
      ZNVC            : out std_logic_vector(3 downto 0);
      --IntMask         : out std_logic_vector(2 downto 0);
      DCCR            : in  std_logic_vector(3 downto 0);
      LoadCCR         : in  std_logic;   
      LoadSR          : in  std_logic; 
      EnableSR        : in  std_logic; 
      reset : in std_logic;
      clock : in std_logic);
end CondCodeRegister;

architecture FourBits of CondCodeRegister is
  signal StateRegister: std_logic_vector(3 downto 0);
  begin

  LoadTheRegister: process(clock, reset)
  begin
    if reset = '0' then
      ZNVC <= "0000" after delay; -- 0X0XX000XXXX0000
      StateRegister <= "0000" after delay;
    elsif rising_edge(clock) and LoadCCR = '1' then
      ZNVC <= DCCR after delay;
    elsif rising_edge(clock) and LoadSR = '1' then
      ZNVC <= busd(3 downto 0) after delay;
    end if;
  end process;


  --  BackupStateRegister: process(clock, reset)
  --  begin
  --     if reset = '0' then StateRegister <= "0000" after delay;
  --     elsif rising_edge(clock) and LoadSR = '1' then
  --         ZNVC <= busd(3 downto 0) after delay;
  --       --StateRegister <= busd(3 downto 0) after delay;
  --       --ZNVC <= StateRegister after delay;
  --     end if;
  --   end process;


    OutputState: process(EnableSR, StateRegister)
    begin
      if EnableSR = '1'  
      then
       --StateRegister <= DCCR; 
       --Busd(3 downto 0) <= StateRegister after delay;
       Busd(3 downto 0) <= DCCR after delay;
      else Busd <= HighImpedance after delay;
      end if;  

 end process;





end FourBits;

