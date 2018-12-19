-- author: DATSI
-- http://www.datsi.fi.upm.es
-- License: GPLv3. See file: GPLv3License.txt

-- author: Salvador Gonzalez Garcia
-- Trabajo fin de grado sept-feb 2017-2018. 

library IEEE;
use IEEE.std_logic_1164.all;
use work.auxiliary.all;

entity Control is
    generic (
      delay          :     time:= 0 ns);
    port (
      -- Related to the ALU:
      AluInputASel    : out  std_logic:= '0'; -- selector de input 1 de la ALU (0 1)
      AluInputBSel    : out  std_logic:= '0'; -- selector de input 1 de la ALU (0 1)
      ALUcontrol     : out std_logic_vector(4 downto 0):= (others => '0');
      cin            : out std_logic:= '0';
      EnableALU      : out std_logic:= '0';
      -- Related to RegAux file
      LoadAux1      : out std_logic:= '0';
      LoadAux2      : out std_logic:= '0';
      EnableAux1    : out std_logic:= '0';
      EnableAux2    : out std_logic:= '0';
      --  Related to the register file:
      RS1sel         : out std_logic_vector(3 downto 0):= (others => '0');
      RS2sel         : out std_logic_vector(3 downto 0):= (others => '0');
      RDSel          : out std_logic_vector(3 downto 0):= (others => '0');
      EnableRS1      : out std_logic:= '0';
      EnableRS2      : out std_logic:= '0';
      LoadRD         : out std_logic:= '0';
      -- Related to the program counter:
      PCop           : out std_logic_vector(1 downto 0):= (others => '0');
      EnablePC       : out std_logic:= '0';
      --  Related to the condition code register:
      ZNVC           : in  std_logic_vector(3 downto 0);
      Intr           : inout std_logic:= '0';
      LoadCCR        : out std_logic:= '0';
      LoadSR         : out std_logic:= '0';
      EnableSR       : out  std_logic:= '0';
      YesJump	       : in std_logic;
      --  Related to the instruction register:
      Instruccion         : in  std_logic_vector(15 downto 0);
      Opcode         : in  std_logic_vector(3 downto 0);
      OpCodeExt      : in  std_logic_vector(3 downto 0);
      RS1IRsel       : in  std_logic_vector(3 downto 0);
      RS2IRsel       : in  std_logic_vector(3 downto 0);
      RDIRsel        : in  std_logic_vector(3 downto 0);
      LoadIReg       : out std_logic:= '0';
      EnableImmed    : out std_logic:= '0';
      EnableDisp     : out std_logic:= '0';
      --  Related to the tristate buffers interfacing memory:
      DriveMem       : out std_logic:= '0';
      DriveCPU       : out std_logic:= '0';  
      -- Related to the external memory:
      ReadMem        : out std_logic:= '0';
      WriteMem       : out std_logic:= '0';
      mhold          : in  std_logic;
      PrintMem       : out boolean;
      LoadMAR        : out std_logic:= '0';
      -- General:
      reset : in std_logic; -- Low level active.
      clock : in std_logic  -- Rising edge triggered.
      );
  end entity;



    
architecture Student of Control is

  type States is (Initial, ReadInst, Execute, Halted, Error, B1, B2, B3, B4, B5, B6, A1, A2, A3, A4, A5, A6, C1,D1,D2,D3,D4,D5,D6,D7,D8,D9,E1,E2,E3,E4,E5,E6,E7,E8,E9,F1,F2,F3,F4,F5,F6,F7,F8,F10,F11,F12,F13,F14);
  
  signal PresentState, FutureState: States;

begin
  
  -- proceso secuencial
  memoryUpdate: PROCESS(clock, reset)
  begin
    if reset = '0' then
      PresentState <= Initial after delay;
    elsif rising_edge(clock) then
      PresentState <= FutureState after delay;
    end if;
  end process;


  -- proceso combinacional 
  outputGeneration: process(PresentState, Opcode, mhold, YesJump )
  begin

    -- reiniciar las señales en cada ciclo de reloj
    EnableALU <= '0';
    LoadMAR <= '0';
    DriveCPU <= '0';
    DriveMem <= '0';
    LoadIReg <= '0';
    EnablePC <= '0';
    ReadMem <= '0';
    PCop <= SAMEPC;
    LoadRD <= '0';
    EnableRS1 <= '0';
    EnableRS2 <= '0';
    EnableDisp <= '0';
    EnableImmed <= '0';
    WriteMem <= '0';
    cin <= '0';
    LoadCCR <= '0';
    EnableAux1 <= '0';
    EnableAux2 <= '0';
    LoadAux1 <= '0';
    LoadAux2 <= '0';
    LoadSR <= '0';
    EnableSR <= '0';

    case PresentState is 
      
      when Initial =>

        -- ZNVC(10 downto 8)
        -- Comprobar si las interrupciones estan habilitadas
        -- si estan habilitadas (Ma'scara no es 000), comprobar interrupciones
        if Intr = '0'  -- Simplificado: Un solo nivel de prioridad de interrupcion.
        then
          EnablePC <= '1'; 
          ALUcontrol <= PASS_A;
          AluInputASel <= '0';
          EnableALU <= '1';
          LoadMAR <= '1';
          FutureState <= ReadInst;
          PCop <= INCRPC;

        else  -- Hacia RTI: SP - 1 -> SP;
          RS1sel <= "1111";
          AluInputASel <= '0';
          ALUcontrol <= DECR_WORD;
          RDsel <= "1111";
          EnableRS1 <= '1';
          LoadRD <= '1';
          enableALU <= '1';
          Intr <= '0';
          FutureState <= F1; -- comenzar guardado de SR y PC

        end if;

      when ReadInst => ReadMem <= '1';
        DriveCPU <= '1';
        LoadIReg <= '1';
        if mhold = '0' then
          FutureState <= ReadInst;
        else
          FutureState <= Execute;
        end if;

      when Execute =>





        --RTS. (SP) -> PC; SP + 1 -> SP
        if Instruccion(15 downto 0) = "0100111001110101"
        then
          RS1sel <= "1111";
          AluInputASel <= '0';
          ALUcontrol <= PASS_A;
          EnableRS1 <= '1';
          EnableALU <= '1';
          LoadMAR <= '1';
          FutureState <= D8;


        -- RTE, Return from Exception (Interrupciones).
        -- RTE: (SP) → SR; SP + 1 → SP; (SP) → PC; SP + 1 → SP;
        elsif Instruccion(15 downto 0) = "0100111001110011"
        then
          RS1sel <= "1111";
          AluInputASel <= '0';
          ALUcontrol <= PASS_A;
          EnableRS1 <= '1';
          EnableALU <= '1';
          LoadMAR <= '1';
          FutureState <= F10;


        elsif Instruccion(15 downto 0) = "0100111001110001"
        then
          FutureState <= initial;


        --LINK.
        --SP - 1 -> SP; An -> (SP); SP -> An; SP + dn -> SP. 2 downto 0 (register). Siguiente palabra desplazamiento.
        elsif Instruccion(15 downto 3) = "0100111001010"
        then
          RS1sel <= "1111";
          AluInputASel <= '0';
          ALUcontrol <= DECR_WORD;
          RDsel <= "1111";
          EnableRS1 <= '1';
          loadRD <= '1';
          enableALU <= '1';
          FutureState <= E1;

        --UNLINK
        -- AN -> SP; (SP) -> An; SP + 1 -> SP
        -- Loads the stack pointer from the specified address register, then loads the address register with the long word 
        -- pulled from  the top of the stack.
        elsif Instruccion(15 downto 3) = "0100111001011"
        then -- An -> SP.
          RS1sel <= '1' & Instruccion(2 downto 0);
          RDsel <= "1111"; 
          AluInputASel <= '0';
          ALUcontrol <= PASS_A;
          LoadRD <= '1';
          EnableRS1 <= '1';
          enableALU <= '1';
          FutureState <= E7;
        
        --BSR. SP - 1 -> SP; PC -> (SP); PC + dn -> PC 
        elsif Instruccion(15 downto 8) = "01100001"
        then
          RS1sel <= "1111";
          AluInputASel <= '0';
          ALUcontrol <= DECR_WORD;
          RDsel <= "1111";
          EnableRS1 <= '1';
          loadRD <= '1';
          enableALU <= '1';
          FutureState <= D3;

        -- BRA. salto relativo a PC: PC + desplazamiento(8 bits). Ahora mismo es un goto.
        elsif Instruccion(15 downto 8) = "01100000"
        then
          if Instruccion(7 downto 0) = "00000000" or Instruccion(7 downto 0) = "11111111" -- 16 bits desplazamiento. 1 palabra
          then
            EnablePC <= '1';
            AluInputASel <= '0';
            ALUcontrol <= PASS_A;
            EnableALU <= '1';
            LoadMAR <= '1';
            PCop <= INCRPC;
            FutureState <= D1;

          else -- desplazamiento en misma palabra que instruccion
            EnableDisp <= '1';
            EnablePC <= '1';
            AluInputBSel <= '0';
            AluInputASel <= '0';
            ALUcontrol <= ALU_ADD; -- ALU_ADDN2
            cin <= ('0' AND ZNVC(0)) XOR '0';
            EnableALU <= '1';
            PCop <= LOADPC;
            FutureState <= Initial;
          end if;

        
        -- Stop
        elsif Instruccion(15 downto 0) = "0000000000000000"  
        then
          FutureState <= Halted;

        -- BCC Branch conditionally
        elsif Instruccion (15 downto 12) = "0110" 
        then
          if YesJump = '1'
          then
            if Instruccion(7 downto 0) = "00000000" or Instruccion(7 downto 0) = "11111111" -- 16 bits desplazamiento. 1 palabra
            then
              EnablePC <= '1';
              AluInputASel <= '0';
              ALUcontrol <= PASS_A;
              EnableALU <= '1';
              LoadMAR <= '1';
              PCop <= INCRPC;
              FutureState <= D1;

            else -- desplazamiento en misma palabra que instruccion
              EnableDisp <= '1';
              EnablePC <= '1';
              AluInputBSel <= '0';
              AluInputASel <= '0';
              ALUcontrol <= ALU_ADD; -- ALU_ADDN2
              cin <= ('0' AND ZNVC(0)) XOR '0';
              EnableALU <= '1';
              PCop <= LOADPC;
              FutureState <= Initial;
            end if;

          else
            FutureState <= Initial;
            -- esta comprobacion es por si no hay que saltar, adelantar el PC para que ejecute un desplazamiento.
            if Instruccion(7 downto 0) = "00000000" or Instruccion(7 downto 0) = "11111111" 
            then
              PCop <= INCRPC;
            end if;
          end if;

        else

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------ Busqueda operando source -----------------------------
-------------------------------------------------------------------------------

          --Elige tipo de direccionamiento para operando source (Directo a registro, indirecto...)
          -- Estados B. Guarda el operando en Aux2.
          --operando source B (Estados B ).
          case Instruccion(5 downto 3) is
            when "000" => ALUcontrol <= PASS_B; -- Dn
              AluInputBSel <= '0';
              RS2sel <= '0' & Instruccion(2 downto 0); --RS1IRsel 
              EnableRS2 <= '1';
              EnableALU <= '1';
              LoadAux2 <= '1';      -- guarda el operando source en aux1
              FutureState <= A1;    -- Va al estado de buscar operando A

            when "001" => ALUcontrol <= PASS_B; -- An
              AluInputBSel <= '0';
              RS2sel <= '1' & Instruccion(2 downto 0); --RS1IRsel 
              EnableRS2 <= '1';
              EnableALU <= '1';
              LoadAux2 <= '1';      -- guarda el operando source en aux1
              FutureState <= A1;    -- Va al estado de buscar operando A

            when "010" =>  -- (An)
              ALUcontrol <= PASS_B; -- An
              AluInputBSel <= '0';
              RS2sel <= '1' & Instruccion(2 downto 0); --RS1IRsel 
              EnableRS2 <= '1';
              enableALU <= '1';
              loadMAR <= '1';
              FutureState <= B1;

            when "011" =>            ALUcontrol <= PASS_B; -- (An)+
              RS2sel <= '1' & Instruccion(2 downto 0); --RS1IRsel 
              AluInputBSel <= '0';
              EnableRS2 <= '1';
              enableALU <= '1';
              loadMAR <= '1';
              FutureState <= B2; -- (An)+

            when "100" =>  --  -(An)
              AluInputASel <= '0';
              -- Realiza primero el predecremento
              ALUcontrol <= DECR_WORD; --DECR_LONG; -- decrementar direccion long

              RS1sel <= '1' & Instruccion(2 downto 0); --RS1IRsel 
              RDsel <= '1' & Instruccion(2 downto 0); --RDsel
              EnableRS1 <= '1';
              enableALU <= '1';
              LoadRD <= '1';
              FutureState <= B1;  -- busca operando A

            when "101" =>  --  (d,An)
              -- primero recoge el desplazamiento de la siguiente palabra en pc
              EnablePC <= '1';
              AluInputASel <= '0';
              ALUcontrol <= PASS_A;
              EnableALU <= '1';
              LoadMAR <= '1';
              PCop <= INCRPC;
              FutureState <= B5; -- lee el desplazamiento

            when "111" =>  -- Inmediato
              -- primero recoge el dato inmediato de la siguiente palabra en pc
              EnablePC <= '1';
              AluInputASel <= '0';
              ALUcontrol <= PASS_A;
              EnableALU <= '1';
              LoadMAR <= '1';
              PCop <= INCRPC;
              FutureState <= B1; -- almacena el inmediato en aux
            
            when others => FutureState <= Error;

          end case;
        end if;


      when B1 => ReadMem <= '1'; -- Op B. (An). Buscar palabra -> AUX
        DriveCPU <= '1';
        LoadAux2 <= '1';
        ALUcontrol <= PASS_B;
        if mhold = '0' then
          FutureState <= B1; -- same state- retry
        else
          FutureState <= A1; -- next state
        end if;

      when B2 => ReadMem <= '1';    -- Op B. (An)+ Buscar palabra -> AUX
        DriveCPU <= '1';
        LoadAux2 <= '1';
        ALUcontrol <= PASS_B;

        if mhold = '0' then
          FutureState <= B2; -- same state- retry
        else
          FutureState <= B3; -- next state
        end if;

      when B3 =>    -- realiza el postincremento de la direccion
        AluInputASel <= '0';
        ALUcontrol <= INCR_WORD; --INCR_LONG; -- Incrementar direccion long
        RS1sel <= '1' & Instruccion(2 downto 0); --RS1IRsel 
        RDsel <= '1' & Instruccion(2 downto 0); --RDsel
        EnableRS1 <= '1';
        enableALU <= '1';
        LoadRD <= '1';
        FutureState <= A1;  -- busca operando A


      when B5 =>    -- Recoge el desplazamiento para el (d,An)
        ReadMem <= '1';    
        DriveCPU <= '1';
        LoadAux2 <= '1';

        if mhold = '0' then
          FutureState <= B5; -- same state- retry
        else
          FutureState <= B6; -- suma el desplazamiento
        end if;

      when B6 =>    -- suma el desplazamiento a la direccion para el (d,An)
        EnableAux2 <= '1'; -- esto no haria falta porque esta cableado a la ALU (no olvidar modificar el mux de ALU a esta entrada) 
        RS1sel <= '1' & Instruccion(2 downto 0); --RS2IRsel 
        EnableRS1 <= '1';
        AluInputASel <= '0'; -- input de la ALU de AUX
        AluInputBSel <= '1'; -- input de la ALU de AUX
        ALUcontrol <= ALU_ADD;
        enableALU <= '1';
        loadMAR <= '1';
        FutureState <= B1;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------ Busqueda operando destino ----------------------------
-------------------------------------------------------------------------------

      -- El estado A1 es para elegir tipo de direccionamiento (Directo a registro, indirecto...)
      when A1 =>      -- Busca el operando A (destination)
        -- almacena el operando en aux1. 
        case Instruccion(8 downto 6) is 
          when "000" =>  --Dn
            ALUcontrol <= PASS_A; -- Dn
            RS1sel <= '0' & Instruccion(11 downto 9); --RS2IRsel 
            EnableRS1 <= '1';
            AluInputASel <= '0'; -- input de la ALU de AUX
            EnableALU <= '1';
            LoadAux1 <= '1';      -- guarda el operando destino en aux2
            FutureState <= C1;    -- Realiza la ejecucion de la instruccion

          when "001" =>  --An -- MOVEA (para registro direccion)
            ALUcontrol <= PASS_A; -- An
            AluInputASel <= '0';
            RS1sel <= '1' & Instruccion(11 downto 9); --RS2IRsel 
            EnableRS1 <= '1';
            EnableALU <= '1';
            LoadAux1 <= '1';      -- guarda el operando destino en aux2
            FutureState <= C1;    -- Realiza la ejecucion de la instruccion

          when "010" =>  --(An)
            ALUcontrol <= PASS_A; -- An
            AluInputASel <= '0';
            RS1sel <= '1' & Instruccion(11 downto 9); --RS1IRsel 
            EnableRS1 <= '1';
            enableALU <= '1';
            loadMAR <= '1';
            FutureState <= A2;

          when "011" =>  --(An)+
            ALUcontrol <= PASS_A; -- (An)+
            RS1sel <= '1' & Instruccion(11 downto 9); --RS1IRsel 
            AluInputASel <= '0';
            EnableRS1 <= '1';
            enableALU <= '1';
            loadMAR <= '1';
            FutureState <= A3; -- (An)+

          when "100" =>  -- -(An)
            AluInputASel <= '0';
            -- Realiza primero el predecremento
            ALUcontrol <= DECR_WORD; -- decrementar direccion long
            RS1sel <= '1' & Instruccion(11 downto 9); --RS1IRsel 
            RDsel <= '1' & Instruccion(11 downto 9); --RDsel
            EnableRS1 <= '1';
            enableALU <= '1';
            LoadRD <= '1';
            FutureState <= A2;  -- busca palabra en memoria para AUX2

          when "101" =>  -- X(An)
            -- primero recoge el desplazamiento de la siguiente palabra en pc
            EnablePC <= '1';
            AluInputASel <= '0';
            ALUcontrol <= PASS_A;
            EnableALU <= '1';
            LoadMAR <= '1';
            PCop <= INCRPC;
            FutureState <= A5; -- lee el desplazamiento

          when others => FutureState <= Error;

        end case;

      when A2 => ReadMem <= '1'; -- Op A. (An). Buscar palabra -> AUX2
        DriveCPU <= '1';
        LoadAux1 <= '1';
        ALUcontrol <= PASS_A;
        if mhold = '0' then
          FutureState <= A2; -- same state- retry
        else
          FutureState <= C1; -- next state
        end if;

      when A3 => ReadMem <= '1'; -- Op A. (An). Buscar palabra -> AUX2
        DriveCPU <= '1';
        LoadAux1 <= '1';

        if mhold = '0' then
          FutureState <= A3; -- same state- retry
        else
          FutureState <= A4; -- next state
        end if;

      when A4 => -- realiza el postincremento de la direccion
        AluInputASel <= '0';
        ALUcontrol <= INCR_WORD; -- Incrementar direccion long
        RS1sel <= '1' & Instruccion(11 downto 9); --RS1IRsel 
        RDsel <= '1' & Instruccion(11 downto 9); --RDsel
        EnableRS1 <= '1';
        enableALU <= '1';
        LoadRD <= '1';
        FutureState <= C1;  -- pasa a terminar de ejecutar y transferir la instruccion

      when A5 =>    -- Recoge el desplazamiento para el (d,An)
        ReadMem <= '1';    
        DriveCPU <= '1';
        LoadAux1 <= '1';

        if mhold = '0' then
          FutureState <= A5; -- same state- retry
        else
          FutureState <= A6; -- suma el desplazamiento
        end if;

      when A6 =>    -- suma el desplazamiento a la direccion para el (d,An)
        enableAUX1 <= '1'; -- esto no haria falta porque esta cableado a la ALU (no olvidar modificar el mux de ALU a esta entrada) 
        RS2sel <= '1' & Instruccion(11 downto 9); --RS1IRsel 
        EnableRS2 <= '1';
        AluInputBSel <= '0'; -- input de la ALU de AUX
        AluInputASel <= '1'; -- input de la ALU de AUX        
        ALUcontrol <= ALU_ADD;
        enableALU <= '1';
        loadMAR <= '1';
        FutureState <= A2;


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------ Ejecucion principal instrucciones  -------------------
-------------------------------------------------------------------------------


      -- Ejecucion de instrucciones principales. Estado C1.
      when C1 =>
        case Instruccion(15 downto 12) is
          when "0001" =>  -- move
            ALUcontrol <= PASS_B;

          when "0011" =>  --move 
            ALUcontrol <= PASS_B;

          when "0010" =>  --move
            ALUcontrol <= PASS_B;

          when "1101" =>  --add/adda
            ALUcontrol <= ALU_ADD;
            cin <= ('0' AND ZNVC(0)) XOR '0'; -- cin <= (OpCodeExt(1) AND ZNVC(0)) XOR OpCodeExt(0);

          when "1100" =>  --and
            ALUcontrol <= ALU_AND;

          when "1011" =>  --cmp
            ALUcontrol <= ALU_ADDN2;
            cin <= ('0' AND ZNVC(0)) XOR '1'; -- UCC = 0, CC = 1

          when "1000" =>  --or
            ALUcontrol <= ALU_OR;

          when "1001" =>  --sub/suba
            ALUcontrol <= ALU_ADDN2;
            cin <= ('0' AND ZNVC(0)) XOR '1'; -- UCC = 0, CC = 1

          when others => FutureState <= Error;
        end case;

        AluInputASel <= '1';
        AluInputBSel <= '1';
        EnableAux1 <= '1';
        EnableAux2 <= '1';
        enableALU <= '1';
        loadCCR <= '1';   -- actualiza el condition code register
        if Instruccion( 15 downto 12 ) = "1011" then -- caso para CMP.
          FutureState <= Initial;
        elsif Instruccion(8 downto 6) = "000" then -- caso destino en registro Dn
          RDSel <= '0' & Instruccion(11 downto 9); --RDsel
          LoadRD <= '1';
          FutureState <= Initial;
        elsif Instruccion(8 downto 6) = "001" then  -- caso destino en registro An
          RDSel <= '1' & Instruccion(11 downto 9); --RDsel
          LoadRD <= '1';
          FutureState <= Initial;

        else
          --FutureState <= C2;
          DriveMem <= '1';
          WriteMem <= '1';
          if mhold = '0' then
            FutureState <= C1;
          else
            FutureState <= Initial;
          end if;
        end if;
          

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------ Continuacion Saltos y Retornos -----------------------
-------------------------------------------------------------------------------         

      -- Estados de salto y retorno de subrutina. Continuacion. Estados D.
      
      when D1 => -- BRA una palabra. Load Aux
        ReadMem <= '1'; --
        DriveCPU <= '1';
        LoadAux2 <= '1';
        --PCop <= LOADPC;
        if mhold = '0' then
          FutureState <= D1; -- same state- retry
        else
          FutureState <= D2; -- next state
        end if;

      -- BRA
      when D2 =>
        EnablePC <= '1';
        EnableAux2 <= '1';
        AluInputASel <= '0';
        AluInputBSel <= '1';
        ALUcontrol <= ALU_ADD;
        cin <= ('0' AND ZNVC(0)) XOR '0';
        enableALU <= '1';
        PCop <= LOADPC;
        FutureState <= Initial;
      
      --BSR. PC -> (SP)
      when D3 => 
        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableRS1 <= '1';
        EnableALU <= '1';
        LoadMAR <= '1';
        FutureState <= D4;

      --BSR. PC -> (SP)
      when D4 =>
        EnablePC <= '1';
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableALU <= '1';
        DriveMem <= '1';
        WriteMem <= '1';
        if mhold = '0' then
          FutureState <= D4;
        else
          FutureState <= D5;
        end if;

      --BSR. PC + dn -> PC 
      when D5 =>
        if Instruccion(7 downto 0) = "00000000" or Instruccion(7 downto 0) = "11111111" then
          EnablePC <= '1';
          AluInputASel <= '0';
          ALUcontrol <= PASS_A;
          EnableALU <= '1';
          LoadMAR <= '1';
          PCop <= INCRPC;
          FutureState <= D6; -- busca el desplazamiento en siguiente palabra.

        else
          EnablePC <= '1';
          EnableDisp <= '1';
          AluInputASel <= '0';
          AluInputBSel <= '0';
          ALUcontrol <= ALU_ADD; -- ALU_ADDN2
          cin <= ('0' AND ZNVC(0)) XOR '0';
          enableALU <= '1';
          PCop <= LOADPC;
          FutureState <= Initial;
        end if;

      --BSR. PC + dn(32) -> PC 
      when D6 =>
        ReadMem <= '1';
        DriveCPU <= '1';
        LoadAux2 <= '1';
        if mhold = '0' then
          FutureState <= D6; -- same state- retry
        else
          FutureState <= D7; -- next state
        end if;

      --BSR. PC + dn(32) -> PC 
      when D7 =>
        EnablePC <= '1';
        EnableAux2 <= '1';
        AluInputASel <= '0';
        AluInputBSel <= '1';
        ALUcontrol <= ALU_ADD; -- ALU_ADDN2
        cin <= ('0' AND ZNVC(0)) XOR '0';
        enableALU <= '1';
        PCop <= LOADPC;
        FutureState <= Initial;

      --RTS. (SP) -> PC
      when D8 =>
        DriveCPU <= '1';
        ReadMem <= '1';
        LoadAux1 <= '1';
        if mhold = '0' then
          FutureState <= D8;
        else
          FutureState <= D9;
        end if;

      --RTS. (SP) -> PC
      when D9 => 
        AluInputASel <= '1';
        EnableAux1 <= '1';
        ALUcontrol <= PASS_A;
        enableALU <= '1';
        PCop <= LOADPC;
        FutureState <= E9; -- SP + 1 -> SP


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------ Continuacion LINK/UNLINK -----------------------------
-------------------------------------------------------------------------------

      -- Continuacion de las instrucciones LINK y UNLINK para marco de pila. Estados E.

      -- LINK An -> (SP); Carga puntero de pila para escribir
      when E1 => 
        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableRS1 <= '1';
        EnableALU <= '1';
        LoadMAR <= '1';
        FutureState <= E2;

      -- LINK An -> (SP); Escribe en la pila
      when E2 => 
        RS1sel <=  '1' & Instruccion(2 downto 0);
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableRS1 <= '1';
        EnableALU <= '1';
        DriveMem <= '1';
        WriteMem <= '1';
        if mhold = '0' then
          FutureState <= E2;
        else
          FutureState <= E3;
        end if;

      --LINK. SP -> An. Mete la direccion del puntero de pila en An
      when E3 => 
        RS1sel <=  "1111";
        RDsel <= '1' & Instruccion(2 downto 0);
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        LoadRD <= '1';
        EnableRS1 <= '1';
        enableALU <= '1';
        FutureState <= E4;

      --LINK. SP + dn -> SP. Puntero de pila + desplazamiento.
      when E4 => 
        EnablePC <= '1';
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableALU <= '1';
        LoadMAR <= '1';
        PCop <= INCRPC;
        FutureState <= E5; -- almacena el inmediato en aux
      
      --LINK. SP + dn -> SP. Recoge el desplazamiento en el registro auxiliar2
      when E5 =>
        ReadMem <= '1';
        DriveCPU <= '1';
        LoadAux2 <= '1';
        if mhold = '0' then
          FutureState <= E5; -- same state- retry
        else
          FutureState <= E6; -- next state
        end if;

      --LINK. SP + dn -> SP. Suma registro y desplazamiento y lo guarda en registro puntero de pila.
      when E6 =>
        RS1sel <= "1111";
        RDsel <= "1111" ;
        AluInputASel <= '0';
        AluInputBSel <= '1';
        ALUcontrol <= ALU_ADD;
        cin <= ('0' AND ZNVC(0)) XOR '0';
        LoadRD <= '1';
        EnableRS1  <= '1';
        EnableAux2 <= '1';
        enableALU <= '1';
        FutureState <= Initial;

      --UNLINK. (SP) -> An
      when E7 =>
        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableRS1 <= '1';
        EnableALU <= '1';
        LoadMAR <= '1';
        FutureState <= E8;

      -- UNLINK. (SP) -> An
      when E8 =>
        DriveCPU <= '1';
        ReadMem <= '1';
        RDsel <=  '1' & Instruccion(2 downto 0);
        LoadRD <= '1';

        if mhold = '0' then
          FutureState <= E8;
        else
          FutureState <= E9;
        end if;

      --SP + 1 -> SP
      when E9 =>
        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= INCR_WORD;
        RDsel <= "1111";
        EnableRS1 <= '1';
        LoadRD <= '1';
        enableALU <= '1';
        FutureState <= Initial;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------ Interrupciones ---------------------------------------
-------------------------------------------------------------------------------

      -- Continuacion de Interrupciones. Interrupcion, Rutina de tratamiento 
      -- de interrupcion y retorno de interrupcion. Estados F.

      -- interrupcion: PC -> (SP). Carga (SP)
      when F1 =>

        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableRS1 <= '1';
        EnableALU <= '1';
        LoadMAR <= '1';
        FutureState <= F2;

      -- Interrupcion: PC -> (SP). Guarda el PC en la direccion cargada (SP).
      when F2 =>
        EnablePC <= '1';
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableALU <= '1';
        DriveMem <= '1';
        WriteMem <= '1';
        if mhold = '0' then
          FutureState <= F2;
        else
          FutureState <= F3;
        end if;

      -- Interrupcion: SP - 1 -> SP
      when F3 =>
        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= DECR_WORD;
        RDsel <= "1111";
        EnableRS1 <= '1';
        LoadRD <= '1';
        enableALU <= '1';
        FutureState <= F4; -- comenzar guardado de SR

      -- Interrupcion. Guarda SR en PC. SR -> (SP). Primero carga la direccion (SP)
      when F4 =>
        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableRS1 <= '1';
        EnableALU <= '1';
        LoadMAR <= '1';
        FutureState <= F5;

      --Interrupcion. SR -> (SP). RTI -> PC
      when F5 =>
        EnableSR <= '1'; --- Acceso de State register a los buses
        DriveMem <= '1';
        WriteMem <= '1';
        PCop <= RTIPC;
        if mhold = '0' then
          FutureState <= F5;
        else
          FutureState <= Initial;
        end if;


      -- RTE: (SP) → SR; SP + 1 → SP; (SP) → PC; SP + 1 → SP;
      when F10 =>
        DriveCPU <= '1';
        ReadMem <= '1';

        LoadSR <= '1';  -- Cargar Registro de Estado.

        if mhold = '0' then
          FutureState <= F10;
        else
          FutureState <= F11;
        end if;

      -- RTE: SP + 1 → SP; (SP) → PC; SP + 1 → SP;
      when F11 =>
        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= INCR_WORD;
        RDsel <= "1111";
        EnableRS1 <= '1';
        LoadRD <= '1';
        enableALU <= '1';
        FutureState <= F12;

      -- RTE: (SP) → PC; SP + 1 → SP;
      when F12 => 
        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= PASS_A;
        EnableRS1 <= '1';
        EnableALU <= '1';
        LoadMAR <= '1';
        FutureState <= F13;

      -- RTE: (SP) → PC; SP + 1 → SP;
      when F13 =>
        DriveCPU <= '1';
        ReadMem <= '1';
        PCop <= LOADPC;
        if mhold = '0' then
          FutureState <= F13;
        else
          FutureState <= F14;
        end if;

      -- RTE: SP + 1 → SP;
      when F14 =>
        RS1sel <= "1111";
        AluInputASel <= '0';
        ALUcontrol <= INCR_WORD;
        RDsel <= "1111";
        EnableRS1 <= '1';
        LoadRD <= '1';
        enableALU <= '1';
        FutureState <= Initial;


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
------------------------ Otros estados ----------------------------------------
-------------------------------------------------------------------------------

      -- Estados de finalizacion y error

      when Halted => FutureState <= Halted;
        PrintMem <= True;

      when Error => FutureState <= Error;

      when others => FutureState <= Error;



    end case;

  end process;





end architecture;











			
