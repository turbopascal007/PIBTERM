(*----------------------------------------------------------------------*)
(*         Write_Log --- Write date/time stamped entry to capture files *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_Log( T            : AnyStr;
                     Continuation : BOOLEAN;
                     On_Screen    : BOOLEAN  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Write_Log                                            *)
(*                                                                      *)
(*     Purpose:    Writes date/time stamped entry to capture files.     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Write_Log( T : AnyStr; Continuation: BOOLEAN;                 *)
(*                   On_Screen : BOOLEAN );                             *)
(*                                                                      *)
(*           T            --- Text to be displayed                      *)
(*           Continuation --- TRUE if line continued from previous.     *)
(*           On_Screen    --- TRUE to display text on screen.           *)
(*                                                                      *)
(*      Calls:   Update_Review_Pointers                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Prefix: STRING[2];
   S     : AnyStr;

(* STATIC VARS *) CONST
   Saved_Time : STRING[8] = '';
   Saved_Date : STRING[8] = '';

BEGIN (* Write_Log *)

   Saved_Time := TimeString( TimeOfDay , Military_Time );
   Saved_Date := DialDateString;

                                   (* Display on screen *)
   IF On_Screen THEN
      WRITELN( T );
                                   (* Add continuation char *)

   IF ( NOT Continuation ) THEN
      Prefix := '  '
   ELSE
      Prefix := '+ ';
                                   (* Add time, date stamp *)

   T := Prefix + Saved_Date + ' ' + Saved_Time + ' ' + T;

                                   (* Write to log file *)

   IF ( Log_File_Open AND Logging_On ) THEN
      WRITELN( Log_File, T );

                                   (* Add marker characters *)
   T := '>>' + T;
                                   (* Write to capture file *)
   IF Capture_On THEN
      WRITELN( Capture_File, T );

                                   (* Write to printer *)
   IF Printer_On THEN
      BEGIN
         Write_Prt_Str( T );
         Write_Prt_Str( CRLF_String );
      END;
                                   (* Point to next slot in review buffer *)
                                   (* and insert text if review mode.     *)
   IF Review_On THEN
      BEGIN

         S           := Review_Line;
         Review_Line := T;

         Update_Review_Pointers;

         Review_Line := S;

      END;

END   (* Write_Log *);
