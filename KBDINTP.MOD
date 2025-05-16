(*----------------------------------------------------------------------*)
(*  Keyboard_Interrupt_Handler --- Replaces int 9 keyboard handler      *)
(*----------------------------------------------------------------------*)

PROCEDURE Keyboard_Interrupt_Handler(
          Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP : WORD );
(*   Interrupt; *)

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Keyboard_Interrupt_Handler                           *)
(*                                                                      *)
(*     Purpose:    Replaces standard interrupt 9 keyboard driver        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*                 -- Called by system only!                            *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine replaces the standard interrupt 9 keyboard       *)
(*        driver so that the extended key combinations will work        *)
(*        properly.                                                     *)
(*                                                                      *)
(*        This handler is a slight modification of one by               *)
(*        Neil J. Rubenking.                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

(* STRUCTURED *) CONST
   Ctrl_Keys : ARRAY[0..12] OF BYTE =
               ( 119, 160, 132, 161, 115, 162, 116,
                 163, 117, 164, 118, 165, 166 );

BEGIN (* Keyboard_Interrupt_Handler *)

INLINE(
                              {;}
  $E4/$60/                    {           IN    AL,$60                 ;Read the keyboard port}
  $88/$C1/                    {           MOV   CL,AL                  ;Save the key in CL}
                              {;}
  $3C/$E0/                    {           CMP   AL,224                 ;Check for scan code of 224}
  $75/$09/                    {           JNE   ChkRel                 ;No -- may be release}
  $A2/>KBD_SAVE_SCAN/         {           MOV   BYTE [>Kbd_Save_Scan],AL}
  $E8/$B2/$00/                {           CALL  ReadPort}
  $E9/$8E/$00/                {           JMP   SendEOI}
                              {;}
  $3C/$80/                    {ChkRel:    CMP   AL,$80                 ;Is is a RELEASE? If so,}
  $72/$08/                    {           JB    ChkPrt                 ;}
  $C6/$06/>KBD_SAVE_SCAN/$00/ {           MOV   BYTE [>Kbd_Save_Scan],0;clear scan code flag, and}
  $E9/$89/$00/                {           JMP   NormalKey              ;treat as Normal}
                              {;}
  $3C/$37/                    {ChkPrt:    CMP   AL,55                  ;Check for PrtSc or kpd * key}
  $75/$03/                    {           JNE   ChkEnt                 ;No -- may be Enter or keypad}
  $E9/$E0/$00/                {           JMP   ChkPrtSc               ;Yes -- process PrtSc/kpd * key}
                              {;}
  $3C/$1C/                    {ChkEnt:    CMP   AL,28                  ;Check for ENTER key}
  $75/$03/                    {           JNE   ChkBS                  ;No -- may be backspace}
  $E9/$A4/$00/                {           JMP   ChkEnter               ;Yes -- process enter key}
                              {;}
  $3C/$0E/                    {ChkBS:     CMP   AL,14                  ;Check for backspace key}
  $75/$03/                    {           JNE   ChkSls                 ;No -- may be slash}
  $E9/$0A/$01/                {           JMP   ChkBackSp              ;Yes -- process backspace key}
                              {;}
  $3C/$35/                    {ChkSls:    CMP   AL,53                  ;Check for forward slash}
  $75/$0A/                    {           JNE   ChkKeyPad              ;No -- may be keypad key}
  $80/$3E/>KBD_SAVE_SCAN/$E0/ {           CMP   BYTE [>Kbd_Save_Scan],224  ;Yes -- Check for 224 as scan code}
  $75/$69/                    {           JNE   NormalKey              ;No -- ordinary slash, process as normal}
  $E9/$1B/$01/                {           JMP   ChkSlash               ;Yes -- process keypad slash}
                              {;}
  $3C/$47/                    {ChkKeyPad: CMP   AL,71                  ;71 = value for HOME key}
  $72/$62/                    {           JB    NormalKey              ;Below Home is normal}
  $3C/$53/                    {           CMP   AL,83                  ;83 = value for DEL key}
  $7F/$5E/                    {           JG    NormalKey              ;Above Del is normal}
                              {;}
  $B8/>KBD_ROM_DATA/          {           MOV   AX,>Kbd_ROM_Data}
  $8E/$C0/                    {           MOV   ES,AX                  ;Point ES at the ROM DATA}
  $26/$A0/>KBD_FLAG/          {       ES: MOV   AL,[>Kbd_Flag]         ;Pick up shift key flags}
                              {;}
  $A8/$F3/                    {           TEST  AL,$F3                 ;Check if shifts other than alt, ctrl}
  $75/$51/                    {           JNZ   NormalKey              ;If so, normal}
                              {;}
  $88/$C3/                    {           MOV   BL,AL                  ;Copy shift state}
  $80/$E3/$0C/                {           AND   BL,$0C                 ;Remove all but Ctrl + Alt}
  $80/$FB/$0C/                {           CMP   BL,$0C                 ;We only want one shift --}
  $74/$47/                    {           JE    NormalKey              ;If Ctrl + Alt, pass key on.}
                              {;}
                              {;   If we got here w/o a jump, it's one of our}
                              {;   special keystrokes.}
                              {;}
  $E8/$5E/$00/                {Special:   CALL  ReadPort               ;Read the keyboard port.}
                              {;}
                              {;   Figure out TURBO code for key based upon scan code.}
                              {;   For normal keys, add nothing.  For ALT keys, add 103.}
                              {;   For control keys, special mapping is required.}
                              {;}
  $A8/$08/                    {           TEST  AL,8                   ;Check for ALT}
  $74/$06/                    {           JZ    TestCtrl}
                              {;}
  $80/$C1/$67/                {           ADD   CL,103                 ;+103 converts to TURBO code for ALT}
  $E9/$11/$00/                {           JMP   InsCode}
                              {;}
  $A8/$04/                    {TestCtrl:  TEST  AL,4                   ;Check for CTRL}
  $74/$0D/                    {           JZ    InsCode                ;otherwise it is unshifted}
                              {;}
  $8D/$1E/>CTRL_KEYS/         {           LEA   BX,[>Ctrl_Keys]        ;Get address of ctrl key table}
  $80/$E9/$47/                {           SUB   CL,71                  ;Zero origin for key}
  $30/$ED/                    {           XOR   CH,CH}
  $01/$CB/                    {           ADD   BX,CX                  ;Get offset of new key value}
  $8A/$0F/                    {           MOV   CL,[BX]                ;Pick up TURBO value from table}
                              {;}
  $8A/$26/>KBD_SAVE_SCAN/     {InsCode:   MOV   AH,[>Kbd_Save_Scan]    ;Get back saved scan code header}
  $88/$C8/                    {           MOV   AL,CL                  ;Get the key back from CL}
  $86/$C4/                    {           XCHG  AH,AL}
  $26/$8B/$1E/>KBD_TAIL/      {       ES: MOV   BX,[>Kbd_Tail]         ;Get tail of keyboard buffer}
  $26/$89/$07/                {       ES: MOV   [BX],AX                ;Put the key in the buffer}
                              {;}
  $81/$C3/$02/$00/            {           ADD   BX,2                   ;Advance the tail pointer}
  $81/$FB/>KBD_BUFFER_END/    {           CMP   BX,>Kbd_Buffer_End     ;If at end of buffer...}
  $7C/$03/                    {           JL    BufOK}
                              {;}
  $BB/>KBD_BUFFER/            {           MOV   BX,>Kbd_Buffer         ;...set back to beginning.}
  $26/$89/$1E/>KBD_TAIL/      {BufOK: ES: MOV   [>Kbd_Tail],BX}
                              {;}
  $B0/$20/                    {SendEOI:   MOV   AL,$20                 ;Send the EOI to the}
  $E6/$20/                    {           OUT   $20,AL                 ;...interrupt controller}
                              {;}
  $E9/$D9/$00/                {           JMP   Exit                   ;and return}
                              {;}
                              {;          NormalKey}
                              {;                                       ;Chain to old keyboard ISR}
                              {;}
  $FF/$36/>KBD_SAVE_IADDR+2/  {NormalKey: PUSH   [>Kbd_Save_IAddr+2]   ;Push address of old ISR onto stack}
  $FF/$36/>KBD_SAVE_IADDR/    {           PUSH   [>Kbd_Save_IAddr]     ;Need to do this before DS restored!}
  $5B/                        {           POP    BX                    ;BX = OFS(Old_Keyboard_Interrupt)}
  $58/                        {           POP    AX                    ;AX = SEG(Old_Keyboard_Interrupt)}
  $87/$5E/$0E/                {           XCHG   BX,[BP+14]            ;Swap old BX and Ofs(Old_Key...)}
  $87/$46/$10/                {           XCHG   AX,[BP+16]            ;Swap old AX and Seg(Old_Key...)}
  $89/$EC/                    {           MOV    SP,BP                 ;Restore other registers}
  $5D/                        {           POP    BP}
  $07/                        {           POP    ES}
  $1F/                        {           POP    DS}
  $5F/                        {           POP    DI}
  $5E/                        {           POP    SI}
  $5A/                        {           POP    DX}
  $59/                        {           POP    CX}
                              {;                                       ;BX and AX restored earlier.}
                              {;                                       ;Their places on stack now have}
                              {;                                       ;old keyboard interrupt address,}
                              {;                                       ;which is where return will go.}
                              {;}
  $CB/                        {           RETF                         ;Chain to Old_Keyboard_Interrupt}
                              {;}
                              {;          Read keyboard control port.}
                              {;}
  $50/                        {ReadPort:  PUSH  AX}
  $E4/$61/                    {           IN    AL,$61                 ;Read keyboard control port}
  $88/$C4/                    {           MOV   AH,AL}
  $0C/$80/                    {           OR    AL,$80                 ;Set the "reset" bit and}
  $E6/$61/                    {           OUT   $61,AL                 ;   send it back to control}
  $86/$C4/                    {           XCHG  AH,AL                  ;Get back the control value}
  $E6/$61/                    {           OUT   $61,AL                 ;Send it out also}
  $58/                        {           POP   AX}
  $C3/                        {           RET}
                              {;}
                              {;          Handle Enter key.  We're only interested in Alt-Enter,}
                              {;          which we want to return as Esc + CHR( 28 ).}
                              {;}
  $B8/>KBD_ROM_DATA/          {ChkEnter:  MOV   AX,>Kbd_ROM_Data}
  $8E/$C0/                    {           MOV   ES,AX                  ;Point ES at the ROM DATA}
  $26/$A0/>KBD_FLAG/          {       ES: MOV   AL,[>Kbd_Flag]         ;Pick up shift key flags}
                              {;}
  $80/$3E/>KBD_SAVE_SCAN/$E0/ {           CMP   BYTE [>Kbd_Save_Scan],224 ;Distinguish Enter from Keypad Enter}
  $74/$0E/                    {           JE    ChkKEnt                   ;No difference on some keyboards}
                              {;}
  $A8/$F7/                    {           TEST  AL,$F7                 ;Test for shifts other than ALT}
  $75/$C3/                    {           JNZ   NormalKey              ;If so, treat as normal key.}
                              {;}
  $A8/$08/                    {           TEST  AL,8                   ;Check for ALT}
  $74/$BF/                    {           JZ    NormalKey              ;Process as normal key if not ALT}
                              {;}
  $80/$E9/$67/                {           SUB   CL,103                 ;Bias for ALT key code above}
  $E9/$72/$FF/                {           JMP   Special                ;Go insert ESC 28.}
                              {;}
  $A8/$F3/                    {ChkKEnt:   TEST  AL,$F3                 ;Test for shifts other than CTRL, ALT}
  $74/$02/                    {           JZ    ChkKEnt1}
  $EB/$B3/                    {           JMP   NormalKey              ;If so, treat as normal key.}
                              {;}
  $B1/$08/                    {ChkKEnt1:  MOV   CL,8}
  $A8/$08/                    {           TEST  AL,8                   ;Check for ALT}
  $75/$2D/                    {           JNZ   ChkPrtSc2              ;}
                              {;}
  $B1/$09/                    {           MOV   CL,9}
  $A8/$04/                    {           TEST  AL,4                   ;Check for CTRL}
  $75/$27/                    {           JNZ   ChkPrtSc2              ;}
                              {;}
  $B1/$07/                    {           MOV   CL,7                   ;Unshifted}
  $E9/$22/$00/                {           JMP   ChkPrtSc2              ;Go insert ESC + Code.}
                              {;}
                              {;          Handle PrtSc or Keypad * key.}
                              {;}
  $B8/>KBD_ROM_DATA/          {ChkPrtSc:  MOV   AX,>Kbd_ROM_Data}
  $8E/$C0/                    {           MOV   ES,AX                  ;Point ES at the ROM DATA}
  $26/$A0/>KBD_FLAG/          {       ES: MOV   AL,[>Kbd_Flag]         ;Pick up shift key flags}
                              {;}
  $A8/$F3/                    {           TEST  AL,$F3                 ;Test for shifts other than CTRL, ALT}
  $75/$95/                    {           JNZ   NormalKey              ;If so, treat as normal key.}
                              {;}
  $80/$3E/>KBD_SAVE_SCAN/$E0/ {           CMP   BYTE [>Kbd_Save_Scan],224 ;Distinguish PrtSc from Keypad *}
  $75/$14/                    {           JNE   ChkStar                   ;No difference on some keyboards}
                              {;}
  $B1/$0B/                    {           MOV   CL,11}
  $A8/$08/                    {           TEST  AL,8                   ;Check for ALT}
  $75/$08/                    {           JNZ   ChkPrtSc2              ;}
                              {;}
  $B1/$0C/                    {           MOV   CL,12}
  $A8/$04/                    {           TEST  AL,4                   ;Check for CTRL}
  $75/$02/                    {           JNZ   ChkPrtSc2              ;}
                              {;}
  $B1/$0A/                    {           MOV   CL,10                  ;Unshifted}
                              {;}
  $E8/$97/$FF/                {ChkPrtSc2: CALL  ReadPort               ;Read keyboard port.}
  $E9/$51/$FF/                {           JMP   InsCode                ;Go insert ESC + Code.}
                              {;}
  $B1/$02/                    {ChkStar:   MOV   CL,2                   ;Code for Alt}
  $A8/$08/                    {           TEST  AL,8                   ;Check for Alt}
  $75/$F4/                    {           JNZ   ChkPrtSc2}
                              {;}
  $B1/$03/                    {           MOV   CL,3                   ;Code for Ctrl}
  $A8/$04/                    {           TEST  AL,4                   ;Check for Ctrl}
  $75/$EE/                    {           JNZ   ChkPrtSc2}
                              {;}
  $B1/$01/                    {           MOV   CL,1                   ;Code for unshifted}
  $EB/$EA/                    {           JMP   ChkprtSc2}
                              {;}
                              {;          Handle backspace key.  We're only interested in Alt-backspace,}
                              {;          which we want to return as Esc + CHR( 171 ).}
                              {;}
  $B8/>KBD_ROM_DATA/          {ChkBackSp: MOV   AX,>Kbd_ROM_Data}
  $8E/$C0/                    {           MOV   ES,AX                  ;Point ES at the ROM DATA}
  $26/$A0/>KBD_FLAG/          {       ES: MOV   AL,[>Kbd_Flag]         ;Pick up shift key flags}
                              {;}
  $A8/$F7/                    {           TEST  AL,$F7                 ;Test for shifts other than ALT}
  $74/$03/                    {           JZ    ChkBacSp1              ;If so, treat as normal key.}
  $E9/$5A/$FF/                {           JMP   NormalKey}
                              {;}
  $A8/$08/                    {ChkBacSp1 :TEST  AL,8                   ;Check for ALT}
  $75/$03/                    {           JNZ   ChkBacSp2}
  $E9/$53/$FF/                {           JMP   NormalKey              ;Process as normal key if not ALT}
                              {;}
  $B1/$AB/                    {ChkbacSp2: MOV   CL,171                 ;Alt-backspace code}
  $E8/$68/$FF/                {           CALL  ReadPort               ;Read keyboard port}
  $E9/$22/$FF/                {           JMP   InsCode                ;Go insert ESC 171.}
                              {;}
                              {;          Handle / key.  We're only interested in the keypad /,}
                              {;          so the scan code flag must be 224 to process this.}
                              {;}
  $B8/>KBD_ROM_DATA/          {ChkSlash:  MOV   AX,>Kbd_ROM_Data}
  $8E/$C0/                    {           MOV   ES,AX                  ;Point ES at the ROM DATA}
  $26/$A0/>KBD_FLAG/          {       ES: MOV   AL,[>Kbd_Flag]         ;Pick up shift key flags}
                              {;}
  $A8/$F3/                    {           TEST  AL,$F3                 ;Test for shifts other than Ctrl, Alt.}
  $74/$03/                    {           JZ    ChkSlash1              ;No -- handle it here.}
  $E9/$3B/$FF/                {           JMP   NormalKey              ;Else treat as normal key.}
                              {;}
  $B1/$05/                    {ChkSlash1: MOV   CL,5                   ;Scan code if ALT flag.}
  $A8/$08/                    {           TEST  AL,8                   ;Check for Alt}
  $75/$08/                    {           JNZ   ChkSlash2}
                              {;}
  $B1/$06/                    {           MOV   CL,6                   ;Scan code if CTRL flag.}
  $A8/$04/                    {           TEST  AL,4                   ;Check for CTRL}
  $75/$02/                    {           JNZ   ChkSlash2}
                              {;}
  $B1/$04/                    {           MOV   CL,4                   ;Scan code with no shifts}
                              {;}
  $E8/$44/$FF/                {ChkSlash2: CALL  ReadPort               ;Read keyboard port.}
  $E9/$FE/$FE);               {           JMP   InsCode                ;Go insert ESC + Code.}
                              {;}
                              {Exit:}

END   (* Keyboard_Interrupt_Handler *);

(*----------------------------------------------------------------------*)
(* Ext_Keyboard_Interrupt_Handler --- Replaces int 9 keyboard handler   *)
(*----------------------------------------------------------------------*)

PROCEDURE Ext_Keyboard_Interrupt_Handler(
          Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP : WORD );
(*   Interrupt; *)

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Ext_Keyboard_Interrupt_Handler                       *)
(*                                                                      *)
(*     Purpose:    Replaces standard interrupt 9 keyboard driver for    *)
(*                 extended 101-key keyboards.                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*                 -- Called by system only!                            *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine replaces the standard interrupt 9 keyboard       *)
(*        driver so that the extended key combinations will work        *)
(*        properly.  This version for the 101-key keyboard is much      *)
(*        simpler than for the 83/84-key keyboards since only the       *)
(*        keyboard <ALT>key combinations need to be handled.            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Ext_Keyboard_Interrupt_Handler *)

INLINE(
                              {;}
  $E4/$60/                    {           IN    AL,$60                 ;Read the keyboard port}
  $88/$C1/                    {           MOV   CL,AL                  ;Save the key in CL}
                              {;}
  $3C/$E0/                    {           CMP   AL,$E0                 ;Check for scan code of 224}
  $75/$06/                    {           JNE   ChkRel                 ;No -- may be release}
  $A2/>KBD_SAVE_SCAN/         {           MOV   BYTE [>Kbd_Save_Scan],AL}
  $E9/$63/$00/                {           JMP   NormalKey}
                              {;}
  $3C/$80/                    {ChkRel:    CMP   AL,$80                 ;Is is a RELEASE? If so,}
  $72/$08/                    {           JB    Chk224                 ;}
  $C6/$06/>KBD_SAVE_SCAN/$00/ {           MOV   BYTE [>Kbd_Save_Scan],0;clear scan code flag, and}
  $E9/$57/$00/                {           JMP   NormalKey              ;treat as Normal}
                              {;}
  $80/$3E/>KBD_SAVE_SCAN/$00/ {Chk224:    CMP   BYTE [>Kbd_Save_Scan],0;Check for extended scan code}
  $74/$08/                    {           JE    ChkKeyPad              ;No -- go check keypad}
                              {;}
  $C6/$06/>KBD_SAVE_SCAN/$00/ {           MOV   BYTE [>Kbd_Save_Scan],0;Yes -- clear scan code flag,}
  $E9/$48/$00/                {           JMP   NormalKey              ;and treat as Normal}
                              {;}
  $3C/$47/                    {ChkKeyPad: CMP   AL,71                  ;71 = value for HOME key}
  $72/$44/                    {           JB    NormalKey              ;Below Home is normal}
  $3C/$53/                    {           CMP   AL,83                  ;83 = value for DEL key}
  $7F/$40/                    {           JG    NormalKey              ;Above Del is normal}
                              {;}
  $B8/>KBD_ROM_DATA/          {           MOV   AX,>Kbd_ROM_Data}
  $8E/$C0/                    {           MOV   ES,AX                  ;Point ES at the ROM DATA}
  $26/$A0/>KBD_FLAG/          {       ES: MOV   AL,[>Kbd_Flag]         ;Pick up shift key flags}
                              {;}
  $A8/$F7/                    {           TEST  AL,$F7                 ;Check if shifts other than alt}
  $75/$33/                    {           JNZ   NormalKey              ;If so, normal}
                              {;}
                              {;   If we got here w/o a jump, it's one of our}
                              {;   special keystrokes.}
                              {;}
  $E8/$4A/$00/                {Special:   CALL  ReadPort               ;Read the keyboard port.}
                              {;}
                              {;   Figure out TURBO code for key based upon scan code.}
                              {;   For normal keys, add nothing.  For ALT keys, add 103.}
                              {;   For control keys, special mapping is required.}
                              {;}
  $A8/$08/                    {           TEST  AL,8                   ;See if ALT turned on}
  $74/$2C/                    {           JZ    NormalKey              ;No -- treat as normal key.}
                              {;}
  $80/$C1/$67/                {           ADD   CL,103                 ;+103 converts to TURBO code for ALT}
                              {;}
  $8A/$26/>KBD_SAVE_SCAN/     {InsCode:   MOV   AH,[>Kbd_Save_Scan]    ;Get back saved scan code header}
  $88/$C8/                    {           MOV   AL,CL                  ;Get the key back from CL}
  $86/$C4/                    {           XCHG  AH,AL}
  $26/$8B/$1E/>KBD_TAIL/      {       ES: MOV   BX,[>Kbd_Tail]         ;Get tail of keyboard buffer}
  $26/$89/$07/                {       ES: MOV   [BX],AX                ;Put the key in the buffer}
                              {;}
  $81/$C3/$02/$00/            {           ADD   BX,2                   ;Advance the tail pointer}
  $81/$FB/>KBD_BUFFER_END/    {           CMP   BX,>Kbd_Buffer_End     ;If at end of buffer...}
  $7C/$03/                    {           JL    BufOK}
                              {;}
  $BB/>KBD_BUFFER/            {           MOV   BX,>Kbd_Buffer         ;...set back to beginning.}
  $26/$89/$1E/>KBD_TAIL/      {BufOK: ES: MOV   [>Kbd_Tail],BX}
                              {;}
  $B0/$20/                    {SendEOI:   MOV   AL,$20                 ;Send the EOI to the}
  $E6/$20/                    {           OUT   $20,AL                 ;...interrupt controller}
                              {;}
  $E9/$29/$00/                {           JMP   Exit                   ;and return}
                              {;}
                              {;          NormalKey}
                              {;                                       ;Chain to old keyboard ISR}
                              {;}
  $FF/$36/>KBD_SAVE_IADDR+2/  {NormalKey: PUSH   [>Kbd_Save_IAddr+2]   ;Push address of old ISR onto stack}
  $FF/$36/>KBD_SAVE_IADDR/    {           PUSH   [>Kbd_Save_IAddr]     ;Need to do this before DS restored!}
  $5B/                        {           POP    BX                    ;BX = OFS(Old_Keyboard_Interrupt)}
  $58/                        {           POP    AX                    ;AX = SEG(Old_Keyboard_Interrupt)}
  $87/$5E/$0E/                {           XCHG   BX,[BP+14]            ;Swap old BX and Ofs(Old_Key...)}
  $87/$46/$10/                {           XCHG   AX,[BP+16]            ;Swap old AX and Seg(Old_Key...)}
  $89/$EC/                    {           MOV    SP,BP                 ;Restore other registers}
  $5D/                        {           POP    BP}
  $07/                        {           POP    ES}
  $1F/                        {           POP    DS}
  $5F/                        {           POP    DI}
  $5E/                        {           POP    SI}
  $5A/                        {           POP    DX}
  $59/                        {           POP    CX}
                              {;                                       ;BX and AX restored earlier.}
                              {;                                       ;Their places on stack now have}
                              {;                                       ;old keyboard interrupt address,}
                              {;                                       ;which is where return will go.}
                              {;}
  $CB/                        {           RETF                         ;Chain to Old_Keyboard_Interrupt}
                              {;}
                              {;          Read keyboard control port.}
                              {;}
  $50/                        {ReadPort:  PUSH  AX}
  $E4/$61/                    {           IN    AL,$61                 ;Read keyboard control port}
  $88/$C4/                    {           MOV   AH,AL}
  $0C/$80/                    {           OR    AL,$80                 ;Set the "reset" bit and}
  $E6/$61/                    {           OUT   $61,AL                 ;   send it back to control}
  $86/$C4/                    {           XCHG  AH,AL                  ;Get back the control value}
  $E6/$61/                    {           OUT   $61,AL                 ;Send it out also}
  $58/                        {           POP   AX}
  $C3);                       {           RET}
                              {;}
                              {Exit:}

END   (* Ext_Keyboard_Interrupt_Handler *);

(*----------------------------------------------------------------------*)
(* Install_Keyboard_Handler --- Installs new interrupt 9 keyboard driver*)
(*----------------------------------------------------------------------*)

PROCEDURE Install_Keyboard_Handler;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Install_Keyboard_Handler                             *)
(*                                                                      *)
(*     Purpose:    Replaces standard interrupt 9 keyboard driver        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Install_Keyboard_Handler;                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Install_Keyboard_Handler *)

                                   (* Make sure keyboard scan is zero *)
   Kbd_Save_Scan := 0;
                                   (* Set interrupt routine address *)

   IF ( ( Mem[$40:$96] AND $10 ) <> 0 ) THEN
      SetIntVec( Kbd_Interrupt , @Ext_Keyboard_Interrupt_Handler )
   ELSE
      SetIntVec( Kbd_Interrupt , @Keyboard_Interrupt_Handler );

END   (* Install_Keyboard_Handler *);

(*----------------------------------------------------------------------*)
(*  Remove_Keyboard_Handler --- Removes installed interrupt 9 driver    *)
(*----------------------------------------------------------------------*)

PROCEDURE Remove_Keyboard_Handler;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Remove_Keyboard_Handler                              *)
(*                                                                      *)
(*     Purpose:    Restores standard interrupt 9 keyboard driver        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Remove_Keyboard_Handler;                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Remove_Keyboard_Handler *)

                     (* Restore the previous interrupt pointers *)

   SetIntVec( Kbd_Interrupt , Kbd_Save_Iaddr );

END   (* Remove_Keyboard_Handler *);
