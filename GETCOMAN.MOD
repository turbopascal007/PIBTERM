(*----------------------------------------------------------------------*)
(*      Get_Command_Line_Parameters --- Get command line parameters     *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Command_Line_Parameters;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Command_Line_Parameters                          *)
(*                                                                      *)
(*     Purpose:    Gets command line parameters for PibTerm             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Command_Line_Parameters;                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   S : AnyStr;
   S2: AnyStr;
   I : INTEGER;

(*----------------------------------------------------------------------*)
(*                Fix_Name --- Fix up parameter file name               *)
(*----------------------------------------------------------------------*)

FUNCTION Fix_Name( FName : AnyStr; FType : AnyStr ) : STRING;

BEGIN (* Fix_Name *)

   IF ( POS( '.' , FName ) = 0 ) THEN
      FName := FName + '.' + FType;

   Fix_Name := UpperCase( FName );

END   (* Fix_Parameter_File_Name *);

(*----------------------------------------------------------------------*)

BEGIN (* Get_Command_Line_Parameters *)

                                   (* Loop over command line params *)
   FOR I := 1 TO ParamCount DO
      BEGIN
         S := ParamStr( I );
         IF ( S[1] = '/' ) THEN
            BEGIN
               IF ( S[3] = '=' ) THEN
                  S2    := COPY( S, 4, LENGTH( S ) - 3 )
               ELSE
                  S2 := '';
               CASE UpCase( S[2] ) OF
                  'S':  Script_File_Name     := Fix_Name( S2 , 'SCR' );
                  'C':  Config_File_Name     := Fix_Name( S2 , 'CNF' );
                  'D':  Dialing_File_Name    := Fix_Name( S2 , 'FON' );
                  'E':  Prefix_File_Name     := Fix_Name( S2 , 'PRE' );
                  'K':  Function_Key_Name    := Fix_Name( S2 , 'FNC' );
                  'L':  Log_File_Name        := Fix_Name( S2 , 'LOG' );
                  'P':  IF ( S2[1] IN ['1'..'4'] ) THEN
                           Cmd_Line_Port := ORD( S2[1] ) - ORD( '0' );
                  'T':  Translate_File_Name  := Fix_Name( S2 , 'TRA' );
                  '0':  Debug_Mode           := TRUE;
                  'X':  Use_EMM_For_Overlays := TRUE;
                  ELSE;
               END (* CASE *);
            END
         ELSE
            Script_File_Name    := Fix_Name( S , 'SCR' );
      END;

END   (* Get_Command_Line_Parameters *);
