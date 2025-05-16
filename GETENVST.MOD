(*----------------------------------------------------------------------*)
(*           GetEnvStr --- get string from DOS environment              *)
(*----------------------------------------------------------------------*)

FUNCTION GetEnvStr( Search_String : AnyStr ) : AnyStr;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   GetEnvStr                                            *)
(*                                                                      *)
(*     Purpose:    Gets string from DOS enviroment area                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        EnvString := GetEnvStr( Search_String : AnyStr ) : AnyStr;    *)
(*                                                                      *)
(*           Search_String --- String to be searched for                *)
(*           EnvString     --- Resultant string value or null if not    *)
(*                             found.                                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

TYPE
   DosEnv = ARRAY[0..32767] OF CHAR;

VAR
   EnvPtr: ^DosEnv;
   EnvStr: AnyStr;
   Done  : BOOLEAN;
   I     : INTEGER;
   L     : INTEGER;

BEGIN (* GetEnvStr *)
                                   (* Add '=' to search string.           *)

   Search_String := Search_String + '=';
   L             := LENGTH( Search_String );

                                   (* Get address of DOS environment area *)

   EnvPtr        := PTR( MemW[ PrefixSeg:$002C ] , 0 );

                                   (* Begin loop looking for string *)
   I              := 0;
   Done           := FALSE;
   EnvStr         := '';
   GetEnvStr      := '';

   REPEAT
      IF EnvPtr^[I] = #0 THEN
         BEGIN
                                   (* Environment area ends with two      *)
                                   (* successive 0 bytes.                 *)

            IF ( EnvPtr^[I+1] = #0 ) THEN
               BEGIN

                  Done := TRUE;

                  IF ( Search_String = '==' ) THEN
                     BEGIN
                        EnvStr    := '';
                        INC( I , 4 );
                        WHILE( EnvPtr^[I] <> #0 ) DO
                           BEGIN
                              EnvStr := EnvStr + EnvPtr^[I];
                              INC( I );
                           END;
                        GetEnvStr := EnvStr;
                     END;

               END;
                                   (* If we found string, get associated  *)
                                   (* value.                              *)

            IF ( COPY( EnvStr , 1 , L ) = Search_String ) THEN
               BEGIN
                  GetEnvStr := COPY( EnvStr, SUCC( L ), LENGTH( EnvStr ) - L );
                  Done      := TRUE;
               END;
                                   (* Set current environment string to null *)
            EnvStr := ''

         END
      ELSE
                                   (* Not CHR(0) --- append to current    *)
                                   (* environment string being extracted. *)

         EnvStr := EnvStr + EnvPtr^[I];

      INC( I );

   UNTIL Done;

END    (* GetEnvStr *);
