(*----------------------------------------------------------------------*)
(*              Do_Screen_Dump --- write screen image to file           *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Screen_Dump;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*      Procedure:  Do_Screen_Dump                                      *)
(*                                                                      *)
(*      Purpose:    Handles screen dump requests                        *)
(*                                                                      *)
(*      Calling sequence:                                               *)
(*                                                                      *)
(*         Do_Screen_Dump;                                              *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         Depending upon the current text/graphics mode, either the    *)
(*         text screen or the graphics screen is written out.           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Vid_Mode      : INTEGER;
   Graphics_Mode : BOOLEAN;

(*----------------------------------------------------------------------*)
(*      Do_Text_Screen_Dump --- write text screen image to file         *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Text_Screen_Dump;

BEGIN (* Do_Text_Screen_Dump *)

   Save_Partial_Screen( Saved_Screen, 10, 10, 70, 13 );

   IF Screen_Dump_Name <> '' THEN
      BEGIN
         Write_Screen( Screen_Dump_Name );
         Draw_Menu_Frame( 10, 10, 70, 13, Menu_Frame_Color, Menu_Title_Color,
                          Menu_Text_Color, '' );
         WRITE('Screen dump written to ',Screen_Dump_Name );
      END
   ELSE
      BEGIN
         Draw_Menu_Frame( 10, 10, 70, 13, Menu_Frame_Color, Menu_Title_Color,
                          Menu_Text_Color, '' );
         WRITE('No screen dump file defined, dump not done.');
      END;

   Window_Delay;

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Do_Text_Screen_Dump *);

(*----------------------------------------------------------------------*)
(*   Do_Graphics_Screen_Dump --- write graphics screen image to file    *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Graphics_Screen_Dump;

BEGIN (* Do_Graphics_Screen_Dump *)

   Save_Screen( Saved_Screen );

   IF Graphics_Dump_Name <> '' THEN
      BEGIN
         Write_Graphics_Screen( Graphics_Dump_Name );
         Draw_Menu_Frame( 10, 10, 70, 13, Menu_Frame_Color, Menu_Title_Color,
                          Menu_Text_Color, '' );
         WRITE('Screen dump written to ',Graphics_Dump_Name );
      END
   ELSE
      BEGIN
         Draw_Menu_Frame( 10, 10, 70, 13, Menu_Frame_Color, Menu_Title_Color,
                          Menu_Text_Color, '' );
         WRITE('No graphics screen dump file defined, dump not done.');
      END;

   Window_Delay;

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Do_Graphics_Screen_Dump *);

(*----------------------------------------------------------------------*)

BEGIN (* Do_Screen_Dump *)

   Vid_Mode      := Current_Video_Mode;
   Graphics_Mode := ( Vid_Mode >= MedRes_GraphMode ) AND
                    ( Vid_Mode <> Mono_TextMode );

   IF Graphics_Mode THEN
      Do_Graphics_Screen_Dump
   ELSE
      Do_Text_Screen_Dump;

END   (* Do_Screen_Dump *);