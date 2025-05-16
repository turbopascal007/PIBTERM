(*----------------------------------------------------------------------*)
(*                BIOS_RS232_Init --- Initialize UART                   *)
(*----------------------------------------------------------------------*)

PROCEDURE BIOS_RS232_Init( ComPort : INTEGER; ComParm : WORD );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  BIOS_RS232_Init                                      *)
(*                                                                      *)
(*     Purpose:    Issues interrupt $14 to initialize the UART          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        BIOS_RS232_Init( ComPort, ComParm : INTEGER );                *)
(*                                                                      *)
(*           ComPort  --- Communications Port Number (0 thru 3)         *)
(*           ComParm  --- Communications Parameter Word                 *)
(*                                                                      *)
(*      Calls:   INTR   (to perform BIOS interrupt $14)                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Regs: Registers;

BEGIN   (* BIOS_RS232_Init *)
                                   (* Initialize port    *)
   WITH Regs DO
      BEGIN
         Ax := ComParm AND $00FF;  (* AH=0; AL=ComParm   *)
         Dx := ComPort;            (* Port number to use *)
         INTR($14, Regs);
      END;

END    (* BIOS_RS232_Init *);

(*----------------------------------------------------------------------*)
(*               Async_Isr --- Interrupt Service Routine                *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Isr( Flags, CS, IP, AX, BX, CX, DX, SI, DI, DS, ES, BP : WORD );
   Interrupt;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Isr                                            *)
(*                                                                      *)
(*     Purpose:    Invoked when serial port interrupt occurs.           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Isr;                                                    *)
(*                                                                      *)
(*           --- Called asynchronously only!!!!!!                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN   (* Async_Isr *)

INLINE(
  $FB/                                 {         STI                                ;Allow interrupts}
                                       {;}
                                       {;  Begin major polling loop over pending interrupts.}
                                       {;}
                                       {;  The polling loop is needed because the 8259 cannot handle another 8250}
                                       {;  interrupt while we service this interrupt.  We keep polling here as long}
                                       {;  as an interrupt is received.}
                                       {;}
  $8B/$16/>ASYNC_UART_IIR/             {Poll:    MOV     DX,[>Async_Uart_IIR]       ;Get Interrupt ident register}
  $EC/                                 {         IN      AL,DX                      ;Pick up interrupt type}
                                       {;}
  $A8/$01/                             {         TEST    AL,1                       ;See if any interrupt signalled.}
  $74/$03/                             {         JZ      Polla                      ;Yes --- continue}
  $E9/$B9/$01/                         {         JMP     NEAR Back                  ;No  ---  return to invoker}
                                       {;}
                                       {;  Determine type of interrupt.}
                                       {;  Possibilities:}
                                       {;}
                                       {;     0 = Modem status changed}
                                       {;     2 = Transmit hold register empty (write char)}
                                       {;     4 = Character received from port}
                                       {;     6 = Line status changed}
                                       {;}
  $24/$06/                             {Polla:   AND     AL,6                       ;Strip unwanted bits from interrupt type}
  $3C/$04/                             {         CMP     AL,4                       ;Check if interrupt >= 4}
  $74/$03/                             {         JE      Pollb                      ;}
  $E9/$DB/$00/                         {         JMP     NEAR Int2}
                                       {;}
                                       {;  Write interrupts must be turned on if a higher-priority interrupt}
                                       {;  has been received, else the characters may not be sent (and a lockup}
                                       {;  may occur).}
                                       {;}
  $50/                                 {Pollb:   PUSH    AX                         ;Save interrupt type}
  $E8/$9F/$01/                         {         CALL    EnabWI                     ;Enable write interrupts}
  $58/                                 {         POP     AX                         ;Restore interrupt type}
                                       {;}
                                       {;  --- Received a character ----}
                                       {;}
  $3C/$04/                             {Int4:    CMP     AL,4                       ;Check for received char interrupt}
  $74/$03/                             {         JE      Int4a                      ;Yes -- process it.}
  $E9/$CF/$00/                         {         JMP     NEAR Int2                  ;No -- skip.}
                                       {;}
                                       {;  Read the character from the serial port.}
                                       {;}
  $8B/$16/>ASYNC_BASE/                 {Int4a:   MOV     DX,[>Async_Base]           ;Read character from port}
  $EC/                                 {         IN      AL,DX}
                                       {;}
                                       {;  Check if XON/XOFF honored.  If so, check if incoming character is}
                                       {;  an XON or an XOFF.}
                                       {;}
  $F6/$06/>ASYNC_DO_XONXOFF/$01/       {         TEST    BYTE [<Async_Do_XonXoff],1 ;See if we honor XON/XOFF}
  $74/$25/                             {         JZ      Int4d                      ;No -- skip XON/XOFF checks}
                                       {;}
  $3C/<XON/                            {         CMP     AL,<XON                    ;See if XON found}
  $74/$11/                             {         JE      Int4b                      ;Skip if XON found}
  $3C/<XOFF/                           {         CMP     AL,<XOFF                   ;See if XOFF found}
  $75/$1D/                             {         JNE     Int4d                      ;Skip if XOFF not found}
                                       {;}
                                       {;  XOFF received -- set flag indicating sending of chars isn't possible}
                                       {;}
  $C6/$06/>ASYNC_XOFF_RECEIVED/$01/    {         MOV     BYTE [<Async_XOFF_Received],1    ;Turn on received XOFF flag}
  $C6/$06/>ASYNC_XOFF_REC_DISPLAY/$01/ {         MOV     BYTE [<Async_XOFF_Rec_Display],1 ;Turn on display flag}
  $E9/$BE/$FF/                         {         JMP     NEAR Poll}
                                       {;}
                                       {;  XON received -- allow more characters to be sent.}
                                       {;}
  $C6/$06/>ASYNC_XOFF_RECEIVED/$00/    {Int4b:   MOV     BYTE [<Async_XOFF_Received],0   ;Turn off received XOFF flag}
  $C6/$06/>ASYNC_XON_REC_DISPLAY/$01/  {         MOV     BYTE [<Async_XON_Rec_Display],1 ;Turn on display flag}
                                       {;}
  $E8/$69/$01/                         {         CALL    EnabWI                     ;Enable write interrupts}
  $E9/$9B/$00/                         {         JMP     NEAR Int4z}
                                       {;}
                                       {;  Not XON/XOFF -- handle other character.}
                                       {;}
  $F6/$06/>ASYNC_LINE_STATUS/$02/      {Int4d:   TEST    BYTE [>Async_Line_Status],2 ;Check for buffer overrun}
  $74/$03/                             {         JZ      Int4e                       ;Yes --- don't store anything}
  $E9/$91/$00/                         {         JMP     Int4z}
                                       {;}
  $8B/$1E/>ASYNC_BUFFER_HEAD/          {Int4e:   MOV     BX,[>Async_Buffer_Head]    ;Current position in input buffer}
  $C4/$3E/>ASYNC_BUFFER_PTR/           {         LES     DI,[>Async_Buffer_Ptr]     ;Pick up buffer address}
  $01/$DF/                             {         ADD     DI,BX                      ;Update position}
  $26/$88/$05/                         {     ES: MOV     [DI],AL                    ;Store received character in buffer}
  $FF/$06/>ASYNC_BUFFER_USED/          {         INC     WORD [>Async_Buffer_Used]  ;Increment count of chars in buffer}
                                       {;}
  $A1/>ASYNC_BUFFER_USED/              {         MOV     AX,[>Async_Buffer_Used]    ;Pick up buffer usage count}
  $3B/$06/>ASYNC_MAXBUFFERUSED/        {         CMP     AX,[>Async_MaxBufferUsed]  ;See if greater usage than ever before}
  $7E/$03/                             {         JLE     Int4f                      ;Skip if not}
  $A3/>ASYNC_MAXBUFFERUSED/            {         MOV     [>Async_MaxBufferUsed],AX  ;This is greatest use thus far}
                                       {;}
  $43/                                 {Int4f:   INC     BX                         ;Increment buffer pointer}
  $3B/$1E/>ASYNC_BUFFER_SIZE/          {         CMP     BX,[>Async_Buffer_Size]    ;Check if past end of buffer}
  $7E/$02/                             {         JLE     Int4h}
  $31/$DB/                             {         XOR     BX,BX                      ;If so, wrap around to front}
                                       {;}
  $39/$1E/>ASYNC_BUFFER_TAIL/          {Int4h:   CMP     WORD [>Async_Buffer_Tail],BX ;Check for overflow}
  $74/$60/                             {         JE      Int4s                        ;Jump if head ran into tail}
                                       {;}
  $89/$1E/>ASYNC_BUFFER_HEAD/          {         MOV     [>Async_Buffer_Head],BX    ;Update head pointer}
                                       {;}
                                       {;  Check for receive buffer nearly full here.}
                                       {;}
                                       {;  If XON/XOFF available, and buffer getting full, set up to send}
                                       {;  XOFF to remote system.}
                                       {;}
                                       {;  This happens in two possible stages:}
                                       {;}
                                       {;     (1)  An XOFF is sent right when the buffer becomes 'Async_Buffer_High'}
                                       {;          characters full.}
                                       {;}
                                       {;     (2)  A second XOFF is sent right when the buffer becomes}
                                       {;          'Async_Buffer_High_2' characters full;  this case is likely the}
                                       {;          result of the remote not having seen our XOFF because it was}
                                       {;          lost in transmission.}
                                       {;}
                                       {;  If CTS/RTS handshaking, then drop RTS here if buffer nearly full.}
                                       {;  Note that this has to be done even if the XOFF is being sent as well.}
                                       {;}
                                       {;}
                                       {;  Check receive buffer size against first high-water mark.}
                                       {;}
  $3B/$06/>ASYNC_BUFFER_HIGH/          {         CMP     AX,[>Async_Buffer_High]    ;AX still has Async_Buffer_Used}
  $7C/$5B/                             {         JL      Int4z                      ;Not very full, so keep going.}
                                       {;}
                                       {;  Remember if we've already (supposedly) disabled sender.}
                                       {;}
  $8A/$16/>ASYNC_SENDER_ON/            {         MOV     DL,[<Async_Sender_On]      ;Get sender enabled flag.}
                                       {;}
                                       {;  Drop through means receive buffer getting full.}
                                       {;  Check for XON/XOFF.}
                                       {;}
  $F6/$06/>ASYNC_OV_XONXOFF/$01/       {         TEST    BYTE [<Async_OV_XonXoff],1 ;See if we honor XON/XOFF}
                                       {;                                           ; for buffer overflow}
  $74/$1A/                             {         JZ      Int4k                      ;No -- skip XON/XOFF checks}
                                       {;}
                                       {;  Check if we've already sent XOFF.}
                                       {;}
  $F6/$06/>ASYNC_XOFF_SENT/$01/        {         TEST    BYTE [<Async_XOFF_Sent],1  ;Remember if we sent XOFF or not}
  $74/$06/                             {         JZ      Int4j                      ;No -- go send it now.}
                                       {;}
                                       {;  Check against second high-water mark.}
                                       {;  If we are right at it, send an XOFF regardless of whether we've}
                                       {;  already sent one or not.  (Perhaps the first got lost.)}
                                       {;}
  $3B/$06/>ASYNC_BUFFER_HIGH_2/        {         CMP     AX,[>Async_Buffer_High_2]}
  $75/$0D/                             {         JNE     Int4k                      ;Not at 2nd mark -- skip}
                                       {;}
  $C6/$06/>ASYNC_SEND_XOFF/$01/        {Int4j:   MOV     BYTE [<Async_Send_XOFF],1  ;Indicate we need to send XOFF}
  $E8/$06/$01/                         {         CALL    EnabWI                     ;Ensure write interrupts enabled}
  $C6/$06/>ASYNC_SENDER_ON/$00/        {         MOV     BYTE [<Async_Sender_On],0  ;Disable sender}
                                       {;}
                                       {;  Check here if we're doing hardware handshakes.}
                                       {;  Drop RTS if CTS/RTS handshaking.}
                                       {;  Drop DTR if DSR/DTR handshaking.}
                                       {;}
  $F6/$C2/$01/                         {Int4k:   TEST    DL,1                       ;See if sender already disabled}
  $74/$31/                             {         JZ      Int4z                      ;Yes -- skip hardware handshakes.}
                                       {;}
  $30/$E4/                             {         XOR     AH,AH                      ;No hardware handshakes}
                                       {;}
  $F6/$06/>ASYNC_DO_CTS/$01/           {         TEST    BYTE [<Async_Do_CTS],1     ;See if RTS/CTS checking}
  $74/$02/                             {         JZ      Int4l                      ;No -- skip it}
                                       {;}
  $B4/<ASYNC_RTS/                      {         MOV     AH,<Async_RTS              ;Turn on RTS bit}
                                       {;}
  $F6/$06/>ASYNC_DO_DSR/$01/           {Int4l:   TEST    BYTE [<Async_Do_DSR],1     ;See if DSR/DTR checking}
  $74/$03/                             {         JZ      Int4m                      ;No -- skip it}
                                       {;}
  $80/$CC/<ASYNC_DTR/                  {         OR      AH,<Async_DTR              ;Turn on DTR bit}
                                       {;}
  $80/$FC/$00/                         {Int4m:   CMP     AH,0                       ;Any hardware signal?}
  $74/$17/                             {         JZ      Int4z                      ;No -- skip}
                                       {;}
  $8B/$16/>ASYNC_UART_MCR/             {         MOV     DX,[>Async_Uart_MCR]       ;Get modem control register}
  $EC/                                 {         IN      AL,DX}
  $F6/$D4/                             {         NOT     AH                         ;Complement hardware flags}
  $20/$E0/                             {         AND     AL,AH                      ;Nuke RTS/DTR}
  $EE/                                 {         OUT     DX,AL}
                                       {;}
  $C6/$06/>ASYNC_SENDER_ON/$00/        {         MOV     BYTE [<Async_Sender_On],0  ;Indicate sender disabled}
  $E9/$05/$00/                         {         JMP     Int4z}
                                       {;}
                                       {;  If we come here, then the input buffer has overflowed.}
                                       {;  Characters will be thrown away until the buffer empties at least one slot.}
                                       {;}
  $80/$0E/>ASYNC_LINE_STATUS/$02/      {Int4s:   OR      BYTE PTR [>Async_Line_Status],2 ;Flag overrun}
                                       {;}
  $E9/$10/$FF/                         {Int4z:   JMP     NEAR Poll}
                                       {;}
                                       {;  --- Write a character ---}
                                       {;}
  $3C/$02/                             {Int2:    CMP     AL,2                       ;Check for THRE interrupt}
  $74/$03/                             {         JE      Int2a                      ;Yes -- process it.}
  $E9/$97/$00/                         {         JMP     NEAR Int6                  ;No -- skip.}
                                       {;}
                                       {;  Check first if we need to send an XOFF to remote system.}
                                       {;}
  $F6/$06/>ASYNC_SEND_XOFF/$01/        {Int2a:   TEST    BYTE [<Async_Send_Xoff],1  ;See if we are sending XOFF}
  $74/$34/                             {         JZ      Int2d                      ;No -- skip it}
                                       {;}
                                       {;  Yes, we are to send XOFF to remote.}
                                       {;}
                                       {;  First, check DSR and CTS as requested.}
                                       {;  If those status lines aren't ready, turn off write interrupts and}
                                       {;  try later, after a line status change.}
                                       {;}
  $F6/$06/>ASYNC_DO_DSR/$01/           {         TEST    BYTE [<Async_Do_DSR],1     ;See if DSR checking required}
  $74/$09/                             {         JZ      Int2b                      ;No -- skip it}
                                       {;}
  $8B/$16/>ASYNC_UART_MSR/             {         MOV     DX,[>Async_Uart_MSR]       ;Get modem status register}
  $EC/                                 {         IN      AL,DX}
  $A8/<ASYNC_DSR/                      {         TEST    AL,<Async_DSR              ;Check for Data Set Ready}
  $74/$2E/                             {         JZ      Int2e                      ;If not DSR, turn off write interrupts}
                                       {;}
  $F6/$06/>ASYNC_DO_CTS/$01/           {Int2b:   TEST    BYTE [<Async_Do_CTS],1     ;See if CTS checking required}
  $74/$09/                             {         JZ      Int2c                      ;No -- skip it}
                                       {;}
  $8B/$16/>ASYNC_UART_MSR/             {         MOV     DX,[>Async_Uart_MSR]       ;Get modem status register}
  $EC/                                 {         IN      AL,DX}
  $A8/<ASYNC_CTS/                      {         TEST    AL,<Async_CTS              ;Check for Clear To Send}
  $74/$1E/                             {         JZ      Int2e                      ;If not CTS, turn off write ints}
                                       {;}
                                       {;  All status lines look OK.}
                                       {;  Send the XOFF.}
                                       {;}
  $B0/<XOFF/                           {Int2c:   MOV     AL,<XOFF                   ;Get XOFF Character}
  $8B/$16/>ASYNC_BASE/                 {         MOV     DX,[>Async_Base]           ;Get transmit hold register address}
  $EE/                                 {         OUT     DX,AL                      ;Output the XOFF}
  $C6/$06/>ASYNC_SEND_XOFF/$00/        {         MOV     BYTE [<Async_Send_XOFF],0  ;Turn off send XOFF flag}
  $C6/$06/>ASYNC_XOFF_SENT/$01/        {         MOV     BYTE [<Async_XOFF_Sent],1  ;Turn on sent XOFF flag}
  $E9/$CE/$FE/                         {         JMP     NEAR Poll                  ;Return}
                                       {;}
                                       {;  Not sending XOFF -- see if any character in buffer to be sent.}
                                       {;}
  $8B/$1E/>ASYNC_OBUFFER_TAIL/         {Int2d:   MOV     BX,[>Async_OBuffer_Tail]   ;Pick up output buffer pointers}
  $3B/$1E/>ASYNC_OBUFFER_HEAD/         {         CMP     BX,[>Async_OBuffer_Head]}
  $75/$0B/                             {         JNE     Int2m                      ;Skip if not equal --> something to send}
                                       {;}
                                       {;  If nothing to send, turn off write interrupts to avoid unnecessary}
                                       {;  time spent handling useless THRE interrupts.}
                                       {;}
  $8B/$16/>ASYNC_UART_IER/             {Int2e:   MOV     DX,[>Async_Uart_IER]       ;If nothing -- or can't -- send ...}
  $EC/                                 {         IN      AL,DX                      ;}
  $24/$FD/                             {         AND     AL,$FD                     ;}
  $EE/                                 {         OUT     DX,AL                      ;... disable write interrupts}
  $E9/$B9/$FE/                         {         JMP     NEAR Poll                  ;}
                                       {;}
                                       {;  If something to send, ensure that remote system didn't send us XOFF.}
                                       {;  If it did, we can't send anything, so turn off write interrupts and}
                                       {;  wait for later (after an XON has been received).}
                                       {;}
  $F6/$06/>ASYNC_XOFF_RECEIVED/$01/    {Int2m:   TEST    BYTE [<Async_XOFF_Received],1 ;See if we received XOFF}
  $75/$EE/                             {         JNZ     Int2e                      ;Yes -- can't send anything now}
                                       {;}
                                       {;  If we can send character, check DSR and CTS as requested.}
                                       {;  If those status lines aren't ready, turn off write interrupts and}
                                       {;  try later, after a line status change.}
                                       {;}
  $8B/$16/>ASYNC_UART_MSR/             {         MOV     DX,[>Async_Uart_MSR]       ;Otherwise get modem status}
  $EC/                                 {         IN      AL,DX}
  $A2/>ASYNC_MODEM_STATUS/             {         MOV     [>Async_Modem_Status],AL   ;and save modem status for later}
                                       {;}
  $F6/$06/>ASYNC_DO_DSR/$01/           {         TEST    BYTE [<Async_Do_DSR],1     ;See if DSR checking required}
  $74/$04/                             {         JZ      Int2n                      ;No -- skip it}
                                       {;}
  $A8/<ASYNC_DSR/                      {         TEST    AL,<Async_DSR              ;Check for Data Set Ready}
  $74/$DB/                             {         JZ      Int2e                      ;If not DSR, turn off write ints}
                                       {;}
  $F6/$06/>ASYNC_DO_CTS/$01/           {Int2n:   TEST    BYTE [<Async_Do_CTS],1     ;See if CTS checking required}
  $74/$04/                             {         JZ      Int2o                      ;No -- skip it}
                                       {;}
  $A8/<ASYNC_CTS/                      {         TEST    AL,<Async_CTS              ;Check for Clear To Send}
  $74/$D0/                             {         JZ      Int2e                      ;If not CTS, turn off write ints}
                                       {;}
                                       {;  Everything looks OK for sending, so send the character.}
                                       {;}
  $C4/$3E/>ASYNC_OBUFFER_PTR/          {Int2o:   LES     DI,[>Async_OBuffer_Ptr]    ;Get output buffer pointer}
  $01/$DF/                             {         ADD     DI,BX                      ;Position to character to output}
  $26/$8A/$05/                         {     ES: MOV     AL,[DI]                    ;Get character to output}
  $8B/$16/>ASYNC_BASE/                 {         MOV     DX,[>Async_Base]           ;Get transmit hold register address}
  $EE/                                 {         OUT     DX,AL                      ;Output the character}
                                       {;}
  $FF/$0E/>ASYNC_OBUFFER_USED/         {         DEC     WORD [>Async_OBuffer_Used] ;Decrement count of chars in buffer}
  $43/                                 {         INC     BX                         ;Increment tail pointer}
  $3B/$1E/>ASYNC_OBUFFER_SIZE/         {         CMP     BX,[>Async_OBuffer_Size]   ;See if past end of buffer}
  $7E/$02/                             {         JLE     Int2z}
  $31/$DB/                             {         XOR     BX,BX                      ;If so, wrap to front}
                                       {;}
  $89/$1E/>ASYNC_OBUFFER_TAIL/         {Int2z:   MOV     [>Async_OBuffer_Tail],BX   ;Store updated buffer tail}
  $E9/$72/$FE/                         {         JMP     NEAR Poll}
                                       {;}
                                       {;  --- Line status change ---}
                                       {;}
  $3C/$06/                             {Int6:    CMP     AL,6                       ;Check for line status interrupt}
  $75/$11/                             {         JNE     Int0                       ;No -- skip.}
                                       {;}
  $8B/$16/>ASYNC_UART_LSR/             {         MOV     DX,[>Async_Uart_LSR]       ;Yes -- pick up line status register}
  $EC/                                 {         IN      AL,DX                      ;and its contents}
  $24/$1E/                             {         AND     AL,$1E                     ;Strip unwanted bits}
  $A2/>ASYNC_LINE_STATUS/              {         MOV     [>Async_Line_Status],AL    ;Store for future reference}
  $08/$06/>ASYNC_LINE_ERROR_FLAGS/     {         OR      [>Async_Line_Error_Flags],AL ;Add to any past transgressions}
  $E9/$5D/$FE/                         {         JMP     NEAR Poll}
                                       {;}
                                       {;  --- Modem status change ---}
                                       {;}
  $3C/$00/                             {Int0:    CMP     AL,0                       ;Check for modem status change}
  $74/$03/                             {         JE      Int0a                      ;Yes -- handle it}
  $E9/$56/$FE/                         {         JMP     NEAR Poll                  ;Else get next interrupt}
                                       {;}
  $8B/$16/>ASYNC_UART_MSR/             {Int0a:   MOV     DX,[>Async_Uart_MSR]       ;Pick up modem status reg. address}
  $EC/                                 {         IN      AL,DX                      ;and its contents}
  $A2/>ASYNC_MODEM_STATUS/             {         MOV     [>Async_Modem_Status],AL   ;Store for future reference}
  $E8/$03/$00/                         {         CALL    EnabWI                     ;Turn on write interrupts, in case}
                                       {;                                           ;status change resulted from CTS/DSR}
                                       {;                                           ;changing state.}
  $E9/$48/$FE/                         {         JMP     NEAR Poll}
                                       {;}
                                       {;  Internal subroutine to enable write interrupts.}
                                       {;}
                                       {EnabWI: ;PROC    NEAR}
  $8B/$16/>ASYNC_UART_IER/             {         MOV     DX,[>Async_Uart_IER]       ;Get interrupt enable register}
  $EC/                                 {         IN      AL,DX                      ;Check contents of IER}
  $A8/$02/                             {         TEST    AL,2                       ;See if write interrupt enabled}
  $75/$03/                             {         JNZ     EnabRet                    ;Skip if so}
  $0C/$02/                             {         OR      AL,2                       ;Else enable write interrupts ...}
  $EE/                                 {         OUT     DX,AL                      ;... by rewriting IER contents}
  $C3/                                 {EnabRet: RET                                ;Return to caller}
                                       {;}
                                       {;  Send non-specific EOI to 8259 controller.}
                                       {;}
  $B0/$20/                             {Back:    MOV     AL,$20                     ;EOI = $20}
  $E6/$20);                            {         OUT     $20,AL}

END;

(*----------------------------------------------------------------------*)
(*               Async_Close --- Close down communications interrupts   *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Close( Drop_DTR: BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Close                                          *)
(*                                                                      *)
(*     Purpose:    Resets interrupt system when UART interrupts         *)
(*                 are no longer needed.                                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Close( Drop_DTR : BOOLEAN );                            *)
(*                                                                      *)
(*           Drop_DTR --- TRUE to drop DTR when closing down port       *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I : INTEGER;
   M : INTEGER;

BEGIN  (* Async_Close *)

   IF Async_Open_Flag THEN
      BEGIN

                     (* disable the IRQ on the 8259 *)

         INLINE($FA);                 (* disable interrupts *)

         I := Port[I8088_IMR];        (* get the interrupt mask register *)
         M := 1 SHL Async_Irq;        (* set mask to turn off interrupt  *)
         Port[I8088_IMR] := I OR M;

                     (* disable the 8250 interrupts *)

         Port[UART_IER + Async_Base] := 0;

                     (* Disable OUT2, RTS, OUT1 on the 8250, but *)
                     (* possibly leave DTR enabled.              *)

         IF Drop_Dtr THEN
            Port[UART_MCR + Async_Base] := 0
         ELSE
            Port[UART_MCR + Async_Base] := 1;

         INLINE($FB);                 (* enable interrupts *)

                     (* re-initialize our data areas so we know *)
                     (* the port is closed                      *)

         Async_Open_Flag := FALSE;
         Async_XOFF_Sent := FALSE;
         Async_Sender_On := FALSE;

                     (* Restore the previous interrupt pointers *)

         SetIntVec( Async_Int , Async_Save_Iaddr );

      END;

END    (* Async_Close *);

(*----------------------------------------------------------------------*)
(*    Async_Clear_Errors --- Reset pending errors in async port         *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Clear_Errors;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:   Async_Clear_Errors                                  *)
(*                                                                      *)
(*     Purpose:     Resets pending errors in async port                 *)
(*                                                                      *)
(*     Calling sequence:                                                *)
(*                                                                      *)
(*        Async_Clear_Errors;                                           *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I:  INTEGER;
   M:  INTEGER;

BEGIN (* Async_Clear_Errors *)

                   (* Read the RBR and reset any pending error conditions. *)
                   (* First turn off the Divisor Access Latch Bit to allow *)
                   (* access to RBR, etc.                                  *)

   INLINE($FA);  (* disable interrupts *)

   Port[UART_LCR + Async_Base] := Port[UART_LCR + Async_Base] AND $7F;

                   (* Read the Line Status Register to reset any errors *)
                   (* it indicates                                      *)

   I := Port[UART_LSR + Async_Base];

                   (* Read the Receiver Buffer Register in case it *)
                   (* contains a character                         *)

   I := Port[UART_RBR + Async_Base];

                   (* enable the irq on the 8259 controller *)

   I := Port[I8088_IMR];  (* get the interrupt mask register *)
   M := (1 SHL Async_Irq) XOR $00FF;

   Port[I8088_IMR] := I AND M;

                   (* enable OUT2 on 8250 *)

   I := Port[UART_MCR + Async_Base];
   Port[UART_MCR + Async_Base] := I OR $0B;

                   (* enable the data ready interrupt on the 8250 *)

   Port[UART_IER + Async_Base] := $0F;

                   (* Re-enable 8259 *)

   Port[$20] := $20;

   INLINE($FB); (* enable interrupts *)

END   (* Async_Clear_Errors *);

(*----------------------------------------------------------------------*)
(*    Async_Reset_Port --- Set/reset communications port parameters     *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Reset_Port( ComPort       : INTEGER;
                            BaudRate      : WORD;
                            Parity        : CHAR;
                            WordSize      : INTEGER;
                            StopBits      : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:   Async_Reset_Port                                    *)
(*                                                                      *)
(*     Purpose:     Resets communications port                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Reset_Port(   ComPort       : INTEGER;                  *)
(*                            BaudRate      : WORD;                     *)
(*                            Parity        : CHAR;                     *)
(*                            WordSize      : INTEGER;                  *)
(*                            StopBits      : INTEGER);                 *)
(*                                                                      *)
(*           ComPort  --- which port (1, 2, 3, 4)                       *)
(*           BaudRate --- Baud rate (110 to 57600)                      *)
(*           Parity   --- "E" for even, "O" for odd, "N" for none,      *)
(*                        "M" for mark, "S" for space.
(*           WordSize --- Bits per character  (5 through 8)             *)
(*           StopBits --- How many stop bits  (1 or 2)                  *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Clear_Errors --- Clear async line errors                *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST   (* Baud Rate Constants *)

   Async_Num_Bauds = 11;

   Async_Baud_Table : ARRAY [1..Async_Num_Bauds] OF RECORD
                                                       Baud, Bits : WORD;
                                                    END

                    = ( ( Baud:  110;  Bits: $00 ),
                        ( Baud:  150;  Bits: $20 ),
                        ( Baud:  300;  Bits: $40 ),
                        ( Baud:  600;  Bits: $60 ),
                        ( Baud:  1200; Bits: $80 ),
                        ( Baud:  2400; Bits: $A0 ),
                        ( Baud:  4800; Bits: $C0 ),
                        ( Baud:  9600; Bits: $E0 ),
                        ( Baud: 19200; Bits: $E0 ),
                        ( Baud: 38400; Bits: $E0 ),
                        ( Baud: 57600; Bits: $E0 ) );

VAR
   I       : INTEGER;
   M       : INTEGER;
   ComParm : INTEGER;

BEGIN (* Async_Reset_Port *)

            (*---------------------------------------------------*)
            (*    Build the ComParm for RS232_Init               *)
            (*    See Technical Reference Manual for description *)
            (*---------------------------------------------------*)

                                   (* Set up the bits for the baud rate *)

   IF ( BaudRate > Async_Baud_Table[Async_Num_Bauds].Baud ) THEN
      BaudRate := Async_Baud_Table[Async_Num_Bauds].Baud

   ELSE IF ( BaudRate < Async_Baud_Table[1].Baud ) THEN
      BaudRate := Async_Baud_Table[1].Baud;

                                   (* Remember baud rate for purges *)
   Async_Baud_Rate := BaudRate;

   I := 0;

   REPEAT
      I := I + 1
   UNTIL ( ( I >= Async_Num_Bauds ) OR
           ( BaudRate = Async_Baud_Table[I].Baud ) );

   ComParm := Async_Baud_Table[I].Bits;

                                   (* Choose Parity.  Temporarily   *)
                                   (* consider mark, space as none. *)
   Parity := UpCase( Parity );

   CASE Parity OF
      'E' : ComParm := ComParm OR $0018;
      'O' : ComParm := ComParm OR $0008;
      ELSE ;
   END (* CASE *);
                                   (* Choose number of data bits *)

   WordSize := WordSize - 5;

   IF ( WordSize < 0 ) OR ( WordSize > 3 ) THEN
      WordSize := 3;

   ComParm := ComParm OR WordSize;

                                   (* Choose stop bits *)

   IF StopBits = 2 THEN
      ComParm := ComParm OR $0004;  (* default is 1 stop bit *)

                                   (* Use the BIOS COM port init routine *)

   BIOS_RS232_Init( ComPort - 1 , ComParm );

                                   (* If > 9600 baud, we have to screw *)
                                   (* around a bit                     *)

   IF ( BaudRate >= 19200 ) THEN
      BEGIN

         I                             := PORT[ UART_LCR + Async_Base ];
         PORT[ UART_LCR + Async_Base ] := I OR $80;

         PORT[ UART_THR + Async_Base ] := 115200 DIV BaudRate;
         PORT[ UART_IER + Async_Base ] := 0;

         I                             := PORT[ UART_LCR + Async_Base ];
         PORT[ UART_LCR + Async_Base ] := I AND $7F;

      END;
                                   (* Now fix up mark, space parity *)

   IF ( ( Parity = 'M' ) OR ( Parity = 'S' ) ) THEN
      BEGIN

         I := PORT[ UART_LCR + Async_Base ];
         PORT[ UART_LCR + Async_Base ] := $80;

         ComParm := WordSize OR ( ( StopBits - 1 ) SHL 2 );

         CASE Parity OF
            'M' : ComParm := ComParm OR $0028;
            'S' : ComParm := ComParm OR $0038;
            ELSE ;
         END (* CASE *);

         PORT[ UART_LCR + Async_Base ] := ComParm;

      END;
                                   (* Sender is enabled *)
   Async_Sender_On := TRUE;
                                   (* Clear any pending errors on *)
                                   (* async line                  *)
   Async_Clear_Errors;

END   (* Async_Reset_Port *);

(*----------------------------------------------------------------------*)
(*               Async_Open --- Open communications port                *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Open( ComPort       : INTEGER;
                     BaudRate      : WORD;
                     Parity        : CHAR;
                     WordSize      : INTEGER;
                     StopBits      : INTEGER  ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Open                                           *)
(*                                                                      *)
(*     Purpose:    Opens communications port                            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Open( ComPort       : INTEGER;                  *)
(*                            BaudRate      : WORD;                     *)
(*                            Parity        : CHAR;                     *)
(*                            WordSize      : INTEGER;                  *)
(*                            StopBits      : INTEGER) : BOOLEAN;       *)
(*                                                                      *)
(*           ComPort  --- which port (1 though 4)                       *)
(*           BaudRate --- Baud rate (110 to 57600)                      *)
(*           Parity   --- "E" for even, "O" for odd, "N" for none,      *)
(*                        "S" for space, "M" for mark.                  *)
(*           WordSize --- Bits per character  (5 through 8)             *)
(*           StopBits --- How many stop bits  (1 or 2)                  *)
(*                                                                      *)
(*           Flag returned TRUE if port initialized successfully;       *)
(*           Flag returned FALSE if any errors.                         *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Reset_Port --- initialize RS232 port                    *)
(*        Async_Close      --- close open RS232 port                    *)
(*        SetIntVec        --- set address of RS232 interrupt routine   *)
(*        GetIntVec        --- get address of RS232 interrupt routine   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Async_Open *)
                             (* If port open, close it down first.  *)
   IF Async_Open_Flag THEN
      Async_Close( FALSE );
                             (* Choose communications port *)

   IF ( ComPort < 1 ) THEN
      ComPort := 1
   ELSE IF ( ComPort > MaxComPorts ) THEN
      ComPort := MaxComPorts;

   Async_Port  := ComPort;
   Async_Base  := Com_Base [ ComPort ];
   Async_Irq   := Com_Irq  [ ComPort ];
   Async_Int   := Com_Int  [ ComPort ];

                                   (* Set register pointers for ISR routine *)

   Async_Uart_IER  := Async_Base + UART_IER;
   Async_Uart_IIR  := Async_Base + UART_IIR;
   Async_Uart_MSR  := Async_Base + UART_MSR;
   Async_Uart_LSR  := Async_Base + UART_LSR;
   Async_Uart_MCR  := Async_Base + UART_MCR;

                                   (* Check if given port installed *)

   IF ( Port[UART_IIR + Async_Base] AND $00F8 ) <> 0 THEN
      Async_Open := FALSE          (* Serial port not installed *)
   ELSE
      BEGIN   (* Open the port *)

                                   (* Get current interrupt address *)

         GetIntVec( Async_Int , Async_Save_Iaddr );

                                   (* Set interrupt routine address *)

         SetIntVec( Async_Int , @Async_Isr );

                                   (* Set up UART                   *)

         Async_Reset_Port( ComPort, BaudRate, Parity, WordSize, StopBits );

                                   (* Remember that port is open *)
         Async_Open      := TRUE;
         Async_Open_Flag := TRUE;

    END;

END   (* Async_Open *);

