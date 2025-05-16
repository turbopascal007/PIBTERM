(*----------------------------------------------------------------------*)
(*                Get_Other_Files --- read initialization files         *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Other_Files;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Get_Other_Files                                       *)
(*                                                                      *)
(*     Purpose:   Reads other initialization files than primary config. *)
(*                file PIBTERM.CNF.                                     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Other_Files;                                              *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I                    : INTEGER;

(*----------------------------------------------------------------------*)
(*            Read_Prefix_File --- Read dialing prefix file             *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Prefix_File;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Read_Prefix_File                                     *)
(*                                                                      *)
(*     Purpose:    Reads dialing prefix file                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Prefix_File;                                             *)
(*                                                                      *)
(*      Calls:   Read_Config_File                                       *)
(*               Read_Prefix_File                                       *)
(*               Read_Phone_Directory                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   IPrefix           : INTEGER;
   OK_To_Read        : BOOLEAN;
   Full_Name         : AnyStr;
   Phone_Prefix_File : Text_File;

BEGIN (* Read_Prefix_File *)
                                   (* Clear out prefix entries *)

   FOR IPrefix := 1 TO Max_Phone_Prefixes DO
      Phone_Prefix_Nos[IPrefix] := '';

                                   (* Assign phone prefix file *)

   Add_Path( Prefix_File_Name, Home_Dir, Full_Name );

   ASSIGN( Phone_Prefix_File , Full_Name );
        (*!I-*)
   RESET( Phone_Prefix_File );
        (*!I+*)

   OK_To_Read := ( Int24Result = 0 );
   TextColor( WHITE );

   IF NOT OK_To_Read THEN
      WRITELN('Can''t find prefix file ',Full_Name,', no prefixes set.')

                                   (* Read prefix entries *)
   ELSE
      BEGIN

         WRITELN('Reading phone prefixes from ',Full_Name);

         IPrefix := 1;

         REPEAT
            READLN( Phone_Prefix_File , Phone_Prefix_Nos[ IPrefix ] );
            Phone_Prefix_Nos[ IPrefix ] :=
               Read_Ctrls( Phone_Prefix_Nos[ IPrefix ] );
            IPrefix := IPrefix + 1;
         UNTIL( EOF( Phone_Prefix_File ) OR ( IPrefix > Max_Phone_Prefixes ) );

              (*!I-*)
         CLOSE( Phone_Prefix_File );
              (*!I+*)

      END;
                                   (* Write new prefix file *)

   IF NOT Ok_To_Read THEN
      BEGIN

         ASSIGN( Phone_Prefix_File , Full_Name );
             (*!I-*)
         REWRITE( Phone_Prefix_File );
             (*!I+*)

         IF Int24Result <> 0 THEN
            BEGIN
               WRITELN;
               WRITELN('Can''t create new dialing prefix file ',Full_Name,'.')
            END
         ELSE
            BEGIN

               WRITELN;
               WRITELN('Creating dialing prefix file ',Full_Name,'.');

               FOR IPrefix := 1 TO Max_Phone_Prefixes DO
                  WRITELN( Phone_Prefix_File , Phone_Prefix_Nos[ IPrefix ] );

               CLOSE( Phone_Prefix_File );

            END;

      END;

END   (* Read_Prefix_File *);

(*----------------------------------------------------------------------*)
(*        Read_Phone_Directory --- Read phone number directory          *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Phone_Directory;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Read_Phone_Directory                                 *)
(*                                                                      *)
(*     Purpose:    Read phone directory entries                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Phone_Directory;                                         *)
(*                                                                      *)
(*      Calls:   Read_Config_File                                       *)
(*               Read_Prefix_File                                       *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*          Watch out -- some tricky stuff with accessing string data   *)
(*          and lengths is used here.                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I          : INTEGER;
   J          : INTEGER;
   L          : INTEGER;
   OK_To_Read : BOOLEAN;
   T_String   : AnyStr;
   Phone_File : Text_File;
   Phone_Str  : AnyStr;
   Full_Name  : AnyStr;

BEGIN (* Read_Phone_Directory *)
                                   (* If there wasn't room to store the    *)
                                   (* directory, don't read it in.         *)

   IF ( Dialing_Directory = NIL ) THEN
      BEGIN
         Dialing_Dir_Size := 0;
         EXIT;
      END;
                                   (* Indicate we're reading phone numbers *)

   Add_Path( Dialing_File_Name, Home_Dir, Full_Name );

   WRITELN('Reading dialing directory ',Full_Name);

                                   (* Assign phone number file *)

   ASSIGN( Phone_File , Full_Name );
        (*!I-*)
   SetTextBuf( Phone_File , Sector_Data );
   RESET( Phone_File );
        (*!I+*)

   OK_To_Read := ( INT24Result = 0 );
   TextColor( WHITE );
                                   (* Create phone directory if needed *)

   IF ( NOT OK_To_Read ) THEN
      BEGIN  (* Phone directory doesn't exist *)

         ASSIGN( Phone_File , Full_Name );
             (*!I-*)
         SetTextBuf( Phone_File , Sector_Data );
         REWRITE( Phone_File );
             (*!I+*)

         IF Int24Result <> 0 THEN
            BEGIN
               WRITELN;
               WRITELN('Can''t create new phone directory ',Full_Name,'.')
            END
         ELSE
            BEGIN  (* Create phone directory *)

               WRITELN;
               WRITELN('Creating phone directory ',Full_Name,'.');

               WITH Phone_Entry_Data DO
                  BEGIN

                     CopyStoA( Dupl( '-' , 25 ) , Phone_Name ,   25 );
                     CopyStoA( ' # ### ###-####' , Phone_Number , 15 );

                     Phone_Parity   := Parity;

                     STR ( Baud_Rate:5 , T_String );
                     CopyStoA( T_String , Phone_Baud , 5 );

                     STR ( Data_Bits:1 , T_String );
                     Phone_Databits := T_STRING[1];

                     STR ( Stop_Bits:1 , T_String );
                     Phone_StopBits := T_STRING[1];

                     IF Local_Echo THEN
                        Phone_Echo := 'Y'
                     ELSE
                        Phone_Echo := 'N';

                     IF ( BS_String = CHR( BS ) ) THEN
                        Phone_BackSpace := 'B'
                     ELSE IF ( BS_String = CHR( DEL ) ) THEN
                        Phone_BackSpace := 'D'
                     ELSE
                        Phone_BackSpace := ' ';

                     IF Add_LF THEN
                        Phone_LineFeed := 'Y'
                     ELSE
                        Phone_LineFeed := 'N';

                     T_String          := COPY( Dec_To_Hex( ORD( Terminal_to_Emulate ) ), 1, 1 );
                     Phone_Term_Type   := T_String[1];

                     Phone_Trans_Type  := Trans_Type_Name[ Default_Transfer_Type ];

                     Phone_Script      := '         ';

                     Phone_Last_Date   := '        ';

                     Phone_Last_Time   := '        ';

                  END;

               Phone_Str[0] := CHR( Dialing_Dir_Entry_Length );
               MOVE( Phone_Entry_Data, Phone_Str[1],
                     Dialing_Dir_Entry_Length );

               FOR I := 1 TO Dialing_Dir_Size_Max DO
                  BEGIN
                    Dialing_Directory^[I] := Phone_Entry_Data;
                    WRITELN( Phone_File , Phone_Str );
                  END;

               CLOSE( Phone_File );

               Dialing_Dir_Size := Dialing_Dir_Size_Max;

               EXIT;

            END    (* Create phone directory *);

      END   (* Phone directory doesn't exist *);

                                   (* Finally, read in directory! *)
      (*!I-*)

   Dialing_Dir_Size := 0;

   REPEAT

      READLN( Phone_File, Phone_Str );

      L := LENGTH( Phone_Str );
      FOR J := ( L + 1 ) TO Dialing_Dir_Entry_Length DO
         Phone_Str[J] := ' ';

      MOVE( Phone_Str[1], Phone_Entry_Data, Dialing_Dir_Entry_Length );

      Dialing_Dir_Size                     := Dialing_Dir_Size + 1;
      Dialing_Directory^[Dialing_Dir_Size] := Phone_Entry_Data;

   UNTIL( EOF( Phone_File ) OR ( Dialing_Dir_Size >= Dialing_Dir_Size_Max ) );

   CLOSE( Phone_File );
      (*!I+*)

   I := INT24Result;

END   (* Read_Phone_Directory *);

(*----------------------------------------------------------------------*)
(*        Read_Function_Keys --- Read function key definitions          *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Function_Keys;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Read_Function_Keys                                   *)
(*                                                                      *)
(*     Purpose:    Read function key definitions                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Function_Keys;                                           *)
(*                                                                      *)
(*      Calls:   Read_Config_File                                       *)
(*               Read_Prefix_File                                       *)
(*               Read_Phone_Directory                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Input_Key_File : Text;
   Key_Name       : STRING[4];
   Key_Text       : AnyStr;
   Section_No     : INTEGER;
   Key_Def_Text   : AnyStr;
   Key_Number     : INTEGER;
   L_Text         : INTEGER;
   I              : INTEGER;
   J              : INTEGER;
   Full_Name      : AnyStr;

(*----------------------------------------------------------------------*)
(*       Process_Key_Definition --- Process Function Key Definition     *)
(*----------------------------------------------------------------------*)

PROCEDURE Process_Key_Definition;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Process_Key_Definition                               *)
(*                                                                      *)
(*     Purpose:    Process and store key definition string              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Process_Key_Definition;                                       *)
(*                                                                      *)
(*           On entry, Key_Text should have the key definition text     *)
(*           as read from a file.                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Process_Key_Definition *)

                                   (* Get key name   *)

   I        := POS( '=' , Key_Text );
   L_Text   := LENGTH( Key_Text );

   IF ( I > 0 ) THEN
      Define_Key( COPY( Key_Text, 1, PRED( I ) ) ,
                  COPY( Key_Text, SUCC( I ) , L_Text - I ) );

END   (* Process_Key_Definition *);

(*----------------------------------------------------------------------*)

BEGIN (* Read_Function_Keys *)
                                   (* Attach file with definitions *)

   Add_Path( Function_Key_Name, Home_Dir, Full_Name );

   ASSIGN( Input_Key_File , Full_Name );
       (*!I-*)
   RESET ( Input_Key_File );
       (*!I+*)
                                   (* See if openable *)
   IF ( Int24Result = 0 ) THEN
      BEGIN (* File OK, read definitions *)

         WRITELN('Reading key definitions from ',Full_Name);

         REPEAT

            Key_Text       := ' ';
                                   (* Read key definition *)

            READLN( Input_Key_File , Key_Text );

                                   (* Process it *)

            Process_Key_Definition;

         UNTIL( EOF( Input_Key_File ) );

         CLOSE( Input_Key_File );

      END   (* File OK, read definitions *);

END   (* Read_Function_Keys *);

(*----------------------------------------------------------------------*)
(*        Read_Translate_Table --- Read translate table definitions     *)
(*----------------------------------------------------------------------*)

PROCEDURE Read_Translate_Table;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Read_Translate_Table                                 *)
(*                                                                      *)
(*     Purpose:    Read translate table definitions                     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Translate_Table;                                         *)
(*                                                                      *)
(*      Calls:   Read_Config_File                                       *)
(*               Read_Prefix_File                                       *)
(*               Read_Phone_Directory                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   TrTab_File : TEXT;
   I          : INTEGER;
   J          : INTEGER;
   Full_Name  : AnyStr;

BEGIN (* Read_Translate_Table *)

   Add_Path( Translate_File_Name, Home_Dir, Full_Name );

   ASSIGN( TrTab_File , Full_Name );
      (*!I-*)
   RESET ( TrTab_File );
      (*!I+*)

   IF ( Int24Result = 0 ) THEN
      BEGIN (* File OK, read definition *)

         WRITELN('Reading translate table from ', Full_Name);

         REPEAT
               (*!I-*)
            READLN( TrTab_File , I, J );
               (*!I+*)
            IF Int24Result = 0 THEN
               IF ( I >= 0 ) AND ( I <= 255 ) AND
                  ( J >= 0 ) AND ( J <= 255 ) THEN
                  TrTab[CHR(I)] := CHR( J );

         UNTIL( EOF( TrTab_File ) );

            (*!I-*)
         CLOSE( TrTab_File );
            (*!I+*)

      END   (* Get definition from file *);

END   (* Read_Translate_Table *);

(*----------------------------------------------------------------------*)

BEGIN (* Get_Other_Files *)
                                   (* Read dialing prefix file        *)
   Read_Prefix_File;
                                   (* Read dialing entries            *)
   Read_Phone_Directory;
                                   (* Read function key definitions   *)
   Read_Function_Keys;
                                   (* Read translate table definitions*)
   Read_Translate_Table;

END   (* Get_Other_Files *);
