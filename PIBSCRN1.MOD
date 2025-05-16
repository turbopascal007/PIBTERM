(*----------------------------------------------------------------------*)
(*       PIBSCREN.PAS --- Screen Handling Routines for Turbo Pascal     *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Author:  Philip R. Burns                                            *)
(*                                                                      *)
(*  Date:    Version 1.0: January, 1985 (Part of PibMenus)              *)
(*           Version 1.1: March, 1985   (Part of PibMenus)              *)
(*           Version 1.2: May, 1985     (Part of PibMenus)              *)
(*           Version 2.0: June, 1985    (Split from PibMenus)           *)
(*           Version 3.0: October, 1985                                 *)
(*           Version 3.1: October, 1985                                 *)
(*           Version 3.2: November, 1985                                *)
(*           Version 4.0: March, 1987                                   *)
(*                                                                      *)
(*  Systems: For MS-DOS on IBM PCs and close compatibles only.          *)
(*           Note:  I have checked these on Zenith 151s under           *)
(*                  MSDOS 2.1 and IBM PCs under PCDOS 2.0.              *)
(*                  Version 4.0 provides automatic support for          *)
(*                  SoftLogic's DoubleDos and TopView-like systems.     *)
(*                                                                      *)
(*  History: These routines provide a simple windowing facility for     *)
(*           Turbo Pascal as well as routines for direct access to the  *)
(*           screen memory area.                                        *)
(*                                                                      *)
(*           The windowing facility provides windows similar to those   *)
(*           implemented in QMODEM by John Friel III.                   *)
(*                                                                      *)
(*           Version 1.0 of these routines formed part of the           *)
(*           PIBMENUS.PAS include file.  These routines were split off  *)
(*           into a separate PIBSCREN.PAS file at version 2.0.          *)
(*                                                                      *)
(*           Starting with version 3.2, PibScren uses a (hopefully)     *)
(*           version-independent method for ascertaining the size       *)
(*           of the current window.  The method relies on the 1-pass    *)
(*           construction of Turbo, so that the standard built-in       *)
(*           procedure WINDOW can be replaced by one defined here, and  *)
(*           the built-in version then referred to by the name          *)
(*           TurboWindow.                                               *)
(*                                                                      *)
(*           Version 4.0 adds DoubleDos, DesqView, and TopView compati- *)
(*           bility.  MS Windows is supported via TopView emulation.    *)
(*           Many thanks to Barry Kasindorf and Gary Saxer for their    *)
(*           assistance with the DesqView interface.                    *)
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
(*    Note that code for stacked windows is available here.  You may    *)
(*    want to modify this to use compile-time window spaces, or remove  *)
(*    the current push-down stack structure.                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

(*----------------------------------------------------------------------*)
(*     PibTerm_Window --- PibTerm interface to TP4 WINDOW procedure     *)
(*----------------------------------------------------------------------*)

PROCEDURE PibTerm_Window( X1, Y1, X2, Y2 : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  PibTerm_Window                                       *)
(*                                                                      *)
(*     Purpose:    Redefines built-in Turbo procedure WINDOW so that    *)
(*                 we can keep track of window boundaries.              *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* PibTerm_Window *)
                                   (* Set Turbo's window guys *)

   WindMin := PRED( Y1 ) SHL 8 + PRED( X1 );
   WindMax := PRED( Y2 ) SHL 8 + PRED( X2 );

                                   (* Save new window coords *)
   Upper_Left_Column  := X1;
   Upper_Left_Row     := Y1;
   Lower_Right_Column := X2;
   Lower_Right_Row    := Y2;

END   (* PibTerm_Window *);

(*----------------------------------------------------------------------*)
(*                    Set_Text_Mode --- Set text mode                   *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Text_Mode( Text_Mode : INTEGER );

BEGIN (* Set_Text_Mode *)

   TextMode( Text_Mode );
{
   DirectVideo := Write_Screen_Memory AND ( NOT TimeSharingActive );
}
   DirectVideo := FALSE;

END   (* Set_Text_Mode *);

(*----------------------------------------------------------------------*)
(*    Color_Screen_Active --- Determine if color or mono screen         *)
(*----------------------------------------------------------------------*)

FUNCTION Color_Screen_Active;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Color_Screen_Active                                  *)
(*                                                                      *)
(*     Purpose:    Determines if color or mono screen active            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Color_Active := Color_Screen_Active : BOOLEAN;                *)
(*                                                                      *)
(*           Color_Active --- set to TRUE if the color screen is        *)
(*                            active, FALSE if the mono screen is       *)
(*                            active.                                   *)
(*                                                                      *)
(*     Calls:   INTR                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs : Registers;

BEGIN  (* Color_Screen_Active *)

   Regs.Ax := 15 SHL 8;

   INTR( $10 , Regs );

   Color_Screen_Active := ( Regs.Al <> 7 );

End    (* Color_Screen_Active *);

(*----------------------------------------------------------------------*)
(*     Current_Video_Mode --- Determine current video mode setting      *)
(*----------------------------------------------------------------------*)

FUNCTION Current_Video_Mode: INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Current_Video_Mode                                   *)
(*                                                                      *)
(*     Purpose:    Gets current video mode setting from system          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Current_Mode := Current_Video_Mode : INTEGER;                 *)
(*                                                                      *)
(*           Current_Mode --- set to integer representing current       *)
(*                            video mode inherited from system.         *)
(*                                                                      *)
(*     Calls:   INTR                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs : Registers;

BEGIN  (* Current_Video_Mode *)

   Regs.Ax := 15 SHL 8;

   INTR( $10 , Regs );

   Current_Video_Mode := Regs.Al;

END    (* Current_Video_Mode *);

(*----------------------------------------------------------------------*)
(*     EGA_Installed  ---  Test if Enhanced Graphics Adapter installed  *)
(*----------------------------------------------------------------------*)

FUNCTION EGA_Installed : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   EGA_Installed                                        *)
(*                                                                      *)
(*     Purpose:    Checks if Enhanced Graphics Adapter is installed.    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        EGA_There := EGA_Installed : BOOLEAN;                         *)
(*                                                                      *)
(*           EGA_There --- TRUE if EGA installed                        *)
(*                                                                      *)
(*     Calls:   INTR                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs : Registers;

BEGIN  (* EGA_Installed *)
                                   (* Determine if EGA installed       *)
   Regs.AH := $12;
   Regs.BX := $FF10;
   INTR( $10 , Regs );

   IF ( Regs.BH = $FF ) THEN       (* EGA not installed *)
      EGA_Installed := FALSE
   ELSE IF ( Regs.CL = 9 ) THEN
      BEGIN (* EGA present with enhanced display *)
         EGA_Installed := TRUE;
      END
   ELSE IF ( Regs.CL = 13 ) THEN
      BEGIN (* EGA present with monochrome display *)
         EGA_Installed := TRUE;
      END
   ELSE (* EGA present but with old color display  *)
      EGA_Installed := FALSE;

END    (* EGA_Installed *);

(*----------------------------------------------------------------------*)
(*     VGA_Installed  ---  Test if Virtual Graphics Array installed     *)
(*----------------------------------------------------------------------*)

FUNCTION VGA_Installed : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   VGA_Installed                                        *)
(*                                                                      *)
(*     Purpose:    Checks if Virtual Graphics Array is installed.       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        VGA_There := VGA_Installed : BOOLEAN;                         *)
(*                                                                      *)
(*           VGA_There --- TRUE if VGA installed                        *)
(*                                                                      *)
(*     Calls:   INTR                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs : Registers;

BEGIN  (* VGA_Installed *)

   Regs.AX := $1A00;
   Regs.BL := 0;

   INTR( $10 , Regs );

   VGA_Installed := ( Regs.BL = 8 ) OR ( Regs.BL = 7 );

END    (* VGA_Installed *);

(*----------------------------------------------------------------------*)
(*        Get_Screen_Address --- Get address of current screen          *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Screen_Address( VAR Actual_Screen : Screen_Ptr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Screen_Address                                   *)
(*                                                                      *)
(*     Purpose:    Gets screen address for current type of display      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Screen_Address( VAR Actual_Screen : Screen_Ptr );         *)
(*                                                                      *)
(*           Actual_Screen --- pointer whose value receives the         *)
(*                             current screen address.                  *)
(*                                                                      *)
(*     Calls:   Color_Screen_Active                                     *)
(*              PTR                                                     *)
(*              Get_Virtual_Screen_Address                              *)
(*              TimeSharingActive                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs: Registers;

BEGIN  (* Get_Screen_Address *)
                                   (* Check if timesharing active.   *)
   IF TimeSharingActive THEN
      CASE MultiTasker OF
         DoubleDos:  BEGIN
                        Regs.Ax := $EC00;
                        MsDos( Regs );
                        Actual_Screen := PTR( Regs.Es, 0 );
                     END;
         TaskView,
         TopView,
         MSWindows,
         DesqView:   CASE Current_Video_Mode OF
                        HiRes_GraphMode : Actual_Screen := PTR( Color_Screen_Address , 0 );
                        EGA_GraphMode   : Actual_Screen := PTR( EGA_Screen_Address , 0 );
                        ELSE              Actual_Screen := DesqView_Screen;
                     END (* CASE *);
         ELSE;
      END
   ELSE
      IF Color_Screen_Active THEN
         Actual_Screen := PTR( Color_Screen_Address , 0 )
      ELSE
         Actual_Screen := PTR( Mono_Screen_Address , 0 );

END    (* Get_Screen_Address *);

(*----------------------------------------------------------------------*)
(*        Get_Rows_For_EGA  --- Get # of rows in display for EGA        *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Rows_For_EGA : INTEGER;

VAR
   Regs: Registers;

BEGIN (* Get_Rows_For_EGA *)
                                   (* Get # of rows in current EGA display *)
   Regs.AH := $11;
   Regs.AL := $30;
   Regs.BH := 0;

   INTR( $10 , Regs );

   IF ( Regs.DL > 0 ) THEN
      Get_Rows_For_EGA := SUCC( Regs.DL )
   ELSE
      Get_Rows_For_EGA := 25;

END   (* Get_Rows_For_EGA *);

(*----------------------------------------------------------------------*)
(*                Video Display Control Routines                        *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       RvsVideoOn  --- Turn On Reverse Video                          *)
(*       RvsVideoOff --- Turn Off Reverse Video                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

PROCEDURE RvsVideoOn( Foreground_Color, Background_Color : INTEGER );

BEGIN (* RvsVideoOn *)

   TextColor     ( Background_color );
   TextBackGround( Foreground_color );

END   (* RvsVideoOn *);

(*----------------------------------------------------------------------*)

PROCEDURE RvsVideoOff( Foreground_Color, Background_Color : INTEGER );

BEGIN (* RvsVideoOff *)

   TextColor     ( Foreground_color );
   TextBackGround( Background_color );

END   (* RvsVideoOff *);

(*----------------------------------------------------------------------*)
(*                Cursor Display Control Routines                       *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       CursorOn    --- Turn On Cursor                                 *)
(*       CursorOff   --- Turn Off Cursor                                *)
(*       CursorGet   --- Get current cursor type                        *)
(*       CursorSet   --- Set cursor type                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

PROCEDURE CursorOn;

VAR
   Regs: Registers;
   I   : INTEGER;

BEGIN (* CursorOn *)
                                   (* Change cursor back to underline *)
   Regs.Ax := $0100;
                                   (* Turn off cursor emulation to *)
                                   (* avoid bug in some EGAs       *)
   IF Font8x8Loaded THEN
      BEGIN
         Regs.CX      := $0507;
         I            := MEM[$0:$487];
         MEM[$0:$487] := I OR 1;
      END
   ELSE
      IF ( Current_Video_Mode = 7 ) THEN
         Regs.CX := $0B0C
      ELSE
         Regs.CX := $0607;

   INTR( $10, Regs );
                                   (* Turn cursor emulation back on *)
   IF Font8x8Loaded THEN
      MEM[$0:$487] := I;

END   (* CursorOn *);

(*----------------------------------------------------------------------*)

PROCEDURE CursorOff;

VAR
   Regs: Registers;

BEGIN (* CursorOff *)
                                   (* Make cursor invisible *)
   Regs.Ax := $0100;
   Regs.Ch := 32;

   INTR( $10, Regs );

END   (* CursorOff *);

(*----------------------------------------------------------------------*)

PROCEDURE CursorGet( VAR Current_Cursor : INTEGER );

VAR
   Regs: Registers;

BEGIN (* CursorGet *)
                                   (* Get current cursor type *)
   Regs.Ax := $0300;
   Regs.Bh := 0;

   INTR( $10, Regs );

   CASE Regs.CX of
      $0067 : Current_Cursor := $0607;    (* Compaq's bug *)
      $0607 : IF ( ( Current_Video_Mode = 7 ) AND
                   ( NOT Font8x8Loaded      ) ) THEN
                 Current_Cursor := $0C0D  (* IBM's bug    *)
              ELSE
                 Current_Cursor := $0607;
      ELSE    Current_Cursor := Regs.CX;
   END;

END   (* CursorGet *);

(*----------------------------------------------------------------------*)

PROCEDURE CursorSet( New_Cursor_Type : INTEGER );

VAR
   Regs: Registers;
   I   : INTEGER;

BEGIN (* CursorSet *)
                                   (* Set cursor *)
   Regs.Ax := $0100;
   Regs.Cx := New_Cursor_Type;
                                   (* Turn off cursor emulation to *)
                                   (* avoid bug in some EGAs       *)
   IF Font8x8Loaded THEN
      BEGIN
         I            := MEM[$0:$487];
         MEM[$0:$487] := I OR 1;
      END;

   INTR( $10, Regs );
                                   (* Turn cursor emulation back on *)
   IF Font8x8Loaded THEN
      MEM[$0:$487] := I;

END   (* CursorSet *);

(*----------------------------------------------------------------------*)
(*            Upper_Left ---  Upper Position of current window          *)
(*----------------------------------------------------------------------*)

PROCEDURE Upper_Left( VAR X1, Y1 : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:   Upper_Left                                          *)
(*                                                                      *)
(*     Purpose:     Returns upper position of current TURBO window      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Upper_Left( VAR X1, Y1 : INTEGER );                           *)
(*                                                                      *)
(*           X1   --- returned upper left column                        *)
(*           Y1   --- returned upper left row                           *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Upper_Left *)

    Y1 := Upper_Left_Row;          (* get Row *)
    X1 := Upper_Left_Column        (* get Column *)

END    (* Upper_Left *);

(*----------------------------------------------------------------------*)
(*                Set/Reset Text Color Routines                         *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   These routines set and reset the global text foreground and        *)
(*   background colors.                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

                   (* Global Text Color Variables *)

PROCEDURE Set_Global_Colors( ForeGround, BackGround : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_Global_Colors                                    *)
(*                                                                      *)
(*     Purpose:    Sets global text foreground, background colors.      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Global_Colors( ForeGround, BackGround : INTEGER );        *)
(*                                                                      *)
(*           ForeGround --- Default foreground color                    *)
(*           BackGround --- Default background color                    *)
(*                                                                      *)
(*     Calls:   TextColor                                               *)
(*              TextBackGround                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   My_Blink : INTEGER;

BEGIN  (* Set_Global_Colors *)

   Global_ForeGround_Color := ForeGround;
   Global_BackGround_Color := BackGround;

   IF ( ForeGround >= Blink ) THEN
      BEGIN
         ForeGround := ForeGround - Blink;
         My_Blink   := 8;
      END
   ELSE
      My_Blink := 0;

   Global_Text_Attribute   := ( ( BackGround AND 7 ) OR My_Blink ) SHL 4 +
                                ForeGround;

   TextColor     ( Global_ForeGround_Color );
   TextBackground( Global_BackGround_Color );

END    (* Set_Global_Colors *);

(*----------------------------------------------------------------------*)
(*  Reset_Global_Colors --- Reset global foreground, background cols.   *)
(*----------------------------------------------------------------------*)

PROCEDURE Reset_Global_Colors;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Reset_Global_Colors                                  *)
(*                                                                      *)
(*     Purpose:    Resets text foreground, background colors to global  *)
(*                 defaults.                                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Reset_Global_Colors;                                          *)
(*                                                                      *)
(*     Calls:   TextColor                                               *)
(*              TextBackGround                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Reset_Global_Colors *)

   TextColor     ( Global_ForeGround_Color );
   TextBackground( Global_BackGround_Color );

   Global_Text_Attribute   := ( Global_BackGround_Color AND 7 ) SHL 4 +
                              Global_ForeGround_Color;

END    (* Reset_Global_Colors *);

(*----------------------------------------------------------------------*)
(*             Set_Border_Color --- Set global border color             *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Border_Color( The_Border_Color : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_Border_Color                                     *)
(*                                                                      *)
(*     Purpose:    Sets border color                                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Border_Color( The_Border_Color : INTEGER );               *)
(*                                                                      *)
(*           The_Border_Color --- the border color                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs: Registers;

BEGIN  (* Set_Border_Color *)

   IF ( ( NOT TimeSharingActive ) AND Write_Screen_Memory AND
        ( Current_Video_Mode <> 7 ) ) THEN
      BEGIN

         Regs.Ah := $0B;
         Regs.Bh := 0;
         Regs.Bl := The_Border_Color;

         INTR( $10 , Regs );

         Global_Border_Color := The_Border_Color;

      END;

END    (* Set_Border_Color *);

(*----------------------------------------------------------------------*)
(*    Change_Attributes --- Changes specified number of attributes      *)
(*----------------------------------------------------------------------*)

PROCEDURE Change_Attributes( NAttr: INTEGER;
                             X    : INTEGER;
                             Y    : INTEGER;
                             Color: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Change_Attributes                                    *)
(*                                                                      *)
(*     Purpose:    Changes specified number of attributes               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Change_Attributes( NAttr : INTEGER;                           *)
(*                           X     : INTEGER;                           *)
(*                           Y     : INTEGER;                           *)
(*                           Color : INTEGER );                         *)
(*                                                                      *)
(*           NAttr  --- number of attributes to change                  *)
(*           (X,Y)  --- starting column and row position to change      *)
(*           Color  --- new attribute                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Change_Attributes *)

INLINE(
                                  {;}
                                  {;  Check if we're using BIOS.}
                                  {;}
  $F6/$06/>WRITE_SCREEN_MEMORY/$01{         TEST  BYTE [>Write_Screen_Memory],1 ;Direct screen write?}
  /$74/$4F                        {         JZ    Bios                          ;No -- go use BIOS}
                                  {;}
                                  {;  Set up for direct screen write.}
                                  {;  Get row position and column positions, and offset in screen buffer.}
                                  {;}
  /$C4/$3E/>DESQVIEW_SCREEN       {         LES     DI,[>DesqView_Screen]       ;Get base address of screen}
  /$8B/$4E/<Y                     {         MOV     CX,[BP+<Y]                  ;CX = Row}
  /$49                            {         DEC     CX                          ;Row to 0..Max_Screen_Line-1 range}
  /$A1/>MAX_SCREEN_COL            {         MOV     AX,[>Max_Screen_Col]        ;Physical screen width}
  /$F7/$E1                        {         MUL     CX                          ;Row * Max_Screen_Col}
  /$8B/$5E/<X                     {         MOV     BX,[BP+<X]                  ;BX = Column}
  /$4B                            {         DEC     BX                          ;Column to 0..Max_Screen_Col-1 range}
  /$01/$D8                        {         ADD     AX,BX                       ;AX = (Row * Max_Screen_Col) + Col}
  /$D1/$E0                        {         SHL     AX,1                        ;Account for attribute bytes}
  /$89/$FB                        {         MOV     BX,DI                       ;Get base offset of screen}
  /$01/$C3                        {         ADD     BX,AX                       ;Add computed offset}
  /$43                            {         INC     BX                          ;Add 1 to point to attribute}
  /$89/$DF                        {         MOV     DI,BX                       ;Move result into DI}
                                  {;}
  /$8B/$8E/>NATTR                 {         MOV     CX,[BP+>NAttr]              ;CX = # attributes to change}
  /$E3/$79                        {         JCXZ    Exit                        ;If string empty, Exit}
                                  {;}
  /$8A/$26/>WAIT_FOR_RETRACE      {         MOV     AH,[<Wait_For_Retrace]      ;AH = retrace flag}
  /$8A/$46/<COLOR                 {         MOV     AL,[BP+<Color]              ;AL = Attribute}
  /$FC                            {         CLD                                 ;Set direction to forward}
  /$D0/$DC                        {         RCR     AH,1                        ;If we don't wait for retrace, ...}
  /$73/$1A                        {         JNC     Mono                        ; use "Mono" routine}
                                  {;}
                                  {;  Color routine -- wait for retraces.}
                                  {;}
  /$BA/>CRT_STATUS                {         MOV     DX,>CRT_Status              ;Point DX to CGA status port}
  /$89/$C3                        {         MOV     BX,AX                       ;Store video word in BX}
                                  {;}
  /$EC                            {WaitNoH: IN      AL,DX                       ;Get 6845 status}
  /$A8/$01                        {         TEST    AL,1                        ;Wait for horizontal}
  /$75/$FB                        {         JNZ     WaitNoH                     ; retrace to finish}
                                  {;}
  /$FA                            {         CLI                                 ;Turn off interrupts}
  /$EC                            {WaitH:   IN      AL,DX                       ;Get 6845 status again}
  /$A8/$01                        {         TEST    AL,1                        ;Wait for horizontal retrace}
  /$74/$FB                        {         JZ      WaitH                       ; to start}
                                  {;}
  /$89/$D8                        {Store:   MOV     AX,BX                       ;Restore attribute}
  /$AA                            {         STOSB                               ;Store attribute (already in AH)}
  /$FB                            {         STI                                 ;Allow interrupts}
  /$47                            {         INC     DI                          ;Skip character byte}
  /$E2/$EE                        {         LOOP    WaitNoH                     ;Go back and do next attribute}
                                  {;}
  /$E9/$53/$00                    {         JMP     Exit                        ;Quit when done}
                                  {;}
                                  {;  Mono routine (used whenever Wait_For_Retrace is False) **}
                                  {;}
  /$AA                            {Mono:    STOSB                               ;Change attribute}
  /$47                            {         INC     DI                          ;Skip character byte}
  /$E2/$FC                        {         LOOP    Mono                        ;Do next attribute}
                                  {;}
  /$E9/$4C/$00                    {         JMP     Exit                        ;Done}
                                  {;}
                                  {;  Use BIOS to change attributes}
                                  {;}
  /$B4/$03                        {Bios:    MOV     AH,3                        ;Get current cursor position}
  /$30/$FF                        {         XOR     BH,BH                       ;Display page 0}
  /$55                            {         PUSH    BP}
  /$CD/$10                        {         INT     $10}
  /$5D                            {         POP     BP}
                                  {;}
  /$52                            {         PUSH    DX                          ;Save current cursor position}
                                  {;}
  /$8B/$8E/>NATTR                 {         MOV     CX,[BP+>Nattr]              ;Get # attributes to change}
  /$E3/$34                        {         JCXZ    Bios3                       ;Skip this stuff if nothing to do}
                                  {;}
  /$8A/$76/<Y                     {         MOV     DH,[BP+<Y]                  ;Get row}
  /$FE/$CE                        {         DEC     DH                          ;Drop by 1 for 0-origin}
  /$8A/$56/<X                     {         MOV     DL,[BP+<X]                  ;Get column}
  /$FE/$CA                        {         DEC     DL                          ;Drop by 1 for 0-origin}
                                  {;}
  /$51                            {Bios1:   PUSH    CX                          ;Save attributes left to do}
  /$52                            {         PUSH    DX                          ;Save row and column}
  /$30/$FF                        {         XOR     BH,BH                       ;Display page 0}
  /$B4/$02                        {         MOV     AH,2                        ;Set cursor position}
  /$55                            {         PUSH    BP}
  /$CD/$10                        {         INT     $10}
  /$B4/$08                        {         MOV     AH,8                        ;Read character at current position}
  /$CD/$10                        {         INT     $10}
  /$5D                            {         POP     BP}
                                  {;}
  /$B4/$09                        {         MOV     AH,9                        ;Rewrite character with new attrib}
  /$8A/$5E/<COLOR                 {         MOV     BL,[BP+<Color]              ;Get attribute}
  /$B9/$01/$00                    {         MOV     CX,1                        ;Write one character}
  /$55                            {         PUSH    BP}
  /$CD/$10                        {         INT     $10}
  /$5D                            {         POP     BP}
                                  {;}
  /$5A                            {         POP     DX                          ;Restore position}
  /$59                            {         POP     CX                          ;Restore count of attribs left}
                                  {;}
  /$FE/$C2                        {         INC     DL                          ;Point to next column}
  /$3A/$16/>MAX_SCREEN_COL        {         CMP     DL,[>Max_Screen_Col]        ;See if we're past end of line}
  /$72/$04                        {         JB      Bios2}
                                  {;}
  /$FE/$C6                        {         INC     DH                          ;If so, increment row}
  /$30/$D2                        {         XOR     DL,DL                       ;and reset column to 0.}
                                  {;}
  /$E2/$D6                        {Bios2:   LOOP    Bios1                       ;Loop if more attribs to change}
                                  {;}
  /$5A                            {Bios3:   POP     DX                          ;Restore original cursor position}
  /$30/$FF                        {         XOR     BH,BH}
  /$B4/$02                        {         MOV     AH,2}
  /$55                            {         PUSH    BP}
  /$CD/$10                        {         INT     $10}
  /$5D                            {         POP     BP}
                                  {;}
                                  {Exit:}
);

END   (* Change_Attributes *);

(*----------------------------------------------------------------------*)
(*    Set_Text_Attributes --- Set text attributes for portion of screen *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Text_Attributes( X1, Y1, X2, Y2, FG, BG : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_Text_Attributes                                  *)
(*                                                                      *)
(*     Purpose:    Sets text attributes for portion of screen           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Text_Attributes( X1, Y2, X2, Y2, FG, BG: INTEGER );       *)
(*                                                                      *)
(*           (X1,Y1);(X2,Y2) --- region to set attributes in            *)
(*           FG --- ForeGround color                                    *)
(*           BG --- BackGround color                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Attrib: INTEGER;
   SaveX : INTEGER;
   SaveY : INTEGER;
   I     : INTEGER;
   N     : INTEGER;

BEGIN  (* Set_Text_Attributes *)
                                   (* Get # attribs per line to change *)
   N := ( X2 - X1 + 1 );

   IF ( N <= 0 ) THEN EXIT;
                                   (* Get new text attribute *)

   Attrib := ( BG AND 7 ) SHL 4 + FG;

                                   (* Save current position  *)
   SaveX := WhereX;
   SaveY := WhereY;
                                   (* Turn off the cursor      *)
   CursorOff;
                                   (* Freeze screen for DoubleDos *)

   IF ( MultiTasker = DoubleDos ) AND ( Write_Screen_Memory ) THEN
      BEGIN
         TurnOffTimeSharing;
         Get_Screen_Address( DesqView_Screen );
      END;
                                   (* Loop over area to change *)
   FOR I := Y1 TO Y2 DO
      Change_Attributes( N, X1, I, Attrib );

                                   (* Unfreeze screen in DoubleDos *)

   IF Write_Screen_Memory THEN
      IF ( MultiTasker = DoubleDos ) THEN
         TurnOnTimeSharing
                                   (* Synchronize screen for TopView *)

      ELSE IF ( MultiTasker = TopView ) THEN
          Sync_Screen( SUCC( ( PRED( Y1 ) * Max_Screen_Col ) SHL 1 ),
                       ( Y2 - Y1 ) * Max_Screen_Col );

                                   (* Restore old location *)
   GoToXY( SaveX, SaveY );
                                   (* Turn on the cursor   *)
   CursorOn;

END    (* Set_Text_Attributes *);

(*----------------------------------------------------------------------*)
(*                 Screen Manipulation Routines                         *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*   These routines save and restore screen images in support of the    *)
(*   windowing facility.  Also, the current screen image can be printed *)
(*   and text extracted from the screen memory.                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

(*----------------------------------------------------------------------*)
(*         ReadCXY --- Read character/attribute from screen             *)
(*----------------------------------------------------------------------*)

PROCEDURE ReadCXY( VAR C     (*  : CHAR *);
                       X         : INTEGER;
                       Y         : INTEGER;
                   VAR Color (*  : BYTE *) );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  ReadCXY                                              *)
(*                                                                      *)
(*     Purpose:    Reads a character from specified row and column      *)
(*                 position on screen.                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        ReadCXY( VAR C: CHAR; X: INTEGER; Y: INTEGER;                 *)
(*                 VAR Color: INTEGER );                                *)
(*                                                                      *)
(*           C      --- Character picked up                             *)
(*           X      --- Column position to read character               *)
(*           Y      --- Column position to read character               *)
(*           Color  --- Attribute of character                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   SaveXY: INTEGER;

BEGIN (* ReadCXY *)

INLINE(
                         {;}
  $B4/$03                {          MOV    AH,3              ;Get current cursor position}
  /$B7/$00               {          MOV    BH,0}
  /$CD/$10               {          INT    $10}
                         {;}
  /$89/$96/>SAVEXY       {          MOV    [BP+>SaveXY],DX   ;Save current coordinates}
                         {;}
  /$B4/$02               {          MOV    AH,2              ;Position cursor function}
  /$B7/$00               {          MOV    BH,0}
  /$8A/$76/<Y            {          MOV    DH,[BP+<Y]        ;Get row}
  /$FE/$CE               {          DEC    DH}
  /$8A/$56/<X            {          MOV    DL,[BP+<X]        ;Get column}
  /$FE/$CA               {          DEC    DL}
  /$CD/$10               {          INT    $10               ;Position cursor}
                         {;}
  /$B4/$08               {          MOV    AH,8              ;Get character and attribute}
  /$B7/$00               {          MOV    BH,0}
  /$CD/$10               {          INT    $10}
                         {;}
  /$C4/$7E/<C            {          LES    DI,[BP+<C]        ;Get address of where to store character}
  /$26/$88/$05           {      ES: MOV    [DI],AL           ;and store it}
                         {;}
  /$C4/$7E/<COLOR        {          LES    DI,[BP+<Color]    ;Get address of where to store attribute}
  /$26/$88/$25           {      ES: MOV    [DI],AH           ;and store it}
                         {;}
  /$B4/$02               {          MOV    AH,2              ;Position cursor function}
  /$B7/$00               {          MOV    BH,0}
  /$8B/$96/>SAVEXY       {          MOV    DX,[BP+>SaveXY]   ;Get back previous position}
  /$CD/$10               {          INT    $10               ;Position cursor}
                         {;}
);

END   (* ReadCXY *);

(*----------------------------------------------------------------------*)
(*           MoveToScreen  ---  Move data to screen memory              *)
(*----------------------------------------------------------------------*)

PROCEDURE MoveToScreen( VAR Source, Dest; SLen: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  MoveToScreen                                         *)
(*                                                                      *)
(*     Purpose:    Moves bytes to screen memory at specified offset     *)
(*                 with retrace locks.                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        MoveToScreen( VAR Source, Dest; SLen: INTEGER );              *)
(*                                                                      *)
(*           Source --- Data to be moved to screen                      *)
(*           Dest   --- Offset in screen to start storing SData         *)
(*           SLen   --- Number of words to move                         *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* MoveToScreen *)

INLINE(
  $1E                    {         PUSH  DS                     ;Save DS}
                         {;}
  /$8B/$4E/<SLEN         {         MOV   CX,[BP+<SLen]          ;CX = Length(Source)}
  /$E3/$1E               {         JCXZ  Return                 ;If string empty, Return}
                         {;}
  /$C4/$7E/<DEST         {         LES   DI,[BP+<Dest]          ;ES:DI points to destination}
  /$C5/$76/<SOURCE       {         LDS   SI,[BP+<Source]        ;DS:SI points to source}
  /$FC                   {         CLD                          ;Forward direction}
                         {;}
  /$BA/>CRT_STATUS       {         MOV   DX,>CRT_Status         ;Point DX to CGA status port}
                         {;}
  /$AD                   {GetNext: LODSW                        ;Load next character/attr into AX}
  /$89/$C3               {         MOV   BX,AX                  ;Store video word in BX}
                         {;}
  /$EC                   {WaitNoH: IN    AL,DX                  ;Get 6845 status}
  /$A8/$01               {         TEST  AL,1                   ;Wait for horizontal}
  /$75/$FB               {         JNZ   WaitNoH                ; retrace to finish}
                         {;}
  /$FA                   {         CLI                          ;Turn off interrupts}
  /$EC                   {WaitH:   IN    AL,DX                  ;Get 6845 status again}
  /$A8/$01               {         TEST  AL,1                   ;Wait for horizontal retrace}
  /$74/$FB               {         JZ    WaitH                  ; to start}
                         {;}
  /$89/$D8               {Store:   MOV   AX,BX                  ;Restore attribute}
  /$AB                   {         STOSW                        ; and then to screen}
  /$FB                   {         STI                          ;Allow interrupts}
                         {;}
  /$E2/$EC               {         LOOP  GetNext                ;Get next character}
                         {;}
  /$1F                   {Return:  POP   DS                     ;Restore DS}
);

END   (* MoveToScreen *);

(*----------------------------------------------------------------------*)
(*           MoveFromScreen  ---  Move data from screen memory          *)
(*----------------------------------------------------------------------*)

PROCEDURE MoveFromScreen( VAR Source, Dest; SLen: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  MoveFromScreen                                       *)
(*                                                                      *)
(*     Purpose:    Moves bytes from screen memory at specified offset   *)
(*                 with retrace locks.                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        MoveFromScreen( VAR Source, Dest; SLen: INTEGER );            *)
(*                                                                      *)
(*           Source --- Offset in screen to start at                    *)
(*           Dest   --- Receiving data area                             *)
(*           SLen   --- Number of words to move                         *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* MoveFromScreen *)

INLINE(
  $1E                    {         PUSH  DS                     ;Save DS}
                         {;}
  /$8B/$4E/<SLEN         {         MOV   CX,[BP+<SLen]          ;CX = Length(Source)}
  /$E3/$1A               {         JCXZ  Return                 ;If string empty, Return}
  /$C4/$7E/<DEST         {         LES   DI,[BP+<Dest]          ;ES:DI points to destination}
  /$C5/$76/<SOURCE       {         LDS   SI,[BP+<Source]        ;DS:SI points to source}
  /$FC                   {         CLD                          ;Forward direction}
  /$BA/>CRT_STATUS       {         MOV   DX,>CRT_Status         ;Point DX to CGA status port}
                         {;}
  /$EC                   {WaitNoH: IN    AL,DX                  ;Get 6845 status}
  /$A8/$01               {         TEST  AL,1                   ;Wait for horizontal}
  /$75/$FB               {         JNZ   WaitNoH                ; retrace to finish}
                         {;}
  /$FA                   {         CLI                          ;Turn off interrupts}
  /$EC                   {WaitH:   IN    AL,DX                  ;Get 6845 status again}
  /$A8/$01               {         TEST  AL,1                   ;Wait for horizontal retrace}
  /$74/$FB               {         JZ    WaitH                  ; to start}
                         {;}
  /$AD                   {         LODSW                        ;Get word from screen}
  /$FB                   {         STI                          ;Allow interrupts}
  /$AB                   {         STOSW                        ;Store in receiving data area}
  /$E2/$F0               {         LOOP  WaitNoH                ;Get next character}
                         {;}
  /$1F                   {Return:  POP   DS                     ;Restore DS}
);

END   (* MoveFromScreen *);
