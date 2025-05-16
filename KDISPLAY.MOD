(*----------------------------------------------------------------------*)
(*    Initialize_Display --- Set up status display of Kermit transfer   *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Display;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Initialize_Display                                   *)
(*                                                                      *)
(*     Purpose:    Initializes status display for Kermit transfers      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Initialize_Display;                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;

BEGIN (* Initialize_Display *)

   IF ( NOT Display_Status ) THEN EXIT;

   Draw_Menu_Frame( 15, 5, 78, 20, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, Kermit_Menu_Title );

   PibTerm_Window( 16, 6, 77, 19 );

   TextColor( Menu_Text_Color_2 );

   FOR I := 1 TO 5 DO
      BEGIN
         GoToXY( 1 , I );
         IF Sending_File THEN
            WRITE(' ', Send_Titles[I] )
         ELSE
            WRITE(' ', Receive_Titles[I] );
         ClrEol;
      END;

   FOR I := 6 TO 14 DO
      BEGIN
         GoToXY( 1 , I );
         WRITE(' ', Line_Titles[I] );
         ClrEol;
      END;

   GoToXY( 1 , Kermit_Title_Line );
   WRITE( Key_Title );
   ClrEol;

   TextColor( Menu_Text_Color );

END   (* Initialize_Display *);

(*----------------------------------------------------------------------*)
(*   Initialize_Logout_Display --- Set up display for server logout     *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Logout_Display;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Initialize_Logout_Display                            *)
(*                                                                      *)
(*     Purpose:    Initializes logout display                           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Initialize_Logout_Display;                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Initialize_Logout_Display *)

   IF ( NOT Display_Status ) THEN EXIT;

   Draw_Menu_Frame( 15, 5, 78, 20, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, 'Logging out remote server' );

   PibTerm_Window( 16, 6, 77, 19 );

   TextColor( Menu_Text_Color_2 );

   GoToXY( 1 , 1 );
   WRITE( ' ', Send_Titles[1] );
   ClrEol;

   GoToXY( 1 , 3 );
   WRITE( ' ', Send_Titles[3] );
   ClrEol;

   GoToXY( 1 , 11 );
   WRITE( ' ' , Line_Titles[11] );
   ClrEol;

   TextColor( Menu_Text_Color );

END   (* Initialize_Logout_Display *);

(*----------------------------------------------------------------------*)
(*  Display_Kermit_Init_Params --- Display Kermit init. parameters      *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Kermit_Init_Params;

VAR
   Quote_8: CHAR;

BEGIN (* Display_Kermit_Init_Params *)

   IF Display_Status THEN
      BEGIN

         GoToXY( 25 , 6 );

         IF Sending_File THEN
            Quote_8 := Kermit_Quote_8_Char
         ELSE
            Quote_8 := His_Quote_8_Char;

         IF Quoting THEN
            WRITE('ON using <',Quote_8,'>')
         ELSE
            WRITE('OFF');

         ClrEol;

         GoToXY( 25 , 7 );

         CASE His_Chk_Type OF
            '1':  WRITE('1 character checksum');
            '2':  WRITE('2 character checksum');
            '3':  WRITE('3 character CRC');
         END (* CASE *);

         ClrEol;

         GoToXY( 25 , 8 );

         IF Repeating THEN
            WRITE('ON using <',His_Repeat_Char,'>')
         ELSE
            WRITE('OFF');

         ClrEol;

         GoToXY( 25 , 9 );

         IF Kermit_Do_Sliding_Win THEN
            WRITE('ON with window size ', His_Kermit_Window_Size )
         ELSE
            WRITE('OFF');

         ClrEol;

         GoToXY( 25 , 10 );

         IF Kermit_Do_Long_Blocks THEN
            WRITE('ON with maximum size ', His_Kermit_MaxLX1 * 95 + His_Kermit_MaxLX2 )
         ELSE
            WRITE('OFF');

         ClrEol;

      END;

END   (* Display_Kermit_Init_Params *);

(*----------------------------------------------------------------------*)
(*        Flip_Display_Status --- turn status display on/off            *)
(*----------------------------------------------------------------------*)

PROCEDURE Flip_Display_Status;

BEGIN (* Flip_Display_Status *)

   IF ( NOT Kermit_Screen_Write ) THEN
      CASE Display_Status OF

         TRUE:   BEGIN
                                   (* Indicate no display   *)

                    Display_Status := FALSE;

                                   (* Remove display window  *)

                    Restore_Screen_And_Colors( Kermit_Local_Save );

                                   (* Restore cursor *)
                    CursorOn;

                 END;

         FALSE:  BEGIN
                                   (* Indicate display will be done *)

                    Display_Status := TRUE;

                                   (* Hide cursor *)
                    CursorOff;
                                   (* Save screen image *)

                    Save_Screen( Kermit_Local_Save );

                                   (* Initialize display window     *)

                    IF Logging_Out_Server THEN
                       Initialize_Logout_Display
                    ELSE
                       BEGIN
                          Initialize_Display;
                          Display_Kermit_Init_Params;
                       END;

                 END;

      END (* CASE *);

END   (* Flip_Display_Status *);

(*----------------------------------------------------------------------*)
(*      Update_Kermit_Display --- Update display of Kermit transfer     *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Kermit_Display;

BEGIN (* Update_Kermit_Display *)

   IF ( Display_Status ) THEN
      BEGIN

         GoToXY( 25 , 1 );
         IF Sending_File THEN
            WRITE( Packets_Sent )
         ELSE
            WRITE( Packets_Received );

         IF ( NOT Logging_Out_Server ) THEN
            BEGIN
               GoToXY( 25 , 2 );
               WRITE( Buffer_Num );
               ClrEol;
            END;

         GoToXY( 25 , 3 );
         WRITE( Packets_Bad );

         GoToXY( 25 , 5 );
         IF Kermit_Doing_Transfer THEN
            WRITE ( Kermit_Window_Bottom, ' : ', Kermit_Window_Top );
         ClrEol;

      END;

END   (* Update_Kermit_Display *);

(*----------------------------------------------------------------------*)
(*  Display_Kermit_Message --- Display Kermit reception status message  *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Kermit_Message( Status_Text: AnyStr );

BEGIN (* Display_Kermit_Message *)

   IF ( NOT Display_Status ) THEN
      Flip_Display_Status;

   IF Display_Status THEN
      BEGIN

         Update_Kermit_Display;

         GoToXY( 25 , Kermit_Mess1_Line );
         WRITE( Status_Text );
         ClrEol;

     END;

   Write_Log( Status_Text, TRUE, FALSE );

END   (* Display_Kermit_Message *);

(*----------------------------------------------------------------------*)
(* Display_Kermit_Message_2 --- Display Kermit reception status message *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Kermit_Message_2( Status_Text: AnyStr );

BEGIN (* Display_Kermit_Message_2 *)

   IF ( NOT Display_Status ) THEN
      Flip_Display_Status;

   IF Display_Status THEN
      BEGIN

         Update_Kermit_Display;

         GoToXY( 2 , Kermit_Mess2_Line );
         WRITE( Status_Text );
         ClrEol;

      END;

   Write_Log( Status_Text, TRUE, FALSE );

END   (* Display_Kermit_Message_2 *);

(*----------------------------------------------------------------------*)
(* Display_Kermit_Message_3 --- Display Kermit reception status message *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Kermit_Message_3( Status_Text: AnyStr );

BEGIN (* Display_Kermit_Message_3 *)

   IF ( NOT Display_Status ) THEN
      Flip_Display_Status;

   IF Display_Status THEN
      BEGIN

         Update_Kermit_Display;

         GoToXY( 2 , Kermit_Mess3_Line );
         WRITE( Status_Text );
         ClrEol;

      END;

   Write_Log( Status_Text, TRUE, FALSE );

END   (* Display_Kermit_Message_3 *);

(*----------------------------------------------------------------------*)
(*       Kermit_Clear_Message_Lines --- Clear Kermit message lines      *)
(*----------------------------------------------------------------------*)

PROCEDURE Kermit_Clear_Message_Lines;

BEGIN (* Kermit_Clear_Message_Lines *)

   IF Display_Status THEN
      BEGIN

         GoToXY( 1 , Kermit_Mess2_Line );
         ClrEol;

         GoToXY( 1 , Kermit_Mess3_Line );
         ClrEol;

      END;

END   (* Kermit_Clear_Message_Lines *);