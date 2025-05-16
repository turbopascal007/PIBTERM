PROCEDURE Emulate_TEK4010;

(*----------------------------------------------------------------------*)
(*             Emulate_TEK4010 --- Emulate TekTronix 4010 terminal      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Author:  Philip R. Burns                                            *)
(*  Date:    April, 1986        (Version 1.0)                           *)
(*           January, 1988      (Version 4.1 -- add EGA support)        *)
(*                                                                      *)
(*  Systems: For MS-DOS on IBM PCs and close compatibles only.          *)
(*                                                                      *)
(*  History: Original with me.                                          *)
(*                                                                      *)
(*           This emulator uses the high-resolution graphics mode       *)
(*           (640x200) of the standard IBM color graphics adapter,      *)
(*           or the high-resolution mode of the EGA (640x350).          *)
(*           Only graphics output is emulated, not graphics input.      *)
(*           On the CGA, the display consists of 33 rather than 35      *)
(*           lines of text, while on the EGA 35 lines are displayed.    *)
(*                                                                      *)
(*           Suggestions for improvements or corrections are welcome.   *)
(*           Please leave messages on Gene Plantz's BBS (312) 882 4145  *)
(*           or Ron Fox's BBS (312) 940 6496.                           *)
(*                                                                      *)
(*           IF you use this code in your own programs, please be nice  *)
(*           and give proper credit.                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

TYPE
   Graphics_State = ( Text_Plot, Vector_Plot_Start, Vector_Plot,
                      Point_Plot_Start, Point_Plot, Graphics_Input );

VAR
   Done       : BOOLEAN            (* TRUE to exit terminal emulation mode *);
   Ch         : CHAR               (* Character read/written               *);
   B          : BOOLEAN            (* Boolean flag                         *);
   Regs       : Registers          (* For MS DOS interfacing               *);
   FlagG      : Graphics_State     (* Current graphics state               *);
   CursorX    : INTEGER            (* X position of cursor                 *);
   CursorY    : INTEGER            (* Y position of cursor                 *);
   Reset_T    : BOOLEAN            (* Dummy for reset of terminal          *);
   EGA_On     : BOOLEAN            (* TRUE if EGA installed                *);
   XFactor    : REAL               (* Horizontal scaling factor            *);
   YFactor    : REAL               (* Vertical scaling factor              *);
   YMax       : INTEGER            (* Maximum Y value ==> 199, 349         *);
   YMaxM1     : INTEGER            (* Maximum Y value - 1 ==> 198, 348     *);
   YInc       : INTEGER            (* Increment in Y for characters        *);
   GMode      : INTEGER            (* Graphics mode type                   *);
   ClrScr_Req : BOOLEAN            (* TRUE if clear screen request typed   *);
   Save_SUpper: BOOLEAN            (* Save send_upper_case_only flag       *);

CONST
   Prev_Ch : CHAR = ^@;
   Hx      : INTEGER = 0;
   Hy      : INTEGER = 0;
   Lx      : INTEGER = 0;
   Ly      : INTEGER = 0;
   Old     : INTEGER = 0;
   LeftH   : BOOLEAN = TRUE;
   LastX   : INTEGER = 0;
   LastY   : INTEGER = 0;
   YDist   : INTEGER = 6;

CONST
   Ch_FF   = #12                   (* Form Feed       *);
   Ch_CR   = #13                   (* Carriage Return *);
   Ch_SO   = #14                   (* Start grahics   *);
   Ch_SI   = #15                   (* End graphics    *);
   Ch_SUB  = #26                   (* EOF Character   *);
   Ch_ESC  = #27                   (* Escape          *);
   Ch_FS   = #28                   (* Graphics start  *);
   Ch_GS   = #29                   (* Graphics start  *);
   Ch_RS   = #30                   (* Inc. plot start *);
   Ch_US   = #31                   (* Graphics end    *);

(*----------------------------------------------------------------------*)
(*         Plot_Point --- Plot one point in graphics display            *)
(*----------------------------------------------------------------------*)

PROCEDURE Plot_Point( X , Y: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Plot_Point                                           *)
(*                                                                      *)
(*     Purpose:    Plots one pixel in high-resolution graphics screen.  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Plot_Point( X , Y : INTEGER );                                *)
(*                                                                      *)
(*           X --- Horizontal coordinate (0--639)                       *)
(*           Y --- Vertical coordinate   (0--349)                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Plot_Point *)

INLINE(
                                      {;}
                                      {;  Check if we are to use BIOS to plot pixel}
                                      {;}
  $F6/$06/>WRITE_GRAPHICS_SCREEN/$01/ {         TEST    Byte [>Write_Graphics_Screen],1 ;Check if direct scren writes}
  $74/$30/                            {         JZ      Bios                            ;No -- use BIOS}
                                      {;}
                                      {;  Write pixel directly to screen memory}
                                      {;}
  $8B/$96/>Y/                         {         MOV     DX,[BP+>Y]            ; Get Y}
  $8D/$1E/>SCAN_LINE_TABLE/           {         LEA     BX,[>Scan_Line_Table] ; Get scan line table address}
  $D1/$E2/                            {         SHL     DX,1                  ; Y * 2 for integer offset}
  $01/$D3/                            {         ADD     BX,DX                 ; Get offset of entry for Y}
  $8B/$1F/                            {         MOV     BX,[BX]               ; Get offset for Y}
                                      {;}
  $8B/$96/>X/                         {         MOV     DX,[BP+>X]            ; Get X}
  $89/$D0/                            {         MOV     AX,DX}
  $B1/$03/                            {         MOV     CL,3                  ;}
  $D3/$EA/                            {         SHR     DX,CL                 ; X DIV 8 = Byte offset within row}
  $01/$D3/                            {         ADD     BX,DX                 ; Byte location in screen memory}
  $25/$07/$00/                        {         AND     AX,7                  ; X MOD 8}
  $BA/$80/$00/                        {         MOV     DX,$80                ; 1 bit in leftmost position}
  $89/$C1/                            {         MOV     CX,AX                 ; shift count}
  $D3/$EA/                            {         SHR     DX,CL                 ; 1 bit in proper position}
  $C4/$3E/>GRAPHICS_SCREEN/           {         LES     DI,[>Graphics_Screen] ; Get screen address}
  $01/$DF/                            {         ADD     DI,BX                 ; Get byte address}
  $26/$08/$15/                        {     ES: OR      BYTE PTR [DI],DL      ; Get byte to alter}
  $E9/$13/$00/                        {         JMP     Exit                  ; Return to caller}
                                      {;}
                                      {;  Plot pixel using BIOS}
                                      {;}
  $55/                                {Bios:    PUSH    BP                    ; Save BP in case BIOS zaps it}
  $1E/                                {         PUSH    DS}
  $B8/$01/$0C/                        {         MOV     AX,$0C01              ; Plot pixel function}
  $8B/$8E/>X/                         {         MOV     CX,[BP+>X]            ; Get horizontal position}
  $8B/$96/>Y/                         {         MOV     DX,[BP+>Y]            ; Get vertical position}
  $B7/$00/                            {         MOV     BH,0                  ; Always page 0}
  $CD/$10/                            {         INT     $10                   ; Plot the pixel via BIOS}
  $1F/                                {         POP     DS}
  $5D);                               {         POP     BP                    ; Restore BP}
                                      {;}
                                      {Exit:}

END   (* Plot_Point *);

(*----------------------------------------------------------------------*)
(*  XOR_Plot_Point --- Plot one point in graphics display using XOR     *)
(*----------------------------------------------------------------------*)

PROCEDURE XOR_Plot_Point( X , Y: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  XOR_Plot_Point                                       *)
(*                                                                      *)
(*     Purpose:    Plots one pixel in high-res graphics using XOR.      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        XOR_Plot_Point( X , Y : INTEGER );                            *)
(*                                                                      *)
(*           X --- Horizontal coordinate (0--639)                       *)
(*           Y --- Vertical coordinate   (0--199)                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* XOR_Plot_Point *)

INLINE(
                                      {;}
                                      {;  Check if we are to use BIOS to plot pixel}
                                      {;}
  $F6/$06/>WRITE_GRAPHICS_SCREEN/$01/ {         TEST    Byte [>Write_Graphics_Screen],1 ;Check if direct scren writes}
  $74/$30/                            {         JZ      Bios                            ;No -- use BIOS}
                                      {;}
                                      {;  Write pixel directly to screen memory}
                                      {;}
  $8B/$96/>Y/                         {         MOV     DX,[BP+>Y]            ; Get Y}
  $8D/$1E/>SCAN_LINE_TABLE/           {         LEA     BX,[>Scan_Line_Table] ; Get scan line table address}
  $D1/$E2/                            {         SHL     DX,1                  ; Y * 2 for integer offset}
  $01/$D3/                            {         ADD     BX,DX                 ; Get offset of entry for Y}
  $8B/$1F/                            {         MOV     BX,[BX]               ; Get offset for Y}
                                      {;}
  $8B/$96/>X/                         {         MOV     DX,[BP+>X]            ; Get X}
  $89/$D0/                            {         MOV     AX,DX}
  $B1/$03/                            {         MOV     CL,3                  ;}
  $D3/$EA/                            {         SHR     DX,CL                 ; X DIV 8 = Byte offset within row}
  $01/$D3/                            {         ADD     BX,DX                 ; Byte location in screen memory}
  $25/$07/$00/                        {         AND     AX,7                  ; X MOD 8}
  $BA/$80/$00/                        {         MOV     DX,$80                ; 1 bit in leftmost position}
  $89/$C1/                            {         MOV     CX,AX                 ; shift count}
  $D3/$EA/                            {         SHR     DX,CL                 ; 1 bit in proper position}
  $C4/$3E/>GRAPHICS_SCREEN/           {         LES     DI,[>Graphics_Screen] ; Get screen address}
  $01/$DF/                            {         ADD     DI,BX                 ; Get byte address}
  $26/$08/$15/                        {     ES: OR      BYTE PTR [DI],DL      ; Get byte to alter}
  $E9/$13/$00/                        {         JMP     Exit                  ; Return to caller}
                                      {;}
                                      {;  Plot pixel using BIOS}
                                      {;}
  $55/                                {Bios:    PUSH    BP                    ; Save BP in case BIOS zaps it}
  $1E/                                {         PUSH    DS}
  $B8/$81/$0C/                        {         MOV     AX,$0C81              ; Plot pixel function}
  $8B/$8E/>X/                         {         MOV     CX,[BP+>X]            ; Get horizontal position}
  $8B/$96/>Y/                         {         MOV     DX,[BP+>Y]            ; Get vertical position}
  $B7/$00/                            {         MOV     BH,0                  ; Always page 0}
  $CD/$10/                            {         INT     $10                   ; Plot the pixel via BIOS}
  $1F/                                {         POP     DS}
  $5D);                               {         POP     BP                    ; Restore BP}
                                      {;}
                                      {Exit:}

END   (* XOR_Plot_Point *);

(*----------------------------------------------------------------------*)
(*          Clear_Graphics_Screen --- Clear screen and home cursor      *)
(*----------------------------------------------------------------------*)

PROCEDURE Clear_Graphics_Screen;

BEGIN (* Clear_Graphics_Screen *)

   Set_Graphics_Colors( EGA_On,
                        GMode,
                        Graphics_Foreground_Color,
                        Graphics_BackGround_Color  );

                                   (* Move cursor to upper left-hand *)
                                   (* cursor.                        *)
   Graphics_XPos := 0;
   Graphics_YPos := 5;

   CursorX       := 0;
   CursorY       := 5;

   LeftH         := TRUE;
   Prev_Ch       := CHR( 0 );

END   (* Clear_Graphics_Screen *);

(*--------------------------------------------------------------------------*)
(*           Draw_Line -- Draw line between two points, low res. mode      *)
(*--------------------------------------------------------------------------*)

PROCEDURE Draw_Line( X1, Y1, X2, Y2: INTEGER );

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Procedure:  Draw_Line                                                 *)
(*                                                                          *)
(*    Purpose:    Draws line between two points in hi-res. graphics mode    *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       Draw_Line( X1 , Y1 , X2, Y2, LineCol : INTEGER );                  *)
(*                                                                          *)
(*           X1      -- Horizontal postion (0 through 639), 1st point       *)
(*           Y1      -- Vertical position (0 through 119), 1st point        *)
(*           X2      -- Horizontal postion (0 through 639), 2nd point       *)
(*           Y2      -- Vertical position (0 through 119), 2nd point        *)
(*                                                                          *)
(*    Calls:  TurnOnTimeSharing                                             *)
(*            TurnOffTimeSharing                                            *)
(*            Get_Screen_Address                                            *)
(*                                                                          *)
(*    Remarks: An incremental plotter algorithm is used.                    *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   LongDelta : INTEGER;
   LongStep  : INTEGER;
   ShortStep : INTEGER;
   LineStart : INTEGER;
   LineStop  : INTEGER;

BEGIN (* Draw_Line *)
                                   (* Turn off timesharing while drawing *)

   IF ( MultiTasker = DoubleDos ) THEN
      BEGIN
         TurnOffTimeSharing;
         Get_Screen_Address( Graphics_Screen );
      END;

INLINE(
  $C7/$86/>LONGSTEP/$01/$00/          {          MOV    WORD PTR >LongStep[BP],1       ; assume motion down or right}
  $8B/$B6/>X2/                        {          MOV    SI,>X2[BP]}
  $2B/$B6/>X1/                        {          SUB    SI,>X1[BP]                     ; get BP := LongDelta}
  $7D/$06/                            {          JGE    PL1                            ; if X1 <= X2 then no change}
  $F7/$9E/>LONGSTEP/                  {          NEG    WORD PTR >LongStep[BP]         ; ELSE LongStep := -1 (go up or left)}
  $F7/$DE/                            {          NEG    SI                             ;       LongDelta = abs(LongDelta)}
                                      {PL1:}
  $C7/$86/>SHORTSTEP/$01/$00/         {          MOV    WORD PTR >ShortStep[BP],1      ; assume motion down or right}
  $8B/$86/>Y2/                        {          MOV    AX,>Y2[BP]}
  $2B/$86/>Y1/                        {          SUB    AX,>Y1[BP]                     ; get AX := shortdelta}
  $7D/$06/                            {          JGE    PL2                            ; if y1 <= y2 then no change}
  $F7/$9E/>SHORTSTEP/                 {          NEG    WORD PTR >ShortStep[BP]        ; else, ShortStep = -1 (go up or left)}
  $F7/$D8/                            {          NEG    AX                             ;       shortdelta = abs(shortdelta)}
                                      {PL2:}
  $C7/$86/>LINESTART/$00/$00/         {          MOV    WORD PTR >LineStart[BP],0      ; assume no skip length}
  $8B/$8E/>X1/                        {          MOV    CX,>X1[BP]                     ; x coordinate in CX}
  $8B/$96/>Y1/                        {          MOV    DX,>Y1[BP]                     ; y coordinate in DX}
  $39/$F0/                            {          CMP    AX,SI                          ; is shortdelta > LongDelta?}
  $77/$40/                            {          JA     AltCode                        ; yes, use alternate draw code}
                                      {;}
                                      {;         Do following when line has slope between 0 and 1}
                                      {;}
  $89/$B6/>LINESTOP/                  {          MOV    >LineStop[BP],SI               ; assume length = LongDelta}
  $89/$F7/                            {          MOV    DI,SI                          ; set up the cycle pointer}
  $D1/$EF/                            {          SHR    DI,1                           ; cycle := LongDelta/2}
  $89/$B6/>LONGDELTA/                 {          MOV    >LongDelta[BP],SI}
  $BE/$00/$00/                        {          MOV    SI,0                           ; initialize loop counter}
                                      {NormLoop:}
  $3B/$B6/>LINESTART/                 {          CMP    SI,>LineStart[BP]              ; start to plot yet???}
  $7C/$0D/                            {          JL     PL5                            ; no, skip}
                                      {;}
  $50/                                {          PUSH   AX                             ;Save registers}
  $53/                                {          PUSH   BX}
  $51/                                {          PUSH   CX}
  $52/                                {          PUSH   DX}
  $57/                                {          PUSH   DI}
                                      {;}
  $E8/$6E/$00/                        {          CALL   PlotDot                        ;Plot pixel}
                                      {;}
  $5F/                                {          POP    DI                             ;Restore registers}
  $5A/                                {          POP    DX}
  $59/                                {          POP    CX}
  $5B/                                {          POP    BX}
  $58/                                {          POP    AX}
                                      {;}
                                      {PL5:}
  $03/$8E/>LONGSTEP/                  {          ADD    CX,>LongStep[BP]               ; always move along the X AXis}
  $01/$C7/                            {          ADD    DI,AX                          ; cycle = cycle + shortdelta}
  $3B/$BE/>LONGDELTA/                 {          CMP    DI,>LongDelta[BP]              ; is cycle >= LongDelta?}
  $7C/$08/                            {          JL     PL6                            ; no skip (don't go along y yet}
  $2B/$BE/>LONGDELTA/                 {          SUB    DI,>LongDelta[BP]              ; yes, reset cycle pointer}
  $03/$96/>SHORTSTEP/                 {          ADD    DX,>ShortStep[BP]              ;       and bump the y coord}
                                      {PL6:}
  $46/                                {          INC    SI                             ; bump dot counter}
  $3B/$B6/>LINESTOP/                  {          CMP    SI,>LineStop[BP]               ; done??}
  $76/$D2/                            {          JBE    NormLoop                       ; no, plot next dot}
  $E9/$A1/$00/                        {          JMP    PLExit                         ; yes, go to commom exit code}
                                      {;}
                                      {;         Do following when slope has absolute value > 1}
                                      {;}
                                      {AltCode:}
  $96/                                {          XCHG   AX,SI                          ; swap LongDelta, shortdelta}
  $8B/$BE/>LONGSTEP/                  {          MOV    DI,>LongStep[BP]               ;}
  $87/$BE/>SHORTSTEP/                 {          XCHG   >ShortStep[BP],DI}
  $89/$BE/>LONGSTEP/                  {          MOV    >LongStep[BP],DI               ; swap LongStep, ShortStep}
  $89/$B6/>LINESTOP/                  {          MOV    >LineStop[BP],SI               ; assume length = LongDelta}
  $89/$F7/                            {          MOV    DI,SI                          ; set up cycle pointer}
  $D1/$EF/                            {          SHR    DI,1                           ; cycle := LongDelta/2}
  $89/$B6/>LONGDELTA/                 {          MOV    >LongDelta[BP],SI}
  $BE/$00/$00/                        {          MOV    SI,0                           ; initialize loop counter}
                                      {AltLoop:}
  $3B/$B6/>LINESTART/                 {          CMP    SI,>LineStart[BP]              ; start to plot yet?}
  $7C/$0B/                            {          JL     PL8                            ; no, skip}
                                      {;}
  $50/                                {          PUSH   AX                             ;Save registers}
  $51/                                {          PUSH   CX}
  $52/                                {          PUSH   DX}
  $57/                                {          PUSH   DI}
                                      {;}
  $E8/$22/$00/                        {          CALL   PlotDot                        ;Plot pixel}
                                      {;}
  $5F/                                {          POP    DI                             ;Restore registers}
  $5A/                                {          POP    DX}
  $59/                                {          POP    CX}
  $58/                                {          POP    AX}
                                      {;}
                                      {PL8:}
  $03/$96/>LONGSTEP/                  {          ADD    DX,>LongStep[BP]               ; always move along Y AXis}
  $01/$C7/                            {          ADD    DI,AX                          ; cycle := cycle + shortdelta}
  $3B/$BE/>LONGDELTA/                 {          CMP    DI,>LongDelta[BP]              ; is cycle >= long delta???}
  $7C/$08/                            {          JL     PL9                            ; no, skip (don't move along x yet)}
  $2B/$BE/>LONGDELTA/                 {          SUB    DI,>LongDelta[BP]              ; yes, reset cycle pointer}
  $03/$8E/>SHORTSTEP/                 {          ADD    CX,>ShortStep[BP]              ;        and bump x coordinate}
                                      {PL9:}
  $46/                                {          INC    SI                             ; bump dot counter}
  $3B/$B6/>LINESTOP/                  {          CMP    SI,>LineStop[BP]               ; done???}
  $76/$D4/                            {          JBE    AltLoop                        ; no, plot next dot}
  $E9/$56/$00/                        {          JMP    PLExit                         ; yes, go to common exit}
                                      {;}
                                      {PlotDot:  ;PROC   Near}
                                      {;}
                                      {;  Check if we are to use BIOS to plot pixel}
                                      {;}
  $F6/$06/>WRITE_GRAPHICS_SCREEN/$01/ {         TEST    Byte [>Write_Graphics_Screen],1 ;Check if direct screen writes}
  $74/$43/                            {         JZ      Bios                            ;No -- use BIOS}
                                      {;}
                                      {;  Write pixel directly to screen memory.}
                                      {;  Determine if EGA or CGA and get Y offset.}
                                      {;}
  $F6/$06/>EGA_USE/$01/               {         TEST    Byte [>Ega_Use],1      ;Check if EGA used}
  $74/$12/                            {         JZ      CGA                    ;No -- go figure CGA offset}
                                      {;}
  $89/$C8/                            {         MOV     AX,CX                  ;Save X}
  $B1/$06/                            {         MOV     CL,6                   ;Shift count}
  $89/$D3/                            {         MOV     BX,DX                  ;Copy Y}
  $D3/$E2/                            {         SHL     DX,CL                  ;Y * 64}
  $B1/$04/                            {         MOV     CL,4                   ;Shift count}
  $D3/$E3/                            {         SHL     BX,CL                  ;Y * 16}
  $01/$D3/                            {         ADD     BX,DX                  ;Y * 80 = offset for Y}
  $89/$C1/                            {         MOV     CX,AX                  ;Restore X}
  $EB/$0A/                            {         JMP     Short Both}
                                      {;}
  $8D/$1E/>SCAN_LINE_TABLE/           {CGA:     LEA     BX,[>Scan_Line_Table]          ; Get scan line table address}
  $D1/$E2/                            {         SHL     DX,1                           ; Y * 2 for integer offset}
  $01/$D3/                            {         ADD     BX,DX                          ; Get offset of entry for Y}
  $8B/$1F/                            {         MOV     BX,[BX]                        ; Get offset for Y}
                                      {;}
  $89/$CA/                            {Both:    MOV     DX,CX                          ; Get X}
  $89/$C8/                            {         MOV     AX,CX}
  $B1/$03/                            {         MOV     CL,3                           ;}
  $D3/$EA/                            {         SHR     DX,CL                          ; X DIV 8 = Byte offset in row}
  $01/$D3/                            {         ADD     BX,DX                          ; Byte pos in screen memory}
  $25/$07/$00/                        {         AND     AX,7                           ; X MOD 8}
  $BA/$80/$00/                        {         MOV     DX,$80                         ; 1 bit in leftmost position}
  $89/$C1/                            {         MOV     CX,AX                          ; shift count}
  $D3/$EA/                            {         SHR     DX,CL                          ; 1 bit in proper position}
  $C4/$3E/>GRAPHICS_SCREEN/           {         LES     DI,[>Graphics_Screen]          ; Get screen address}
  $01/$DF/                            {         ADD     DI,BX                          ; Get byte address}
  $26/$08/$15/                        {     ES: OR      BYTE PTR [DI],DL               ; Get byte to alter}
  $E9/$0B/$00/                        {         JMP     Exit                           ; Return to caller}
                                      {;}
                                      {;  Plot pixel using BIOS}
                                      {;}
  $55/                                {Bios:    PUSH    BP                             ; Save BP in case BIOS zaps it}
  $53/                                {         PUSH    BX                             ; Save BX}
  $B7/$00/                            {         MOV     BH,0                           ; Page 0 always}
  $B8/$01/$0C/                        {         MOV     AX,$0C01                       ; Plot pixel function}
  $CD/$10/                            {         INT     $10                            ; Plot the pixel via BIOS}
  $5B/                                {         POP     BX                             ; Restore BX}
  $5D/                                {         POP     BP                             ; Restore BP}
                                      {;}
                                      {Exit:}
  $C3);                               {         RET}
                                      {;}
                                      {PLExit:}

                                   (* Restore timesharing mode *)

   IF ( MultiTasker = DoubleDos ) THEN
      TurnOnTimeSharing;

END   (* Draw_Line *);

(*----------------------------------------------------------------------*)
(*          Plot_Char --- Interpret current char as text to display     *)
(*----------------------------------------------------------------------*)

PROCEDURE Plot_Char( Ch: CHAR; X: INTEGER; Y: INTEGER );

VAR
   I         : INTEGER;
   K1        : INTEGER;
   K2        : INTEGER;
   XB        : INTEGER;
   XO        : INTEGER;
   XO1       : INTEGER;
   XS        : INTEGER;
   XSL       : INTEGER;
   Do_XOR    : BOOLEAN;
                                   (* Holds point plot routine offset *)
(* STRUCTURED *) CONST
   Plot_Pixel_Function : WORD = 0;

                                   (* Shape table for characters *)
(* STRUCTURED *) CONST
   Char_Bits_Table: ARRAY[0..581] OF BYTE =
                    (     0,   0,   0,   0,   0,   0,
                          0,  96,   0,  96,  96,  96,
                          0,   0,   0,   0, 216, 216,
                          0,  80, 248,  80, 248,  80,
                          0, 240,  40, 112, 160, 120,
                          0, 152,  88,  32, 208, 200,
                          0,  16, 120, 144, 144, 112,
                          0,   0,   0,  32,  48,  48,
                          0,  32,  64,  64,  64,  32,
                          0,  64,  32,  32,  32,  64,
                          0, 136,  80, 248,  80, 136,
                          0,  32,  32, 248,  32,  32,
                          0,  64,  96,   0,   0,   0,
                          0,   0,   0, 240,   0,   0,
                          0,  24,  24,   0,   0,   0,
                          0, 128,  64,  32,  16,   8,
                          0, 112, 136, 168, 136, 112,
                          0, 112,  32,  32,  96,  32,
                          0, 248,  96,  16, 136, 112,
                          0, 112, 136,  48, 136, 112,
                          0,  16, 248, 144,  80,  32,
                          0, 240,   8, 240, 128, 248,
                          0, 112, 136, 240, 128, 112,
                          0,  64,  32,  16,   8, 120,
                          0, 112, 136, 112, 136, 112,
                          0, 112,   8, 120, 136, 112,
                          0,  96,  96,   0,  96,  96,
                          0,  64,  96,   0,  96,  96,
                          0,  16,  32,  64,  32,  16,
                          0,   0, 240,   0, 240,   0,
                          0,  64,  32,  16,  32,  64,
                          0,  32,  32,  48, 136, 112,
                          0, 112, 128, 176, 136, 112,
                          0, 136, 248, 136,  80,  32,
                          0, 240, 136, 240, 136, 240,
                          0, 120, 128, 128, 128, 120,
                          0, 240, 136, 136, 136, 240,
                          0, 248, 128, 240, 128, 248,
                          0, 128, 128, 240, 128, 248,
                          0, 120, 136, 184, 128, 120,
                          0, 136, 136, 248, 136, 136,
                          0, 112,  32,  32,  32, 112,
                          0, 112, 136,   8,   8,   8,
                          0, 136, 144, 224, 144, 136,
                          0, 248, 128, 128, 128, 128,
                          0, 136, 136, 168, 216, 136,
                          0, 136, 152, 168, 200, 136,
                          0, 112, 136, 136, 136, 112,
                          0, 128, 128, 240, 136, 240,
                          0, 104, 152, 168, 136, 112,
                          0, 152, 144, 240, 136, 240,
                          0, 240,   8, 112, 128, 120,
                          0,  32,  32,  32,  32, 248,
                          0, 112, 136, 136, 136, 136,
                          0,  32, 112, 136, 136, 136,
                          0, 136, 216, 168, 136, 136,
                          0, 136,  80,  32,  80, 136,
                          0,  32,  32,  32,  80, 136,
                          0, 248,  64,  32,  16, 248,
                          0, 120,  96,  96,  96, 120,
                          0,   8,  16,  32,  64, 128,
                          0, 120,  24,  24,  24, 120,
                          0,   0,   0, 136,  80,  32,
                          0,   0, 248,   0,   0,   0,
                          0,   0,   0,  32,  96,  96,
                          0, 136, 248, 136,  80,  32,
                          0, 240, 136, 240, 136, 240,
                          0, 120, 128, 128, 128, 120,
                          0, 240, 136, 136, 136, 240,
                          0, 248, 128, 240, 128, 248,
                          0, 128, 128, 240, 128, 248,
                          0, 120, 136, 184, 128, 120,
                          0, 136, 136, 248, 136, 136,
                          0, 112,  32,  32,  32, 112,
                          0, 112, 136,   8,   8,   8,
                          0, 136, 144, 224, 144, 136,
                          0, 248, 128, 128, 128, 128,
                          0, 136, 136, 168, 216, 136,
                          0, 136, 152, 168, 200, 136,
                          0, 112, 136, 136, 136, 112,
                          0, 128, 128, 240, 136, 240,
                          0, 104, 152, 168, 136, 112,
                          0, 152, 144, 240, 136, 240,
                          0, 240,   8, 112, 128, 120,
                          0,  32,  32,  32,  32, 248,
                          0, 112, 136, 136, 136, 136,
                          0,  32, 112, 136, 136, 136,
                          0, 136, 216, 168, 136, 136,
                          0, 136,  80,  32,  80, 136,
                          0,  32,  32,  32,  80, 136,
                          0, 248,  64,  32,  16, 248,
                          0,   0,   0,   0,   0,   0,
                          0,   0,   0,   0,   0,   0,
                          0,   0,   0,   0,   0,   0,
                          0,   0,   0,   0,   0,   0,
                          0,   0,   0,   0,   0,   0,
                          0, 124, 124, 124, 124, 124 );

BEGIN (* Plot_Char *)
                                   (* Use XOR rather than OR for *)
                                   (* the cursor.                *)
   Do_XOR := ( ORD( Ch ) = 128 );

   IF Write_Graphics_Screen THEN
      BEGIN
                                   (* Turn off timesharing while drawing *)

         IF ( MultiTasker = DoubleDos ) THEN
            BEGIN
               TurnOffTimeSharing;
               Get_Screen_Address( Graphics_Screen );
            END;
                                   (* Get byte offset in row *)
         XB  := SUCC( X SHR 3 );
                                   (* Get bit offset within byte *)
         XS  := X AND 7;
         XSL := 8 - XS;
                                   (* Get offset of character bit *)
                                   (* pattern.                    *)

         K1  := ( ORD( Ch ) - 32 ) * 6;
         K2  := K1 + 5;

                                   (* OR/XOR in bits of new character. *)
                                   (* If X is even byte address, then  *)
                                   (* simply loop over rows in the     *)
                                   (* character.  If X is not even     *)
                                   (* byte address, we need to store   *)
                                   (* part of pattern in two success-  *)
                                   (* ive bytes.                       *)

         IF ( XS = 0 ) THEN
            WITH Graphics_Screen^ DO
               FOR I := K1 TO K2 DO
                  BEGIN
                     CASE EGA_Use OF
                        FALSE: XO := Scan_Line_Table[ Y ] + XB;
                        TRUE : XO := ( Y * 80 ) + XB;
                     END (* CASE *);
                     IF Do_XOR THEN
                        Screen_Image[ XO ] := Screen_Image[ XO ] XOR
                                              Char_Bits_Table[ I ]
                     ELSE
                        Screen_Image[ XO ] := Screen_Image[ XO ] OR
                                              Char_Bits_Table[ I ];
                     Y := PRED( Y );
                  END
         ELSE
            WITH Graphics_Screen^ DO
               FOR I := K1 TO K2 DO
                  BEGIN
                     CASE EGA_Use OF
                        FALSE: XO := Scan_Line_Table[ Y ] + XB;
                        TRUE : XO := ( Y * 80 ) + XB;
                     END (* CASE *);
                     XO1 := SUCC( XO );
                     IF Do_XOR THEN
                        BEGIN
                           Screen_Image[ XO  ] := Screen_Image[ XO  ] XOR
                                                  ( Char_Bits_Table[ I ] SHR XS );
                           Screen_Image[ XO1 ] := Screen_Image[ XO1 ] XOR
                                                  ( Char_Bits_Table[ I ] SHL XSL );
                        END
                     ELSE
                        BEGIN
                           Screen_Image[ XO  ] := Screen_Image[ XO  ] OR
                                                  ( Char_Bits_Table[ I ] SHR XS );
                           Screen_Image[ XO1 ] := Screen_Image[ XO1 ] OR
                                                  ( Char_Bits_Table[ I ] SHL XSL );
                        END;
                     Y := PRED( Y );
                  END;

                                   (* Restore timesharing mode *)

         IF ( MultiTasker = DoubleDos ) THEN
            TurnOnTimeSharing;

      END
   ELSE
      BEGIN (* Plot through BIOS the hard way *)

         IF Do_XOR THEN
            Plot_Pixel_Function := $0C81
         ELSE
            Plot_Pixel_Function := $0C01;

INLINE(
  $8B/$86/>X/               {         MOV     AX,[BP+>X]                 ;Get X position}
  $48/                      {         DEC     AX                         ;Decrement for 0 offset later}
  $89/$C6/                  {         MOV     SI,AX                      ;Save X position}
                            {;}
  $8B/$86/>Y/               {         MOV     AX,[BP+>Y]                 ;Get Y position}
  $89/$C7/                  {         MOV     DI,AX                      ;Save Y position}
                            {;}
  $31/$C0/                  {         XOR     AX,AX                      ;Clear AX}
  $8A/$46/<CH/              {         MOV     AL,[BP+<Ch]                ;Pick up character to display}
  $2D/$20/$00/              {         SUB     AX,32                      ;Convert to 0 offset}
  $89/$C3/                  {         MOV     BX,AX}
  $D1/$E0/                  {         SHL     AX,1                       ;Offset * 2}
  $D1/$E0/                  {         SHL     AX,1                       ;Offset * 4}
  $01/$D8/                  {         ADD     AX,BX                      ;Offset * 5}
  $01/$C3/                  {         ADD     BX,AX                      ;Offset * 6 = offset into shape table}
  $8D/$06/>CHAR_BITS_TABLE/ {         LEA     AX,[<Char_Bits_Table]      ;Get address of shape table}
  $01/$C3/                  {         ADD     BX,AX                      ;Get starting address this character}
                            {;}
  $B9/$06/$00/              {         MOV     CX,6                       ;Loop over rows in character}
                            {;}
  $51/                      {Char1:   PUSH    CX                         ;Save loop counter for rows}
  $53/                      {         PUSH    BX                         ;Save table offset}
                            {;}
  $8A/$07/                  {         MOV     AL,[BX]                    ;Get bit pattern for this row}
  $08/$C0/                  {         OR      AL,AL                      ;Check if any bits on in this row}
  $74/$22/                  {         JZ      Char4                      ;No -- skip display this row}
                            {;}
  $B9/$08/$00/              {         MOV     CX,8                       ;Loop over bits this row}
                            {;}
  $51/                      {Char2:   PUSH    CX                         ;Save loop counter for bits}
                            {;}
  $A8/$01/                  {         TEST    AL,1                       ;See if "this" bit is turned on}
  $74/$15/                  {         JZ      Char3                      ;No -- skip to next bit}
                            {;}
  $50/                      {         PUSH    AX                         ;Save bit mask}
  $56/                      {         PUSH    SI                         ;Save X}
  $57/                      {         PUSH    DI                         ;Save Y}
                            {;}
  $89/$F0/                  {         MOV     AX,SI                      ;Get X}
  $01/$C1/                  {         ADD     CX,AX                      ;Add offset}
  $A1/>PLOT_PIXEL_FUNCTION/ {         MOV     AX,[>Plot_Pixel_Function]  ;Plot pixel function}
  $89/$FA/                  {         MOV     DX,DI                      ;Get vertical position}
  $B7/$00/                  {         MOV     BH,0                       ;Always page 0}
  $55/                      {         PUSH    BP                         ;Save BP in case BIOS clobbers it}
  $CD/$10/                  {         INT     $10                        ;Plot the pixel via BIOS}
  $5D/                      {         POP     BP                         ;Restore BP}
                            {;}
  $5F/                      {         POP     DI                         ;Restore Y}
  $5E/                      {         POP     SI                         ;Restore X}
  $58/                      {         POP     AX                         ;Restore bit mask}
                            {;}
  $D0/$E8/                  {Char3:   SHR     AL,1                       ;Shift bit mask to next bit}
  $59/                      {         POP     CX                         ;Retrieve bits counter}
  $E2/$E1/                  {         LOOP    Char2                      ;and try next bit}
                            {;}
  $5B/                      {Char4:   POP     BX                         ;Retrieve table offset}
  $43/                      {         INC     BX                         ;Point to next shape table byte}
  $89/$F8/                  {         MOV     AX,DI                      ;Decrement Y}
  $48/                      {         DEC     AX                         ;  ...}
  $89/$C7/                  {         MOV     DI,AX                      ;  ...}
  $59/                      {         POP     CX                         ;Retrieve rows counter}
  $E2/$CC);                 {         LOOP    Char1                      ;and try next row}

      END;

END   (* Plot_Char *);

(*----------------------------------------------------------------------*)
(*               Display_Cursor  --- Display block cursor               *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Cursor( X, Y: INTEGER );

BEGIN (* Display_Cursor *)
                                   (* Don't display cursor while plotting *)

   IF ( FlagG = Text_Plot ) THEN
      Plot_Char( CHR( 128 ) , X , Y );

END   (* Display_Cursor *);

(*----------------------------------------------------------------------*)
(*           Display_Graphics --- show character received from port     *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Graphics( VAR Ch : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Graphics                                     *)
(*                                                                      *)
(*     Purpose:    Displays character received from comm. port on       *)
(*                 screen/printer/capture file.                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Graphics( Ch : CHAR );                                *)
(*                                                                      *)
(*           Ch         --- Character received from Comm. port.         *)
(*                                                                      *)
(*      Calls:   Async_Receive                                          *)
(*               Min                                                    *)
(*               Update_Review_Pointers                                 *)
(*               TimeOfDay                                              *)
(*               TimeDiff                                               *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         This routine strips out certain characters which             *)
(*         should not be displayed, implements the XON/XOFF protocol    *)
(*         in a simple-minded manner, performs output wrap, and saves   *)
(*         output line in the review the review buffer.                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)


(* STRUCTURED *) CONST
   CR_Ch   : CHAR = ^M;
   LF_Ch   : CHAR = ^J;
   BL_Ch   : CHAR = ' ';

VAR
   I    : INTEGER;
   L    : INTEGER;
   Xpos : INTEGER;
   Ypos : INTEGER;
   C    : INTEGER;
   KeyC : CHAR;
   TT   : Transfer_Type;

(*----------------------------------------------------------------------*)
(*          Do_Graphics --- Interpret current char as graphics command  *)
(*----------------------------------------------------------------------*)

PROCEDURE Do_Graphics;

BEGIN (* Do_Graphics *)
                                   (* Get previous character and *)
                                   (* save current character     *)
   Old     := ORD( Prev_Ch );
   Prev_Ch := Ch;
                                   (* Set first X corrdinate     *)

   IF ( C > 31 ) AND ( C < 64 ) AND ( Old > 95 ) AND ( Old < 128 ) THEN
      BEGIN
         Hx      := C;
         EXIT;
      END;
                                   (* Set first Y coordinate     *)

   IF ( C > 31 ) AND ( C < 64 ) THEN
      BEGIN
         Hy      := C;
         EXIT;
      END;
                                   (* Set second Y coordinate    *)

   IF ( C > 95 ) AND ( C < 128 ) THEN
      BEGIN
         Ly      := C;
         EXIT;
      END;
                                   (* Set second X coordinate, and *)
                                   (* plot point if necessary.     *)

   IF ( C > 63 ) AND ( C < 96 ) THEN
      BEGIN

         Lx      := C;
                                   (* Get PC screen position of point *)

         XPos    := TRUNC( XFactor * ( ( Hx - 32 ) * 32 + Lx - 64 ));
         YPos    := YMax - TRUNC( YFactor * ( ( Hy - 32 ) * 32 + Ly - 96 ));

                                   (* Turn off timesharing while drawing *)

         IF ( MultiTasker = DoubleDos ) THEN
            BEGIN
               TurnOffTimeSharing;
               Get_Screen_Address( Graphics_Screen );
            END;
                                   (* First coordinate -- just move *)
                                   (* to it                         *)

         CASE FlagG OF
            Vector_Plot      : Draw_Line( Graphics_XPos, Graphics_YPos,
                                          XPos, YPos );
            Vector_Plot_Start: FlagG   := Vector_Plot;
            Point_Plot       : Plot_Point( XPos, YPos );
            Point_Plot_Start : FlagG   := Point_Plot;
            ELSE;
         END (* CASE *);

                                   (* Restore timesharing mode *)

         IF ( MultiTasker = DoubleDos ) THEN
            TurnOnTimeSharing;
                                   (* Update graphics position *)
         Graphics_XPos := XPos;
         Graphics_YPos := YPos;

      END;

END   (* Do_Graphics *);

