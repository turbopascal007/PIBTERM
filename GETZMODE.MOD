(*----------------------------------------------------------------------*)
(*         Get_Zmodem_Type --- Finds which user protocol is Zmodem      *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Zmodem_Type : Transfer_Type;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Get_Zmodem_Type                                      *)
(*                                                                      *)
(*     Purpose:    Finds which external protocol (if any) is Zmodem.    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        ZmodemT := Get_Zmodem_Type : Transfer_Type;                   *)
(*                                                                      *)
(*           ZmodemT --- external protocol type corresponding to        *)
(*                       Zmodem, or None if not external protocol       *)
(*                       seems to be Zmodem.                            *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The check is based upon the Zmodem protocol having the        *)
(*        abbreviation 'ZM'.                                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   T : Transfer_Type;

BEGIN (* Get_Zmodem_Type *)
                                   (* Assume Zmodem not found *)
   Get_Zmodem_Type := None;
                                   (* Search external defs for 'ZM' *)
   FOR T := PUser1 TO Puser10 DO
      BEGIN
         IF ( Trans_Type_Name[T] = 'ZM' ) THEN
            BEGIN
               Get_Zmodem_Type := T;
               EXIT;
            END;
      END;

END   (* Get_Zmodem_Type *);
