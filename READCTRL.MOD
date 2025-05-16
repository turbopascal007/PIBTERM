(*----------------------------------------------------------------------*)
(*         Read_Ctrls --- Fix up ctrl key definitions in string         *)
(*----------------------------------------------------------------------*)

FUNCTION Read_Ctrls( S : AnyStr ) : AnyStr;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Read_Ctrls                                           *)
(*                                                                      *)
(*     Purpose:    Convert control sequences in strings.                *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Fixed_S := Read_Ctrls( S: AnyStr ) : AnyStr;                  *)
(*                                                                      *)
(*           S       --- the string with potential ctrl seqs to convert *)
(*           Fixed_S --- fixed up string                                *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This routine replaces a character sequence of the form        *)
(*        '^G' -- ascii 94 + ascii 71 -- with the single control        *)
(*        character ctrl-G -- ascii 07.  The actual '^' character       *)
(*        is the global parameter FK_Ctrl_Mark and can be set with      *)
(*        a configuration file.                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   T      : AnyStr;
   I      : INTEGER;
   J      : INTEGER;
   L      : INTEGER;

BEGIN (* Read_Ctrls *)
                                   (* Scan for ctrl markers *)
   T    := '';
   I    := 1;
   J    := 0;
   L    := LENGTH( S );

   WHILE( I <= L ) DO
      BEGIN                        (* Ctrl marker -- convert next char *)
                                   (* to control character             *)

         IF ( S[I] = FK_Ctrl_Mark ) THEN
            IF ( S[I+1] <> '''' ) THEN
               BEGIN               (* Process control character *)
                  INC( I );
                  INC( J );
                  T[J] := CHR( ORD( S[I] ) - 64 );
                  INC( I );
               END
            ELSE
               BEGIN
                  INC( J );
                  T[J]   := S[I];
                  T[J+1] := S[I+1];
                  T[J+2] := S[I+2];
                  INC( I , 3 );
                  INC( J , 2 );
               END
         ELSE
            BEGIN                  (* Regular character -- just copy *)
               INC( J );
               T[J] := S[I];
               INC( I );
            END;

      END;

   T[0]       := CHR( J );
   Read_Ctrls := T;

END   (* Read_Ctrls *);
