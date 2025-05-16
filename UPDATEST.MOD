(*----------------------------------------------------------------------*)
(*             Update_Status_Line --- Update status line time           *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Status_Line;

VAR
   H_String : STRING[2];
   M_String : STRING[2];
   HM_String: STRING[5];
   Hours    : INTEGER;
   Mins     : INTEGER;

(* STRUCTURED *) CONST
   OffOn : ARRAY[0..1] OF STRING[1] = ('-','+');

BEGIN (* Update_Status_Line *)

   IF Do_Status_Time THEN
      BEGIN

         FastTime( New_Status_Time );

         IF ( New_Status_Time <> Current_Status_Time ) THEN
            BEGIN

               Current_Status_Time := New_Status_Time;

               Hours := HI( New_Status_Time );
               Mins  := LO( New_Status_Time );

               IF ( Time_Format = AMPM_Time ) THEN
                  IF ( Hours = 0 ) THEN
                     Hours := 12
                  ELSE IF ( Hours > 12 ) THEN
                     Hours := Hours - 12;

               STR( Hours : 2 , H_String );
               STR( Mins  : 2 , M_String );

               IF ( M_String[1] = ' ' ) THEN
                  M_String[1] := '0';

               HM_String := H_String + ':' + M_String;

               Write_To_Status_Line( HM_String , 13 );

               MOVE( HM_String[1], Status_Line_Name[13], 5 );

            END;

      END;

(* New_Carrier_Status := Async_Carrier_Detect; *)

   New_Carrier_Status := ODD( Port[ UART_MSR + Async_Base ] SHR 7 ) OR
                         Async_Hard_Wired_On;

   IF ( New_Carrier_Status <> Current_Carrier_Status ) THEN
      BEGIN
         Carrier_Dropped        := ( New_Carrier_Status = FALSE );
         Current_Carrier_Status := New_Carrier_Status;
         IF ( NOT Host_Mode ) THEN
            Write_To_Status_Line( OffOn[ ORD( Current_Carrier_Status ) ], 47 );
      END;

END   (* Update_Status_Line *);
