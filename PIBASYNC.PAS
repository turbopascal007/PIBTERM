UNIT PibAsync;

(*----------------------------------------------------------------------*)
(*         PIBASYNC.PAS   --- Asynchronous I/O for Turbo Pascal         *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Author:  (c) 1985, 1986, 1987 by Philip R. Burns                    *)
(*                                                                      *)
(*  Version: 1.0   (January, 1985)                                      *)
(*           2.0   (June, 1985)                                         *)
(*           2.1   (July, 1985)                                         *)
(*           3.0   (October, 1985)                                      *)
(*           3.1   (October, 1985)                                      *)
(*           3.2   (November, 1985)                                     *)
(*           4.0   (October, 1986)                                      *)
(*           4.1   (December, 1986)                                     *)
(*           4.2   (January, 1987)                                      *)
(*           4.3   (March, 1987)                                        *)
(*           4.4   (July, 1987)                                         *)
(*           4.5   (November, 1987)                                     *)
(*           4.6   (January, 1988)                                      *)
(*           4.7   (February, 1988)                                     *)
(*                                                                      *)
(*  Systems: For MSDOS/PC DOS on IBM PCs and close compatibles only.    *)
(*                                                                      *)
(*  History: Some of these routines are based upon ones written by:     *)
(*                                                                      *)
(*              Alan Bishop                                             *)
(*              C. J. Dunford                                           *)
(*              Michael Quinlan                                         *)
(*              Gene Harris                                             *)
(*                                                                      *)
(*           I have cleaned up these other authors' code, fixed some    *)
(*           bugs, and added many new features.                         *)
(*                                                                      *)
(*           In particular, starting with v4.0 of PibTerm, both input   *)
(*           and output to the serial port is buffered and interrupt-   *)
(*           driven.  Also, XON/XOFF support has been moved to the      *)
(*           serial port interrupt handler, which results in fewer      *)
(*           overrun problems.                                          *)
(*                                                                      *)
(*           Suggestions for improvements or corrections are welcome.   *)
(*                                                                      *)
(*           If you use this code in your own programs, please be nice  *)
(*           and give proper credit.                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Routines:                                                           *)
(*                                                                      *)
(*     BIOS_RS232_Init        ---    Use BIOS to initialize port        *)
(*     Async_Isr              ---    Com port interrupt service routine *)
(*     Async_Init             ---    Performs initialization.           *)
(*     Async_Clear_Errors     ---    Clear pending serial port errors   *)
(*     Async_Reset_Port       ---    Resets UART parameters for port    *)
(*     Async_Open             ---    Sets up COM port                   *)
(*     Async_Close            ---    Closes down COM port               *)
(*     Async_Carrier_Detect   ---    Checks for modem carrier detect    *)
(*     Async_Carrier_Drop     ---    Checks for modem carrier drop      *)
(*     Async_Buffer_Check     ---    Checks if character in COM buffer  *)
(*     Async_Term_Ready       ---    Toggles terminal ready status      *)
(*     Async_Find_Delay       ---    Find busy wait count for 1ms delay *)
(*     Async_Receive          ---    Reads character from COM buffer    *)
(*     Async_Receive_With_Timeout                                       *)
(*                            ---    Receives char. with timeout check  *)
(*     Async_Ring_Detect      ---    If ringing detected                *)
(*     Async_Send             ---    Transmits char over COM port       *)
(*     Async_Send_String      ---    Sends string over COM port         *)
(*     Async_Send_String_With_Delays                                    *)
(*                            ---    Sends string with timed delays     *)
(*     Async_Send_Break       ---    Sends break (attention) signal     *)
(*     Async_Percentage_Used  ---    Returns percentage com buffer used *)
(*     Async_Purge_Buffer     ---    Purges receive buffer              *)
(*     Async_Release_Buffers  ---    Free memory for serial port queues *)
(*     Async_Setup_Port       ---    Define port base, IRQ, RS232 addr  *)
(*     Async_Stuff            ---    Insert char into receive buffer    *)
(*     Async_Flush_Output_Buffer                                        *)
(*                            ---    Flush serial port output buffer    *)
(*     Async_Drain_Output_Buffer                                        *)
(*                            ---    Wait for serial output to drain    *)
(*     Async_Port_Address_Given                                         *)
(*                            ---    Check if port address installed    *)
(*     Async_Send_Now         ---    Send character without buffering   *)
(*     Async_Wait_For_Quiet   ---    Wait for port to quiesce           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*      PIBASYNC.PAS was split into PIBASYN1.PAS and PIBASYN2.PAS at    *)
(*      version 3.2 of PibTerm, and into PIBASYN1, PIBASYN2, and        *)
(*      PIBASYN3 for v4.0 of PibTerm.   The UNIT structure was added    *)
(*      for use with Turbo Pascal v4.0.                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

INTERFACE

USES
   Dos, Crt, GlobType, PibTimer, PibMTask;

PROCEDURE BIOS_RS232_Init( ComPort : INTEGER; ComParm : WORD );
PROCEDURE Async_Close( Drop_DTR: BOOLEAN );
PROCEDURE Async_Clear_Errors;
PROCEDURE Async_Reset_Port( ComPort       : INTEGER;
                            BaudRate      : WORD;
                            Parity        : CHAR;
                            WordSize      : INTEGER;
                            StopBits      : INTEGER  );
FUNCTION  Async_Open( ComPort       : INTEGER;
                      BaudRate      : WORD;
                      Parity        : CHAR;
                      WordSize      : INTEGER;
                      StopBits      : INTEGER  ) : BOOLEAN;
PROCEDURE Async_Send( C : Char );
FUNCTION Async_Receive( VAR C : Char ) : BOOLEAN;
PROCEDURE Async_Receive_With_Timeout( Secs : INTEGER; VAR C : INTEGER );
PROCEDURE Async_Stuff( Ch: CHAR );
PROCEDURE Async_Find_Delay( VAR One_MS_Delay : INTEGER );
PROCEDURE Async_Init( Async_Buffer_Max  : INTEGER;
                      Async_OBuffer_Max : INTEGER;
                      Async_High_Lev1   : INTEGER;
                      Async_High_Lev2   : INTEGER;
                      Async_Low_Lev     : INTEGER );
FUNCTION  Async_Carrier_Detect : BOOLEAN;
FUNCTION  Async_Carrier_Drop : BOOLEAN;
PROCEDURE Async_Term_Ready( Ready_Status : BOOLEAN );
FUNCTION  Async_Buffer_Check : BOOLEAN;
FUNCTION  Async_Line_Error( VAR Error_Flags: BYTE ) : BOOLEAN;
FUNCTION  Async_Ring_Detect : BOOLEAN;
PROCEDURE Async_Send_Break;
PROCEDURE Async_Send_String( S : AnyStr );
PROCEDURE Async_Send_String_With_Delays( S          : AnyStr;
                                         Char_Delay : INTEGER;
                                         EOS_Delay  : INTEGER  );
FUNCTION  Async_Percentage_Used : REAL;
PROCEDURE Async_Purge_Buffer;
FUNCTION  Async_Peek( Nchars : INTEGER ) : CHAR;
PROCEDURE Async_Setup_Port( ComPort       : INTEGER;
                            Base_Address  : INTEGER;
                            IRQ_Line      : INTEGER;
                            Int_Numb      : INTEGER );
PROCEDURE Async_Release_Buffers;
PROCEDURE Async_Flush_Output_Buffer;
PROCEDURE Async_Drain_Output_Buffer( Max_Wait_Time : INTEGER );
FUNCTION  Async_Port_Address_Given( Com_Port : INTEGER ) : BOOLEAN;
PROCEDURE Async_Send_Now( C : Char );
FUNCTION  Async_Wait_For_Quiet( Max_Wait : LONGINT;
                                Wait_Time: LONGINT  ) : BOOLEAN;

IMPLEMENTATION
                                   (* Ensure multitasking defined       *)
{$DEFINE MTASK}

(*$I PIBASYN1.MOD *)
(*$I PIBASYN2.MOD *)
(*$I PIBASYN3.MOD *)

BEGIN (* PibAsync *)
                                   (* Default communications parameters *)
   Async_Do_CTS         := FALSE;
   Async_Do_DSR         := FALSE;
   Async_Hard_Wired_On  := FALSE;
   Async_Break_Length   := 500;
   Async_Do_XonXoff     := TRUE;
   Async_OV_XonXoff     := TRUE;
   Async_Buffer_Length  := 4096;
   Async_OBuffer_Length := 1132;
                                   (* Port addresses of each com port *)

   Default_Com_Base[1]  := COM1_Base;
   Default_Com_Base[2]  := COM2_Base;
   Default_Com_Base[3]  := COM3_Base;
   Default_Com_Base[4]  := COM4_Base;

                                   (* IRQ line for each port *)

   Default_Com_Irq [1]  := COM1_Irq;
   Default_Com_Irq [2]  := COM2_Irq;
   Default_Com_Irq [3]  := COM3_Irq;
   Default_Com_Irq [4]  := COM4_Irq;

                                   (* Pick up address of send-a-character *)
                                   (* routine, which is used by INLINE    *)
                                   (* code.                               *)

   Async_Send_Addr := ADDR( Async_Send );

END   (* PibAsync *).
