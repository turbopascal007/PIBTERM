UNIT PT4CISB;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibAsync;

(* EXPORTS *)
   PROCEDURE CISB_Term_ENQ;
   PROCEDURE CISB_Term_ESC_I;
   PROCEDURE CISB_DLE_Seen;

IMPLEMENTATION
                                   (* Global CISB variables *)
(*$I CISB.LOC *)
                                   (* CompuServe B Protocol *)
(*$I DOCISBA.MOD *)
(*$I DOCISBB.MOD *)

END   (* PT4CISB *).
