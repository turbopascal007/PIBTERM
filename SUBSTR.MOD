(*--------------------------------------------------------------------------*)
(*                 Substr -- Get substring of a string                      *)
(*--------------------------------------------------------------------------*)

FUNCTION Substr( S : AnyStr; IS : INTEGER; NS: INTEGER ) : AnyStr;

(*--------------------------------------------------------------------------*)
(*                                                                          *)
(*    Function: Substr                                                      *)
(*                                                                          *)
(*    Purpose:  Takes substring of a string                                 *)
(*                                                                          *)
(*    Calling Sequence:                                                     *)
(*                                                                          *)
(*       Sub_String := Substr(  S: Anystr;                                  *)
(*                             IS: INTEGER;                                 *)
(*                             NS: INTEGER ): AnyStr;                       *)
(*                                                                          *)
(*          S   --- String to get substring from                            *)
(*          IS  --- Starting character in S of substring to extract         *)
(*          NS  --- Number of characters to extract                         *)
(*                                                                          *)
(*    Calls:  Copy                                                          *)
(*                                                                          *)
(*    Remarks:                                                              *)
(*                                                                          *)
(*       This routine handles null strings which COPY doesn't like.         *)
(*                                                                          *)
(*--------------------------------------------------------------------------*)

VAR
   L : INTEGER;
   L0: INTEGER;

BEGIN (* Substr *)
                                   (* Keep all strings in proper range *)
   L0 := LENGTH( S );
   L  := L0 - IS + 1;

   IF( L < NS ) THEN
      NS := L;
                                   (* Extract substring or return null string *)

   IF ( NS <= 0 ) OR ( IS < 1 ) OR ( IS > L0 ) THEN
      Substr := ''
   ELSE
      Substr := COPY( S, IS, NS );

END   (* Substr *);
