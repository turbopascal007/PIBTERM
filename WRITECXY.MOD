(*----------------------------------------------------------------------*)
(*   WriteCXY --- Write character to screen  at specified row/column    *)
(*----------------------------------------------------------------------*)

PROCEDURE WriteCXY( C: CHAR; X: INTEGER; Y: INTEGER; Color: INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  WriteCXY                                             *)
(*                                                                      *)
(*     Purpose:    Writes a character at specified row and column       *)
(*                 position on screen.                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        WriteCXY( C: CHAR; X: INTEGER; Y: INTEGER; Color: INTEGER );  *)
(*                                                                      *)
(*           C      --- Character to be written                         *)
(*           X      --- Column position to write character              *)
(*           Y      --- Column position to write character              *)
(*           Color  --- Color in which to write character               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Save_WTS : BOOLEAN;

BEGIN (* WriteCXY *)
                                   (* Use BIOS for DoubleDos *)
   Save_WTS := Write_Screen_Memory;

   IF ( MultiTasker = DoubleDos ) OR
      ( MultiTasker = TopView   ) THEN
         Write_Screen_Memory := FALSE;

INLINE(
  $1E                              {         PUSH  DS                             ;Save DS}
                                   {;}
                                   {;  Check if we're going to use BIOS}
                                   {;}
  /$F6/$06/>WRITE_SCREEN_MEMORY/$01{         TEST  BYTE [<Write_Screen_Memory],1  ;See if we're writing to screen memory}
  /$74/$43                         {         JZ    BIOS                           ;No -- skip to BIOS code}
                                   {;}
                                   {;  Set up for direct screen write.}
                                   {;  Get row position and column positions, and offset in screen buffer.}
                                   {;}
  /$C4/$3E/>DESQVIEW_SCREEN        {         LES   DI,[>DesqView_Screen]          ;Get base address of screen}
  /$8B/$4E/<Y                      {         MOV   CX,[BP+<Y]                     ;CX = Row}
  /$49                             {         DEC   CX                             ;Row to 0..Max_Screen_Line-1 range}
  /$A1/>MAX_SCREEN_COL             {         MOV   AX,[>Max_Screen_Col]           ;Physical screen width}
  /$F7/$E1                         {         MUL   CX                             ;Row * Max_Screen_Col}
  /$8B/$5E/<X                      {         MOV   BX,[BP+<X]                     ;BX = Column}
  /$4B                             {         DEC   BX                             ;Col to 0..Max_Screen_Col-1 range}
  /$01/$D8                         {         ADD   AX,BX                          ;AX = (Row * Max_Screen_Col) + Col}
  /$D1/$E0                         {         SHL   AX,1                           ;Account for attribute bytes}
  /$89/$FB                         {         MOV   BX,DI                          ;Get base offset of screen}
  /$01/$C3                         {         ADD   BX,AX                          ;Add computed offset}
  /$89/$DF                         {         MOV   DI,BX                          ;Move result into DI}
  /$8A/$5E/<C                      {         MOV   BL,[BP+<C]                     ;BL = character}
  /$8A/$7E/<COLOR                  {         MOV   BH,[BP+<Color]                 ;BH = Attribute}
  /$F6/$06/>WAIT_FOR_RETRACE/$01   {         TEST  BYTE [<Wait_For_Retrace],1     ;Check retrace wait flag}
  /$74/$15                         {         JZ    Mono                           ; use "Mono" routine}
                                   {;}
                                   {;  Color routine (used only when Wait_For_Retrace is True) **}
                                   {;}
  /$BA/>CRT_STATUS                 {         MOV   DX,>CRT_Status                 ;Point DX to CGA status port}
                                   {;}
  /$EC                             {WaitNoH: IN    AL,DX                          ;Get 6845 status}
  /$A8/$01                         {         TEST  AL,1                           ;Wait for horizontal}
  /$75/$FB                         {         JNZ   WaitNoH                        ; retrace to finish}
                                   {;}
  /$FA                             {         CLI                                  ;Turn off interrupts}
  /$EC                             {WaitH:   IN    AL,DX                          ;Get 6845 status again}
  /$A8/$01                         {         TEST  AL,1                           ;Wait for horizontal retrace}
  /$74/$FB                         {         JZ    WaitH                          ; to start}
                                   {;}
  /$89/$D8                         {Store:   MOV   AX,BX                          ;Restore attribute}
  /$AB                             {         STOSW                                ; and then to screen}
  /$FB                             {         STI                                  ;Allow interrupts}
  /$E9/$25/$00                     {         JMP   Exit                           ;Done}
                                   {;}
                                   {;  Mono routine (used whenever Wait_For_Retrace is False) **}
                                   {;}
  /$89/$D8                         {Mono:    MOV   AX,BX                          ;Get character + attribute}
  /$AB                             {         STOSW                                ;Move video word into place}
  /$E9/$1F/$00                     {         JMP   Exit                           ;Done}
                                   {;}
                                   {;  Use BIOS to display string (if Write_Screen is False) **}
                                   {;}
  /$B4/$02                         {Bios:    MOV   AH,2                           ;BIOS positioning}
  /$B7/$00                         {         MOV   BH,0                           ;Text page 0}
  /$8A/$76/<Y                      {         MOV   DH,[BP+<Y]                     ;Y}
  /$FE/$CE                         {         DEC   DH                             ;Y - 1}
  /$8A/$56/<X                      {         MOV   DL,[BP+<X]                     ;X}
  /$FE/$CA                         {         DEC   DL                             ;X - 1}
  /$CD/$10                         {         INT   $10                            ;Call BIOS to position cursor}
  /$B4/$09                         {         MOV   AH,9                           ;BIOS display character}
  /$8A/$46/<C                      {         MOV   AL,[BP+<C]                     ;Character to display}
  /$B7/$00                         {         MOV   BH,0                           ;Text page 0}
  /$8A/$5E/<COLOR                  {         MOV   BL,[BP+<Color]                 ;Color}
  /$B9/$01/$00                     {         MOV   CX,1                           ;One character}
  /$CD/$10                         {         INT   $10                            ;Call BIOS to display character}
                                   {;}
  /$1F                             {Exit:    POP   DS                             ;Restore DS}
);
                                   (* Return BIOS write to previous state *)

   Write_Screen_Memory := Save_WTS;

   IF ( MultiTasker = TopView ) THEN
      IF Write_Screen_Memory THEN
         Sync_Screen( PRED( ( PRED( Y ) * Max_Screen_Col + X ) SHL 1 ) , 1 );
{
   IF Save_WTS THEN
      IF ( MultiTasker = DoubleDos ) OR
         ( MultiTasker = TopView   ) THEN
         Write_Screen_Memory := Save_WTS;
}
                                   (* Synchronize screen for TopView *)
{
}
END   (* WriteCXY *);
