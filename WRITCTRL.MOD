(*----------------------------------------------------------------------*)
(*             Write_Ctrls --- Convert ctrl key defs in string          *)
(*----------------------------------------------------------------------*)

FUNCTION Write_Ctrls( S : AnyStr ) : AnyStr;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Write_Ctrls                                          *)
(*                                                                      *)
(*     Purpose:    Convert ctrl key defs to ascii sequences             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Fixed_S := Write_Ctrls( S: AnyStr ) : AnyStr;                 *)
(*                                                                      *)
(*           S       --- the string with potential ctrl seqs to convert *)
(*           Fixed_S --- fixed up string                                *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine replaces control sequences like ^G (ascii 07)    *)
(*        with a two-character sequence like '^G' -- ascii 94 +         *)
(*        ascii 71. The actual '^' character                            *)
(*        is the global parameter FK_Ctrl_Mark and can be set with      *)
(*        a configuration file.                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   T: AnyStr;
   I: INTEGER;
   J: INTEGER;

BEGIN (* Write_Ctrls *)
                                   (* Scan for ctrl characters *)
   T    := '';
   J    := 0;

   FOR I := 1 TO LENGTH( S ) DO
      BEGIN                        (* Ctrl char --- convert to marker  *)
                                   (* plus ascii character             *)

         IF ( S[I] IN [^@..^_] ) THEN
            BEGIN
               INC( J );
               T[J] := FK_Ctrl_Mark;
               INC( J );
               T[J] := CHR( ORD( S[I] ) + 64 );
            END

                                   (* Regular character -- just copy *)
         ELSE
            BEGIN
               INC( J );
               T[J] := S[I];
            END;
      END;

   T[0]        := CHR( J );
   Write_Ctrls := T;

END   (* Write_Ctrls *);
