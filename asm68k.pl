#!/usr/bin/perl

$WordSize = 32;

%OpCodes4 =
    (

     MOVE, "0001",
     MOVE, "0011",
     MOVE, "0010",
     ADD, "1101", 
     ADDA, "1101",    
     AND, "1100",
     CMP,  "1011",
     OR, "1000", 
     SUB, "1001",    
     SUBA, "1001" 


);    

%OpCodes8 =
    (BSR, "01100001",
     BRA, "01100000",    

     BCC, "01100000",
     BCS, "01100001",
     BEQ, "01100010",
     BF,  "01101111",
     BGE, "01100011",
     BGT, "01100100",
     BHI, "01100101",
     BLS, "01100111",
     BLE, "01100110",
     BLT, "01101000",
     BMI, "01101001",
     BNE, "01101010",
     BPL, "01101011",
     BT,  "01101110",
     BVC, "01101100",
     BVS, "01101101"
          

    );

%OpCodes13 =
    (LINK, "0100111001010",
     UNLK, "0100111001011"    

    );

%Registers =
    (
    D0, "000",
    D1, "001",
    D2, "010",
    D3, "011",
    D4, "100",
    D5, "101",
    D6, "110",
    D7, "111",    
    A0, "000",
    A1, "001",
    A2, "010",
    A3, "011",
    A4, "100",
    A5, "101",
    A6, "110",
    A7, "111"
    );

%RegisterModes =
    (     
    RegistroDatos, "000",
    RegistroDireccion, "001",
    IndirectoRegistro, "010",
    Postincremento, "011",
    Predecremento, "100",
    RelativoBase, "101",
    Inmediato, "111"
    );
    

sub ToBinStr {
# Converts a number into the binary string which is its two's
# complement representation. Needs the number and the size of the
# string to which it is going to be converted.  If it doesn't fit in
# that size it warns and produces a message in the errorlog file.
    
    local($number, $size) = @_;
    $limit = 2**($size -1);
    if ($number > $limit -1 || $number < -$limit){
	print($ERRORLOG "Bad value: $number in line: $linenumber\n");
	return "-INVALID-";}
    elsif($number < 0){
	$number += 2**$size;}
    $string="";
    for($i=1; $i <= $size ; $i++){
	if ($number % 2){
	    $string="1".$string;}
	else{
	    $string="0".$string;} 
	$number/=2;
    }
    return $string;
}


$linenumber=0;    
$filename = $ARGV[0];
$preword = "0000000000000000";
open ($AsmFile,"<", $filename) || die "can't open $filename for reading: $!\n";
open ($OUTPUT, " >", "out.txt") || die "can't open out.txt for writing: $!\n";
open ($ERRORLOG, " >", "ERRORS.txt") || die "can't open ERRORS.txt for writing: $!\n";

while(<$AsmFile>){
    $linenumber++;


    # STOP
    if (/STOP\s*(.*)/){
	    print($OUTPUT $preword,"0000000000000000 ", ": STOP ", "\n");
    }

    # RTE
    elsif (/RTE\s*(.*)/){
	    print($OUTPUT $preword,"0100111001110011 ", ": RTE ", "\n");
    }
    # RTS
    elsif (/RTS\s*(.*)/){
	    print($OUTPUT $preword,"0100111001110101 ", ": RTS ", "\n");
    }
    # NOP
    elsif(/NOP\s*(.*)/){
        print($OUTPUT $preword,"0100111001110001 ", ": NOP ", "\n");
    }

    # Inmediato.
    elsif (/\s*(\w+)\s+(#(\-?)(\d+)),(D\d|A\d|\(A\d\)\+?|\-?\(A\d\)|\(A\d\)|\(#(\-?)\d+,A\d\))\s*(.*)/){
        
        # $1 opcode. $2 Immediate. $3 sign. $4 value. $5 destiny. $6 comment
        $match1 = $1;
        $match2 = $2;
        $match3 = $3;
        $match4 = $4;
        $match5 = $5;
        $match6 = $6;
        $TheInstrCode=$OpCodes4{$1}; # This is the opcode in binary
        $SMode = "111"; 
        $SReg = "010";
        $DReg = "";
        $DMode = "";
        $InmediatoDestino = "";
        $Sign = $3;
        $Value = $4;
        $Value =  -$Value if ($Sign eq "-");	
        $InmediatoSource = &ToBinStr($Value,32);
        #print STDOUT "enters here\n";

        # get the binary mode of the destiny operand (no immediate addressing)
        if($match5 =~ /\((A\d)\)\+/){
            $DMode = "011";
        }
        elsif($match5 =~ /\-\((A\d)\)/){
            $DMode = "100";
        }
        elsif($match5 =~ /\(#(\-?)(\d+),(A\d)\)/){
            $DMode = "101";
        }
        elsif($match5 =~ /\((A\d)\)/){
            $DMode = "010";
        }
        elsif ($match5 =~ /(D\d)/ ){
            $DMode = "000";
        }
        elsif($match5 =~ /(A\d)/){
            $DMode = "001";
        }

        # Get the destiny register in binary
        # Inicializar variables de Relativo a base con desplazamiento # Initialize variables for base plus offset addressing
        if($DMode eq "101"){
            $DReg=$Registers{$3};
            $Sign = $1;
            $Value = $2;
            $Value =  -$Value if ($Sign eq "-");	
            $InmediatoDestino = &ToBinStr($Value,32);

        }
        else{
            $DestinationRegisterDecimal = $1;
            $DReg=$Registers{$DestinationRegisterDecimal};

        }


        # simple error check
        if (length($TheInstrCode)!=4){
            print($ERRORLOG "Bad instruction name: $1 in line: $linenumber\n");
            $TheInstrCode="XXXX";
        }
        if (length($DReg)!=3){	
            print($ERRORLOG "Bad destination register: $2 in line: $linenumber\n");
            $DReg="XXX";
        }
        if (length($DMode)!=3){	
            print($ERRORLOG "Bad destination register mode: $3 in line:  $linenumber\n");
            $DMode="XXX";
        }
        if (length($SMode)!=3){	
            print($ERRORLOG "Bad source register mode: $4 in line: $linenumber\n");
            $SMode="XXX";
        }
        if (length($SReg)!=3){	
            print($ERRORLOG "Bad source register: $4 in line: $linenumber\n");
            $SReg="XXX";
        }

        #$Code = $TheInstrCode.$DReg.$DMode.$SMode.$SReg."\n".$Inmediato;
        #print($OUTPUT $preword.$Code." : ", $match1." ", $match2.",", $match5." ", $match6." ", "\n");    

        $Code = $TheInstrCode.$DReg.$DMode.$SMode.$SReg."\n".$InmediatoSource;
        if($DMode eq "101"){
            $Code = $Code."\n".$InmediatoDestino;
        }
        print($OUTPUT $preword.$Code." : ", $match1." ", $match2.",".$match5." "."\n");    

    }


    # Move, Add, And, Or, cmp, sub
    # Regular expression. Check out Perl doc to understand.
    elsif (/\s*(\w+)\s+(D\d|A\d|\(A\d\)\+?|\-?\(A\d\)|\(A\d\)|\(#(\-?)\d+,A\d\)),(D\d|A\d|\(A\d\)\+?|\-?\(A\d\)|\(A\d\)|\(#(\-?)\d+,A\d\))\s*(.*)/)
    {
        # $1 opcode. $2 source. $3 Destino. $4 Comentario
        $match1 = $1;
        $match2 = $2;
        $match3 = $3;
        $match4 = $4;
        #print STDOUT "Enters here\n";
        $SMode = "";
        $TheInstrCode=$OpCodes4{$1}; # Binary opcode here
        
        # Get the binary mode of the source operand 
        if($match2 =~ /\((A\d)\)\+/){
            $SMode = "011";
        }
        elsif($match2 =~ /\-\((A\d)\)/){
            $SMode = "100";
        }
        elsif($match2 =~ /\(#(\-?)(\d+),(A\d)\)/){
            $SMode = "101";
        }
        elsif($match2 =~ /\((A\d)\)/){
            $SMode = "010";
        }
        elsif ($match2 =~ /(D\d)/ ){
            $SMode = "000";
        }
        elsif($match2 =~ /(A\d)/){
            $SMode = "001";
        }
        $SReg = "";
        $DReg = "";

        $Sign = "";
        $Value = "";
        $InmediatoSource = "";
        $SourceRegisterDecimal = "";
        $InmediatoDestino = "";

        # Initialize variables for base plus offset addressing
        if($SMode eq "101"){
            $SReg=$Registers{$3};
            $Sign = $1;
            $Value = $2;
            $Value =  -$Value if ($Sign eq "-");	
            $InmediatoSource = &ToBinStr($Value,32);


        }
        else{
            #print STDOUT $SMode."\n";
            # Get the source register in binary

            $SourceRegisterDecimal = $1;
            $SReg=$Registers{$SourceRegisterDecimal};
        }
        #print STDOUT $SReg."\n";
        #############
        $DMode = "";
        # Get the mode of the destiny operand in binary (no immediate addressing)
        if($match4 =~ /\((A\d)\)\+/){
            $DMode = "011";
        }
        elsif($match4 =~ /\-\((A\d)\)/){
            $DMode = "100";
        }
        elsif($match4 =~ /\(#(\-?)(\d+),(A\d)\)/){
            $DMode = "101";
            
        }
        elsif($match4 =~ /\((A\d)\)/){
            $DMode = "010";
        }
        elsif ($match4 =~ /(D\d)/ ){
            $DMode = "000";
        }
        elsif($match4 =~ /(A\d)/){
            $DMode = "001";
        }

        # Get the destiny register in binary
        # Initialize variables for base plus offset addresing mode
        if($DMode eq "101"){
            $DReg=$Registers{$3};
            $Sign = $1;
            $Value = $2;
            $Value =  -$Value if ($Sign eq "-");	
            $InmediatoDestino = &ToBinStr($Value,32);

        }
        else{
            $DestinationRegisterDecimal = $1;
            $DReg=$Registers{$DestinationRegisterDecimal};

        }

        #print STDOUT $DReg."\n";

        # Simple error check
        if (length($TheInstrCode)!=4){
            print($ERRORLOG "Bad instruction name: $1 in line: $linenumber\n");
            $TheInstrCode="XXXX";
        }
        if (length($DReg)!=3){	
            print($ERRORLOG "Bad destination register: $2 in line: $linenumber\n");
            $DReg="XXX";
        }
        if (length($DMode)!=3){	
            print($ERRORLOG "Bad destination register mode: $3 in line:  $linenumber\n");
            $DMode="XXX";
        }
        if (length($SMode)!=3){	
            print($ERRORLOG "Bad source register mode: $4 in line: $linenumber\n");
            $SMode="XXX";
        }
        if (length($SReg)!=3){	
            print($ERRORLOG "Bad source register: $4 in line: $linenumber\n");
            $SReg="XXX";
        }

        $Code = $TheInstrCode.$DReg.$DMode.$SMode.$SReg;
        if($SMode eq "101"){
            $Code = $Code."\n".$InmediatoSource;
        }
        if($DMode eq "101"){
            $Code = $Code."\n".$InmediatoDestino;
        }
        print($OUTPUT $preword.$Code." : ", $match1." ", $match2.",", $match4." ", "\n");    
    }

    # Branches
    elsif(/\s*(\w+)\s+#(\-?)(\d+)\s*(.*)/){
        # $1 opcode.  $2 sign. $3 offset/displacement. $4 comment
        $match1 = $1;
        $match2 = $2;
        $match3 = $3;
        $match4 = $4;

        $TheInstrCode=$OpCodes8{$1}; # this is the Opcode in binary
        $Sign = $2;
        $Value = $3;
        $Value =  -$Value if ($Sign eq "-");	
	    $Displacement = &ToBinStr($Value,32);

        $Code = $preword.$TheInstrCode."00000000"."\n".$Displacement;
        print($OUTPUT $Code." : ", $match1." ", "#".$match2.$match3." ", $match4." ", "\n");
    }

    # LINK
    elsif (/\s*(\w+)\s+(A\d),#(\-?)(\d+)\s*(.*)/)
    {
        # $1 opcode. $2 address register. $3 sign. $4 offset/displacement. $5 comment
        $match1 = $1;
        $match2 = $2;
        $match3 = $3;
        $match4 = $4;
        $match5 = $5;

        $TheInstrCode=$OpCodes13{$1}; # this is the opcode in binary
        $DReg = $Registers{$2};
        $Sign = $3;
        $Value = $4;
        $Value =  -$Value if ($Sign eq "-");	
  
	    $Displacement = &ToBinStr($Value,32);

        $Code = $preword.$TheInstrCode.$DReg." ".$match5."\n".$Displacement;
        print($OUTPUT $Code." : ", $match1." ", $match2.",", "#".$match3.$match4." ", $match5." ", "\n");    

    }

    # UNLINK
    elsif (/\s*(\w+)\s+(A\d)\s*(.*)/)
    {
        # $1 opcode. $2 address register.  $3 comment
        $match1 = $1;
        $match2 = $2;
        $match3 = $3;

        $TheInstrCode=$OpCodes13{$1}; # this is the opcode in binary
        $DReg = $Registers{$2};
  

        $Code = $preword.$TheInstrCode.$DReg;
        print($OUTPUT $Code." : ", $match1." ", $match2.$match3."\n");

    }





    # Comments
    elsif (/\#(.*)/){
	print($OUTPUT "#", $1, "\n");}
    
    # Empty lines
    elsif (/^(s*)$/){
	print($OUTPUT "#\n");}

}