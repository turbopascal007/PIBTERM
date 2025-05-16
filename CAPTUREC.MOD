(*----------------------------------------------------------------------*)
(*          Capture_Char -- write character to capture file             *)
(*----------------------------------------------------------------------*)

PROCEDURE Capture_Char( Ch : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Capture_Char                                         *)
(*                                                                      *)
(*     Purpose:    Writes character to capture file                     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Capture_Char( Ch : CHAR );                                    *)
(*                                                                      *)
(*           Ch --- the character to be written out                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        If Exact_Capture is TRUE, then characters are written just    *)
(*        as they are received.  If Exact_Capture is FALSE, then        *)
(*        a full screen image line is gathered up and written when      *)
(*        an LF or FF is encountered.                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Screen_Line : AnyStr;
   IY          : INTEGER;
   Local_Save  : Saved_Screen_Ptr;

BEGIN (* Capture_Char *)

   IF Exact_Capture THEN
      IF ( Ch = CHR( LF ) ) THEN
         WRITELN( Capture_File )
      ELSE
         WRITE( Capture_File , Ch )
   ELSE
      BEGIN
         IF ( ( Ch = CHR( LF ) ) OR ( Ch = CHR( FF ) ) ) THEN
            BEGIN
               IY := WhereY;
               Get_Screen_Text_Line( Screen_Line , IY, 1 );
               WRITELN( Capture_File , TRIM( Screen_Line ) );
            END;
         IF ( Ch = CHR( FF ) ) THEN
            WRITE( Capture_File , Ch );
      END;
                                   (* If I/O error on capture file, *)
                                   (* close it.                     *)
   IF ( Int24Result <> 0 ) THEN
      BEGIN

         Draw_Titled_Box( Local_Save, 10, 10, 70, 16, 'Error in Capture' );

         CLOSE( Capture_File );

         IY         := Int24Result;

         Capture_On := FALSE;

         WRITELN;
         WRITELN('*** Capture to ', Capture_File_Name,
                 ' stopped because of I/O error.');
         WRITELN('*** The receiving disk may be out of room.');

         Press_Any;

         Restore_Screen_And_Colors( Local_Save );

         Set_Status_Line_Name( Short_Terminal_Name );
         Write_To_Status_Line( Status_Line_Name, 1 );

      END;

END   (* Capture_Char *);
