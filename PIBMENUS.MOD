(*----------------------------------------------------------------------*)
(*           PIBMENUS.PAS   --- Menu Routines for Turbo Pascal          *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Author:  Philip R. Burns                                            *)
(*                                                                      *)
(*  Date:    Version 1.0: January, 1985                                 *)
(*           Version 1.1: March, 1985                                   *)
(*           Version 1.2: May, 1985                                     *)
(*           Version 2.0: June, 1985                                    *)
(*           Version 2.1: July, 1985                                    *)
(*           Version 3.0: October, 1985                                 *)
(*           Version 3.2: November, 1985                                *)
(*           Version 4.0: March, 1986                                   *)
(*           Version 4.1: February, 1987                                *)
(*           Version 4.2: March, 1987                                   *)
(*                                                                      *)
(*  Systems: For MS-DOS on IBM PCs and close compatibles only.          *)
(*                                                                      *)
(*  History: These routines represent my substantial upgrading of the   *)
(*           simple menu routines written by Barry Abrahamsen which     *)
(*           I believe appeared originally in the TUG newsletter.       *)
(*           The windowing facility provides windows similar to those   *)
(*           implemented in QMODEM by John Friel III.                   *)
(*                                                                      *)
(*           Version 2.0 of these adds the exploding windows feature    *)
(*           as well the use-selectable box-drawing characters.         *)
(*           The exploding box algorithm is derived from one by         *)
(*           Jim Everingham.                                            *)
(*                                                                      *)
(*           Note that the routines present in PIBSCREN.PAS were        *)
(*           originally part of the PIBMENUS.PAS file.  With version    *)
(*           2.0 of PibMenus, PIBMENUS.PAS is split into the screen-    *)
(*           handling routines in PIBSCREN.PAS and the actual menu      *)
(*           routines in PIBMENUS.PAS.                                  *)
(*                                                                      *)
(*           Suggestions for improvements or corrections are welcome.   *)
(*           Please leave messages on Gene Plantz's BBS (312) 882 4145  *)
(*           or Ron Fox's BBS (312) 940 6496.                           *)
(*                                                                      *)
(*           If you use this code in your own programs, please be nice  *)
(*           and give all of us credit.                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Needs:  These routines need the include files MINMAX.PAS,           *)
(*          GLOBTYPE.PAS, ASCII.PAS, and PIBSCREN.PAS. These files      *)
(*          are not included here, since Turbo Pascal regrettably does  *)
(*          not allow nested includes.                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  What these routines do:                                             *)
(*                                                                      *)
(*    These routines provide a straight-forward menu-selection          *)
(*    facility, similar to that used in programs like Lotus.  A pop-up  *)
(*    window holds the menu.  The menu is contained in a frame.  The    *)
(*    items are displayed within the frame.  The currently selected     *)
(*    item is highlighted in reverse video.  You move up and down in    *)
(*    the list of menu items by using the up and down arrow keys, or    *)
(*    the space bar.  To make a selection, hit the Enter (Return) key.  *)
(*                                                                      *)
(*    Alternatively, you may hit the first character of a menu item.    *)
(*    The first menu item found with that initial letter is selected.   *)
(*                                                                      *)
(*    The characters comprising the menu box are user-selectable.       *)
(*    In addition, menus may just "pop up" onto the screen, or may      *)
(*    "explode" onto the screen.                                        *)
(*                                                                      *)
(*    Hitting the escape key causes a menu choice of "-1" to be         *)
(*    returned to the calling routine.                                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Use:                                                                *)
(*                                                                      *)
(*     (1)  Define a variable of type Menu_Type, say, MYMENU.           *)
(*                                                                      *)
(*     (2)  Define the following entries in MYMENU:                     *)
(*                                                                      *)
(*             Menu_Size    --- Number of entries in this menu          *)
(*             Menu_Title   --- Title for the menu                      *)
(*             Menu_Row     --- Row where menu should appear (upper LHC *)
(*             Menu_Column  --- Column where menu should appear         *)
(*             Menu_Width   --- Width of menu                           *)
(*             Menu_Height  --- Height of menu                          *)
(*             Menu_Default --- Ordinal of the default menu entry       *)
(*             Menu_Tcolor  --- Color to display menu text              *)
(*             Menu_Bcolor  --- Color for menu background               *)
(*             Menu_Fcolor  --- Color for menu frame box                *)
(*                                                                      *)
(*     (3)  Now for each of Menu_Size Menu_Entries, define:             *)
(*             Menu_Text   --- Text of menu item                        *)
(*                                                                      *)
(*     (4)  Optionally call  Menu_Set_Box_Chars  to define the          *)
(*          characters used to form the menu box.                       *)
(*                                                                      *)
(*     (5)  Optionally call Menu_Set_Explode to set the menus as either *)
(*          exploding or pop-up.                                        *)
(*                                                                      *)
(*     (6)  Optionally call Menu_Set_Beep to turn beeping on/off.       *)
(*                                                                      *)
(*     (7)  Call  Menu_Display_Choices  to display menu.  The default   *)
(*          menu choice will be highlighted.                            *)
(*                                                                      *)
(*     (8)  Call  Menu_Get_Choice  to retrieve menu choice.  The up and *)
(*          down arrows, and the space bar, can be used to move         *)
(*          through the menu items.  Each item is highlighted in turn.  *)
(*          Whichever item is highlighted when a carriage return is     *)
(*          entered is returned as the chosen item.                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Menu_Set_Explode( Explode_ON : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Menu_Set_Explode                                     *)
(*                                                                      *)
(*     Purpose:    Turn exploding menus on or off                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Menu_Set_Explode( Explode_ON : BOOLEAN );                     *)
(*                                                                      *)
(*           Explode_ON --- TRUE to use exploding menus,                *)
(*                          FALSE to use pop-up menus                   *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Menu_Set_Explode *)

   Menu_Explode_Mode := Explode_ON;

END   (* Menu_Set_Explode *);

(*----------------------------------------------------------------------*)
(*               Menu_Set_Beep --- Set beep mode on or off              *)
(*----------------------------------------------------------------------*)

PROCEDURE Menu_Set_Beep( Beep_ON : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Menu_Set_Beep                                        *)
(*                                                                      *)
(*     Purpose:    Turn beeping (errors, etc.) on or off                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Menu_Set_Beep( Beep_ON : BOOLEAN );                           *)
(*                                                                      *)
(*           Beep_ON --- TRUE to allow beeps,                           *)
(*                       FALSE to disallow beeps.                       *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Menu_Set_Beep *)

   Menu_Beep_Mode := Beep_ON;

END   (* Menu_Set_Beep *);

(*----------------------------------------------------------------------*)
(*     Menu_Set_Box_Chars --- Set box drawing characters for menus      *)
(*----------------------------------------------------------------------*)

PROCEDURE Menu_Set_Box_Chars( Top_Left_Corner     : CHAR;
                              Top_Line            : CHAR;
                              Top_Right_Corner    : CHAR;
                              Right_Line          : CHAR;
                              Bottom_Right_Corner : CHAR;
                              Bottom_Line         : CHAR;
                              Bottom_Left_Corner  : CHAR;
                              Left_Line           : CHAR  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Menu_Set_Box_Chars                                   *)
(*                                                                      *)
(*     Purpose:    Set box characters for drawing menu boxes            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Menu_Set_Box_Chars( Top_Left_Corner     : CHAR;               *)
(*                            Top_Line            : CHAR;               *)
(*                            Top_Right_Corner    : CHAR;               *)
(*                            Right_Line          : CHAR;               *)
(*                            Bottom_Right_Corner : CHAR;               *)
(*                            Bottom_Line         : CHAR;               *)
(*                            Bottom_Left_Corner  : CHAR;               *)
(*                            Left_Line           : CHAR  );            *)
(*                                                                      *)
(*           --- arguments are what their names suggest.                *)
(*                                                                      *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Menu_Set_Box_Chars *)

   Menu_Box_Chars.Top_Left_Corner     := Top_Left_Corner;
   Menu_Box_Chars.Top_Line            := Top_Line;
   Menu_Box_Chars.Top_Right_Corner    := Top_Right_Corner;
   Menu_Box_Chars.Right_Line          := Right_Line;
   Menu_Box_Chars.Bottom_Right_Corner := Bottom_Right_Corner;
   Menu_Box_Chars.Bottom_Line         := Bottom_Line;
   Menu_Box_Chars.Bottom_Left_Corner  := Bottom_Left_Corner;
   Menu_Box_Chars.Left_Line           := Left_Line;

END   (* Menu_Set_Box_Chars *);

(*----------------------------------------------------------------------*)
(*                      Draw_Box --- Draw a box                         *)
(*----------------------------------------------------------------------*)

PROCEDURE Draw_Box( X1, Y1, X2, Y2 : INTEGER;
                    Frame_Color    : INTEGER;
                    Title_Color    : INTEGER;
                    Title          : AnyStr   );

VAR
   I     : INTEGER;
   LT    : INTEGER;
   FColor: INTEGER;

BEGIN (* Draw_Box *)

   LT     := LENGTH( Title );
   FColor := Frame_Color;

   IF LT > 0 THEN
      BEGIN
         WriteSXY( Menu_Box_Chars.Top_Left_Corner + '[ ',
                   X1, Y1, FColor );
         WriteSXY( Title, X1 + 3, Y1, Title_Color );
         WriteSXY( ' ]', X1 + LT + 3, Y1, FColor );
      END
   ELSE
      WriteSXY( Menu_Box_Chars.Top_Left_Corner +
                DUPL( Menu_Box_Chars.Top_Line , 4 ), X1, Y1, FColor );

                                   (* Draw remainder of top of frame *)

   WriteSXY( Dupl( Menu_Box_Chars.Top_Line , X2 - X1 - LT - 5 ),
             ( X1 + LT + 5 ), Y1, FColor );

   WriteCXY( Menu_Box_Chars.Top_Right_Corner, X2, Y1, FColor );

                                  (* Draw sides of frame *)

   FOR I := SUCC( Y1 ) TO PRED( Y2 ) DO
      BEGIN
         WriteCXY( Menu_Box_Chars.Left_Line,  X1, I, FColor );
         WriteCXY( Menu_Box_Chars.Right_Line, X2, I, FColor );
      END;
                                  (* Draw bottom of frame     *)

   WriteCXY( Menu_Box_Chars.Bottom_Left_Corner, X1, Y2, FColor );

   WriteSXY( Dupl( Menu_Box_Chars.Bottom_Line , PRED( X2 - X1 ) ),
             SUCC( X1 ), Y2, FColor );

   WriteCXY( Menu_Box_Chars.Bottom_Right_Corner, X2, Y2, FColor );

END   (* Draw_Box *);

(*----------------------------------------------------------------------*)
(*                Draw_Menu_Frame --- Draw a Frame                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Draw_Menu_Frame( UpperLeftX,  UpperLeftY,
                           LowerRightX, LowerRightY : INTEGER;
                           Frame_Color, Title_Color,
                           Text_Color               : INTEGER;
                           Menu_Title: AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Draw_Menu_Frame                                      *)
(*                                                                      *)
(*     Purpose:    Draws a titled frame using PC graphics characters    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Draw_Menu_Frame( UpperLeftX,  UpperLeftY,                     *)
(*                         LowerRightX, LowerRightY,                    *)
(*                         Frame_Color, Title_Color : INTEGER;          *)
(*                         Menu_Title: AnyStr );                        *)
(*                                                                      *)
(*           UpperLeftX,  UpperLeftY  --- Upper left coordinates        *)
(*           LowerRightX, LowerRightY --- Lower right coordinates       *)
(*           Frame_Color              --- Color for frame               *)
(*           Title_Color              --- Color for title text          *)
(*           Text_Color               --- Color for interior text       *)
(*           Menu_Title               --- Menu Title                    *)
(*                                                                      *)
(*     Calls:   GoToXY                                                  *)
(*              Dupl                                                    *)
(*              Draw_Box                                                *)
(*              Do_Explosion (internal)                                 *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The area inside the frame is cleared after the frame is       *)
(*        drawn.  If a box without a title is desired, enter a null     *)
(*        string for a title.                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I  : INTEGER;
   L  : INTEGER;
   LT : INTEGER;
   XM : INTEGER;
   YM : INTEGER;
   XS : INTEGER;
   YS : INTEGER;
   R  : REAL;
   X1 : INTEGER;
   X2 : INTEGER;
   Y1 : INTEGER;
   Y2 : INTEGER;
   XM1: INTEGER;
   YM1: INTEGER;
   Knt: INTEGER;

(*----------------------------------------------------------------------*)
(*               Do_Explosion --- Draw an 'exploding' box               *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Explosion;

(*----------------------------------------------------------------------*)
(*               --- Basic algorithm by Jim Everingham ---              *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;
   
BEGIN (* Do_Explosion *)

   XM     := UpperLeftX + L SHR 1;
   YM     := UpperLeftY + ( LowerRightY - UpperLeftY ) SHR 1;
   X1     := UpperLeftX;
   X2     := LowerRightX;
   Y1     := UpperLeftY;
   Y2     := LowerRightY;

   XM1    := XM;
   YM1    := YM;
                                    (* Figure out increments for *)
                                    (* increasing boz dimensions *)
                                    (* to produce explosion.     *)
   IF ( XM > YM ) THEN
       Knt    :=  L SHR 1
   ELSE
       Knt    := ( Y2 - Y1 ) SHR 1;

   Y1     := PRED( Y1 );
   Y2     := PRED( Y2 );

   X1     := SUCC( X1 );
   X2     := PRED( X2 );
                                   (* Draw series of increasing     *)
                                   (* size boxes, giving appearance *)
                                   (* that box "explodes" from its  *)
                                   (* center.                       *)

   FOR I := 1 TO ROUND( Knt / 3 ) DO
      BEGIN
                                   (* Adjust sides *)

         IF ( XM > ( X1 - 2 ) ) THEN
            XM := XM - 3
         ELSE IF ( XM > PRED( X1 ) ) THEN
            XM := XM - 2
         ELSE IF ( XM > X1 ) THEN
            XM := PRED( XM );

         IF ( XM1 < ( X2 + 2 ) ) THEN
            XM1 := XM1 + 3
         ELSE IF ( XM1 < ( X2 + 1 ) ) THEN
            XM1 := XM1 + 2
         ELSE IF ( XM1 < X2 ) THEN
            XM1 := SUCC( XM1 );
                                   (* Adjust top and bottom *)

         IF ( YM > ( Y1 + 2 ) ) THEN
            YM := YM - 3
         ELSE IF ( YM > ( Y1 + 1 ) ) THEN
            YM := YM - 2
         ELSE IF ( YM > Y1 ) THEN
            YM := PRED( YM );

         IF ( YM1 < ( Y2 - 2 ) ) THEN
            YM1 := YM1 + 3
         ELSE IF ( YM1 < PRED( Y2 ) ) THEN
            YM1 := YM1 + 2
         ELSE IF ( YM1 < Y2 ) THEN
            YM1 := SUCC( YM1 );
                                   (* Define new window *)

         PibTerm_Window( SUCC( XM ), SUCC( YM ), XM1, YM1 );

                                   (* Clear it out      *)
         Clear_Window;
                                   (* Draw box          *)

         Draw_Box( SUCC( XM ), SUCC( YM ), MIN( LowerRightX , XM1 ),
                   YM1, Frame_Color, Title_Color, '' );

      END (* FOR *);

END   (* Do_Explosion *);

(*----------------------------------------------------------------------*)

BEGIN (* Draw_Menu_Frame *)

   L  := LowerRightX - UpperLeftX;
   LT := LENGTH( Menu_Title );
                                   (* Adjust title length if necessary *)

   IF LT > ( L - 5 ) THEN Menu_Title[0] := CHR( L - 5 );

                                   (* Get explosion if requested *)

   IF Menu_Explode_Mode THEN Do_Explosion;

                                   (* Display actual menu frame       *)

   Draw_Box( UpperLeftX, UpperLeftY, LowerRightX, LowerRightY,
             Frame_Color, Title_Color, Menu_Title );

                                   (* Establish scrolling window area *)

   PibTerm_Window( UpperLeftX+1, UpperLeftY+1, LowerRightX-1, LowerRightY-1 );

                                   (* Ensure proper color for text    *)
   TextColor     ( Text_Color );
   TextBackGround( BLACK );
                                   (* Clear out the window area       *)
                                   (* KLUDGE NOTE:  ClrScr doesn't    *)
                                   (* seem to work correctly on mono  *)
                                   (* screens with Turbo 3.0 in the   *)
                                   (* context of PibTerm.             *)
{
   GoToXY( 1 , 1 );
   ClrScr;
}

   FOR I := 1 TO PRED( LowerRightY - UpperLeftY ) DO
      BEGIN
         GoToXY( 1 , I );
         ClrEol;
      END;

   GoToXY( 1 , 1 );

END   (* Draw_Menu_Frame *);

(*----------------------------------------------------------------------*)
(*                Menu_Click --- Make short click noise                 *)
(*----------------------------------------------------------------------*)

PROCEDURE Menu_Click;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Menu_Click                                           *)
(*                                                                      *)
(*     Purpose:    Clicks Terminal Bell                                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Menu_Click;                                                   *)
(*                                                                      *)
(*     Calls:    Sound                                                  *)
(*               Delay                                                  *)
(*               NoSound                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Menu_Click *)

   IF Menu_Beep_Mode THEN
      BEGIN
         Sound( 2000 );
         DELAY( 10 );
         NoSound;
      END;

END   (* Menu_Click *);

(*----------------------------------------------------------------------*)
(*                Menu_Beep --- Ring Terminal Bell                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Menu_Beep;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Menu_Beep                                            *)
(*                                                                      *)
(*     Purpose:    Rings Terminal Bell                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Menu_Beep;                                                    *)
(*                                                                      *)
(*     Calls:    None                                                   *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        If Menu_Beep_Mode is FALSE, then '<ALERT>' is displayed in    *)
(*        blinking characters on status line for 1 second               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I        : INTEGER;
   J        : INTEGER;
   Save_C25 : PACKED ARRAY[1..7] OF CHAR;
   Save_A25 : PACKED ARRAY[1..7] OF BYTE;

BEGIN (* Menu_Beep *)
                                   (* Generate beep if beep mode on *)
   IF Menu_Beep_Mode THEN
      Sound_Bell
   ELSE                            (* Else generate blinking error  *)
      BEGIN
                                   (* Save character, attribute *)
         FOR I := 1 TO 7 DO
             ReadCXY( Save_C25[I], ( 35 + I ), Max_Screen_Line, Save_A25[I] );

                                   (* Display blinking error indicator *)

         WriteSXY( '<ALERT>', 36, Max_Screen_Line, WHITE + BLINK );

         DELAY( One_Second_Delay );

                                   (* Restore previous text *)
         FOR I := 1 TO 7 DO
            WriteCXY( Save_C25[I], ( 35 + I ), Max_Screen_Line, Save_A25[I] );

      END;

END   (* Menu_Beep *);

(*----------------------------------------------------------------------*)
(*                Menu_Turn_On --- Highlight Menu Choice                *)
(*----------------------------------------------------------------------*)

PROCEDURE Menu_Turn_On( Menu: Menu_Type; Menu_Item : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Menu_Turn_On                                         *)
(*                                                                      *)
(*     Purpose:    Highlight a menu item using reverse video            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Menu_Turn_On( Menu: Menu_Type; Menu_Item : INTEGER );         *)
(*                                                                      *)
(*           Menu      : Menu containing item to highlight              *)
(*           Menu_Item : Menu entry to highlight                        *)
(*                                                                      *)
(*     Calls:    GoToXY                                                 *)
(*               RvsVideoOn                                             *)
(*               RvsVideoOff                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Menu_Turn_On *)

   WITH Menu.Menu_Entries[ Menu_Item ] DO
      BEGIN

         GoToXY( Menu_Item_Column, Menu_Item_Row );

         TextColor     ( Menu.Menu_Bcolor );
         TextBackGround( Menu.Menu_Tcolor );

         WRITE( Menu_Item_Text );

         TextColor     ( Menu.Menu_Tcolor );
         TextBackGround( Menu.Menu_Bcolor );

      END;

END   (* Menu_Turn_On *);

(*----------------------------------------------------------------------*)
(*                Menu_Turn_Off --- UnHighlight Menu Choice             *)
(*----------------------------------------------------------------------*)

PROCEDURE Menu_Turn_Off( Menu: Menu_Type; Menu_Item : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Menu_Turn_Off                                        *)
(*                                                                      *)
(*     Purpose:    Removes highlighting from menu item                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Menu_Turn_Off( Menu : Menu_Type; Menu_Item : INTEGER );       *)
(*                                                                      *)
(*           Menu        : Menu containing item to unhighlight          *)
(*           RvsVideoOff : Menu entry to un-highlight                   *)
(*                                                                      *)
(*     Calls:    GoToXY                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Menu_Turn_Off *)

   WITH Menu.Menu_Entries[ Menu_Item ] DO
      BEGIN

         GoToXY( Menu_Item_Column , Menu_Item_Row );

         TextColor     ( Menu.Menu_TColor );
         TextBackGround( Menu.Menu_BColor );

         WRITE( Menu_Item_Text );

      END;

END   (* Menu_Turn_Off *);

(*----------------------------------------------------------------------*)
(*                Menu_IBMCh --- Interpret IBM keyboard chars.          *)
(*----------------------------------------------------------------------*)

PROCEDURE Menu_IBMCh( VAR C : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Menu_IBMCh                                           *)
(*                                                                      *)
(*     Purpose:    Interpret IBM keyboard chars.                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Menu_IBMCh( Var C : Char );                                   *)
(*                                                                      *)
(*           C --- On input, char following escape;                     *)
(*                 on output, char revised to Wordstar command code.    *)
(*                                                                      *)
(*     Calls:   Read_Kbd_Old                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Menu_IBMCh *)

   Read_Kbd_Old( C );

   CASE ORD( C ) OF

      U_Arrow : C := Up_Arrow;
      D_Arrow : C := Down_Arrow;
      L_Arrow : C := Left_Arrow;
      R_Arrow : C := Right_Arrow;
      ELSE
              C := CHR( ESC );

   END;

END   (* Menu_IBMCh *);

(*----------------------------------------------------------------------*)
(*                Menu_Display_Choices --- Display Menu Choices         *)
(*----------------------------------------------------------------------*)

PROCEDURE Menu_Display_Choices( Menu : Menu_Type );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Menu_Display_Choices                                 *)
(*                                                                      *)
(*     Purpose:    Displays Menu Choices                                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Menu_Display_Choices( Menu : Menu_Type );                     *)
(*                                                                      *)
(*           Menu --- Menu record to be displayed.                      *)
(*                                                                      *)
(*     Calls:   ClsScr                                                  *)
(*              GoToXY                                                  *)
(*              Draw_Menu_Frame                                         *)
(*              Save_Screen                                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I    : INTEGER;
   J    : INTEGER;
   XL   : INTEGER;
   YL   : INTEGER;
   XR   : INTEGER;
   YR   : INTEGER;
   MaxX : INTEGER;
   MaxY : INTEGER;

BEGIN (* Menu_Display_Choices *)

                                   (* Establish menu size *)
   XL := Menu.Menu_Column;
   YL := Menu.Menu_Row;

   XR := PRED( LENGTH( Menu.Menu_Title ) + XL );
   YR := YL;

   MaxX := MAX( Menu.Menu_Width , ( LENGTH( Menu.Menu_Title ) + 2 ) );
   MaxY := Menu.Menu_Height;

   FOR I := 1 TO Menu.Menu_Size DO
      WITH Menu.Menu_Entries[I] DO
      BEGIN
         IF Menu_Item_Row > MaxY THEN MaxY := Menu_Item_Row;
         J := PRED( LENGTH( Menu_Item_Text ) + Menu_Item_Column );
         IF J > MaxX THEN MaxX := J;
      END;

   J := PRED( XL + MaxX );
   IF J > XR THEN XR := J;

   J := PRED( YL + MaxY );
   IF J > YR THEN YR := J;

   XL := XL - 4;
   IF XL < 0 THEN XL := 0;

   YL := PRED( YL );
   IF YL < 0 THEN YL := 0;

   YR := SUCC( YR );
   IF YR > Max_Screen_Line THEN YR := Max_Screen_Line;

   IF XR > Max_Screen_Col THEN XR := Max_Screen_Col;

                                   (* Save current screen image *)
                                   (* if not already saved      *)

   IF Current_Saved_Screen > 0 THEN
      BEGIN
         IF Saved_Screen_List[ Current_Saved_Screen ] <> Saved_Screen THEN
            Save_Partial_Screen( Saved_Screen, XL, YL, XR, YR );
      END
   ELSE
      Save_Partial_Screen( Saved_Screen, XL, YL, XR, YR );

                                   (* Draw the menu frame       *)

   Draw_Menu_Frame( XL, YL, XR, YR, Menu.Menu_FColor, Menu.Menu_HColor,
                    Menu.Menu_TColor, Menu.Menu_Title );

                                   (* Display Menu Entries *)

   FOR I := 1 TO Menu.Menu_Size DO
      WITH Menu.Menu_Entries[I] DO
         BEGIN
            GoToXY( Menu_Item_Column , Menu_Item_Row );
            WRITE( Menu_Item_Text );
         END;
                                   (* Highlight Default Choice *)

   Menu_Turn_On( Menu, Menu.Menu_Default );

END   (* Menu_Display_Choices *);

(*----------------------------------------------------------------------*)
(*                Menu_Get_Choice --- Get Menu Choice                   *)
(*----------------------------------------------------------------------*)

FUNCTION Menu_Get_Choice( Menu: Menu_Type; Erase_After: BOOLEAN ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:  Menu_Get_Choice                                       *)
(*                                                                      *)
(*     Purpose:   Retrieves Menu Choice from current menu               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ichoice := Menu_Get_Choice( Menu       : Menu_Type;           *)
(*                                    Erase_After: BOOLEAN ) : INTEGER; *)
(*                                                                      *)
(*           Menu        --- Currently displayed menu                   *)
(*           Erase_After --- TRUE to erase menu after choice found      *)
(*           Ichoice     --- Returned menu item chosen                  *)
(*                                                                      *)
(*      Calls:   Menu_Click                                             *)
(*               Menu_IBMCh                                             *)
(*               Menu_Turn_Off                                          *)
(*               Menu_Turn_On                                           *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         The current menu item is highlighted in reverse video.       *)
(*         It may be chosen by hitting the return key.  Movement        *)
(*         to other menu items is done using the up-arrow and           *)
(*         down-arrow.                                                  *)
(*                                                                      *)
(*         An item may also be chosen by hitting the first character    *)
(*         of that item.                                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   C       : CHAR;
   Current : INTEGER;
   Last    : INTEGER;
   I       : INTEGER;
   Found   : BOOLEAN;

BEGIN  (* Menu_Get_Choice *)
                                   (* Increase menu depth *)

   INC( Menu_Depth );

                                   (* Get default *)
   Current := Menu.Menu_Default;

   Last    := PRED( Current );
   IF Last < 1 THEN Last := Menu.Menu_Size;

   REPEAT  (* Loop until return key hit *)

                                   (* Read a character *)
      Read_Kbd_Old( C );
      Menu_Click;

      C := UpCase( C );
                                   (* Convert character to menu code *)

      IF ( C = Ch_Esc ) AND PibTerm_KeyPressed THEN
         Menu_IBMCh( C );
                                   (* Process character *)
      CASE C OF

         Down_Arrow,
         Right_Arrow,
         Space_Bar     : BEGIN (* Move down menu *)
                            Last    := Current;
                            INC( Current );
                            IF Current > Menu.Menu_Size THEN
                               Current := 1;
                         END;

         Left_Arrow,
         Up_Arrow      : BEGIN (* Move up menu *)
                            Last    := Current;
                            DEC( Current );
                            IF Current < 1 THEN
                               Current := Menu.Menu_Size;
                         END   (* Move up menu *);

         Ch_Cr         : ;

         Ch_Esc        : Current := -1;

         ELSE

            Found := FALSE;

            FOR I := 1 TO Menu.Menu_Size DO
               IF C = UpCase( Menu.Menu_Entries[I].Menu_Item_Text[1] ) THEN
                  BEGIN
                     Found   := TRUE;
                     C       := Ch_Cr;
                     Last    := Current;
                     Current := I;
                  END;

            IF ( NOT Found ) THEN Menu_Beep;

      END (* CASE *);
                                   (* Highlight new menu choice *)

      IF C IN [ Up_Arrow, Down_Arrow, Left_Arrow, Right_Arrow,
                Space_Bar, Ch_Cr ] THEN
         BEGIN
            Menu_Turn_Off( Menu, Last    );
            Menu_Turn_On ( Menu, Current );
         END;

   UNTIL ( C = Ch_CR ) OR ( C = Ch_Esc );

                                   (* Return index of chosen value *)
   Menu_Get_Choice := Current;

                                   (* Erase menu from display      *)
   IF Erase_After THEN
      Restore_Screen_And_Colors( Saved_Screen );

                                   (* Decrease menu depth *)

   Menu_Depth := MAX( PRED( Menu_Depth ) , 0 );

END   (* Menu_Get_Choice *);
