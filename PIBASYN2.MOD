(*----------------------------------------------------------------------*)
(*          Async_Send --- Send character over communications port      *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Send( C : Char );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Send                                           *)
(*                                                                      *)
(*     Purpose:    Sends character out over communications port         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Send( C : Char );                                       *)
(*                                                                      *)
(*           C --- Character to send                                    *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN   (* Async_Send *)

INLINE(
  $8B/$1E/>ASYNC_OBUFFER_HEAD/         {         MOV     BX,[>Async_OBuffer_Head]   ;Get output queue head pointer}
  $C4/$3E/>ASYNC_OBUFFER_PTR/          {         LES     DI,[>Async_OBuffer_Ptr]    ;Pick up output buffer address}
  $01/$DF/                             {         ADD     DI,BX                      ;Position to current character}
                                       {;}
  $89/$DA/                             {         MOV     DX,BX                      ;Save previous head pointer}
  $43/                                 {         INC     BX                         ;Increment head pointer}
  $3B/$1E/>ASYNC_OBUFFER_SIZE/         {         CMP     BX,[>Async_OBuffer_Size]   ;See if past end of buffer}
  $7E/$02/                             {         JLE     Send1                      ;Skip if not}
  $31/$DB/                             {         XOR     BX,BX                      ;Wrap to start of buffer}
                                       {;}
  $3B/$1E/>ASYNC_OBUFFER_TAIL/         {Send1:   CMP     BX,[>Async_OBuffer_Tail]   ;See if head collided with tail}
  $75/$1C/                             {         JNE     Send4                      ;No -- buffer didn't fill up}
                                       {;}
  $8B/$0E/>ASYNC_OUTPUT_DELAY/         {         MOV     CX,[>Async_Output_Delay]   ;Run delay loop and see if buffer drains}
                                       {;}
  $51/                                 {Send2:   PUSH    CX                         ;Save milleseconds to go}
  $8B/$0E/>ASYNC_ONEMSDELAY/           {         MOV     CX,[>Async_OneMSDelay]     ;Get delay loop value for 1 ms}
                                       {;}
  $E2/$FE/                             {Send3:   LOOP    Send3                      ;Tight loop for 1 ms delay}
                                       {;}
  $59/                                 {         POP     CX                         ;Get back millesecond count}
                                       {;}
  $3B/$1E/>ASYNC_OBUFFER_TAIL/         {         CMP     BX,[>Async_OBuffer_Tail]   ;See if buffer drained yet}
  $75/$0A/                             {         JNE     Send4                      ;Yes -- OK, stop delay loop.}
                                       {;}
  $E2/$F0/                             {         LOOP    Send2                      ;Decrement millesecond count and loop}
                                       {;}
  $C6/$06/>ASYNC_OBUFFER_OVERFLOW/$01/ {         MOV     BYTE [>Async_OBuffer_Overflow],1 ;Indicate output buffer overflow}
  $E9/$1A/$00/                         {         JMP     Send5                      ;Skip updating head pointers}
                                       {;}
  $89/$1E/>ASYNC_OBUFFER_HEAD/         {Send4:   MOV     [>Async_OBuffer_Head],BX   ;Save updated head pointer}
  $8A/$46/<C/                          {         MOV     AL,[BP+<C]                 ;Pick up character to send}
  $26/$88/$05/                         {     ES: MOV     [DI],AL                    ;Place character in output buffer}
                                       {;}
  $A1/>ASYNC_OBUFFER_USED/             {         MOV     AX,[>Async_OBuffer_Used]   ;Get buffer use count}
  $40/                                 {         INC     AX                         ;Increment buffer use count}
  $A3/>ASYNC_OBUFFER_USED/             {         MOV     [>Async_OBuffer_Used],AX   ;Save new count}
  $3B/$06/>ASYNC_MAXOBUFFERUSED/       {         CMP     AX,[>Async_MaxOBufferUsed] ;See if larger than ever before}
  $7E/$03/                             {         JLE     Send5                      ;Skip if not}
  $A3/>ASYNC_MAXOBUFFERUSED/           {         MOV     [>Async_MaxOBufferUsed],AX ;Save new maximum usage}
                                       {;}
  $8B/$16/>ASYNC_UART_IER/             {Send5:   MOV     DX,[>Async_Uart_IER]       ;Get interrupt enable register}
  $EC/                                 {         IN      AL,DX                      ;Check contents of IER}
  $A8/$02/                             {         TEST    AL,2                       ;See if write interrupt enabled}
  $75/$03/                             {         JNZ     Send6                      ;Skip if so}
  $0C/$02/                             {         OR      AL,2                       ;Else enable write interrupts ...}
  $EE);                                {         OUT     DX,AL                      ;... by rewriting IER contents}
                                       {;}
                                       {Send6:}

END    (* Async_Send *);

(*----------------------------------------------------------------------*)
(*          Async_Receive --- Return character from buffer              *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Receive( VAR C : Char ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Receive                                        *)
(*                                                                      *)
(*     Purpose:    Retrieve character (if any) from buffer              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Receive( VAR C: Char ) : BOOLEAN;               *)
(*                                                                      *)
(*           C --- character (if any) retrieved from buffer;            *)
(*                 set to CHR(0) if no character available.             *)
(*                                                                      *)
(*           Flag returned TRUE if character retrieved from buffer,     *)
(*           Flag returned FALSE if no character retrieved.             *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN   (* Async_Receive *)

INLINE(
                                  {;}
                                  {;  Check if any characters in input comm buffer}
                                  {;}
  $A1/>ASYNC_BUFFER_TAIL/         {         MOV   AX,[>Async_Buffer_Tail]}
  $3B/$06/>ASYNC_BUFFER_HEAD/     {         CMP   AX,[>Async_Buffer_Head]}
  $75/$0B/                        {         JNE   Rec1}
                                  {;}
                                  {;  Buffer is empty -- return NUL character}
                                  {;}
  $C4/$7E/<C/                     {         LES   DI,[BP+<C]                   ;Get character address}
  $31/$C0/                        {         XOR   AX,AX                        ;Clear out unused bits}
  $26/$88/$05/                    {     ES: MOV   [DI],AL                      ;NUL character}
  $E9/$69/$00/                    {         JMP   Return}
                                  {;}
                                  {;  Buffer not empty -- pick up next character.}
                                  {;}
  $C4/$3E/>ASYNC_BUFFER_PTR/      {Rec1:    LES   DI,[>Async_Buffer_Ptr]       ;Pick up buffer address}
  $01/$C7/                        {         ADD   DI,AX                        ;Add character offset}
  $26/$8A/$1D/                    {     ES: MOV   BL,[DI]                      ;Get character from buffer}
  $C4/$7E/<C/                     {         LES   DI,[BP+<C]                   ;Get result address}
  $26/$88/$1D/                    {     ES: MOV   [DI],BL                      ;Store character from buffer}
  $40/                            {         INC   AX                           ;Increment tail pointer}
  $3B/$06/>ASYNC_BUFFER_SIZE/     {         CMP   AX,[>Async_Buffer_Size]      ;Past end of buffer?}
  $7E/$02/                        {         JLE   Rec2                         ;No -- skip wrapping}
  $31/$C0/                        {         XOR   AX,AX                        ;Yes -- point to start of buffer}
  $A3/>ASYNC_BUFFER_TAIL/         {Rec2:    MOV   [>Async_Buffer_Tail],AX      ;Update tail pointer}
  $A1/>ASYNC_BUFFER_USED/         {         MOV   AX,[>Async_Buffer_Used]      ;Pick up amount of buffer used}
  $48/                            {         DEC   AX                           ;Update buffer use count}
  $A3/>ASYNC_BUFFER_USED/         {         MOV   [>Async_Buffer_Used],AX      ;}
                                  {;}
                                  {; Check how empty the receive buffer is.}
                                  {; We may have previously sent XOFF, or dropped RTS, to}
                                  {; stop sender from sending.  If so, and the buffer is}
                                  {; now empty enough, we should re-enable the sender.}
                                  {;}
  $F6/$06/>ASYNC_SENDER_ON/$01/   {         TEST  BYTE [<Async_Sender_On],1    ;See if sender enabled}
  $75/$3D/                        {         JNZ   Rec6                         ;Skip buffer tests if so}
                                  {;}
  $3B/$06/>ASYNC_BUFFER_LOW/      {         CMP   AX,[>Async_Buffer_Low]       ;Check if low enough}
  $7F/$37/                        {         JG    Rec6                         ;Still too full, skip}
                                  {;}
                                  {; Buffer is reasonably empty, send XON to get things rolling again}
                                  {; if XOFF previously sent.}
                                  {;}
  $F6/$06/>ASYNC_XOFF_SENT/$01/   {         TEST  BYTE [<Async_XOff_Sent],1    ;Check if Xoff sent}
  $74/$0D/                        {         JZ    Rec3                         ;No -- skip.}
                                  {;}
  $B8/>XON/                       {         MOV   AX,>XON                      ;Else push XON onto stack}
  $50/                            {         PUSH  AX}
  $FF/$1E/>ASYNC_SEND_ADDR/       {         CALL  FAR [>Async_Send_Addr]       ;Call output routine}
                                  {;}
  $C6/$06/>ASYNC_XOFF_SENT/$00/   {         MOV   BYTE [>Async_XOff_Sent],0    ;Clear Xoff flag}
                                  {;}
                                  {; If RTS dropped because buffer was too full, enable RTS.}
                                  {;}
  $F6/$06/>ASYNC_DO_CTS/$01/      {Rec3:    TEST    BYTE [<Async_Do_Cts],1     ;Check if CTS/RTS checking}
  $74/$08/                        {         JZ      Rec4                       ;No -- skip}
                                  {;}
  $8B/$16/>ASYNC_UART_MCR/        {         MOV     DX,[>Async_Uart_MCR]       ;Get modem control register}
  $EC/                            {         IN      AL,DX}
  $0C/<ASYNC_RTS/                 {         OR      AL,<Async_RTS              ;Enable RTS}
  $EE/                            {         OUT     DX,AL}
                                  {;}
                                  {; If DTR dropped because buffer was too full, enable DTR.}
                                  {;}
  $F6/$06/>ASYNC_DO_DSR/$01/      {Rec4:    TEST    BYTE [<Async_Do_Dsr],1     ;Check if DSR/DTR checking}
  $74/$08/                        {         JZ      Rec5                       ;No -- skip}
                                  {;}
  $8B/$16/>ASYNC_UART_MCR/        {         MOV     DX,[>Async_Uart_MCR]       ;Get modem control register}
  $EC/                            {         IN      AL,DX}
  $0C/<ASYNC_DTR/                 {         OR      AL,<Async_DTR              ;Enable DTR}
  $EE/                            {         OUT     DX,AL}
                                  {;}
  $C6/$06/>ASYNC_SENDER_ON/$01/   {Rec5:    MOV     BYTE [>Async_Sender_On],1  ;Indicate sender enabled}
                                  {;}
                                  {;  Indicate character found}
                                  {;}
  $B8/$01/$00/                    {Rec6:    MOV    AX,1}
                                  {;}
  $80/$26/>ASYNC_LINE_STATUS/$FD/ {Return:  AND    Byte [>Async_Line_Status],$FD ;Remove overflow flag}
  $09/$C0/                        {         OR     AX,AX                       ;Set zero flag to indicate return status}
  $89/$EC/                        {         MOV    SP,BP}
  $5D/                            {         POP    BP}
  $CA/$04/$00);                   {         RETF   4}

END   (* Async_Receive *);

(*----------------------------------------------------------------------*)
(*   Async_Receive_With_TimeOut --- Return char. from buffer with delay *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Receive_With_Timeout( Secs : INTEGER; VAR C : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Receive_With_Timeout                           *)
(*                                                                      *)
(*     Purpose:    Retrieve character as integer from buffer,           *)
(*                 or return TimeOut if specified delay period          *)
(*                 expires.                                             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Receive_With_Timeout( Secs: INTEGER; VAR C: INTEGER );  *)
(*                                                                      *)
(*           Secs ---  Timeout period in seconds                        *)
(*                     NOTE:  Cannot be longer than 32 seconds!         *)
(*           C     --- ORD(character) (if any) retrieved from buffer;   *)
(*                     set to TimeOut if no character found before      *)
(*                     delay period expires.                            *)
(*                                                                      *)
(*     Calls:  Async_Receive                                            *)
(*                                                                      *)
(*     WATCH OUT!  THIS ROUTINE RETURNS AN INTEGER, NOT A CHARACTER!!!  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Async_Receive_With_Timeout *)

INLINE(
                                  {;}
                                  {;  Check if a character in input comm buffer}
                                  {;}
  $A1/>ASYNC_BUFFER_TAIL/         {         MOV   AX,[>Async_Buffer_Tail]}
  $3B/$06/>ASYNC_BUFFER_HEAD/     {         CMP   AX,[>Async_Buffer_Head]}
  $75/$29/                        {         JNE   Rec1}
                                  {;}
                                  {;  Buffer empty -- begin wait loop.}
                                  {;}
  $8B/$46/<SECS/                  {         MOV   AX,[BP+<Secs]                 ;Get seconds to wait}
  $B9/$0A/$00/                    {         MOV   CX,10                         ;Shift count = 2 ** 10 = 1024}
  $D3/$E0/                        {         SHL   AX,CL                         ;Seconds * 1024 = milleseconds}
  $89/$C1/                        {         MOV   CX,AX                         ;Move to looping register}
                                  {;}
                                  {;  Delay for 1 ms.}
                                  {;}
  $51/                            {Delay:   PUSH  CX                            ;Save milleseconds to go}
  $8B/$0E/>ASYNC_ONEMSDELAY/      {         MOV   CX,[>Async_OneMSDelay]        ;Get delay loop value for 1 ms}
  $E2/$FE/                        {Delay1:  LOOP  Delay1                        ;Tight loop for 1 ms delay}
                                  {;}
                                  {;  Check if any character yet.}
                                  {;}
  $59/                            {         POP   CX                            ;Get back millesecond count}
                                  {;}
  $A1/>ASYNC_BUFFER_TAIL/         {         MOV   AX,[>Async_Buffer_Tail]}
  $3B/$06/>ASYNC_BUFFER_HEAD/     {         CMP   AX,[>Async_Buffer_Head]}
  $75/$0E/                        {         JNE   Rec1}
                                  {;}
                                  {;  Buffer still empty -- decrement elapsed time}
                                  {;}
  $E2/$ED/                        {         LOOP  Delay                         ;Decrement millesecond count and loop}
                                  {;}
                                  {;  Dropped through -- no character arrived in specified interval.}
                                  {;  Return TimeOut as result.}
                                  {;}
  $BB/>TIMEOUT/                   {         MOV   BX,>TimeOut                   ;Pick up timeout value}
  $C4/$7E/<C/                     {         LES   DI,[BP+<C]                    ;Get result character address}
  $26/$89/$1D/                    {    ES:  MOV   [DI],BX                       ;Store timeout value}
  $E9/$68/$00/                    {         JMP   Return                        ;Return to caller}
                                  {;}
                                  {;  Buffer not empty -- pick up next character.}
                                  {;}
  $C4/$3E/>ASYNC_BUFFER_PTR/      {Rec1:    LES   DI,[>Async_Buffer_Ptr]        ;Pick up buffer address}
  $01/$C7/                        {         ADD   DI,AX                         ;Add character offset}
  $26/$8A/$1D/                    {     ES: MOV   BL,[DI]                       ;Get character from buffer}
                                  {;}
  $30/$FF/                        {         XOR   BH,BH                         ;Clear high-order bits}
  $C4/$7E/<C/                     {         LES   DI,[BP+<C]                    ;Get result address}
  $26/$89/$1D/                    {     ES: MOV   [DI],BX                       ;Store character from buffer}
                                  {;}
  $40/                            {         INC   AX                            ;Increment tail pointer}
  $3B/$06/>ASYNC_BUFFER_SIZE/     {         CMP   AX,[>Async_Buffer_Size]       ;Past end of buffer?}
  $7E/$02/                        {         JLE   Rec2                          ;No -- skip wrapping}
  $31/$C0/                        {         XOR   AX,AX                         ;Yes -- point to start of buffer}
  $A3/>ASYNC_BUFFER_TAIL/         {Rec2:    MOV   [>Async_Buffer_Tail],AX       ;Update tail pointer}
  $A1/>ASYNC_BUFFER_USED/         {         MOV   AX,[>Async_Buffer_Used]       ;Pick up amount of buffer used}
  $48/                            {         DEC   AX                            ;Update buffer use count}
  $A3/>ASYNC_BUFFER_USED/         {         MOV   [>Async_Buffer_Used],AX       ;}
                                  {;}
                                  {; Check how empty the receive buffer is.}
                                  {; We may have previously sent XOFF, or dropped RTS, to}
                                  {; stop sender from sending.  If so, and the buffer is}
                                  {; now empty enough, we should re-enable the sender.}
                                  {;}
  $F6/$06/>ASYNC_SENDER_ON/$01/   {         TEST  BYTE [<Async_Sender_On],1     ;See if sender enabled}
  $75/$3D/                        {         JNZ   Return                        ;Skip buffer tests if so}
                                  {;}
  $3B/$06/>ASYNC_BUFFER_LOW/      {         CMP   AX,[>Async_Buffer_Low]        ;Check if low enough}
  $7F/$37/                        {         JG    Return                        ;Still too full, skip}
                                  {;}
                                  {; Buffer is reasonably empty, send XON to get things rolling again}
                                  {; if XOFF previously sent.}
                                  {;}
  $F6/$06/>ASYNC_XOFF_SENT/$01/   {         TEST  BYTE [<Async_XOff_Sent],1     ;Check if Xoff sent}
  $74/$0D/                        {         JZ    Rec3                          ;No -- skip.}
                                  {;}
  $B8/>XON/                       {         MOV   AX,>XON                       ;Else push XON onto stack}
  $50/                            {         PUSH  AX}
  $FF/$1E/>ASYNC_SEND_ADDR/       {         CALL  FAR [>Async_Send_Addr]        ;Call output routine}
                                  {;}
  $C6/$06/>ASYNC_XOFF_SENT/$00/   {         MOV   BYTE [>Async_XOff_Sent],0     ;Clear Xoff flag}
                                  {;}
                                  {; If RTS dropped because buffer was too full, enable RTS.}
                                  {;}
  $F6/$06/>ASYNC_DO_CTS/$01/      {Rec3:    TEST    BYTE [<Async_Do_Cts],1      ;Check if CTS/RTS checking}
  $74/$08/                        {         JZ      Rec4                        ;No -- skip}
                                  {;}
  $8B/$16/>ASYNC_UART_MCR/        {         MOV     DX,[>Async_Uart_MCR]        ;Get modem control register}
  $EC/                            {         IN      AL,DX}
  $0C/<ASYNC_RTS/                 {         OR      AL,<Async_RTS               ;Enable RTS}
  $EE/                            {         OUT     DX,AL}
                                  {;}
                                  {; If DTR dropped because buffer was too full, enable DTR.}
                                  {;}
  $F6/$06/>ASYNC_DO_DSR/$01/      {Rec4:    TEST    BYTE [<Async_Do_Dsr],1      ;Check if DSR/DTR checking}
  $74/$08/                        {         JZ      Rec5                        ;No -- skip}
                                  {;}
  $8B/$16/>ASYNC_UART_MCR/        {         MOV     DX,[>Async_Uart_MCR]        ;Get modem control register}
  $EC/                            {         IN      AL,DX}
  $0C/<ASYNC_DTR/                 {         OR      AL,<Async_DTR               ;Enable DTR}
  $EE/                            {         OUT     DX,AL}
                                  {;}
  $C6/$06/>ASYNC_SENDER_ON/$01/   {Rec5:    MOV     BYTE [>Async_Sender_On],1   ;Indicate sender enabled}
  $80/$26/>ASYNC_LINE_STATUS/$FD);{Return:  AND     Byte [>Async_Line_Status],$FD ;Remove overflow flag}

END   (* Async_Receive_With_Timeout *);

(*----------------------------------------------------------------------*)
(*        Async_Stuff --- Stuff character into receive buffer           *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Stuff( Ch: CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Stuff                                          *)
(*                                                                      *)
(*     Purpose:    Stuffs a character into receive buffer               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Stuff( Ch : Char );                                     *)
(*                                                                      *)
(*           Ch --- Character to stuff                                  *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   New_Head : INTEGER;

BEGIN (* Async_Stuff *)

   Async_Buffer_Ptr^[Async_Buffer_Head] := Ch;
   New_Head                             := SUCC( Async_Buffer_Head ) MOD
                                           SUCC( Async_Buffer_Size );

   IF ( New_Head = Async_Buffer_Tail ) THEN
      Async_Buffer_Overflow := TRUE
   ELSE
      BEGIN
         Async_Buffer_Head := New_Head;
         INC( Async_Buffer_Used );
         IF ( Async_Buffer_Used > Async_MaxBufferUsed ) THEN
            Async_MaxBufferUsed := Async_Buffer_Used;
      END;

END   (* Async_Stuff *);

(*----------------------------------------------------------------------*)
(*          Async_Wait_For_Quiet --- Wait for port to quiesce           *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Wait_For_Quiet( Max_Wait : LONGINT;
                               Wait_Time: LONGINT  ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Wait_For_Quiet                                 *)
(*                                                                      *)
(*     Purpose:    Waits for serial port input to quiesce.              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Wait_For_Quiet( Max_Wait  : LONGINT;                    *)
(*                              Wait_Time : LONGINT  ) : BOOLEAN;       *)
(*                                                                      *)
(*           Max_Wait   --- Total time in 1/100 seconds to wait for     *)
(*                          quiet.                                      *)
(*           Wait_Time  --- Length of time without receiving character  *)
(*                          which is assumed to mean port is quiet.     *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   T1   : LONGINT;
   W1   : LONGINT;
   Head : INTEGER;

BEGIN (* Async_Wait_For_Quiet *)
                                   (* Get current time of day *)
   T1 := TimeOfDayH;
                                   (* Outer loop runs over maximum time *)
                                   (* to wait for quiet spell to appear *)
   REPEAT
                                   (* Get time defining "quiet" for  *)
                                   (* our purposes in 1/100th secs.  *)
      W1 := Wait_Time;
                                   (* Delay 1/100th second and then  *)
                                   (* see if receive buffer head     *)
                                   (* has changed or not.  If head   *)
                                   (* changed, drop through to start *)
                                   (* check over again.              *)
      REPEAT
         DELAY( 10 );
         DEC  ( W1 );
      UNTIL  ( ( W1 = 0 ) OR ( Head <> Async_Buffer_Head ) );

                                   (* Check if maximum wait time is  *)
                                   (* exhausted -- quit if so.  Else *)
                                   (* if buffer head didn't change,  *)
                                   (* then port is quiet, so quit.   *)
                                   (* Else keep on going.            *)

   UNTIL ( ( TimeDiffH( T1 , TimeOfDay ) > Max_Wait ) OR
           ( Head = Async_Buffer_Head ) );

                                   (* If we dropped through with   *)
                                   (* the buffer head not changed, *)
                                   (* this means that the port     *)
                                   (* is quiet.                    *)

   Async_Wait_For_Quiet := ( Head = Async_Buffer_Head );

END   (* Async_Wait_For_Quiet *);

(*----------------------------------------------------------------------*)
(*      Async_Send_Now --- Send character over communications port      *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Send_Now( C : Char );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Send_Now                                       *)
(*                                                                      *)
(*     Purpose:    Sends character out over communications port         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Send_Now( C : Char );                                   *)
(*                                                                      *)
(*           C --- Character to send                                    *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine differs from Async_Send in that Async_Send_Now   *)
(*        transmits the given character as soon as possible, ignoring   *)
(*        the contents of the current output buffer.  This behavior     *)
(*        is useful if a character MUST be sent ASAP -- for example,    *)
(*        an XOFF.                                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   TimeOut : WORD;

BEGIN   (* Async_Send_Now *)

                   (* Turn on OUT2, DTR, and RTS *)

   Port[UART_MCR + Async_Base] := $0B;

                   (* Wait for DSR using Busy Wait *)

   IF Async_Do_DSR THEN
      BEGIN
         TimeOut := 65535;
         WHILE ( ( Port[UART_MSR + Async_Base] AND $20 ) = 0 ) AND
                 ( TimeOut > 0 ) DO
            DEC( TimeOut );
      END;

                   (* Wait for CTS using Busy Wait *)

   IF Async_Do_CTS THEN
      BEGIN
         TimeOut := 65535;
         WHILE ( ( Port[UART_MSR + Async_Base] AND $10 ) = 0 ) AND
                 ( TimeOut > 0 ) DO
            DEC( TimeOut );
      END;

                   (* Wait for Transmit Hold Register Empty (THRE) *)

   IF ( TimeOut > 0 ) THEN
      TimeOut := 65535;

   WHILE ( ( Port[UART_LSR + Async_Base] AND $20 ) = 0 ) AND
           ( TimeOut > 0 ) DO
      DEC( TimeOut );

                   (* Send the character when port clear *)

   INLINE($FA);                    (* CLI --- disable interrupts *)

   Port[UART_THR + Async_Base] := ORD( C );

   INLINE($FB);                    (* STI --- enable interrupts *)

END    (* Async_Send_Now *);
