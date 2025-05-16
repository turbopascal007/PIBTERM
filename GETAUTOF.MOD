(*----------------------------------------------------------------------*)
(* Get_Auto_File_Name --- Get transfer file name from prior kbd input   *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_File_Name_From_String( VAR Name_String : AnyStr;
                                     VAR FileName    : AnyStr;
                                         Period_Last : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_File_Name_From_String                            *)
(*                                                                      *)
(*     Purpose:    Gets file name from a string                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_File_Name_From_String( VAR Name_String : AnyStr;          *)
(*                                   VAR FileName    : AnyStr;          *)
(*                                       Period_Last : BOOLEAN );       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dot_Pos : INTEGER;
   I       : INTEGER;
   K       : INTEGER;
   L       : INTEGER;
   AllDigs : BOOLEAN;

(* STRUCTURED *) CONST
   Legal_File_Name_Chars : SET OF CHAR = ['A'..'Z','0'..'9','$','&',
                                          '#','%','''','(',')','-',
                                          '@','^','{','}','~','`',
                                          '!','_'];

BEGIN (* Get_Auto_File_Name *)

                                   (* Null file name to start *)
   FileName := '';
                                   (* No '.' in Name_String --    *)
                                   (* no file name then, so exit. *)
   L := LENGTH( Name_String );

   IF ( L = 0 ) THEN EXIT;

   Dot_Pos := POS( '.' , Name_String );

   IF ( Dot_Pos > 0 ) THEN
      BEGIN
                                   (* Pick up first part of file name *)
         I := PRED( Dot_Pos );
         K := 8;
         WHILE ( ( I > 0 ) AND
                 ( K > 0 ) AND
                 ( UpCase( Name_String[I] ) IN Legal_File_Name_Chars ) ) DO
            BEGIN
               FileName := Name_String[I] + FileName;
               DEC( I );
               DEC( K );
            END;
                                   (* Insert '.' *)

         FileName := FileName + '.';

                                   (* Pick up file extension *)

         I       := SUCC( Dot_Pos );
         K       := 3;
         AllDigs := TRUE;

         WHILE ( ( I <= L ) AND
                 ( K >  0 ) AND
                 ( UpCase( Name_String[I] ) IN Legal_File_Name_Chars ) ) DO
            BEGIN
               FileName := FileName + Name_String[I];
               AllDigs  := AllDigs AND ( Name_String[I] IN Digits );
               INC( I );
               DEC( K );
            END;

      END;
                                   (* Nuke filename whose extension  *)
                                   (* is all digits.  It's probably  *)
                                   (* a program version number rather*)
                                   (* than a file name.              *)

   IF ( AllDigs AND ( K < 3 ) ) THEN
      FileName := ''
                                   (* If we don't allow file name to *)
                                   (* end in period, and it does,    *)
                                   (* nuke filename.                 *)

   ELSE IF ( FileName[ LENGTH(FileName) ] = '.' ) THEN
      IF ( NOT Period_Last ) THEN
         FileName := '';

END   (* Get_Auto_File_Name *);

(*----------------------------------------------------------------------*)
(* Get_Auto_File_Name --- Get transfer file name from prior kbd input   *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Auto_File_Name( VAR Keybrd_Line : AnyStr;
                              VAR FileName    : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Auto_File_Name                                   *)
(*                                                                      *)
(*     Purpose:    Gets transfer file name from prior kbd input or      *)
(*                 screen display.                                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Auto_File_Name( VAR Keybrd_Line : AnyStr;                 *)
(*                            VAR FileName    : AnyStr );               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Y : INTEGER;
   S : AnyStr;

BEGIN (* Get_Auto_File_Name *)
                                   (* Try current keyboard input *)

   Get_File_Name_From_String( Keybrd_Line , FileName , TRUE );

                                   (* Exit if file name found *)
   IF ( FileName <> '' ) THEN EXIT;

                                   (* Scan screen contents from current *)
                                   (* line back to top of screen.       *)
   Y := WhereY;

   WHILE ( ( Y > 0 ) AND ( FileName = '' ) ) DO
      BEGIN
         Get_Screen_Text_Line     ( S , Y , 1 );
         Get_File_Name_From_String( S , FileName , FALSE );
         DEC( Y );
      END;

END   (* Get_Auto_File_Name *);