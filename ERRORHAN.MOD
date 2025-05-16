(*----------------------------------------------------------------------*)
(*     Error_Handler --- Handle program aborts by exiting gracefully    *)
(*----------------------------------------------------------------------*)

PROCEDURE Error_Handler;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Error_Handler                                        *)
(*                                                                      *)
(*     Purpose:    Handle PibTerm program aborts by halting gracefully  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Error_Handler;                                                *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine needs to be cleaned up to handle file closing    *)
(*        better at some point.                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I    : INTEGER;
   Mess : AnyStr;

(* STRUCTURED *) Const
   Sorry_Mess  : STRING[60]
                 = 'Sorry, there has been a system error, please call back later';
   Discon_Mess : STRING[17]
                 = 'Disconnecting....';

BEGIN (* Error_Handler *)
                                   (* Make sure we're in text mode.        *)
   Set_Text_Mode( Text_Mode );
                                   (* Send notice of fatal error (also to  *)
                                   (* caller in host mode) and quit.       *)
   IF ( ExitCode > 0 ) THEN
      BEGIN

         IF Host_Mode THEN
            BEGIN
               Async_Send_String(' ');
               Async_Send_String(Sorry_Mess);
               Async_Send_String(Discon_Mess);
               WRITELN;
               WRITELN(Sorry_Mess);
               WRITELN(Discon_Mess);
            END
         ELSE
            BEGIN
               WRITELN;
               WRITELN('Sorry, PibTerm has encountered a serious error.');
            END;

                                   (* Report error number *)

         IF ( ErrorAddr <> NIL ) THEN
            WRITELN('Error number: ', ExitCode, ' ($',
                    Dec_To_Hex( WORD( ExitCode ) ),
                    ') at address $',
                    Dec_To_Hex( SEG( ErrorAddr^ ) ),':$',
                    Dec_To_Hex( OFS( ErrorAddr^ ) ) );

                                   (* Report memory management errors  *)
                                   (* as possibly not enough installed *)
                                   (* memory.                          *)

         IF ( ( ExitCode = HeapTooSmall ) OR
              ( ExitCode = StackTooSmall ) ) THEN
            BEGIN
               WRITE  ('This machine does not have enough memory available');
               WRITELN(' to run PibTerm.');
            END
         ELSE IF ( ErrorAddr = NIL ) THEN

            CASE ExitCode OF

               1: BEGIN
                     CASE OverlayError OF
                        1    :  Mess := 'Insufficient heap space for stack and fixup lists';
                        2    :  Mess := 'OVR file not found';
                        3    :  Mess := 'OVERLAY has not been run on the EXE file';
                        4    :  Mess := 'OVR file invalid format';
                        5,
                        $200 :  Mess := 'Error reading overlay file';
                        6,
                        $300 :  Mess := 'Error accessing expanded memory';
                        7    :  Mess := 'Too many relocation items in the OVR file';
                        $100 :  Mess := 'Out of overlay stack space';
                        ELSE Mess := 'Overlay error';
                     END (* CASE *);
                     WRITELN( Mess );
                  END;

               2: BEGIN
                     WRITELN('Set Block error on return from DOS, PibTerm cannot continue.');
                     WRITELN('You will probably need to re-boot.');
                  END;

               3: BEGIN
                     WRITELN('PibTerm cannot initialize communications.');
                     WRITELN('The serial port you specified cannot be accessed.');
                     WRITELN('Make sure that you have specified the correct serial');
                     WRITELN('port number in the PIBTERM.CNF file, or use the');
                     WRITELN('/P=portnumber parameter when invoking PibTerm to');
                     WRITELN('override the port indicated by PIBTERM.CNF.');
                     WRITELN('For example, type');
                     WRITELN('     PIBTERM /P=2');
                     WRITELN('to use serial port 2 regardless of what port is');
                     WRITELN('specified in PIBTERM.CNF.');
                  END;

               ELSE;

            END (* CASE *);

      END;
                                   (* Close down all program facilities *)
   FiniTerm;

   WRITELN;
   WRITELN('PibTerm execution stopped ... ');
   DELAY  ( Three_Second_Delay    );

                                   (* Restore old handler *)
   ExitProc  := ExitSave;
   ErrorAddr := NIL;

   Error_Exit_Taken := TRUE;

   Halt( ErrorEnd );

END   (* Error_Handler *);

(*----------------------------------------------------------------------*)
(*     Heap_Error_Handler --- Handle heap request errors                *)
(*----------------------------------------------------------------------*)

FUNCTION Heap_Error_Handler( Size : WORD ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Heap_Error_Handler                                   *)
(*                                                                      *)
(*     Purpose:    Handle heap overflow errors.                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Heap_Error_Handler *)

   Heap_Error_Handler := 1;

END   (* Heap_Error_Handler *);