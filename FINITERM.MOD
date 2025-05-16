(*----------------------------------------------------------------------*)
(*                  FiniTerm --- Finish up PibTerm                      *)
(*----------------------------------------------------------------------*)

PROCEDURE FiniTerm;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  FiniTerm                                             *)
(*                                                                      *)
(*     Purpose:    Terminates PibTerm                                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        FiniTerm;                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I             : INTEGER;
   Vid_Mode      : INTEGER;

BEGIN (* FiniTerm *)
                                   (* Make sure we're in text mode *)

   Vid_Mode      := Current_Video_Mode;
   IF ( ( Vid_Mode >= MedRes_GraphMode ) AND
        ( Vid_Mode <> Mono_TextMode    ) ) THEN
      Set_Text_Mode( Text_Mode );

                                   (* Close down serial port   *)
   Async_Close( Drop_Dtr_At_End );
                                   (* Remove buffers               *)
   Async_Release_Buffers;
                                   (* Turn off keyboard handler    *)
   IF Extended_Keypad THEN
      Remove_Keyboard_Handler;
                                   (* Turn off video handler       *)
   IF Software_Scroll THEN
      Remove_Video_Handler;
                                   (* Close all script files           *)

   FOR I := 1 TO MaxScriptOpenFiles DO
      IF Script_File_Used[I] THEN
         BEGIN
            IF Script_File_List[I]^.Opened THEN
               BEGIN
                     (*!I-*)
                  CLOSE( Script_File_List[I]^.F );
                     (*!I+*)
                  I := Int24Result;
               END;
         END;
                                   (* Close capture file       *)
   IF Capture_On THEN
         (*!I-*)
      BEGIN
         CLOSE( Capture_File );
         I := Int24Result;
      END;
         (*!I+*)
                                   (* Close log file           *)
   IF Log_File_Open THEN
         (*!I-*)
      BEGIN
         CLOSE( Log_File );
         I := Int24Result;
      END;

         (*!I+*)
                                   (* Close down print spooling *)
   IF Print_Spooling THEN
      BEGIN
         CLOSE( Spool_File );
         DISPOSE( Spool_Buffer );
         I := Int24Result;
      END;
                                   (* Close printer *)
   CLOSE( LST );
   I := Int24Result;
                                   (* Remove scrolling buffer  *)

   MyFreeMem( Review_Buffer , Max_Review_Length );

                                 (* Remove Interrupt 24 trap *)
   Int24OFF( FALSE );

   TextColor( LightGray );
   TextBackGround( Black );
   Set_Border_Color( Black );

   ExitProc := ExitSave;

END   (* FiniTerm *);
