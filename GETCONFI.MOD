(*--------------------------------------------------------------------------*)
(*      Get_Config_File_Line --- Get one parameter line from config file    *)
(*--------------------------------------------------------------------------*)

FUNCTION Get_Config_File_Line(  VAR Config_File : Text_File;
                                VAR Param_Num   : INTEGER;
                                VAR Param_Str   : AnyStr;
                                VAR Param_Ival  : INTEGER;
                                VAR Param_Rval  : LONGINT ) : BOOLEAN;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*     Function:  Get_Config_File_Line                                      *)
(*                                                                          *)
(*     Purpose:   Reads and interprets one line of configuration file       *)
(*                                                                          *)
(*     Calling Sequence:                                                    *)
(*                                                                          *)
(*        QGot := Get_Config_File_Line(  VAR Config_File : Text_File;       *)
(*                                       VAR Param_Num   : INTEGER;         *)
(*                                       VAR Param_Str   : AnyStr;          *)
(*                                       VAR Param_Ival  : INTEGER;         *)
(*                                       VAR Param_Rval  : LONGINT):BOOLEAN;*)
(*                                                                          *)
(*           Config_File --- the configuration file                         *)
(*           Param_Num   --- parameter number of this line                  *)
(*           Param_Str   --- string value of parameter                      *)
(*           Param_Ival  --- Integer value of parameter                     *)
(*           Param_Rval  --- Real value of parameter                        *)
(*                                                                          *)
(*           Qgot        --- TRUE if configuration line returned;           *)
(*                           FALSE if end-of-file encountered on            *)
(*                           configuration file.                            *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   I:       INTEGER;
   S:       AnyStr;
   PName:   Char_2;
   L:       INTEGER;
   NumDone: BOOLEAN;
   IVal   : LONGINT;

BEGIN (* Get_Config_File_Line *)
                                   (* Initialize parameter values *)
   Param_Num  := 0;
   Param_Str  := '';
   Param_Ival := 0;
   Param_Rval := 0;
   IVal       := 0;

   IF NOT EOF( Config_File ) THEN
      BEGIN

         Get_Config_File_Line := TRUE;

                                   (* Indicate line from configuration file *)
         READLN( Config_File , S );

                                   (* If comment line, skip it.             *)

         IF ( LENGTH( S ) > 0 ) THEN
            IF ( S[1] = '*' ) THEN
               EXIT;
                                   (* Pick up parameter name.  Only first 2 *)
                                   (* characters matter, skip rest up to    *)
                                   (* '='.                                  *)

         S         := S + '    ';
         PName[1]  := UpCase( S[1] );
         PName[2]  := UpCase( S[2] );
         L         := LENGTH( S );
         I         := 1;

         WHILE( ( I <= L ) AND ( S[I] <> '=' ) ) DO
            INC( I );

         Param_Str := Trim( COPY( S, SUCC( I ), LENGTH( S ) - I ) );

                                   (* Search for parameter.           *)
                                   (* If found, convert to numeric if *)
                                   (* appropriate                     *)

         Param_Num := Look_Up_Parameter( PName );

         IF ( Param_Num > 0 ) THEN
            BEGIN

                  L       := LENGTH( Param_Str );
                  NumDone := ( L = 0 );
                  I       := 0;

                  WHILE ( NOT NumDone ) DO
                     BEGIN
                        INC( I );
                        IF Param_Str[I] IN ['0'..'9'] THEN
                           Ival := Ival * 10 +
                                   ORD( Param_Str[I] ) - ORD( '0' );
                        NumDone := NumDone OR ( I >= L ) OR
                                   ( Param_Str[I] = ' ');
                     END;

                  IF ( L > 0 ) THEN
                     IF ( UpCase( Param_Str[1] ) = 'Y' ) THEN
                        Ival := 1;

               Param_IVal := IVal;
               Param_Rval := Ival;

            END;

      END

   ELSE
      Get_Config_File_Line := FALSE;

END   (* Get_Config_File_Line *);
