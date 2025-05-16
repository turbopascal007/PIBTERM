(*----------------------------------------------------------------------*)
(* Async_Find_Delay  --- Finds delay loop value for 1 millesecond delay *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Find_Delay( VAR One_MS_Delay : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*      Procedure: Async_Find_Delay                                     *)
(*                                                                      *)
(*      Purpose:   Finds loop count value to effect 1 ms delay          *)
(*                                                                      *)
(*      Calling Sequence:                                               *)
(*                                                                      *)
(*         Async_Find_Delay( VAR One_MS_Delay : INTEGER );              *)
(*                                                                      *)
(*            One_MS_Delay --- Resulting loop count for 1 ms delay      *)
(*                                                                      *)
(*      Using result:                                                   *)
(*                                                                      *)
(*            Use loop of form:                                         *)
(*                                                                      *)
(*                      MOV    CX,[>One_MS_Delay]                       *)
(*               Delay: LOOP   Delay                                    *)
(*                                                                      *)
(*            to delay for 1 ms.                                        *)
(*                                                                      *)
(*      Remarks:                                                        *)
(*                                                                      *)
(*         This routine watches over the CPU elapsed timer value for    *)
(*         just one timer interval (55 milleseconds).  During that time *)
(*         we run a tight loop and accumulate the ticks.  The result    *)
(*         is the number of ticks required for a 55 ms delay.  The      *)
(*         ticks for a 1 ms delay = ( ticks for 55 ms ) / 55.           *)
(*                                                                      *)
(*         To avoid overflow problems on fast machines, and to ease the *)
(*         worry about storing results at the second timer tick, we     *)
(*         break up the single long tight loop into a series of short   *)
(*         loops inside an outer loop.  We check if the timer has       *)
(*         expired at the end of each inner short loop.  Then the       *)
(*         time for the 55 ms delay is:                                 *)
(*                                                                      *)
(*            Ticks_for_55 := Inner_Ticks * Outer_Ticks;                *)
(*                                                                      *)
(*         and the corresponding 1 ms delay is:                         *)
(*                                                                      *)
(*            Ticks_For_1  := Ticks_For_55 DIV 55;                      *)
(*                                                                      *)
(*         To simplify things, we choose the inner tick value to be     *)
(*         2 x 55 = 110.  Then:                                         *)
(*                                                                      *)
(*            Ticks_For_1  := ( 110 * Outer_Ticks ) / 55;  ==>          *)
(*            Ticks_For_1  := 2 * Outer_Ticks;                          *)
(*                                                                      *)
(*         The CPU timer is located in four bytes at $0000:$46C.        *)
(*         Interrupt $1A also returns these bytes, but using the        *)
(*         interrupt results in an inaccurate loop count value.         *)
(*                                                                      *)
(*         Thanks to Brian Foley and Kim Kokonnen for help with this    *)
(*         problem.                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

(* STRUCTURED *) CONST
   Hi_Timer         : INTEGER = 0  (* Saves high portion of timer        *);
   Lo_Timer         : INTEGER = 0  (* Saves low portion of timer         *);
   OutCount         : INTEGER = 0  (* Accumulates outer loop counts      *);

BEGIN (* Async_Find_Delay *)

INLINE(
                             {;}
  $31/$C0/                   {          XOR    AX,AX                 ;Clear AX to zero}
  $8E/$C0/                   {          MOV    ES,AX                 ;Allow low-memory access}
                             {;}
  $C7/$06/>OUTCOUNT/$00/$00/ {          MOV    WORD [>OutCount],0    ;Clear outer loop counter}
                             {;}
  $FA/                       {          CLI                          ;No interrupts while reading}
  $26/$8B/$0E/>$46E/         {      ES: MOV    CX,[>$46E]            ;Hi part of CPU timer value}
  $26/$8B/$16/>$46C/         {      ES: MOV    DX,[>$46C]            ;Lo part of CPU timer value}
  $FB/                       {          STI                          ;Interrupts back on}
                             {;}
  $89/$0E/>HI_TIMER/         {          MOV    [>Hi_Timer],CX        ;Save hi part of timer}
  $89/$16/>LO_TIMER/         {          MOV    [>Lo_Timer],DX        ;Save low part of timer}
                             {;}
  $FA/                       {Loop1:    CLI                          ;No interrupts while reading}
                             {;}
  $26/$8B/$0E/>$46E/         {      ES: MOV    CX,[>$46E]            ;Hi part of CPU timer value}
  $26/$8B/$16/>$46C/         {      ES: MOV    DX,[>$46C]            ;Lo part of CPU timer value}
                             {;}
  $FB/                       {          STI                          ;Interrupts back on}
                             {;}
  $89/$C8/                   {          MOV    AX,CX                 ;Save CX and DX for later}
  $89/$D3/                   {          MOV    BX,DX}
                             {;}
  $2B/$06/>HI_TIMER/         {          SUB    AX,[>Hi_Timer]        ;Subtract low order part}
  $1B/$1E/>LO_TIMER/         {          SBB    BX,[>Lo_Timer]        ;Subtract high order part}
                             {;}
  $74/$E6/                   {          JE     Loop1                 ;Continue until non-0 tick difference}
                             {;}
  $89/$0E/>HI_TIMER/         {          MOV    [>Hi_Timer],CX        ;Save hi part}
  $89/$16/>LO_TIMER/         {          MOV    [>Lo_Timer],DX        ;Save low part}
                             {;}
  $B9/$6E/$00/               {Loop2:    MOV    CX,110                ;Run short delay loop.}
  $E2/$FE/                   {Delay:    LOOP   Delay}
                             {;}
  $FA/                       {          CLI                          ;No interrupts while reading}
                             {;}
  $26/$8B/$0E/>$46E/         {      ES: MOV    CX,[>$46E]            ;Hi part of CPU timer value}
  $26/$8B/$16/>$46C/         {      ES: MOV    DX,[>$46C]            ;Lo part of CPU timer value}
                             {;}
  $FB/                       {          STI                          ;Interrupts back on}
                             {;}
  $FF/$06/>OUTCOUNT/         {          INC    WORD [>OutCount]      ;Increment outer loop count}
                             {;}
  $2B/$0E/>HI_TIMER/         {          SUB    CX,[>Hi_Timer]        ;Subtract low order part}
  $1B/$16/>LO_TIMER/         {          SBB    DX,[>Lo_Timer]        ;Subtract high order part}
                             {;}
  $74/$E1/                   {          JE     Loop2                 ;Keep going if next tick not found}
                             {;}
  $A1/>OUTCOUNT/             {          MOV    AX,[>OutCount]        ;Pick up outer loop counter}
  $D1/$E0/                   {          SHL    AX,1                  ;* 2 = ticks for 1 ms delay}
                             {;}
  $C4/$BE/>ONE_MS_DELAY/     {          LES    DI,[BP+>One_MS_Delay] ;Get address of result}
  $26/$89/$05);              {      ES: MOV    [DI],AX               ;Store result}

END   (* Async_Find_Delay *);

(*----------------------------------------------------------------------*)
(*               Async_Init --- Initialize Asynchronous Variables       *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Init( Async_Buffer_Max  : INTEGER;
                      Async_OBuffer_Max : INTEGER;
                      Async_High_Lev1   : INTEGER;
                      Async_High_Lev2   : INTEGER;
                      Async_Low_Lev     : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Init                                           *)
(*                                                                      *)
(*     Purpose:    Initializes variables                                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*         Async_Init( Async_Buffer_Max  : INTEGER;                     *)
(*                     Async_OBuffer_Max : INTEGER;                     *)
(*                     Async_High_Lev1   : INTEGER;                     *)
(*                     Async_High_Lev2   : INTEGER;                     *)
(*                     Async_Low_Lev     : INTEGER );                   *)
(*                                                                      *)
(*     Calls:  Async_Find_Delay                                         *)
(*             TurnOffTimeSharing                                       *)
(*             TurnOnTimeSharing                                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;

(*----------------------------------------------------------------------*)

BEGIN   (* Async_Init *)
                                   (* No port open yet.                 *)
   Async_Open_Flag        := FALSE;

                                   (* No XON/XOFF handling yet.         *)
   Async_XOFF_Sent        := FALSE;
   Async_XOFF_Received    := FALSE;
   Async_XOFF_Rec_Display := FALSE;
   Async_XON_Rec_Display  := FALSE;
   Async_Send_XOFF        := FALSE;

                                   (* Sender not enabled.               *)
   Async_Sender_On        := FALSE;

                                   (* Set up empty receive buffer       *)
   Async_Buffer_Overflow  := FALSE;
   Async_Buffer_Used      := 0;
   Async_MaxBufferUsed    := 0;
   Async_Buffer_Head      := 0;
   Async_Buffer_Tail      := 0;
                                   (* Set up empty send buffer.         *)
   Async_OBuffer_Overflow := FALSE;
   Async_OBuffer_Used     := 0;
   Async_MaxOBufferUsed   := 0;
   Async_OBuffer_Head     := 0;
   Async_OBuffer_Tail     := 0;
                                   (* Set default wait time for output   *)
                                   (* buffer to drain when it fills up.  *)
   Async_Output_Delay     := 500;

                                   (* No modem or line errors yet.       *)
   Async_Line_Status      := 0;
   Async_Modem_Status     := 0;
   Async_Line_Error_Flags := 0;

                                   (* Get buffer sizes *)

   IF ( Async_Buffer_Max > 0 ) THEN
      Async_Buffer_Size := Async_Buffer_Max  - 1
   ELSE
      Async_Buffer_Size := 4095;

   IF ( Async_OBuffer_Max > 0 ) THEN
      Async_OBuffer_Size := Async_OBuffer_Max - 1
   ELSE
      Async_OBuffer_Size := 1131;

                                   (* Get receive buffer overflow *)
                                   (* check-points.               *)
   IF ( Async_Low_Lev > 0 ) THEN
      Async_Buffer_Low := Async_Low_Lev
   ELSE
      Async_Buffer_Low := Async_Buffer_Size DIV 4;

   IF ( Async_High_Lev1 > 0 ) THEN
      Async_Buffer_High := Async_High_Lev1
   ELSE
      Async_Buffer_High := ( Async_Buffer_Size DIV 4 ) * 3;

   IF ( Async_High_Lev2 > 0 ) THEN
      Async_Buffer_High_2 := Async_High_Lev2
   ELSE
      Async_Buffer_High_2 := ( Async_Buffer_Size DIV 10 ) * 9;

                                   (* Allocate buffers *)

   GETMEM( Async_Buffer_Ptr  , Async_Buffer_Size  + 1 );
   GETMEM( Async_OBuffer_Ptr , Async_OBuffer_Size + 1 );

                                   (* No UART addresses defined yet *)
   Async_Uart_IER         := 0;
   Async_Uart_IIR         := 0;
   Async_Uart_MSR         := 0;
   Async_Uart_LSR         := 0;
   Async_Uart_MCR         := 0;
                                   (* Set default port addresses *)
                                   (* and default IRQ lines      *)
   FOR I := 1 TO MaxComPorts DO
      BEGIN
         Com_Base[I]  := Default_Com_Base [I];
         Com_Irq [I]  := Default_Com_Irq  [I];
         Com_Int [I]  := Default_Com_Int  [I];
      END;
                                   (* Get the delay loop value for 1 ms *)
                                   (* delay loops.                      *)

(* ---- You should turn off time sharing if running under a multitasker *)
(* ---- to get an accurate delay loop value.  If MTASK is $DEFINEd,     *)
(* ---- then the calls to the PibMDos routines for interfacing with     *)
(* ---- multitaskers will be generated.                                 *)

{$IFDEF MTASK}
   IF TimeSharingActive THEN
      TurnOffTimeSharing;
{$ENDIF}

   Async_Find_Delay( Async_OneMSDelay );

{$IFDEF MTASK}
   IF TimeSharingActive THEN
      TurnOnTimeSharing;
{$ENDIF}

END     (* Async_Init *);

(*----------------------------------------------------------------------*)
(*      Async_Carrier_Detect --- Check for modem carrier detect         *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Carrier_Detect : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Carrier_Detect                                 *)
(*                                                                      *)
(*     Purpose:    Looks for modem carrier detect                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Carrier_Detect : BOOLEAN;                       *)
(*                                                                      *)
(*           Flag is set TRUE if carrier detected, else FALSE.          *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Async_Carrier_Detect *)

   Async_Carrier_Detect := ODD( Port[ UART_MSR + Async_Base ] SHR 7 ) OR
                           Async_Hard_Wired_On;

END   (* Async_Carrier_Detect *);

(*----------------------------------------------------------------------*)
(*      Async_Carrier_Drop --- Check for modem carrier drop/timeout     *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Carrier_Drop : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Carrier_Drop                                   *)
(*                                                                      *)
(*     Purpose:    Looks for modem carrier drop/timeout                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Carrier_Drop : BOOLEAN;                         *)
(*                                                                      *)
(*           Flag is set TRUE if carrier dropped, else FALSE.           *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Async_Carrier_Drop *)

   Async_Carrier_Drop := NOT ( ODD( Port[ UART_MSR + Async_Base ] SHR 7 ) OR
                               Async_Hard_Wired_On );

END   (* Async_Carrier_Drop *);

(*----------------------------------------------------------------------*)
(*      Async_Term_Ready --- Set terminal ready status                  *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Term_Ready( Ready_Status : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Term_Ready                                     *)
(*                                                                      *)
(*     Purpose:    Sets terminal ready status                           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Term_Ready( Ready_Status : BOOLEAN );                   *)
(*                                                                      *)
(*           Ready_Status --- Set TRUE to set terminal ready on,        *)
(*                            Set FALSE to set terminal ready off.      *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Mcr_Value: BYTE;

BEGIN (* Async_Term_Ready *)

   Mcr_Value := Port[ UART_MCR + Async_Base ];

   IF ODD( Mcr_Value ) THEN Mcr_Value := Mcr_Value - 1;

   IF Ready_Status THEN Mcr_Value := Mcr_Value + 1;

   Port[ UART_MCR + Async_Base ] := Mcr_Value;

   Async_Clear_Errors;

END   (* Async_Term_Ready *);

(*----------------------------------------------------------------------*)
(*          Async_Buffer_Check --- Check if character in buffer         *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Buffer_Check : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Buffer_Check                                   *)
(*                                                                      *)
(*     Purpose:    Check if character in buffer                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Buffer_Check : BOOLEAN;                         *)
(*                                                                      *)
(*           Flag returned TRUE if character received in buffer,        *)
(*           Flag returned FALSE if no character received.              *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*       This routine only checks if a character has been received      *)
(*       and thus can be read; it does NOT return the character.        *)
(*       Use Async_Receive to read the character.                       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN   (* Async_Buffer_Check *)

   Async_Buffer_Check := ( Async_Buffer_Head <> Async_Buffer_Tail );

END     (* Async_Buffer_Check *);

(*----------------------------------------------------------------------*)
(*          Async_Line_Error --- Check if line status error occurred    *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Line_Error( VAR Error_Flags: BYTE ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Line_Error                                     *)
(*                                                                      *)
(*     Purpose:    Check if line status error occurred                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Line_Error(VAR Error_Flags: BYTE): BOOLEAN;   *)
(*                                                                      *)
(*           Error_Flags --- Current error flags                        *)
(*                                                                      *)
(*           Flag returned TRUE if line status error occurred,          *)
(*           Flag returned FALSE if no error.                           *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The line status error flag is cleared here.                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN   (* Async_Line_Error *)

   Async_Line_Error       := ( Async_Line_Error_Flags <> 0 );
   Error_Flags            := Async_Line_Error_Flags;
   Async_Line_Error_Flags := 0;

END     (* Async_Line_Error  *);

(*----------------------------------------------------------------------*)
(*            Async_Ring_Detect --- Check for phone ringing             *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Ring_Detect : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Ring_Detect                                    *)
(*                                                                      *)
(*     Purpose:    Looks for phone ringing                              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Flag := Async_Ring_Detect : BOOLEAN;                          *)
(*                                                                      *)
(*           Flag is set TRUE if ringing detected, else FALSE.          *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Async_Ring_Detect *)

   Async_Ring_Detect := ODD( Port[ UART_MSR + Async_Base ] SHR 6 );

END   (* Async_Ring_Detect *);

(*----------------------------------------------------------------------*)
(*          Async_Send_Break --- Send break (attention) signal          *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Send_Break;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Send_Break                                     *)
(*                                                                      *)
(*     Purpose:    Sends break signal over communications port          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Send_Break;                                             *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Old_Lcr   : BYTE;
   Break_Lcr : BYTE;

BEGIN (* Async_Send_Break *)

   Old_Lcr   := Port[ UART_LCR + Async_Base ];
   Break_Lcr := Old_Lcr;

   IF Break_Lcr >  127 THEN Break_Lcr := Break_Lcr - 128;
   IF Break_Lcr <=  63 THEN Break_Lcr := Break_Lcr +  64;

   Port[ UART_LCR + Async_Base ] := Break_Lcr;

   DELAY( Async_Break_Length * 10 );

   Port[ UART_LCR + Async_Base ] := Old_Lcr;

END   (* Async_Send_Break *);

(*----------------------------------------------------------------------*)
(*     Async_Send_String --- Send string over communications port       *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Send_String( S : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Send_String                                    *)
(*                                                                      *)
(*     Purpose:    Sends string out over communications port            *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Send_String( S : AnyStr );                              *)
(*                                                                      *)
(*           S --- String to send                                       *)
(*                                                                      *)
(*     Calls:  Async_Send                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I : INTEGER;

BEGIN  (* Async_Send_String *)

  FOR I := 1 TO LENGTH( S ) DO
     Async_Send( S[I] )

END    (* Async_Send_String *);

(*----------------------------------------------------------------------*)
(*     Async_Send_String_With_Delays --- Send string with timed delays  *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Send_String_With_Delays( S          : AnyStr;
                                         Char_Delay : INTEGER;
                                         EOS_Delay  : INTEGER  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Send_String_With_Delays                        *)
(*                                                                      *)
(*     Purpose:    Sends string out over communications port with       *)
(*                 specified delays for each character and at the       *)
(*                 end of the string.                                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Send_String_With_Delays( S          : AnyStr ;          *)
(*                                       Char_Delay : INTEGER;          *)
(*                                       EOS_Delay  : INTEGER );        *)
(*                                                                      *)
(*           S          --- String to send                              *)
(*           Char_Delay --- Number of milliseconds to delay after       *)
(*                          sending each character                      *)
(*           EOS_Delay  --- Number of milleseconds to delay after       *)
(*                          sending last character in string            *)
(*                                                                      *)
(*     Calls:  Async_Send                                               *)
(*             Async_Send_String                                        *)
(*             Length                                                   *)
(*             Delay                                                    *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine is useful when writing routines to perform       *)
(*        non-protocol uploads.  Many computer systems require delays   *)
(*        between receipt of characters for correct processing.  The    *)
(*        delay for end-of-string usually applies when the string       *)
(*        represents an entire line of a file.                          *)
(*                                                                      *)
(*        If delays are not required, Async_Send_String is faster.      *)
(*        This routine will call Async_Send_String is no character      *)
(*        delay is to be done.                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I : INTEGER;

BEGIN  (* Async_Send_String_With_Delays *)

   IF Char_Delay <= 0 THEN
      Async_Send_String( S )
   ELSE
      FOR I := 1 TO LENGTH( S ) DO
         BEGIN
            Async_Send( S[I] );
            Delay( Char_Delay );
         END;

   IF EOS_Delay > 0 THEN Delay( EOS_Delay );

END    (* Async_Send_String_With_Delays *);

(*----------------------------------------------------------------------*)
(*      Async_Percentage_Used --- Report Percentage Buffer Filled       *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Percentage_Used : REAL;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Percent_Used                                   *)
(*                                                                      *)
(*     Purpose:    Reports percentage of com buffer currently filled    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Percentage := Async_Percentage_Used : Real;                   *)
(*                                                                      *)
(*           Percentage gets how much of buffer is filled;              *)
(*           value goes from 0.0 (empty) to 1.0 (totally full).         *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*       This routine is helpful when incorporating handshaking into    *)
(*       a communications program.  For example, assume that the host   *)
(*       computer uses the XON/XOFF (DC1/DC3) protocol.  Then the       *)
(*       PC program should issue an XOFF  to the host when the value    *)
(*       returned by Async_Percentage_Used > .75 or so.  When the       *)
(*       utilization percentage drops below .25 or so, the PC program   *)
(*       should transmit an XON.                                        *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Async_Percentage_Used *)

   Async_Percentage_Used := Async_Buffer_Used / ( Async_Buffer_Size + 1 );

END   (* Async_Percentage_Used *);

(*----------------------------------------------------------------------*)
(*     Async_Purge_Buffer --- Purge communications input buffer         *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Purge_Buffer;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Purge_Buffer                                   *)
(*                                                                      *)
(*     Purpose:    Purges communications input buffer                   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Purge_Buffer;                                           *)
(*                                                                      *)
(*     Calls:  Async_Receive                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   C: CHAR;
   L: INTEGER;

BEGIN  (* Async_Purge_Buffer *)

   L     := 10000 DIV Async_Baud_Rate;

   IF L <= 0 THEN
      L := 3;

   REPEAT
      DELAY( L )
   UNTIL ( NOT Async_Receive( C ) );

END    (* Async_Purge_Buffer *);

(*----------------------------------------------------------------------*)
(*          Async_Peek --- Peek ahead in communications buffer          *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Peek( Nchars : INTEGER ) : CHAR;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Async_Peek                                           *)
(*                                                                      *)
(*     Purpose:    Peeks ahead in comm buffer                           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Ch := Async_Peek( NChars: INTEGER) : CHAR;                    *)
(*                                                                      *)
(*           NChars --- # of characters to peek ahead                   *)
(*           Ch     --- returned (peeked) character                     *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;

BEGIN (* Async_Peek *)

   I := ( Async_Buffer_Tail + NChars ) MOD Async_Buffer_Size;

   IF ( I > Async_Buffer_Head ) THEN
      Async_Peek := CHR( 0 )
   ELSE
      Async_Peek := Async_Buffer_Ptr^[ I ];

END   (* Async_Peek *);

(*----------------------------------------------------------------------*)
(*         Async_Setup_Port --- Setup port address and IRQ line         *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Setup_Port( ComPort       : INTEGER;
                            Base_Address  : INTEGER;
                            IRQ_Line      : INTEGER;
                            Int_Numb      : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Setup_Port                                     *)
(*                                                                      *)
(*     Purpose:    Sets up port address and IRQ line                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Setup_Port( ComPort       : INTEGER;                    *)
(*                          Base_Address  : INTEGER;                    *)
(*                          IRQ_Line      : INTEGER;                    *)
(*                          Int_Numb      : INTEGER );                  *)
(*                                                                      *)
(*           ComPort      --- which port (1 though MaxComPorts)         *)
(*           Base_Address --- Base address of port.  If -1, then        *)
(*                            standard default address used.            *)
(*           IRQ_Line     --- IRQ line for interrupts for port.  If -1, *)
(*                            then standard default irq line used.      *)
(*           Int_Numb     --- Interrupt vector number for port.  If -1, *)
(*                            then standard default interrupt # used.   *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Port_Offset : INTEGER;

BEGIN  (* Async_Setup_Port *)

   IF ( ( ComPort > 0 ) AND ( ComPort <= MaxComPorts ) ) THEN
      BEGIN
         IF ( Base_Address = -1 ) THEN
            Base_Address := Default_Com_Base[ComPort];
         IF ( IRQ_Line = -1 ) THEN
            IRQ_Line := Default_Com_IRQ[ComPort];
         IF ( Int_Numb = -1 ) THEN
            Int_Numb := Default_Com_Int[ComPort];
         Com_Base [ComPort]   := Base_Address;
         Com_Irq  [ComPort]   := IRQ_Line;
         Com_Int  [ComPort]   := Int_Numb;
         Port_Offset          := RS232_Base + ( PRED( ComPort ) SHL 1 );
         MemW[$0:Port_Offset] := Base_Address;
      END;

END    (* Async_Setup_Port *);

(*----------------------------------------------------------------------*)
(*         Async_Release_Buffers --- Release buffers for serial ports   *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Release_Buffers;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Release_Buffers;                               *)
(*                                                                      *)
(*     Purpose:    Releases send and receive buffers                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Release_Buffers;                                        *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Async_Release_Buffers *)

                             (* If port open, close it down first.  *)
   IF Async_Open_Flag THEN
      Async_Close( FALSE );

   FREEMEM( Async_Buffer_Ptr  , Async_Buffer_Size  + 1 );
   FREEMEM( Async_OBuffer_Ptr , Async_OBuffer_Size + 1 );

END    (* Async_Release_Buffers *);

(*----------------------------------------------------------------------*)
(*   Async_Flush_Output_Buffer --- Flush output buffer for serial port  *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Flush_Output_Buffer;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Flush_Output_Buffer;                           *)
(*                                                                      *)
(*     Purpose:    Flushes output buffer for serial port.               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Flush_Output_Buffer;                                    *)
(*                                                                      *)
(*     Calls:  None                                                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN  (* Async_Flush_Output_Buffer *)

   Async_OBuffer_Head  := Async_OBuffer_Tail;
   Async_OBuffer_Used  := 0;

END    (* Async_Flush_Output_Buffer *);

(*----------------------------------------------------------------------*)
(*   Async_Drain_Output_Buffer --- Wait for output buffer to drain      *)
(*----------------------------------------------------------------------*)

PROCEDURE Async_Drain_Output_Buffer( Max_Wait_Time : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Drain_Output_Buffer;                           *)
(*                                                                      *)
(*     Purpose:    Waits for output buffer to drain.                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Async_Drain_Output_Buffer( Max_Wait_Time : INTEGER );         *)
(*                                                                      *)
(*           Max_Wait_Time --- Maximum # of seconds to wait for         *)
(*                             output buffer to drain.                  *)
(*                                                                      *)
(*     Calls:  TimeOfDay                                                *)
(*             TimeDiff                                                 *)
(*             GiveUpTime                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   T1 : LONGINT;

BEGIN  (* Async_Drain_Output_Buffer *)

   T1 := TimeOfDay;

   WHILE( ( Async_OBuffer_Head <> Async_OBuffer_Tail    ) AND
          ( TimeDiff( T1 , TimeOfDay ) <= Max_Wait_Time )     ) DO
{$IFDEF MTASK}
      GiveUpTime( 1 );
{$ELSE}
      ;
{$ENDIF}

END    (* Async_Drain_Output_Buffer *);

(*----------------------------------------------------------------------*)
(*   Async_Port_Address_Given --- Check if port address in memory       *)
(*----------------------------------------------------------------------*)

FUNCTION Async_Port_Address_Given( Com_Port : INTEGER ) : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Async_Port_Address_Given;                            *)
(*                                                                      *)
(*     Purpose:    Checks if port address in memory.                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        There := Async_Port_Address_Given( Com_Port : INTEGER ) :     *)
(*                                         BOOLEAN;                     *)
(*                                                                      *)
(*           Com_Port --- Port to check (1 through MaxComPorts)         *)
(*           There    --- TRUE if port address in memory.               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Port_Offset : INTEGER;

BEGIN  (* Async_Port_Address_Given *)

   IF ( ( Com_Port > 0 ) AND ( Com_Port < MaxComPorts ) ) THEN
      BEGIN
         Port_Offset              := RS232_Base + ( PRED( Com_Port ) SHL 1 );
         Async_Port_Address_Given := ( MemW[$0:Port_Offset] <> 0 );
      END
   ELSE
      Async_Port_Address_Given := FALSE;

END    (* Async_Port_Address_Given *);
