(*----------------------------------------------------------------------*)
(*       Get_Screen_Text_Line --- Extract text from screen image        *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Screen_Text_Line( VAR Text_Line     : AnyStr;
                                    Screen_Line   : INTEGER;
                                    Screen_Column : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Screen_Text_Line                                 *)
(*                                                                      *)
(*     Purpose:    Extracts text from current screen image              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*       Get_Screen_Text_Line( VAR  Text_Line     : AnyStr;             *)
(*                                  Screen_Line   : INTEGER;            *)
(*                                  Screen_Column : INTEGER );          *)
(*                                                                      *)
(*           Text_Line        --- receives text extracted from screen   *)
(*           Screen_Line      --- line on screen to extract             *)
(*           Screen_Column    --- starting column to extract            *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        Only the text -- not attributes -- from the screen is         *)
(*        returned.                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   First_Pos  : INTEGER;
   Len        : INTEGER;
   I          : INTEGER;
   J          : INTEGER;
   Regs       : Registers;
   SaveX      : INTEGER;
   SaveY      : INTEGER;
   C          : BYTE;
   Attr       : BYTE;
   LBuffer    : ARRAY[1..256] OF CHAR;

BEGIN  (* Get_Screen_Text_Line *)

   Screen_Line   := Max( Min( Screen_Line   , Max_Screen_Line ) , 1 );
   Screen_Column := Max( Min( Screen_Column , Max_Screen_Col  ) , 1 );

   Text_Line[0]  := #0;

   IF Write_Screen_Memory THEN
      BEGIN

         First_Pos     := ( ( Screen_Line - 1 ) * Max_Screen_Col +
                            Screen_Column ) SHL 1 - 1;
         Len           := Max_Screen_Col - Screen_Column + 1;
         J             := 0;

         IF TimeSharingActive THEN
            BEGIN
               TurnOffTimeSharing;
               Get_Screen_Address( Actual_Screen );
            END;

         IF Wait_For_Retrace THEN
            MoveFromScreen( Actual_Screen^.Screen_Image[ First_Pos ],
                            LBuffer[1], Len )
         ELSE
            Move( Actual_Screen^.Screen_Image[ First_Pos ], LBuffer[1], Len SHL 1 );

         I := 1;

         FOR J := 1 TO Len DO
            BEGIN
               Text_Line[J] := LBuffer[I];
               I            := I + 2;
            END;

         Text_Line[0] := CHR( Len );

         IF TimeSharingActive THEN
            TurnOnTimeSharing;

      END
   ELSE
      BEGIN                        (* Use BIOS to extract line *)
                                   (* Save current position    *)
         SaveX := WhereX;
         SaveY := WhereY;
         J     := 0;
                                   (* Loop over columns to extract *)

         FOR I := Screen_Column TO Max_Screen_Col DO
            BEGIN
                                   (* Pick up character *)

               ReadCXY( C, I, Screen_Line, Attr );

                                   (* Insert character in result string *)

               J            := SUCC( J );
               Text_Line[J] := CHR ( C );

            END;
                                   (* Set length of string extracted *)
         Text_Line[0] := CHR( J );
                                   (* Restore previous position   *)
         GoToXY( SaveX, SaveY );

      END;

END    (* Get_Screen_Text_Line *);

(*----------------------------------------------------------------------*)
(*                Print_Screen --- Print current screen image           *)
(*----------------------------------------------------------------------*)

PROCEDURE Print_Screen;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Print_Screen                                         *)
(*                                                                      *)
(*     Purpose:    Prints current screen image (memory mapped area)     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Print_Screen;                                                 *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        Only the text from the screen is printed, not the attributes. *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I         : INTEGER;
   Text_Line : AnyStr;

BEGIN  (* Print_Screen *)

   FOR I := 1 TO Max_Screen_Line DO
      BEGIN
         Get_Screen_Text_Line( Text_Line, I, 1 );
         Write_Prt_Str( Text_Line );
         Write_Prt_Str( CRLF_String );
      END;

END    (* Print_Screen *);

(*----------------------------------------------------------------------*)
(*        Write_Screen --- Write current screen image to file           *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_Screen( Fname : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Write_Screen                                         *)
(*                                                                      *)
(*     Purpose:    Write current screen image (memory mapped area) to   *)
(*                 a file.                                              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Write_Screen( Fname : AnyStr );                               *)
(*                                                                      *)
(*           Fname --- Name of file to write screen to                  *)
(*                                                                      *)
(*     Calls:   Open_For_Append                                         *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        Only the text from the screen is written, not the attributes. *)
(*        If the file already exists, then the new screen is appended   *)
(*        to the end of the file.                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I         : INTEGER;
   Text_Line : AnyStr;
   F         : Text_File;
   Cur_Vid   : INTEGER;

BEGIN  (* Write_Screen *)

                                   (* Don't write screen in graphics mode *)
   Cur_Vid := Current_Video_Mode;

   IF ( ( Cur_Vid < MedRes_GraphMode ) OR ( Cur_Vid = Mono_TextMode ) ) THEN

                                   (* Open screen file for append -- new  *)
                                   (* screen dump written at end of file. *)

      IF Open_For_Append( F , Fname , I ) THEN
         BEGIN

            FOR I := 1 TO Max_Screen_Line DO
               BEGIN
                  Get_Screen_Text_Line( Text_Line, I, 1 );
                  WRITELN( F , Text_Line );
               END;

            (*!I-*)
            CLOSE( F );
            (*!I+*)

         END;

END    (* Write_Screen *);

(*----------------------------------------------------------------------*)
(*  Write_Graphics_Screen --- Write current screen image to file        *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_Graphics_Screen( Fname : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Write_Graphics_Screen                                *)
(*                                                                      *)
(*     Purpose:    Write current screen image (memory mapped area) to   *)
(*                 a file.                                              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Write_Graphics_Screen( Fname : AnyStr );                      *)
(*                                                                      *)
(*           Fname --- Name of file to write screen to                  *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        If the file already exists, then the new screen is appended   *)
(*        to the end of the file.                                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I           : INTEGER;
   F           : FILE;
   L           : WORD;
   Cur_Vid     : INTEGER;
   Screen_APtr : Screen_Ptr;

BEGIN  (* Write_Graphics_Screen *)
                                   (* Get length of graphics screen  *)
   Cur_Vid := Current_Video_Mode;

   CASE Cur_Vid OF
      EGA_GraphMode   :  BEGIN
                            L           := EGA_Graphics_Scr_Length;
                            Screen_APtr := PTR( EGA_Screen_Address , 0 )
                         END;
      HiRes_GraphMode :  BEGIN
                            L           := Graphics_Screen_Length;
                            Screen_APtr := PTR( Color_Screen_Address , 0 );
                            IF ( MultiTasker = DoubleDos ) THEN
                               Get_Screen_Address( Screen_APtr );
                         END;
      ELSE               L := 0;
   END (* CASE *);
                                   (* Don't write if not graphics mode *)
   IF ( L = 0 ) THEN EXIT;
                                   (* Assign graphics dump file name *)
   ASSIGN( F , Fname );
   REWRITE( F , L );
                                   (* Turn off timesharing while writing screen *)

   IF ( MultiTasker = DoubleDos ) THEN
      TurnOffTimeSharing;

   BlockWrite( F, Screen_APtr^, 1 );

   CLOSE( F );
     (*!I+*)
                                   (* Restore timesharing mode *)

   IF ( MultiTasker = DoubleDos ) THEN
      TurnOnTimeSharing;

END    (* Write_Graphics_Screen *);

(*----------------------------------------------------------------------*)
(*      Get_Screen_Size --- Get maximum rows, columns of display        *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Screen_Size( VAR Rows: INTEGER; VAR Columns: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Screen_Size                                      *)
(*                                                                      *)
(*     Purpose:    Gets maximum rows, columns in current display        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Screen_Size( VAR Rows: INTEGER; VAR Columns: INTEGER );   *)
(*                                                                      *)
(*           Rows    --- # of rows in current display                   *)
(*           Columns --- # of columns in current display                *)
(*                                                                      *)
(*     Calls:   Bios                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs : Registers;
   I    : INTEGER;

BEGIN  (* Get_Screen_Size *)
                                   (* Set defaults *)
   Regs.AH := $0F;
   INTR( $10 , Regs );

   Rows    := 25;
   Columns := MAX( Regs.AH , 80 );

                                   (* If EGA installed, check for other *)
                                   (* line values.                      *)
   IF EGA_Present THEN
      BEGIN
                                   (* Get # of rows in current EGA display *)
         Rows := Get_Rows_For_EGA;

                                   (* If 25 lines returned, set        *)
                                   (* EGA 25-line mode to avoid cursor *)
                                   (* problems later on, but only if   *)
                                   (* 80 column text mode.             *)

         IF ( ( Rows = 25 ) AND ( Columns = 80 ) ) THEN
            BEGIN
                                   (* Load font for 25 line mode *)
               Regs.AX := $1111;
               Regs.BL := 0;
               INTR( $10, Regs );
                                   (* Reset cursor for 25 line mode *)
               Regs.CX := $0607;
               Regs.AH := 01;
               INTR( $10 , Regs );

            END;

      END;

END    (* Get_Screen_Size *);

(*----------------------------------------------------------------------*)
(*      Set_EGA_Text_Mode --- Set character set, cursor for EGA         *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_EGA_Text_Mode( EGA_Rows : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_EGA_Text_Mode                                    *)
(*                                                                      *)
(*     Purpose:    Set character set, cursor for EGA/VGA                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_EGA_Text_Mode( EGA_Rows : INTEGER );                      *)
(*                                                                      *)
(*           Rows    --- # of rows to set in current display            *)
(*                       25, 35, 43, and 50 lines are supported for     *)
(*                       EGA; 25 and 50 lines for VGA.                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

(* STRUCTURED *) CONST
   Table_Ofs : POINTER = NIL;

BEGIN (* Set_EGA_Text_Mode *)

   Table_Ofs := @Sector_Data;

INLINE(
  $55/                      {                PUSH    BP}
  $1E/                      {                PUSH    DS                      ; Save registers}
                            {;}
  $FC/                      {                CLD                             ; All strings forward}
                            {;}
  $8B/$86/>EGA_ROWS/        {                MOV     AX,[BP+>EGA_Rows]       ; Pick up # lines}
  $3C/$19/                  {                CMP     BYTE AL,25}
  $74/$16/                  {                JE      Line25}
  $3C/$23/                  {                CMP     BYTE AL,35}
  $74/$3A/                  {                JE      Line35}
  $3C/$2B/                  {                CMP     BYTE AL,43}
  $74/$74/                  {                JE      Line43}
  $3C/$32/                  {                CMP     BYTE AL,50}
  $75/$03/                  {                JNE     Check66}
  $E9/$80/$00/              {                JMP     Line50}
  $3C/$42/                  {Check66:        CMP     BYTE AL,66}
  $75/$03/                  {                JNE     Line25}
  $E9/$BA/$00/              {                JMP     Line66}
                            {;                                               ; Assume 25 lines if bogus}
  $B3/$00/                  {Line25:         MOV     BL,0}
                            {;}
  $F6/$06/>VGA_PRESENT/$01/ {                TEST    BYTE [>VGA_Present],1   ; Check for VGA}
  $74/$17/                  {                JZ      Line25a}
                            {;}
                            {;;              MOV     AX,$1114                ; Load 8 x 16 font for VGA}
                            {;;              INT     $10}
                            {;;              JMP     Exit}
  $B8/$30/$11/              {                MOV     AX,$1130                ; Get pointer to 8 x 16 font}
  $B7/$06/                  {                MOV     BH,6}
  $CD/$10/                  {                INT     $10}
                            {;}
  $B8/$10/$11/              {                MOV     AX,$1110}
  $BB/$00/$10/              {                MOV     BX,$1000}
  $B9/$00/$01/              {                MOV     CX,$0100}
  $31/$D2/                  {                XOR     DX,DX}
                            {;}
  $CD/$10/                  {                INT     $10                     ; Load 8 x 16 font}
  $E9/$D1/$00/              {                JMP     Exit}
                            {;}
  $B8/$11/$11/              {Line25a:        MOV     AX,$1111                ; Load 8 x 14 font for EGA}
  $CD/$10/                  {                INT     $10}
  $E9/$C9/$00/              {                JMP     Exit}
                            {;}
  $F6/$06/>VGA_PRESENT/$01/ {Line35:         TEST    BYTE [>VGA_Present],1   ; Check for VGA}
  $75/$03/                  {                JNZ     Line35a                 ; Do nothing if so}
  $E9/$BF/$00/              {                JMP     Exit}
                            {;}
  $B8/$30/$11/              {Line35a:        MOV     AX,$1130                ; Load 8 x 8 font}
  $B7/$03/                  {                MOV     BH,3}
  $CD/$10/                  {                INT     $10}
  $06/                      {                PUSH    ES}
  $C4/$3E/>TABLE_OFS/       {                LES     DI,[>Table_Ofs]}
  $1F/                      {                POP     DS}
  $89/$EE/                  {                MOV     SI,BP                   ; DS:SI point to font}
  $BB/$00/$01/              {                MOV     BX,$0100                ; Number of chars}
  $29/$C0/                  {                SUB     AX,AX}
                            {;}
  $B9/$04/$00/              {Loop35:         MOV     CX,4                    ; Bytes per char}
  $F3/$A5/                  {                REPZ    MOVSW}
  $AB/                      {                STOSW}
  $4B/                      {                DEC     BX}
  $75/$F7/                  {                JNZ     Loop35}
  $1F/                      {                POP     DS}
  $1E/                      {                PUSH    DS}
  $A1/>TABLE_OFS/           {                MOV     AX,[>Table_Ofs]}
  $89/$C5/                  {                MOV     BP,AX                   ; Points to font}
  $31/$D2/                  {                XOR     DX,DX                   ; Starting char}
  $B9/$00/$01/              {                MOV     CX,$0100                ; Number of chars}
  $BB/$00/$0A/              {                MOV     BX,$0A00                ; Bytes/char}
  $B8/$10/$11/              {                MOV     AX,$1110                ; Load user font}
  $CD/$10/                  {                INT     $10}
  $E9/$8B/$00/              {                JMP     Exit}
                            {;}
  $F6/$06/>VGA_PRESENT/$01/ {Line43:         TEST    BYTE [>VGA_Present],1   ; Check for VGA}
  $74/$03/                  {                JZ      Line43a                 ; Do nothing if so}
  $E9/$81/$00/              {                JMP     Exit}
                            {;}
  $B8/$12/$11/              {Line43a:        MOV     AX,$1112                ; Load 8 x 8 font}
  $B3/$00/                  {                MOV     BL,0}
  $CD/$10/                  {                INT     $10}
  $EB/$78/                  {                JMP     Short Exit}
                            {;}
  $F6/$06/>VGA_PRESENT/$01/ {Line50:         TEST    BYTE [>VGA_Present],1   ; Check for VGA}
  $74/$09/                  {                JZ      Line50a                 ;}
                            {;}
  $B8/$12/$11/              {                MOV     AX,$1112                ; Load 8 x 8 font}
  $B3/$00/                  {                MOV     BL,0}
  $CD/$10/                  {                INT     $10}
  $EB/$68/                  {                JMP     Short Exit}
                            {;}
  $B8/$30/$11/              {Line50a:        MOV     AX,$1130                ; Load 8 x 8 font}
  $B7/$03/                  {                MOV     BH,3}
  $CD/$10/                  {                INT     $10}
  $06/                      {                PUSH    ES}
  $C4/$3E/>TABLE_OFS/       {                LES     DI,[>Table_Ofs]}
  $1F/                      {                POP     DS}
  $89/$EE/                  {                MOV     SI,BP                   ; DS:SI point to font}
  $BB/$00/$01/              {                MOV     BX,$0100                ; Number of chars}
                            {;}
  $B9/$07/$00/              {Loop50:         MOV     CX,7                    ; Bytes per char}
  $F3/$A4/                  {                REPZ    MOVSB}
  $46/                      {                INC     SI}
  $4B/                      {                DEC     BX}
  $75/$F7/                  {                JNZ     Loop50}
  $1F/                      {                POP     DS}
  $1E/                      {                PUSH    DS}
  $A1/>TABLE_OFS/           {                MOV     AX,[>Table_Ofs]}
  $89/$C5/                  {                MOV     BP,AX                   ; Points to font}
  $31/$D2/                  {                XOR     DX,DX                   ; Starting char}
  $B9/$00/$01/              {                MOV     CX,$0100                ; Number of chars}
  $BB/$00/$07/              {                MOV     BX,$0700                ; Bytes/char, block load}
  $B8/$10/$11/              {                MOV     AX,$1110                ; Load user font}
  $CD/$10/                  {                INT     $10}
  $EB/$37/                  {                JMP     SHORT Exit}
                            {;}
  $F6/$06/>VGA_PRESENT/$01/ {Line66:         TEST    BYTE [>VGA_Present],1   ; Check for VGA}
  $74/$30/                  {                JZ      Exit                    ;}
                            {;}
  $B8/$30/$11/              {                MOV     AX,$1130                ; Load 8 x 8 font}
  $B7/$03/                  {                MOV     BH,3}
  $CD/$10/                  {                INT     $10}
  $06/                      {                PUSH    ES}
  $C4/$3E/>TABLE_OFS/       {                LES     DI,[>Table_Ofs]}
  $1F/                      {                POP     DS}
  $89/$EE/                  {                MOV     SI,BP                   ; DS:SI point to font}
  $BB/$00/$01/              {                MOV     BX,$0100                ; Number of chars}
                            {;}
  $B9/$06/$00/              {Loop66:         MOV     CX,6                    ; Bytes per char}
  $F3/$A4/                  {                REPZ    MOVSB}
  $46/                      {                INC     SI}
  $46/                      {                INC     SI}
  $4B/                      {                DEC     BX}
  $75/$F6/                  {                JNZ     Loop66}
  $1F/                      {                POP     DS}
  $1E/                      {                PUSH    DS}
  $A1/>TABLE_OFS/           {                MOV     AX,[>Table_Ofs]}
  $89/$C5/                  {                MOV     BP,AX                   ; Points to font}
  $31/$D2/                  {                XOR     DX,DX                   ; Starting char}
  $B9/$00/$01/              {                MOV     CX,$0100                ; Number of chars}
  $BB/$00/$06/              {                MOV     BX,$0600                ; Bytes/char, block load}
  $B8/$10/$11/              {                MOV     AX,$1110                ; Load user font}
  $CD/$10/                  {                INT     $10}
                            {;}
  $1F/                      {Exit:           POP     DS}
  $5D);                     {                POP     BP}

                                   (* Remember if 8x8 font loaded *)

   Font8x8Loaded := ( EGA_Rows = 35 ) OR
                    ( EGA_Rows = 43 ) OR
                    ( EGA_Rows = 50 ) OR
                    ( EGA_Rows = 66 );

                                   (* Make sure cursor is OK *)
   CursorOn;

END   (* Set_EGA_Text_Mode *);

(*----------------------------------------------------------------------*)
(*          WriteSXY --- Write text string to specified row/column      *)
(*----------------------------------------------------------------------*)

PROCEDURE WriteSXY( S: AnyStr; X: INTEGER; Y: INTEGER; Color: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  WriteSXY                                             *)
(*                                                                      *)
(*     Purpose:    Writes text string at specified row and column       *)
(*                 position on screen.                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        WriteSXY( S: AnyStr; X: INTEGER; Y: INTEGER; Color: INTEGER );*)
(*                                                                      *)
(*           S      --- String to be written                            *)
(*           X      --- Column position to write string                 *)
(*           Y      --- Column position to write string                 *)
(*           Color  --- Color in which to write string                  *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* WriteSXY *)
                                   (* Freeze screen for DoubleDos *)

   IF ( MultiTasker = DoubleDos ) THEN
      BEGIN
         TurnOffTimeSharing;
         Get_Screen_Address( DesqView_Screen );
      END;

INLINE(
  $1E/                              {         PUSH  DS                            ;Save data segment register}
                                    {;}
                                    {;  Check if we're using BIOS.}
                                    {;}
  $F6/$06/>WRITE_SCREEN_MEMORY/$01/ {         TEST  BYTE [>Write_Screen_Memory],1 ;Direct screen write?}
  $74/$54/                          {         JZ    Bios                          ;No -- go use BIOS}
                                    {;}
                                    {;  Set up for direct screen write.}
                                    {;  Get row position and column positions, and offset in screen buffer.}
                                    {;}
  $C4/$3E/>DESQVIEW_SCREEN/         {         LES   DI,[>DesqView_Screen]         ;Get base address of screen}
  $8B/$4E/<Y/                       {         MOV   CX,[BP+<Y]                    ;CX = Row}
  $49/                              {         DEC   CX                            ;Row to 0..Max_Screen_Line-1 range}
  $A1/>MAX_SCREEN_COL/              {         MOV   AX,[>Max_Screen_Col]          ;Physical screen width}
  $F7/$E1/                          {         MUL   CX                            ;Row * Max_Screen_Col}
  $8B/$5E/<X/                       {         MOV   BX,[BP+<X]                    ;BX = Column}
  $4B/                              {         DEC   BX                            ;Col to 0..Max_Screen_Col-1 range}
  $01/$D8/                          {         ADD   AX,BX                         ;AX = (Row * Max_Screen_Col) + Col}
  $D1/$E0/                          {         SHL   AX,1                          ;Account for attribute bytes}
  $89/$FB/                          {         MOV   BX,DI                         ;Get base offset of screen}
  $01/$C3/                          {         ADD   BX,AX                         ;Add computed offset}
  $89/$DF/                          {         MOV   DI,BX                         ;Move result into DI}
  $A0/>WAIT_FOR_RETRACE/            {         MOV   AL,[<Wait_For_Retrace]        ;Grab this before changing DS}
  $16/                              {         PUSH  SS}
  $1F/                              {         POP   DS}
  $8D/$B6/>S/                       {         LEA   SI,[BP+>S]                    ;DS:SI will point to S[0]}
  $31/$C9/                          {         XOR   CX,CX                         ;Clear CX}
  $8A/$0C/                          {         MOV   CL,[SI]                       ;CL = Length(S)}
  $E3/$27/                          {         JCXZ  Exit1                         ;If string empty, Exit}
  $46/                              {         INC   SI                            ;DS:SI points to S[1]}
  $8A/$66/<COLOR/                   {         MOV   AH,[BP+<Color]                ;AH = Attribute}
  $FC/                              {         CLD                                 ;Set direction to forward}
  $A8/$01/                          {         TEST  AL,1                          ;If we don't wait for retrace, ...}
  $74/$1A/                          {         JZ    Mono                          ; use "Mono" routine}
                                    {;}
                                    {;  Color routine (used only when Wait_For_Retrace is True) **}
                                    {;}
  $BA/>CRT_STATUS/                  {         MOV   DX,>CRT_Status                ;Point DX to CGA status port}
  $AC/                              {GetNext: LODSB                               ;Load next character into AL}
                                    {                                             ; AH already has Attr}
  $89/$C3/                          {         MOV   BX,AX                         ;Store video word in BX}
                                    {;}
  $EC/                              {WaitNoH: IN    AL,DX                         ;Get 6845 status}
  $A8/$01/                          {         TEST  AL,1                          ;Wait for horizontal}
  $75/$FB/                          {         JNZ   WaitNoH                       ; retrace to finish}
                                    {;}
  $FA/                              {         CLI                                 ;Turn off interrupts}
  $EC/                              {WaitH:   IN    AL,DX                         ;Get 6845 status again}
  $A8/$01/                          {         TEST  AL,1                          ;Wait for horizontal retrace}
  $74/$FB/                          {         JZ    WaitH                         ; to start}
                                    {;}
  $89/$D8/                          {Store:   MOV   AX,BX                         ;Restore attribute}
  $AB/                              {         STOSW                               ; and then to screen}
  $FB/                              {         STI                                 ;Allow interrupts}
  $E2/$EC/                          {         LOOP  GetNext                       ;Get next character}
  $E9/$62/$00/                      {         JMP   Exit                          ;Done}
                                    {;}
                                    {;  Mono routine (used whenever Wait_For_Retrace is False) **}
                                    {;}
  $AC/                              {Mono:    LODSB                               ;Load next character into AL}
                                    {                                             ; AH already has Attr}
  $AB/                              {         STOSW                               ;Move video word into place}
  $E2/$FC/                          {         LOOP  Mono                          ;Get next character}
                                    {;}
  $E9/$5B/$00/                      {Exit1:   JMP   Exit                          ;Done}
                                    {;}
                                    {;  Use BIOS to display string (if Write_Screen is False) **}
                                    {;}
  $B4/$03/                          {Bios:    MOV   AH,3                          ;BIOS get cursor position}
  $B7/$00/                          {         MOV   BH,0}
  $55/                              {         PUSH  BP}
  $CD/$10/                          {         INT   $10                           ;Get current cursor position}
  $5D/                              {         POP   BP}
  $52/                              {         PUSH  DX                            ;Save current cursor position}
                                    {;}
  $8A/$76/<Y/                       {         MOV   DH,[BP+<Y]                    ;Get starting row}
  $FE/$CE/                          {         DEC   DH                            ;Drop by one for BIOS}
  $8A/$56/<X/                       {         MOV   DL,[BP+<X]                    ;Get starting column}
  $FE/$CA/                          {         DEC   DL                            ;Drop for indexing}
  $FE/$CA/                          {         DEC   DL                            ;}
  $16/                              {         PUSH  SS}
  $1F/                              {         POP   DS}
  $8D/$B6/>S/                       {         LEA   SI,[BP+>S]                    ;DS:SI will point to S[0]}
  $31/$C9/                          {         XOR   CX,CX                         ;Clear out CX}
  $8A/$0C/                          {         MOV   CL,[SI]                       ;CL = Length(S)}
  $E3/$31/                          {         JCXZ  Bios2                         ;If string empty, Exit}
  $46/                              {         INC   SI                            ;DS:SI points to S[1]}
  $52/                              {         PUSH  DX                            ;Save X and Y}
  $1E/                              {         PUSH  DS                            ;Save string address}
  $56/                              {         PUSH  SI                            ;}
  $FC/                              {         CLD                                 ;Forward direction}
                                    {;}
  $B4/$02/                          {Bios1:   MOV   AH,2                          ;BIOS Position cursor}
  $B7/$00/                          {         MOV   BH,0                          ;Page zero}
  $5E/                              {         POP   SI                            ;Get S address}
  $1F/                              {         POP   DS                            ;}
  $5A/                              {         POP   DX                            ;X and Y}
  $FE/$C2/                          {         INC   DL                            ;X + 1}
  $52/                              {         PUSH  DX                            ;Save X and Y}
  $1E/                              {         PUSH  DS                            ;Save strin address}
  $56/                              {         PUSH  SI}
  $51/                              {         PUSH  CX                            ;Push length}
  $55/                              {         PUSH  BP}
  $CD/$10/                          {         INT   $10                           ;Call BIOS to move to (X,Y)}
  $5D/                              {         POP   BP}
  $59/                              {         POP   CX                            ;Get back length}
  $5E/                              {         POP   SI                            ;Get String address}
  $1F/                              {         POP   DS                            ;}
  $AC/                              {         LODSB                               ;Next character into AL}
  $1E/                              {         PUSH  DS                            ;Save String address}
  $56/                              {         PUSH  SI                            ;}
  $51/                              {         PUSH  CX                            ;Length left to do}
  $55/                              {         PUSH  BP}
  $B4/$09/                          {         MOV   AH,9                          ;BIOS Display character}
  $B7/$00/                          {         MOV   BH,0                          ;Display page zero}
  $8A/$5E/<COLOR/                   {         MOV   BL,[BP+<Color]                ;BL = Attribute}
  $B9/$01/$00/                      {         MOV   CX,1                          ;One character}
  $CD/$10/                          {         INT   $10                           ;Call BIOS}
  $5D/                              {         POP   BP}
  $59/                              {         POP   CX                            ;Get back length}
  $E2/$D7/                          {         LOOP  Bios1}
                                    {;                                            ;Remove stuff left on stack}
  $5E/                              {         POP   SI}
  $1F/                              {         POP   DS}
  $5A/                              {         POP   DX}
                                    {;}
  $5A/                              {Bios2:   POP   DX                            ;Restore previous cursor position}
  $B7/$00/                          {         MOV   BH,0}
  $B4/$02/                          {         MOV   AH,2                          ;BIOS set cursor position}
  $55/                              {         PUSH  BP}
  $CD/$10/                          {         INT   $10}
  $5D/                              {         POP   BP}
                                    {;}
  $1F);                             {Exit:    POP   DS                            ;Restore DS}

                                   (* Unfreeze screen in DoubleDos *)

   IF ( MultiTasker = DoubleDos ) THEN
      TurnOnTimeSharing
                                   (* Synchronize screen for TopView *)

   ELSE IF ( MultiTasker = TopView ) THEN
      IF Write_Screen_Memory THEN
         Sync_Screen( PRED( ( PRED( Y ) * Max_Screen_Col + X ) SHL 1 ) , LENGTH( S ) );

END   (* WriteSXY *);

(*----------------------------------------------------------------------*)
(*       Set_Graphics_Colors --- Set colors for graphics mode           *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Graphics_Colors( EGA_On : BOOLEAN;
                               GMode  : INTEGER;
                               FG     : INTEGER;
                               BG     : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_Graphics_Colors                                  *)
(*                                                                      *)
(*     Purpose:    Sets colors for graphics modes                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Graphics_Colors( EGA_On: BOOLEAN; GMode: INTEGER;         *)
(*                             FG    : INTEGER; BG   : INTEGER );       *)
(*                                                                      *)
(*           EGA_On --- TRUE if EGA installed                           *)
(*           GMode  --- Graphics mode to set                            *)
(*           FG     --- Foreground color                                *)
(*           BG     --- Background color                                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs: Registers;

BEGIN (* Set_Graphics_Colors *)

                                   (* Request 640x200 graphics mode    *)
   IF EGA_On THEN
      BEGIN (* Set up EGA mode *)

         WITH Regs DO
            BEGIN
               Regs.Ah := 0;
               Regs.Al := GMode;
               INTR( $10, Regs );
            END;
                                   (* Set graphics border color *)
        WITH Regs DO
           BEGIN
              Regs.Ah := 16;
              Regs.Al := 01;
              Regs.Bh := BG;
              Regs.Bl := 0;
              INTR( $10, Regs );
          END;
                                   (* Set graphics foreground color *)
        WITH Regs DO
           BEGIN
              Regs.Ah := 16;
              Regs.Al := 00;
              Regs.Bh := FG;
              Regs.Bl := 1;
              INTR( $10, Regs );
          END;
                                   (* Set graphics background color *)
        WITH Regs DO
           BEGIN
              Regs.Ah := 16;
              Regs.Al := 00;
              Regs.Bh := BG;
              Regs.Bl := 0;
              INTR( $10, Regs );
           END;
                                   (* Set foreground intensity *)

        IF ( FG > 7 ) THEN
           WITH Regs DO
              BEGIN
                 Regs.Ah := 16;
                 Regs.Al := 03;
                 Regs.Bh := FG;
                 Regs.Bl := 0;
                 INTR( $10, Regs );
              END;

      END   (* Set up EGA mode *)
   ELSE
      BEGIN (* Set up CGA mode *)

         WITH Regs DO
            BEGIN
               Regs.Ah := 0;
               Regs.Al := GMode;
               INTR( $10, Regs );
            END;

         WITH Regs DO
            BEGIN
               Regs.Ah := 11;
               Regs.BH := 0;
               Regs.BL := FG;
               INTR( $10, Regs );
            END;

      END   (* Set up CGA mode *);

END   (* Set_Graphics_Colors *);

(*----------------------------------------------------------------------*)
(*   WriteLXY --- Write screen line string to specified row/column      *)
(*----------------------------------------------------------------------*)

PROCEDURE WriteLXY( VAR S;  X: INTEGER; Y: INTEGER; Len : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  WriteLXY                                             *)
(*                                                                      *)
(*     Purpose:    Writes screen line at specified row and column       *)
(*                 position on screen.                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        WriteLXY( VAR S: My_Line_Type; X: INTEGER; Y: INTEGER;        *)
(*                  LEN : INTEGER );                                    *)
(*                                                                      *)
(*           S      --- Screen line to be written                       *)
(*                      ( S[I] = char, S[I+1] = attribute )             *)
(*           X      --- Column position to write string                 *)
(*           Y      --- Column position to write string                 *)
(*           Len    --- # of characters to write                        *)
(*                                                                      *)
(*     Calls:   None                                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* WriteLXY *)
                                   (* Freeze screen for DoubleDos *)

   IF ( MultiTasker = DoubleDos ) THEN
      BEGIN
         TurnOffTimeSharing;
         Get_Screen_Address( DesqView_Screen );
      END;

INLINE(
  $1E/                              {         PUSH  DS                              ;Save DS}
                                    {;}
                                    {;  Check if we're going to use BIOS}
                                    {;}
  $F6/$06/>WRITE_SCREEN_MEMORY/$01/ {         TEST  BYTE [<Write_Screen_Memory],1   ;See if we're to use BIOS}
  $74/$4D/                          {         JZ    BIOS                            ;Yes -- skip to BIOS code}
                                    {;}
                                    {;  Set up for direct screen write.}
                                    {;  Get row position and column positions, and offset in screen buffer.}
                                    {;}
  $C4/$3E/>DESQVIEW_SCREEN/         {         LES   DI,[>DesqView_Screen]         ;Get base address of screen}
  $8B/$4E/<Y/                       {         MOV   CX,[BP+<Y]                    ;CX = Row}
  $49/                              {         DEC   CX                            ;Row to 0..Max_Screen_Line-1 range}
  $A1/>MAX_SCREEN_COL/              {         MOV   AX,[>Max_Screen_Col]          ;Physical screen width}
  $F7/$E1/                          {         MUL   CX                            ;Row * Max_Screen_Col}
  $8B/$5E/<X/                       {         MOV   BX,[BP+<X]                    ;BX = Column}
  $4B/                              {         DEC   BX                            ;Col to 0..Max_Screen_Col-1 range}
  $01/$D8/                          {         ADD   AX,BX                         ;AX = (Row * Max_Screen_Col) + Col}
  $D1/$E0/                          {         SHL   AX,1                          ;Account for attribute bytes}
  $89/$FB/                          {         MOV   BX,DI                         ;Get base offset of screen}
  $01/$C3/                          {         ADD   BX,AX                         ;Add computed offset}
  $89/$DF/                          {         MOV   DI,BX                         ;Move result into DI}
  $A0/>WAIT_FOR_RETRACE/            {         MOV   AL,[<Wait_For_Retrace]        ;Grab this before changing DS}
  $C5/$76/<S/                       {         LDS   SI,[BP+<S]                    ;DS:SI will point to S}
  $8B/$8E/>LEN/                     {         MOV   CX,[BP+>Len]                  ;CL = Length(S)}
  $E3/$7B/                          {         JCXZ  Exit                          ;If string empty, Exit}
  $FC/                              {         CLD                                 ;Set direction to forward}
  $D0/$D8/                          {         RCR   AL,1                          ;If we don't wait for retrace, ...}
  $73/$1A/                          {         JNC   Mono                          ; use "Mono" routine}
                                    {;}
                                    {;  Color routine (used only when Wait_Retrace is True) **}
                                    {;}
  $BA/>CRT_STATUS/                  {         MOV   DX,>CRT_Status                ;Point DX to CGA status port}
  $AD/                              {GetNext: LODSW                               ;Load next char/attrib to AX}
  $89/$C3/                          {         MOV   BX,AX                         ;Store video word in BX}
                                    {;}
  $EC/                              {WaitNoH: IN    AL,DX                         ;Get 6845 status}
  $A8/$01/                          {         TEST  AL,1                          ;Wait for horizontal}
  $75/$FB/                          {         JNZ   WaitNoH                       ; retrace to finish}
                                    {;}
  $FA/                              {         CLI                                 ;Turn off interrupts}
  $EC/                              {WaitH:   IN    AL,DX                         ;Get 6845 status again}
  $A8/$01/                          {         TEST  AL,1                          ;Wait for horizontal retrace}
  $74/$FB/                          {         JZ    WaitH                         ; to start}
                                    {;}
  $89/$D8/                          {Store:   MOV   AX,BX                         ;Restore attribute}
  $AB/                              {         STOSW                               ; and then to screen}
  $FB/                              {         STI                                 ;Allow interrupts}
  $E2/$EC/                          {         LOOP  GetNext                       ;Get next character}
  $E9/$5C/$00/                      {         JMP   Exit                          ;Done}
                                    {;}
                                    {;  Mono routine (used whenever Wait_Retrace is False) **}
                                    {;}
  $AD/                              {Mono:    LODSW                        ;Load next char/attribute into AX}
  $AB/                              {         STOSW                        ;Move video word into place}
  $E2/$FC/                          {         LOOP  Mono                   ;Get next character}
  $E9/$55/$00/                      {         JMP   Exit                   ;Done}
                                    {;}
                                    {;  Use BIOS to display string (if Write_Screen is False) **}
                                    {;}
  $B4/$03/                          {Bios:    MOV   AH,3                   ;Get current cursor position}
  $B7/$00/                          {         MOV   BH,0}
  $55/                              {         PUSH  BP}
  $CD/$10/                          {         INT   $10}
  $5D/                              {         POP   BP}
  $52/                              {         PUSH  DX                     ;Save current cursor position}
  $8A/$76/<Y/                       {         MOV   DH,[BP+<Y]             ;Get starting row}
  $FE/$CE/                          {         DEC   DH                     ;Drop by one for BIOS}
  $8A/$56/<X/                       {         MOV   DL,[BP+<X]             ;Get starting column}
  $FE/$CA/                          {         DEC   DL                     ;Drop for indexing}
  $FE/$CA/                          {         DEC   DL                     ;}
  $C5/$76/<S/                       {         LDS   SI,[BP+<S]             ;DS:SI will point to S[1]}
  $8B/$4E/<LEN/                     {         MOV   CX,[BP+<Len]           ;CX = Length(S)}
  $E3/$2F/                          {         JCXZ  Bios2                  ;If string empty, Exit}
  $52/                              {         PUSH  DX                     ;Save X and Y}
  $1E/                              {         PUSH  DS                     ;Save string address}
  $56/                              {         PUSH  SI                     ;}
  $FC/                              {         CLD                          ;Forward direction}
                                    {;}
  $B4/$02/                          {Bios1:   MOV   AH,2                   ;BIOS Position cursor}
  $B7/$00/                          {         MOV   BH,0                   ;Page zero}
  $5E/                              {         POP   SI                     ;Get S address}
  $1F/                              {         POP   DS                     ;}
  $5A/                              {         POP   DX                     ;X and Y}
  $FE/$C2/                          {         INC   DL                     ;X + 1}
  $52/                              {         PUSH  DX                     ;Save X and Y}
  $1E/                              {         PUSH  DS                     ;Save string address}
  $56/                              {         PUSH  SI}
  $51/                              {         PUSH  CX                     ;Push length}
  $55/                              {         PUSH  BP}
  $CD/$10/                          {         INT   $10                    ;Call BIOS to move to (X,Y)}
  $5D/                              {         POP   BP}
  $59/                              {         POP   CX                     ;Get back length}
  $5E/                              {         POP   SI                     ;Get String address}
  $1F/                              {         POP   DS                     ;}
  $AD/                              {         LODSW                        ;Next char/attribute into AX}
  $1E/                              {         PUSH  DS                     ;Save String address}
  $56/                              {         PUSH  SI                     ;}
  $51/                              {         PUSH  CX                     ;Length left to do}
  $88/$E3/                          {         MOV   BL,AH                  ;BL = Attribute}
  $B4/$09/                          {         MOV   AH,9                   ;BIOS Display character}
  $B7/$00/                          {         MOV   BH,0                   ;Display page zero}
  $B9/$01/$00/                      {         MOV   CX,1                   ;One character}
  $55/                              {         PUSH  BP}
  $CD/$10/                          {         INT   $10                    ;Call BIOS}
  $5D/                              {         POP   BP}
  $59/                              {         POP   CX                     ;Get back length}
  $E2/$D8/                          {         LOOP  Bios1}
                                    {;                                     ;Remove stuff left on stack}
  $5E/                              {         POP   SI}
  $1F/                              {         POP   DS}
  $5A/                              {         POP   DX}
                                    {;}
  $5A/                              {Bios2:   POP   DX                     ;Restore previous cursor position}
  $B7/$00/                          {         MOV   BH,0}
  $B4/$02/                          {         MOV   AH,2}
  $55/                              {         PUSH  BP}
  $CD/$10/                          {         INT   $10}
  $5D/                              {         POP   BP}
                                    {;}
  $1F);                             {Exit:    POP   DS                     ;Restore DS}

                                   (* Unfreeze screen in DoubleDos *)

   IF ( MultiTasker = DoubleDos ) THEN
      TurnOnTimeSharing
                                   (* Synchronize screen for TopView *)

   ELSE IF ( MultiTasker = TopView ) THEN
      IF Write_Screen_Memory THEN
         Sync_Screen( ( ( Y - 1 ) * Max_Screen_Col + X ) SHL 1 - 1 , Len );

END   (* WriteLXY *);
