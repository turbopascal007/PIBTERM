(*----------------------------------------------------------------------*)
(*         Clear_XOFF_Received -- Clear XOFF received flag              *)
(*----------------------------------------------------------------------*)

PROCEDURE Clear_XOFF_Received;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Clear_XOFF_Received                                  *)
(*                                                                      *)
(*     Purpose:    Clears XOFF received flag and restarts serial output *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Clear_XOFF_Received;                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Port_Val : BYTE;

BEGIN (* Clear_XOFF_Received *)

   IF Async_XOff_Received THEN
      BEGIN
                                   (* Clear XOFF received flag *)

         Async_XOff_Received := FALSE;

                                   (* Clear status line *)
         IF Do_Status_Line THEN
            Write_To_Status_Line( '             ', 65 );

                                   (* Start up serial output again *)

         Port_Val := PORT[ Async_Uart_Ier ];

         IF ( ( Port_Val AND 2 ) = 0 ) THEN
            PORT[ Async_Uart_Ier ] := ( Port_Val OR 2 );

      END;

END   (* Clear_XOFF_Received *);