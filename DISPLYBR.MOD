(*----------------------------------------------------------------------*)
(*   Display_Batch_Transfer_Window --- Display batch transfer window    *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Batch_Window;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Batch_Window;                                *)
(*                                                                      *)
(*     Purpose:    Initializes display for batch transfer window        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Batch_Window                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Tname       : STRING[20];
   Batch_Title : AnyStr;

BEGIN (* Display_Batch_Window *)
                                   (* Save current screen image *)
   Save_Screen( Batch_Screen_Ptr );
                                   (* Construct title based upon *)
                                   (* transfer type              *)
   CASE Transfer_Protocol OF
      Telink       : Tname := 'Telink';
      Modem7_Chk   : Tname := 'Modem7 (Checksum)';
      Modem7_CRC   : Tname := 'Modem7 (CRC)';
      Ymodem_Batch : Tname := 'Ymodem Batch';
      Ymodem_G     : Tname := 'Ymodem G Batch';
      SeaLink      : Tname := 'SEALink';
      Rlink        : Tname := 'Rlink';
   END (* CASE *);
                                   (* Draw menu frame            *)

   Batch_Title := 'Batch file download using ' + Tname;

   Draw_Menu_Frame( 2, 2, 79, 24, Menu_Frame_Color, Menu_Title_Color,
                    Menu_Text_Color, Batch_Title );

   Write_Log( Batch_Title , FALSE , FALSE );

   PibTerm_Window( 3, 3, 78, 23 );

END   (* Display_Batch_Window *);
