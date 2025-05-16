(*----------------------------------------------------------------------*)
(*         Handle_Zmodem_Autodownload --- Handle Zmodem autodownload    *)
(*----------------------------------------------------------------------*)

FUNCTION Handle_Zmodem_Autodownload : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Handle_Zmodem_Autodownload;                          *)
(*                                                                      *)
(*     Purpose:    Handles Zmodem autodownload.                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Found_Zmodem := Handle_Zmodem_Autodownload;                   *)
(*                                                                      *)
(*           Found_Zmodem --- TRUE if Zmodem packet found and           *)
(*                            Zmodem transfer executed.                 *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine should be called when Zmodem autodownload        *)
(*        mode is in effect and the terminal emulation has received     *)
(*        a "CAN" character.                                            *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Peek                                                    *)
(*        PibDownLoad                                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   TT  : Transfer_Type;
   Ch1 : CHAR;
   Ch2 : CHAR;
   Ch3 : CHAR;

BEGIN (* Handle_Zmodem_Autodownload *)

                                   (* Pick up transfer type for Zmodem *)
   TT := Get_Zmodem_Type;
                                   (* If none defined, return to caller. *)
   IF ( TT <> None ) THEN
                                   (* If Zmodem type defined, then *)
                                   (* peek ahead for 'B00' marking *)
                                   (* ZRQINIT packet.              *)
      BEGIN
                                   (* Make sure rest of packet arrives  *)

         DELAY( One_Second_Delay );

                                   (* Peek ahead and pick up the next   *)
                                   (* three characters after the CAN.   *)
         Ch1 := Async_Peek( 0 );
         Ch2 := Async_Peek( 1 );
         Ch3 := Async_Peek( 2 );

         IF ( ( Ch1 = 'B' ) AND
              ( Ch2 = '0' ) AND
              ( Ch3 = '0' ) ) THEN
            BEGIN
               Handle_Zmodem_Autodownload := TRUE;
               PibDownload( TT );
            END;

      END
   ELSE
      Handle_Zmodem_Autodownload := FALSE;

END   (* Handle_Zmodem_Autodownload *);

(*----------------------------------------------------------------------*)
(*         Handle_Kermit_Autodownload --- Handle Kermit autodownload    *)
(*----------------------------------------------------------------------*)

FUNCTION Handle_Kermit_Autodownload : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Handle_Kermit_Autodownload;                          *)
(*                                                                      *)
(*     Purpose:    Handles Kermit autodownload.                         *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Found_Kermit := Handle_Kermit_Autodownload;                   *)
(*                                                                      *)
(*           Found_Kermit --- TRUE if Kermit packet found and           *)
(*                            Kermit transfer executed.                 *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine should be called when Kermit autodownload        *)
(*        mode is in effect and the terminal emulation has received     *)
(*        an "SOH" character.                                           *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        Async_Peek                                                    *)
(*        PibDownLoad                                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ch1 : CHAR;
   Ch2 : CHAR;
   Ch3 : CHAR;

BEGIN (* Handle_Kermit_Autodownload *)

                                   (* Wait 1 second to ensure arrival   *)
                                   (* of rest of Kermit packet.         *)
   DELAY( One_Second_Delay );
                                   (* Peek ahead and pick up the next   *)
                                   (* three characters after the SOH.   *)
   Ch1 := Async_Peek( 0 );
   Ch2 := Async_Peek( 1 );
   Ch3 := Async_Peek( 2 );
                                   (* "Ch1" should be a packet length   *)
                                   (* in the range CHR(32) to CHR(96).  *)
                                   (* If not, then this can't be the    *)
                                   (* start of a Kermit packet.         *)
                                   (*                                   *)
                                   (* "Ch2" should be a blank, since    *)
                                   (* the first packet number must be   *)
                                   (* zero.                             *)
                                   (*                                   *)
                                   (* "Ch3" should be an "S", since     *)
                                   (* the first packet of a SEND is a   *)
                                   (* "Send Init".                      *)

   IF ( ( ORD( Ch1 ) IN [32..96] ) AND
        ( Ch2 = ' '              ) AND
        ( Ch3 = 'S'              ) ) THEN
      BEGIN
         Handle_Kermit_Autodownload := TRUE;
         Doing_Kermit_Autodown      := TRUE;
         PibDownLoad( Kermit );
      END
   ELSE
      Handle_Kermit_Autodownload := FALSE;

END   (* Handle_Kermit_Autodownload *);
