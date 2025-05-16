(*----------------------------------------------------------------------*)
(*          Scroll_Up --- Handle graphics screen scroll                 *)
(*----------------------------------------------------------------------*)

PROCEDURE ScrollUp;

BEGIN (* ScrollUp *)

   IF LeftH THEN
      BEGIN
         LeftH := FALSE;
         Graphics_XPos := 320;
      END
   ELSE
      BEGIN
         LeftH := TRUE;
         Graphics_XPos := 0;
      END;

   Graphics_YPos := 5;

END   (* ScrollUp *);

(*----------------------------------------------------------------------*)
(*           Handle_Escape_Sequence --- Handle escape sequence          *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Escape_Sequence;

VAR
   Ch: CHAR;

(*----------------------------------------------------------------------*)

FUNCTION Async_Next_Character : CHAR;

VAR
   C:  INTEGER;

BEGIN (* Async_Next_Character *)

   Async_Receive_With_Timeout( 5 , C );

   IF ( C <> TimeOut ) THEN
      Async_Next_Character := CHR( C )
   ELSE
      Async_Next_Character := CHR(0);

END   (* Async_Next_Character *);

(*----------------------------------------------------------------------*)

BEGIN (* Handle_Escape_Sequence *)

   CASE Async_Next_Character OF

      '/':      BEGIN
                   IF Async_Next_Character IN ['0'..'2'] THEN
                      IF Async_Next_Character = 'd' THEN;
                END;

      '8','9',':',';','?','''': ;

      'a'..'z': ;

      '"':      BEGIN
                   IF Async_Next_Character IN ['0'..'7'] THEN
                      IF Async_Next_Character IN ['e','g'] THEN;
                END;

      Ch_FF:    BEGIN
                   Clear_Graphics_Screen;
                   FlagG := Text_Plot;
                END;

      Ch_FS:   FlagG := Point_Plot_Start;

      Ch_GS:   FlagG := Vector_Plot_Start;

      ELSE;

   END (* CASE *);

END   (* Handle_Escape_Sequence *);

(*----------------------------------------------------------------------*)

BEGIN (* Display_Graphics *)
                                   (* Remove current cursor       *)

   Display_Cursor( CursorX, CursorY );

                                   (* Select display depending on *)
                                   (* character.                  *)
   C := ORD( Ch );

   IF ( FlagG = Text_Plot ) THEN
      CASE C OF

         NUL  :    ;       (* Strip Nulls              *)
         DEL  :    ;       (* Strip Deletes            *)

         ESC  :    Handle_Escape_Sequence;

         BS   :    BEGIN
                      IF LeftH THEN
                         Graphics_XPos := MAX( Graphics_Xpos - 8 , 0 )
                      ELSE
                         Graphics_XPos := MAX( Graphics_Xpos - 8 , 320 );
                   END;

         BELL :    IF Not Silent_Mode THEN
                      WRITE( Ch );

         HT   :    BEGIN

                      L := 9 - WhereX MOD 8;

                      FOR I := 1 TO L DO
                         BEGIN
                            Plot_Char( BL_Ch, Graphics_XPos, Graphics_YPos );
                            Graphics_XPos := Graphics_XPos + 8;
                         END;

                   END;

         FF   :    Clear_Graphics_Screen;

         CR   :    IF Add_LF THEN
                      BEGIN
                         Graphics_YPos := Graphics_YPos + YInc;
                         Last_Column_Hit := FALSE;
                         IF Graphics_YPos > YMaxM1 THEN
                            ScrollUp
                         ELSE IF LeftH THEN
                            Graphics_XPos := 0
                         ELSE
                            Graphics_XPos := 320;
                      END
                   ELSE
                      BEGIN
                         IF LeftH THEN
                            Graphics_XPos := 0
                         ELSE
                            Graphics_XPos := 320;
                         Last_Column_Hit := FALSE;
                      END;


         LF   :    IF NOT Add_LF THEN
                      BEGIN
                         Graphics_YPos := Graphics_YPos + YInc;
                         IF Graphics_YPos > YMaxM1 THEN
                            ScrollUp;
                      END;

         VT   :    IF ( Graphics_YPos > YInc ) THEN
                      Graphics_YPos := Graphics_YPos - YInc;

         FS   :    FlagG := Point_Plot_Start;

         GS   :    FlagG := Vector_Plot_Start;

         SOH  :    IF ( NOT Handle_Kermit_Autodownload ) THEN;

         CAN  :    IF ( NOT Handle_Zmodem_Autodownload ) THEN;

         ELSE
            IF ( C > 31 ) THEN
               BEGIN
                  Plot_Char( Ch, Graphics_XPos, Graphics_YPos );
                  Graphics_XPos := Graphics_XPos + 8;
                  IF ( Graphics_XPos >= 640 ) THEN
                     BEGIN
                        Graphics_XPos := 0;
                        Graphics_YPos := Graphics_YPos + YInc;
                        IF Graphics_YPos > YMaxM1 THEN
                           ScrollUp;
                     END;

               END;

      END (* CASE *)

   ELSE                            (* Graphics mode *)

      CASE C OF

         FF:      BEGIN
                     Clear_Graphics_Screen;
                     FlagG := Text_Plot;
                  END;

         CR:      BEGIN
                     IF LeftH THEN
                        Graphics_XPos := 0
                     ELSE
                        Graphics_XPos := 320;
                     Last_Column_Hit := FALSE;
                     FlagG := Text_Plot;
                  END;

         FS:      FlagG := Point_Plot_Start;

         GS:      FlagG := Vector_Plot_Start;

         US:      FlagG := Text_Plot;

         ESC:     Handle_Escape_Sequence;

         ELSE
            IF C > 31 THEN
               Do_Graphics;

      END (* CASE *);
                                   (* Display cursor *)

   Display_Cursor( Graphics_XPos, Graphics_YPos );

   CursorX := Graphics_XPos;
   CursorY := Graphics_YPos;

END   (* Display_Graphics *);

(*----------------------------------------------------------------------*)
(*  Initialize_Graphics_Mode --- Initialize for CGA/EGA differences     *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Graphics_Mode;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Initialize_Graphics_Mode                             *)
(*                                                                      *)
(*     Purpose:    Set up graphics mode for CGA/EGA differences         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Initialize_Graphics_Mode;                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Initialize_Graphics_Mode *)

                                   (* Determine if EGA installed       *)

   EGA_On := EGA_Present;

                                   (* Set up depending upon EGA or CGA *)

   IF ( EGA_On AND Allow_EGA_Graphics ) THEN
      BEGIN
         XFactor               := 0.625;
         YFactor               := 0.44871795;
         YMax                  := 349;
         YInc                  := 10;
         GMode                 := EGA_GraphMode;
         Write_Graphics_Screen := Write_Screen_Memory;
         EGA_Use               := TRUE;
         Set_EGA_Text_Mode( 25 );
      END
   ELSE
      BEGIN
         XFactor               := 0.625;
         YFactor               := 0.2564103;
         YMax                  := 199;
         YInc                  := 6;
         GMode                 := HiRes_GraphMode;
         Write_Graphics_Screen := Write_Screen_Memory;
         EGA_Use               := FALSE;
      END;

   YMaxM1 := PRED( YMax );

   IF EGA_Use THEN
      Graphics_Screen := PTR( EGA_Screen_Address   , 0 )
   ELSE
      IF ( MultiTasker <> MultiTasker_None ) THEN
         Graphics_Screen := DesqView_Screen
      ELSE
         Graphics_Screen := PTR( Color_Screen_Address , 0 );

END   (* Initialize_Graphics_Mode *);

(*----------------------------------------------------------------------*)

BEGIN (* Emulate_TEK4010 *)
                                   (* Initialize *)
   Graphics_Terminal_Mode := TRUE;
   Auto_Wrap_Mode         := TRUE;
   Done                   := FALSE;
   Do_Status_Line         := FALSE;
   Do_Status_Time         := FALSE;
   FlagG                  := Text_Plot;
   New_Line               := New_Line_Param;
   Insertion_Mode         := FALSE;
   Save_SUpper            := Send_Upper_Case_Only;
   Send_Upper_Case_Only   := TRUE;
   Do_Script_Tests        := Waitstring_Mode OR When_Mode OR
                             WaitCount_Mode  OR WaitQuiet_Mode OR
                             Script_Learn_Mode;

                                   (* Load function keys             *)
   IF Auto_Load_FunKeys THEN
      Load_Function_Keys( 'TEK4010.FNC' );

   Graphics_ForeGround_Color := Global_ForeGround_Color;
   Graphics_BackGround_Color := Global_BackGround_Color;

                                   (* Set up depending upon EGA/CGA *)
   Initialize_Graphics_Mode;
                                   (* Clear graphics screen      *)
   Clear_Graphics_Screen;
                                   (* Display cursor *)

   Display_Cursor( CursorX , CursorY );

                                   (* Loop over input until done *)
   WHILE ( NOT Done ) DO
      BEGIN
                                   (* Check for character typed at keyboard *)
         IF PibTerm_KeyPressed THEN
            BEGIN
               Handle_Keyboard_Input( Done , Reset_Requested ,
                                      ClrScr_Req );
               Do_Status_Line        := FALSE;
               Do_Status_Time        := FALSE;
               Write_Graphics_Screen := Write_Screen_Memory;
               IF Reset_Requested THEN
                  BEGIN
                     Clear_Graphics_Screen;
                     Display_Cursor( CursorX, CursorY );
                     FlagG := Text_Plot;
                  END
               ELSE IF ClrScr_Req THEN
                  BEGIN
                     Clear_Graphics_Screen;
                     Display_Cursor( CursorX, CursorY );
                  END;
            END;
                                   (* Process any script in progress *)

         IF ( Script_File_Mode AND ( NOT ( Done OR Really_Wait_String ) ) ) THEN
            BEGIN
               Get_Script_Command( PibTerm_Command );
               Execute_Command   ( PibTerm_Command , Done , TRUE );
               Write_Graphics_Screen := Write_Screen_Memory;
            END;
                                   (* Handle carrier drop *)
         IF Carrier_Dropped THEN
            Handle_Carrier_Drop;
                                   (* Hold everything while scroll lock on *)

         IF Scroll_Lock_On THEN
            Handle_Scroll_Lock;

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

                                   (* Display the character received *)

               Display_Graphics( Ch );

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

   Graphics_Terminal_Mode := FALSE;
   Send_Upper_Case_Only   := Save_SUpper;

END   (* Emulate_TEK4010 *);
