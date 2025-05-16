(*----------------------------------------------------------------------*)
(*                   HangUpPhone  --- Hang up the phone                 *)
(*----------------------------------------------------------------------*)

PROCEDURE HangUpPhone;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  HangUpPhone                                          *)
(*                                                                      *)
(*     Purpose:    Hangs up the phone.                                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        HangUpPhone;                                                  *)
(*                                                                      *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        DELAY                                                         *)
(*        Send_Modem_Command                                            *)
(*        Async_Close                                                   *)
(*        Async_Open                                                    *)
(*        Async_Purge_Buffer                                            *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        First a hangup is tried by dropping DTR.  If that fails, and  *)
(*        if a modem command delay string and a modem hang-up string    *)
(*        are specified, they are used.                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Open_Flag    : BOOLEAN;
   Save_XonXoff : BOOLEAN;
   Save_XonOV   : BOOLEAN;

BEGIN (* HangUpPhone *)
                                   (* Make sure to clear XOFF received  *)
                                   (* flag.                             *)

   Save_XonXoff     := Async_Do_XonXoff;
   Async_Do_XonXoff := FALSE;

   Save_XonOV       := Async_OV_XonXoff;
   Async_OV_XonXoff := FALSE;

   IF ( Async_XOff_Received ) THEN
      Clear_XOFF_Received;

                                   (* Try hanging up by dropping DTR.   *)
                                   (* We do this by closing port with   *)
                                   (* DTR drop request.                 *)
   Async_Close( TRUE );
                                   (* Wait a second for DTR drop.       *)
   DELAY( One_Second_Delay );
                                   (* Re-open the port.                 *)

   Open_Flag := Async_Open( Comm_Port, Baud_Rate, Parity, Data_Bits,
                            Stop_Bits );

                                   (* If modem hang-up command given,     *)
                                   (* use it if dropping DTR didn't work. *)
   IF Async_Carrier_Detect THEN
      IF ( Modem_Hang_Up <> '' ) THEN
         BEGIN

            DELAY( Modem_Escape_Time );

            Send_Modem_Command( Modem_Escape );

            DELAY( Modem_Escape_Time );

            Send_Modem_Command( Modem_Hang_Up );

            DELAY( Modem_Escape_Time );

         END;
                                   (* Swallow any garbage characters *)
   Async_Purge_Buffer;
                                   (* Restore previous Xon/Xoff status *)

   Async_Do_XonXoff := Save_XonXoff;
   Async_OV_XonXoff := Save_XonOV;

END   (* HangUpPhone *);
