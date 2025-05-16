(*----------------------------------------------------------------------*)
(*     Kermit_Finish_Server --- Finish server mode transfers            *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Finish_Server( Finish_Type: CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Kermit_Finish_Server                                 *)
(*                                                                      *)
(*     Purpose:    Tells remote Kermit server to quit                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Kermit_Finish_Server( Finish_Type : CHAR );                   *)
(*                                                                      *)
(*           Finish_Type --- 'F' to finish, 'L' to logout               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Try       : INTEGER;
   Ch        : CHAR;

BEGIN (* Kermit_Finish_Server *)
                                   (* Hide cursor         *)
   CursorOff;
                                   (* Save current screen *)

   Save_Screen( Kermit_Local_Save );

                                   (* Initialize display  *)
   IF Finish_Type = 'F' THEN
      BEGIN
         Send_Packet_Ptr^[4] := 'G';
         Send_Packet_Ptr^[5] := 'F';
         Send_Packet_Length  := 5;
         Write_Log( 'FINISH remote server.', FALSE, FALSE );
      END
   ELSE
      BEGIN
         Send_Packet_Ptr^[4] := 'G';
         Send_Packet_Ptr^[5] := 'L';
         Send_Packet_Length  := 5;
         Write_Log( 'LOGOUT remote server.', FALSE, FALSE );
      END;

   Packet_Num          := 0;
   Try                 := 0;
   Packets_Received    := 0;
   Packets_Sent        := 0;
   Packets_Bad         := 0;
   Kermit_MaxTry       := 5;
   Kermit_Abort        := FALSE;
   Kermit_Retry        := FALSE;
   Kermit_Abort_Level  := No_Abort;
   Kermit_Screen_Write := FALSE;
   His_Chk_Type        := '1';

   Initialize_Logout_Display;

                                   (* Build FINISH packet *)
   Build_Packet;
                                   (* Don't update display     *)
   Logging_Out_Server := TRUE;
                                   (* Send FINISH packet until *)
                                   (* acknowledged or too many *)
                                   (* tries.                   *)
   REPEAT

      Try := Try + 1;

      Send_Packet;

      Check_ACK;

      IF PibTerm_KeyPressed THEN
         BEGIN

            Read_Kbd( Ch );

            IF ( ( Ch = CHR( ESC ) ) AND PibTerm_KeyPressed ) THEN
               Read_Kbd( Ch )
            ELSE
               CASE Ch OF
                  ^B,^F:  BEGIN    (* Cancel logout *)
                             Kermit_Abort       := TRUE;
                             Kermit_Abort_Level := No_Abort;
                          END;

                     ^K:  BEGIN    (* Drop out of Kermit entirely *)
                             Kermit_Abort       := TRUE;
                             Kermit_Abort_Level := Entire_Protocol;
                          END;

                     ^M:  BEGIN    (* Retry current packet *)
                             Kermit_Retry       := TRUE;
                             Async_Send( CHR( CR ) );
                          END;

                   ELSE;

               END (* CASE *);

         END  (* If PibTerm_KeyPressed *);

   UNTIL ( Kermit_Abort OR ACK_OK OR ( Try > Kermit_MaxTry ) );

   IF ( Try > Kermit_MaxTry ) OR Kermit_Abort THEN
      Display_Kermit_Message('Error -- could not stop remote server.')
   ELSE
      Display_Kermit_Message('Remote server stopped.');

   Window_Delay;

   Logging_Out_Server := FALSE;
                                   (* Remove logout window *)

   Restore_Screen_And_Colors( Kermit_Local_Save );

   CursorOn;

END    (* Kermit_Finish_Server *);
