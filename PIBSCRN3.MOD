(*----------------------------------------------------------------------*)
(*                Save_Screen --- Save current screen image             *)
(*----------------------------------------------------------------------*)

PROCEDURE Save_Partial_Screen( VAR Saved_Screen_Pointer : Saved_Screen_Ptr;
                                   X1                   : INTEGER;
                                   Y1                   : INTEGER;
                                   X2                   : INTEGER;
                                   Y2                   : INTEGER  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Save_Partial_Screen                                  *)
(*                                                                      *)
(*     Purpose:    Saves part of current screen image                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Save_Partial_Screen( VAR Saved_Screen_Pointer :               *)
(*                                      Saved_Screen_Ptr;               *)
(*                                 X1                   : INTEGER;      *)
(*                                 Y1                   : INTEGER;      *)
(*                                 X2                   : INTEGER;      *)
(*                                 Y2                   : INTEGER  );   *)
(*                                                                      *)
(*           Saved_Screen_Pointer  --- pointer to record receiving      *)
(*                                     screen image, window location,   *)
(*                                     and current cursor location.     *)
(*           (X1,Y1)               --- upper left hand corner of area   *)
(*                                     to be saved.                     *)
(*           (X2,Y2)               --- lower right hand corner of area  *)
(*                                     to be saved.                     *)
(*                                                                      *)
(*     Calls:   Move                                                    *)
(*              Upper_Left                                              *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This version checks for stack overflow.                       *)
(*                                                                      *)
(*        Note that text modes can be handled through the BIOS, but     *)
(*        graphics modes always go directly to screen memory -- a       *)
(*        problem to fix sometime in the future.                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   GetMem_Length: WORD;
   Graphics_Mode: BOOLEAN;
   X            : INTEGER;
   Y            : INTEGER;
   SaveX        : INTEGER;
   SaveY        : INTEGER;
   Regs         : Registers;
   S_Pos        : INTEGER;
   F_Pos        : INTEGER;
   L            : INTEGER;
   SVal         : STRING[10];
   SVal2        : STRING[10];
   Vid_Mode     : INTEGER;
   Screen_APtr  : Screen_Ptr;
   EGA_GMode    : BOOLEAN;

BEGIN  (* Save_Partial_Screen *)
                                   (* Figure if graphics mode or text  *)
   SaveX := WhereX;
   SaveY := WhereY;

   Vid_Mode      := Current_Video_Mode;
   Graphics_Mode := ( Vid_Mode >= MedRes_GraphMode ) AND
                    ( Vid_Mode <> Mono_TextMode );
   L             := SIZEOF( Saved_Screen_Type ) - SIZEOF( Screen_Type );
   EGA_GMode     := ( Vid_Mode = EGA_GraphMode );

   IF Graphics_Mode THEN
      BEGIN
         IF EGA_GMode THEN
            IF Really_Save_EGA THEN
               GetMem_Length := EGA_Graphics_Scr_Length + L
            ELSE
               GetMem_Length := L
         ELSE
            GetMem_Length := Graphics_Screen_Length + L;
         F_Pos         := 1;
      END
   ELSE
      BEGIN
         F_Pos         := ( Y1 - 1 ) * Max_Screen_Col + X1;
         S_Pos         := ( Y2 - 1 ) * Max_Screen_Col + X2;
         GetMem_Length := ( S_Pos - F_Pos + 1 ) * 2 + L;
      END;
                                   (* Overwrite last screen if no room *)
                                   (* This needs to be fixed later     *)

   IF ( Current_Saved_Screen >= Max_Saved_Screen ) THEN
      Saved_Screen_Pointer := Saved_Screen_List[ Max_Saved_Screen ]
   ELSE
      BEGIN
         INC( Current_Saved_Screen );
         GETMEM( Saved_Screen_Pointer , GetMem_Length );
         Saved_Screen_List[ Current_Saved_Screen ] := Saved_Screen_Pointer;
      END;


   IF ( Saved_Screen_Pointer = NIL ) THEN
      BEGIN
         WRITELN;
         WRITELN('Not enough memory to save screen, display will be');
         WRITELN('incorrect from now on.  PibTerm may also abort shortly.');
         Press_Any;
      END
   ELSE WITH Saved_Screen_Pointer^ DO
      BEGIN

         IF ( NOT Graphics_Mode ) THEN
            BEGIN

               Upper_Left( Window_X1, Window_Y1 );

               Window_X2     := Lower_Right_Column;
               Window_Y2     := Lower_Right_Row;

               Screen_Row    := SaveY;
               Screen_Column := SaveX;

               Screen_X1     := PRED( X1 );
               Screen_Y1     := PRED( Y1 );

               Screen_X2     := PRED( X2 );
               Screen_Y2     := PRED( Y2 );

            END
         ELSE
            BEGIN

               Window_X1     := 0;
               Window_Y1     := 0;

               IF ( Vid_Mode >= HiRes_GraphMode ) THEN
                  Window_X2  := 639
               ELSE
                  Window_X2  := 319;

               IF EGA_GMode THEN
                  Window_Y2  := 349
               ELSE
                  Window_Y2  := 199;

               Screen_X1     := 0;
               Screen_Y1     := 0;

               Screen_X2     := 639;

               IF EGA_GMode THEN
                  Screen_Y2  := 349
               ELSE
                  Screen_Y2  := 199;

               Screen_Row    := Graphics_YPos;
               Screen_Column := Graphics_XPos;

            END;

         Screen_Size := GetMem_Length - L;
         If_BIOS     := NOT Write_Screen_Memory;
         Video_Mode  := Vid_Mode;

                                   (* Freeze screen for DoubleDos *)

         IF ( MultiTasker = DoubleDos ) THEN
            BEGIN
               TurnOffTimeSharing;
               Get_Screen_Address( DesqView_Screen );
            END;

         IF Graphics_Mode THEN
            BEGIN

               IF ( MultiTasker = DoubleDos ) THEN
                  Screen_APtr := DesqView_Screen
               ELSE
                  IF EGA_GMode THEN
                     Screen_APtr := PTR( EGA_Screen_Address , 0 )
                  ELSE
                     Screen_APtr := PTR( Color_Screen_Address , 0 );

               IF ( Screen_Size > 0 ) THEN
                  MOVE( Screen_APtr^.Screen_Image[1],
                        Screen_Image[1], Screen_Size );

            END
         ELSE IF Write_Screen_Memory THEN
            IF Wait_For_Retrace THEN
               MoveFromScreen( DesqView_Screen^.Screen_Image[F_Pos * 2 - 1],
                               Screen_Image[1], Screen_Size SHR 1 )
            ELSE
               MOVE( DesqView_Screen^.Screen_Image[F_Pos * 2 - 1],
                     Screen_Image[1], Screen_Size )
         ELSE
            BEGIN                  (* Use BIOS (SLOW!!!) *)

               S_Pos := 1;
                                   (* Turn off the cursor *)
               CursorOff;
                                   (* Loop over screen area *)

               FOR Y := Y1 TO Y2 DO
                  FOR X := X1 TO X2 DO
                     BEGIN
                        ReadCXY( Screen_Image[S_Pos], X, Y, Screen_Image[S_Pos + 1] );
                        S_Pos := S_Pos + 2;
                     END;
                                   (* Restore previous position *)

               GoToXY( SaveX, SaveY );

                                   (* Turn on the cursor   *)
               CursorOn;

            END;
                                   (* Unfreeze screen in DoubleDos *)

         IF ( MultiTasker = DoubleDos ) THEN
            TurnOnTimeSharing;

         IF Graphics_Mode THEN
            BEGIN
               Set_Text_Mode( Text_Mode );
               IF EGA_Present THEN
                  Set_EGA_Text_Mode( Max_Screen_Line );
               Reset_Global_Colors;
            END;

      END;

END   (* Save_Partial_Screen *);

(*----------------------------------------------------------------------*)
(*              Restore_Screen --- Restore saved screen image           *)
(*----------------------------------------------------------------------*)

PROCEDURE Restore_Screen( VAR Saved_Screen_Pointer : Saved_Screen_Ptr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Restore_Screen                                       *)
(*                                                                      *)
(*     Purpose:    Restores previously saved screen image.              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Restore_Screen( VAR Saved_Screen_Pointer: Saved_Screen_Ptr ); *)
(*                                                                      *)
(*           Saved_Screen_Pointer  --- pointer to record with saved     *)
(*                                     screen image, window location,   *)
(*                                     and cursor location.             *)
(*                                                                      *)
(*     Calls:   Window                                                  *)
(*              Move                                                    *)
(*              GoToXY                                                  *)
(*              WriteCXY                                                *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        All saved screen pointers from the last saved down to the     *)
(*        argument pointer are popped from the saved screen list.       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   X            : BYTE;
   Y            : BYTE;
   I            : INTEGER;
   L            : INTEGER;
   F_Pos        : INTEGER;
   Graphics_Mode: BOOLEAN;
   Regs         : Registers;
   SVal         : AnyStr;
   Vid_Mode     : INTEGER;
   EGA_On       : BOOLEAN;
   Screen_APtr  : Screen_Ptr;

BEGIN  (* Restore_Screen *)
                                   (* Don't restore screen if pointer  *)
                                   (* is nil                           *)

   IF ( Saved_Screen_Pointer = NIL ) THEN EXIT;

                                   (* Figure if graphics mode or text  *)

   Vid_Mode      := Current_Video_Mode;
   Graphics_Mode := ( Vid_Mode >= MedRes_GraphMode ) AND
                    ( Vid_Mode <> Mono_TextMode );
   L             := SIZEOF( Saved_Screen_Type ) - SIZEOF( Screen_Type );
   EGA_On        := EGA_Present;

   WITH Saved_Screen_Pointer^ DO
      BEGIN

         IF ( Video_Mode >= MedRes_GraphMode ) AND
            ( Video_Mode <> Mono_TextMode    ) THEN
            BEGIN  (* Process saved graphics screen *)

               IF ( NOT Graphics_Mode ) THEN
                  BEGIN
                                   (* If EGA on, make sure 25 line *)
                                   (* text mode.                   *)

                     IF EGA_On THEN
                        Set_EGA_Text_Mode( 25 );

                                   (* Set graphics colors          *)

                     Set_Graphics_Colors( EGA_On, Video_Mode,
                                          Graphics_ForeGround_Color,
                                          Graphics_BackGround_Color );

                  END;
                                   (* Freeze screen for DoubleDos *)

               IF ( MultiTasker = DoubleDos ) THEN
                  BEGIN
                     TurnOffTimeSharing;
                     Get_Screen_Address( DesqView_Screen );
                  END;

               IF ( Video_Mode = EGA_GraphMode ) THEN
                  Screen_APtr := PTR( EGA_Screen_Address , 0 )
               ELSE
                  Screen_APtr := DesqView_Screen;

               IF ( Screen_Size > 0 ) THEN
                  MOVE( Screen_Image, Screen_APtr^.Screen_Image,
                        Screen_Size );

                                   (* Unfreeze screen in DoubleDos *)

               IF ( MultiTasker = DoubleDos ) THEN
                  TurnOnTimeSharing;

               GraphWindow( Window_X1, Window_Y1, Window_X2, Window_Y2 );

               Graphics_XPos := Screen_Column;
               Graphics_YPos := Screen_Row;

            END    (* Process saved graphics screen *)
         ELSE
            BEGIN   (* Process saved text screen *)

               IF Graphics_Mode THEN
                  BEGIN
                     Set_Text_Mode( Text_Mode );
                     IF EGA_On THEN
                        Set_EGA_Text_Mode( Max_Screen_Line );
                     Reset_Global_Colors;
                  END;

               IF ( Write_Screen_Memory AND ( NOT IF_Bios ) ) THEN
                  BEGIN
                                   (* Freeze screen for DoubleDos *)

                     IF ( MultiTasker = DoubleDos ) THEN
                        BEGIN
                           TurnOffTimeSharing;
                           Get_Screen_Address( DesqView_Screen );
                        END;
                                   (* Restore screen image *)

                     F_Pos := ( Screen_Y1 * Max_Screen_Col + Screen_X1 ) * 2 + 1;

                     IF Wait_For_Retrace THEN
                        MoveToScreen( Screen_Image[1],
                                      DesqView_Screen^.Screen_Image[F_Pos],
                                      Screen_Size SHR 1 )
                     ELSE
                        MOVE( Screen_Image[1],
                              DesqView_Screen^.Screen_Image[F_Pos],
                              Screen_Size );

                                   (* Unfreeze screen in DoubleDos *)

                     IF ( MultiTasker = DoubleDos ) THEN
                         TurnOnTimeSharing

                                   (* Synchronize screen for TopView *)

                     ELSE IF ( MultiTasker = TopView ) THEN
                         Sync_Screen( F_Pos , Screen_Size SHR 1 );

                  END
               ELSE
                  BEGIN
                                   (* Turn off the cursor   *)
                     CursorOff;

                     I := 1;
                                   (* Loop over screen area *)

                     FOR Y := Screen_Y1 TO Screen_Y2 DO
                        FOR X := Screen_X1 TO Screen_X2 DO
                           BEGIN
                              WriteCXY( CHR(Screen_Image[I]), X + 1, Y + 1,
                                        Screen_Image[I+1] );
                              I := I + 2;
                           END;
                                   (* Turn on the cursor *)
                     CursorOn;

                  END;

               PibTerm_Window( Window_X1, Window_Y1, Window_X2, Window_Y2 );
               GoToXY( Screen_Column, Screen_Row );

            END    (* Process saved text screen *);

      END;

   WHILE ( ( Current_Saved_Screen > 0 ) AND
           ( Saved_Screen_List[ Current_Saved_Screen ] <> Saved_Screen_Pointer ) ) DO
      BEGIN
         IF ( Saved_Screen_List[ Current_Saved_Screen ] <> NIL ) THEN
            BEGIN
               FREEMEM( Saved_Screen_List[ Current_Saved_Screen ] ,
                        Saved_Screen_List[ Current_Saved_Screen ]^.Screen_Size + L );
               Saved_Screen_List[ Current_Saved_Screen ] := NIL;
            END;
         DEC( Current_Saved_Screen );
      END;

   IF ( Current_Saved_Screen > 0 ) THEN
      BEGIN
         Saved_Screen_List[ Current_Saved_Screen ] := NIL;
         DEC( Current_Saved_Screen );
      END;

   IF ( Saved_Screen_Pointer <> NIL ) THEN
      BEGIN
         FREEMEM( Saved_Screen_Pointer , Saved_Screen_Pointer^.Screen_Size + L );
         Saved_Screen_Pointer := NIL;
      END;
                                   (* Update status line *)
   Current_Status_Time := -1;

   IF Do_Status_Time THEN
      Update_Status_Line;

END    (* Restore_Screen *);

(*----------------------------------------------------------------------*)
(*                Save_Screen --- Save current screen image             *)
(*----------------------------------------------------------------------*)

PROCEDURE Save_Screen( VAR Saved_Screen_Pointer : Saved_Screen_Ptr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Save_Screen                                          *)
(*                                                                      *)
(*     Purpose:    Saves entire current screen image                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Save_Screen( VAR Saved_Screen_Pointer : Saved_Screen_Ptr );   *)
(*                                                                      *)
(*           Saved_Screen_Pointer  --- pointer to record receiving      *)
(*                                     screen image, window location,   *)
(*                                     and current cursor location.     *)
(*                                                                      *)
(*     Calls:   Save_Partial_Screen                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Save_Screen *)

   Save_Partial_Screen( Saved_Screen_Pointer, 1, 1, Max_Screen_Col,
                        Max_Screen_Line );

END   (* Save_Screen *);

(*----------------------------------------------------------------------*)
(*  Restore_Screen_And_Colors --- Restore saved screen image and colors *)
(*----------------------------------------------------------------------*)

PROCEDURE Restore_Screen_And_Colors( VAR Saved_Screen_Pointer : Saved_Screen_Ptr );

BEGIN (* Restore_Screen_And_Colors *)

   Restore_Screen( Saved_Screen_Pointer );
   Reset_Global_Colors;

END   (* Restore_Screen_And_Colors *);

(*----------------------------------------------------------------------*)
(*  Draw_Titled_Box --- Save portion of screen and draw a titled box    *)
(*----------------------------------------------------------------------*)

PROCEDURE Draw_Titled_Box( VAR Saved_Screen_Pointer : Saved_Screen_Ptr;
                               UpperLeftX           : INTEGER;
                               UpperLeftY           : INTEGER;
                               LowerRightX          : INTEGER;
                               LowerRightY          : INTEGER;
                               Box_Title            : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Draw_Titled_Box                                      *)
(*                                                                      *)
(*     Purpose:    Draws a titled frame using PC graphics characters    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*                                                                      *)
(*        Draw_Titled_Box( VAR Saved_Screen_Pointer : Saved_Screen_Ptr; *)
(*                             UpperLeftX           : INTEGER;          *)
(*                             UpperLeftY           : INTEGER;          *)
(*                             LowerRightX          : INTEGER;          *)
(*                             LowerRightY          : INTEGER;          *)
(*                             Box_Title            : AnyStr );         *)
(*                                                                      *)
(*           UpperLeftX,  UpperLeftY  --- Upper left coordinates        *)
(*           LowerRightX, LowerRightY --- Lower right coordinates       *)
(*           Box_Title                --- Box Title                     *)
(*                                                                      *)
(*     Calls:   Draw_Menu_Frame                                         *)
(*              Save_Partial_Screen                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Draw_Titled_Box *)
                                   (* Save portion of screen *)

   Save_Partial_Screen( Saved_Screen_Pointer,
                        UpperLeftX,
                        UpperLeftY,
                        LowerRightX,
                        LowerRightY           );

                                   (* Draw the box *)

   Draw_Menu_Frame    ( UpperLeftX,
                        UpperLeftY,
                        LowerRightX,
                        LowerRightY,
                        Menu_Frame_Color,
                        Menu_Title_Color,
                        Menu_Text_Color,
                        Box_Title            );

END   (* Draw_Titled_Box *);
