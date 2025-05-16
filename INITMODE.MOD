(*----------------------------------------------------------------------*)
(*               Initialize_Modem --- Initialize Modem                  *)
(*----------------------------------------------------------------------*)

PROCEDURE Initialize_Modem;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Initialize_Modem                                     *)
(*                                                                      *)
(*     Purpose:    Initializes Modem                                    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Initialize_Modem;                                             *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Modem_Connected                                               *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Done_Flag : BOOLEAN;
   F         : TEXT;
   Ch        : CHAR;
   Do_Init   : BOOLEAN;

(*----------------------------------------------------------------------*)
(*               Modem_Connected --- Check if modem connected           *)
(*----------------------------------------------------------------------*)

FUNCTION Modem_Connected : BOOLEAN;

VAR
   Start_Time: LONGINT;
   Timed_Out : BOOLEAN;

BEGIN (* Modem_Connected *)
                                   (* Turn on OUT2, DTR, and RTS *)

   Port[UART_MCR + Async_Base] := $0B;

                                   (* Clear pending async errors   *)
   Async_Clear_Errors;
                                   (* Wait for DSR using Busy Wait *)
   Start_Time := TimeOfDay;
   Timed_Out  := FALSE;

   IF Async_Do_DSR THEN
      BEGIN
         WHILE ( NOT Timed_Out )  AND
               ( ( Port[UART_MSR + Async_Base] AND $20 ) = 0 ) DO
            Timed_Out := ( TimeDiff( Start_Time , TimeOfDay ) > 2 );
         IF Timed_Out THEN
            IF Attended_Mode THEN
               BEGIN
                  Async_Do_DSR := YesNo('*** Data set ready doesn''t work, turn ' +
                                        'it off (Y/N) ? ');
                  WRITELN;
                  Timed_Out := Async_Do_DSR;
               END
            ELSE
               WRITELN('*** Data set ready turned off.');
      END;
                                   (* Wait for CTS using Busy Wait *)
   Start_Time := TimeOfDay;

   IF Async_Do_CTS THEN
      BEGIN
         WHILE ( NOT Timed_Out )  AND
               ( ( Port[UART_MSR + Async_Base] AND $10 ) = 0 ) DO
            Timed_Out := ( TimeDiff( Start_Time , TimeOfDay ) > 2 );
         IF Timed_Out THEN
            IF Attended_Mode THEN
               BEGIN
                  Async_Do_CTS := YesNo('*** Clear to send doesn''t work, turn ' +
                                        'it off (Y/N) ? ');
                  WRITELN;
                  Timed_Out := Async_Do_CTS;
               END
            ELSE
               WRITELN('*** Clear to send turned off.');
      END;

                                   (* Wait for Transmit Hold Register Empty (THRE) *)
   Start_Time := TimeOfDay;

   WHILE ( NOT Timed_Out ) AND
         ( ( Port[UART_LSR + Async_Base] AND $20 ) = 0 ) DO
      Timed_Out := ( TimeDiff( Start_Time , TimeOfDay ) > 2 );

                                   (* If we looped through, modem probably *)
                                   (* not connected.                       *)

   Modem_Connected := ( NOT Timed_Out );

END   (* Modem_Connected *);

(*----------------------------------------------------------------------*)

BEGIN (* Initialize_Modem *)
                                   (* Ensure correct setting of carrier *)
                                   (* detect status variables           *)

   Current_Carrier_Status := Async_Carrier_Detect;
   New_Carrier_Status     := Current_Carrier_Status;

                                   (* Check status of hardware lines *)
   IF ( NOT Modem_Connected ) THEN
      BEGIN
         IF ( NOT Hard_Wired ) THEN
            BEGIN
               WRITELN('*** Modem appears to be turned off.');
               WRITELN('*** Please turn it on and then hit any key to continue.');
            END
         ELSE
            BEGIN
               WRITELN('*** Hard-wired connection may be bad.');
               WRITELN('*** You may want to turn off CTS and DSR checking.');
               WRITELN('*** Hit any key to continue.');
            END;
         IF Attended_Mode THEN
            BEGIN
               Read_Kbd( Ch );
               IF ( Ch = CHR( ESC ) ) AND PibTerm_KeyPressed THEN
                  Read_Kbd( Ch );
            END
         ELSE
            WRITELN('*** Continuing anyway because of unattended mode.');
      END;
                                   (* Issue modem initialization string *)

   IF ( Modem_Init <> '' ) AND ( NOT Hard_Wired ) THEN
      BEGIN

         IF Async_Carrier_Detect THEN
            BEGIN
               WRITE('*** Session appears to be already in progress.');
               IF Attended_Mode THEN
                  BEGIN
                     Do_Init := YesNo('*** Send modem initialization anyway (Y/N) ? ');
                     WRITELN;
                  END
               ELSE
                  BEGIN
                     WRITELN('*** Modem initialization not performed.');
                     Do_Init := FALSE;
                  END;
            END
         ELSE
            Do_Init := TRUE;

         IF Do_Init THEN
            BEGIN
               WRITELN;
               WRITELN('Modem initialization: ',Write_Ctrls( Modem_Init ) );
               Send_Modem_Command( Modem_Init );
               DELAY( One_Second_Delay );
               Async_Purge_Buffer;
            END;

      END;

END   (* Initialize_Modem *);
