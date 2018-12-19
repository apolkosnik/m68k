-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

library IEEE;
use IEEE.std_logic_1164.all;
use work.auxiliary.all;
use ieee.numeric_std.all;

entity ALU is
    generic (
      delay    :     time);
    port (
      AluInputASel: in  std_logic;                     -- selector de input 1 (A) de la ALU (0 1)
      AluInputBSel: in  std_logic;                     -- selector de input 2 (B) de la ALU (0 1)
      Ainput     : in  std_logic_vector(31 downto 0); -- Entrada A de la ALU
      A2input     : in  std_logic_vector(31 downto 0); -- Entrada A2 de la ALU
      Binput     : in  std_logic_vector(31 downto 0); -- Entrada B de la ALU
      B2input     : in  std_logic_vector(31 downto 0); -- Entrada B2 de la ALU
      ALUout     : out std_logic_vector(31 downto 0);	
      ALUcontrol : in  std_logic_vector(4 downto 0); 
      cin        : in  std_logic;
      EnableALU  : in  std_logic;
      DCCR       : out std_logic_vector(3 downto 0));
end entity;

architecture functional of ALU is

begin

  CalculateEverything: process(Ainput, A2input, Binput,B2input, ALUcontrol, cin, AluInputASel,AluInputBSel) 
      variable carry: std_logic_vector(32 downto 0);
      variable Bxored: std_logic_vector(31 downto 0);
      variable ALUsal: std_logic_vector(31 downto 0);
      variable Avar, Bvar, Inc, Incxored: std_logic_vector(31 downto 0);
      variable Z: std_logic;
      variable ibit: std_logic;

  begin
  -- This first two statemens are only meant to prevent ALU from putting all Z
  -- in its output when some input is all Z and it must pass that input without
  -- modifying it. When performing an And with a '1', the 'Z' values are
  -- converte into 'X' values, which is what physically makes sense, apart form
  -- the fact that it won't confuse us with having not enabled the output.
if AluInputASel = '0' then
  Avar := Ainput and AllOnes;   -- Cuiadao con la entrada de la ALUUUUUUU!!!!! LOKOOOOO
  else
    Avar := A2input and AllOnes;
end if;

if AluInputBSel = '0' then
  Bvar := Binput and AllOnes;   -- Cuiadao con la entrada de la ALUUUUUUU!!!!!
  else
    Bvar := B2input and AllOnes;
end if;

    
  for i in 0 to 31 loop
    Bxored(i) := Bvar(i) xor ALUcontrol(3);
  end loop;
  carry(0) := cin;
  Inc := "00000000000000000000000000000001";
  case ALUcontrol is
        -- In the first two cases one should not bother to calculate the
        -- condition codes, because they are not going to be stored.
	when PASS_A => 
	   ALUsal := Avar; DCCR <= "0000" after delay;
   	when PASS_B => 
	   ALUsal := Bvar; DCCR <= "0000" after delay;
    when INCR_WORD =>         
--        for i in 0 to 31 loop
--            Incxored(i) := Inc(i) xor ALUcontrol(3); -- Cuidado de esto con ALUCONTROl, ver que es en ADD
--            ALUsal(i):= Avar(i) xor Incxored(i) xor carry(i);
--            carry(i+1) :=  (Avar(i) and Incxored(i)) or (Avar(i) and carry(i)) or (Incxored(i) and carry(i)); 
--	    end loop;
        for i in 0 to 31 loop
            Bxored(i) := Inc(i) xor '0';
        end loop;
        carry(0) := '0';
         Z:= '1';
         for i in 0 to 31 loop
            ALUsal(i):= Avar(i) xor Bxored(i) xor carry(i);
            Z:= Z and (not ALUsal(i));
            carry(i+1) :=  (Avar(i) and Bxored(i)) or (Avar(i) and carry(i)) or (Bxored(i) and carry(i)); 
	    end loop;
	    DCCR <= Z & ALUsal(31) & (carry(32) xor carry(31)) & carry(32) after delay;


    when ALU_SUB =>
        Z:= '1';
        for i in 0 to 31 loop
            ALUsal(i):= Avar(i) xor Bvar(i) xor carry(i);
            Z:= Z and (not ALUsal(i));
            carry(i+1) := (((not Avar(i)) and Bvar(i)) or not( Avar(i) xor ( Bvar(i)))) and carry(i); --(Avar(i) and (not carry(i))) or (Avar(i) and (not Bxored(i))) or (Bxored(i) and carry(i));        
        end loop;

    when DECR_WORD =>
--        for i in 0 to 31 loop
--            ALUsal(i):= Avar(i) xor Inc(i) xor carry(i);
--            carry(i+1) := (((not Avar(i)) and Inc(i)) or (not Avar(i) xnor (not Inc(i)))) and carry(i); --(Avar(i) and (not carry(i))) or (Avar(i) and (not Bxored(i))) or (Bxored(i) and carry(i));        
--       end loop;
        for i in 0 to 31 loop
            Bxored(i) := Inc(i) xor '1';
        end loop;
        carry(0) := '1';
         Z:= '1';
         for i in 0 to 31 loop
            ALUsal(i):= Avar(i) xor Bxored(i) xor carry(i);
            Z:= Z and (not ALUsal(i));
            carry(i+1) :=  (Avar(i) and Bxored(i)) or (Avar(i) and carry(i)) or (Bxored(i) and carry(i)); 
	    end loop;
	    DCCR <= Z & ALUsal(31) & (carry(32) xor carry(31)) & carry(32) after delay;


  	when ALU_ADD | ALU_ADDN2 => 
         Z:= '1';
         for i in 0 to 31 loop
            ALUsal(i):= Avar(i) xor Bxored(i) xor carry(i);
            Z:= Z and (not ALUsal(i));
            carry(i+1) :=  (Avar(i) and Bxored(i)) or (Avar(i) and carry(i)) or (Bxored(i) and carry(i)); 
	    end loop;
	    DCCR <= Z & ALUsal(31) & (carry(32) xor carry(31)) & carry(32) after delay;
	when ALU_AND | ALU_ANDN2 =>
	    Z:= '1';
    	    for i in 0 to 31 loop
		ALUsal(i) := Avar(i) and Bxored(i);
		Z:= Z and (not ALUsal(i));
            end loop;
	    DCCR <= Z & ALUsal(31) & "00" after delay;
	when ALU_OR | ALU_ORN2 =>
	    Z:= '1';
    	    for i in 0 to 31 loop
		ALUsal(i) := Avar(i) or Bxored(i);
		Z:= Z and (not ALUsal(i));
            end loop;
	    DCCR <= Z & ALUsal(31) & "00" after delay;
	when ALU_NOR | ALU_NORN2 =>
	    Z:= '1';
    	    for i in 0 to 31 loop
		ALUsal(i) := Avar(i) nor Bxored(i);
		Z:= Z and (not ALUsal(i));
            end loop;
	    DCCR <= Z & ALUsal(31) & "00" after delay;           
	when ALU_XOR | ALU_XORN2 =>
    	    Z:= '1';
	    for i in 0 to 31 loop
		ALUsal(i) := Avar(i) xor Bxored(i);
		Z:= Z and (not ALUsal(i));
            end loop;
	    DCCR <= Z & ALUsal(31) & "00" after delay;
	when others =>
	    ALUsal := (others => 'X');
            DCCR <= "XXXX" after delay;
   end case;
   if EnableALU = '1' then 
      ALUout <= ALUsal after delay; 
   else 
      ALUout <= HighImpedance after delay;
   end if;
end process;

end architecture;


	
