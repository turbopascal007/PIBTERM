(*----------------------------------------------------------------------*)
(*           GENTERM.PAS --- General Terminal Emulator for PIBTERM      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Author:  Philip R. Burns                                            *)
(*  Version: 1.0   (November, 1986)  for v4.0 of PibTerm.               *)
(*           1.1   (December, 1987)  for new CISB stuff.                *)
(*  Systems: For MS-DOS on IBM PCs and close compatibles only.          *)
(*                                                                      *)
(*  History: Original with me.                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Emulate_General_Terminal;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Emulate_General_Terminal                             *)
(*                                                                      *)
(*     Purpose:    Controls general terminal emulation                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Emulate_General_Terminal;                                     *)
(*                                                                      *)
(*      Calls:   Async_Send                                             *)
(*               Async_Receive                                          *)
(*               Pibterm_keypressed                                             *)
(*               Process_Command                                        *)
(*               Display_Character                                      *)
(*               Async_Buffer_Full                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Done           : BOOLEAN    (* TRUE to exit terminal emulation mode *);
   Ch             : CHAR       (* Character read/written               *);
   B              : BOOLEAN    (* General boolean flag                 *);
   ClrScr_Req     : BOOLEAN    (* Clear screen request                 *);
   Save_Do_Status : BOOLEAN    (* Saves status line status             *);
   Save_CISB      : BOOLEAN    (* Saves CISB status                    *);
   Save_Kermit    : BOOLEAN    (* Saves Kermit status                  *);
   Save_Zmodem    : BOOLEAN    (* Saves Zmodem status                  *);
   Save_State     : INTEGER    (* Saves display action state           *);

                               (* Saves character set pointer          *)
   Save_CPtr      : Character_Vector_Ptr_Type;


BEGIN (* Emulate_General_Terminal *)

                                  (* Initialize text mode display   *)
   Init_Text_Terminal;
                                  (* Set other emulation variables  *)

   Reset_General_Terminal( FALSE );

                                   (* Not done here yet *)
   Done := FALSE;
                                   (* Loop over input until done *)
   WHILE ( NOT Done ) DO
      BEGIN
                                   (* Check for character typed at keyboard *)
         IF PibTerm_KeyPressed THEN
            BEGIN

               Save_Do_Status := Do_Status_Line;
               Save_CISB      := CompuServe_B_On;
               Save_Kermit    := Kermit_Autodownload;
               Save_Zmodem    := Zmodem_Autodownload;

               Handle_Keyboard_Input( Done , Reset_Requested ,
                                      ClrScr_Req );
               IF Reset_Requested THEN
                  BEGIN
                     Clear_Window;
                     Reset_General_Terminal( TRUE );
                     ClrScr_Req := FALSE;
                  END;

               IF ClrScr_Req THEN
                  Clear_Window;

               IF ( Save_Do_Status <> Do_Status_Line ) THEN
                  BEGIN

                     IF Do_Status_Line THEN
                        Ansi_Last_Line := Max_Screen_Line - 1
                     ELSE
                        Ansi_Last_Line := Max_Screen_Line;

                     PibTerm_Window( 1, 1, Max_Screen_Col, Ansi_Last_Line );

                  END;

               IF ( ( Save_CISB   <> CompuServe_B_On       ) OR
                    ( Save_Kermit <> Kermit_Autodownload   ) OR
                    ( Save_Zmodem <> Zmodem_Autodownload   ) ) THEN
                  BEGIN
                     Save_State := Display_Action_State;
                     Save_CPtr  := Character_Set_Ptr;
                     Set_Display_Actions;
                     Display_Action_State  := Save_State;
                     Character_Set_Ptr     := Save_CPtr;
                  END;

            END   (* PibTerm_KeyPressed *);

         IF ( Script_File_Mode AND ( NOT ( Done OR Really_Wait_String ) ) ) THEN
            BEGIN
               Get_Script_Command( PibTerm_Command );
               Execute_Command   ( PibTerm_Command , Done , TRUE );
            END;
                                   (* Hold everything while scroll lock on *)

         IF Scroll_Lock_On THEN
            Handle_Scroll_Lock;
                                   (* Handle carrier drop *)
         IF Carrier_Dropped THEN
            Handle_Carrier_Drop;
                                   (* Process character from remote *)

         IF ( Async_Buffer_Head <> Async_Buffer_Tail ) THEN
            BEGIN
                                   (* Get the character *)

               B := Async_Receive( Ch );

                                   (* Strip high bit if requested *)

               IF Auto_Strip_High_Bit THEN
                  Ch := CHR( ORD( Ch ) AND $7F );

                                   (* Perform translation *)

               Ch := TrTab[Ch];

                                   (* Display the character received. *)

               B := Do_Display_Action( Ch , Done );

               IF Do_Script_Tests THEN
                  Do_Script_Checks( Ch );

            END
                                   (* Check if waitstring time exhausted *)
         ELSE
            BEGIN
               Async_Line_Status := Async_Line_Status AND $FD;
               IF Really_Wait_String THEN
                  Check_Wait_String_Time;
               IF ( ( NOT PibTerm_KeyPressed ) AND ( NOT Script_File_Mode ) ) THEN
                  IF ( Async_Buffer_Head = Async_Buffer_Tail ) THEN
                     GiveAwayTime( 1 );
            END;

      END;
                                   (* Reset whole screen as window *)

   PibTerm_Window( 1, 1, Max_Screen_Col, Max_Screen_Line );

END   (* Emulate_General_Terminal *);
