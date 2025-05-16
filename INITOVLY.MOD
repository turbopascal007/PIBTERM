(*----------------------------------------------------------------------*)
(*              InitOvly --- Initialize PibTerm overlays                *)
(*----------------------------------------------------------------------*)

PROCEDURE InitOvly;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     PROCEDURE:  InitOvly                                             *)
(*                                                                      *)
(*     Purpose:    Initializes PibTerm directory for overlay searches   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        InitOvly;                                                     *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The PibTerm directory should have been set by a previous      *)
(*        SET PIBTERM=   DOS specification.                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ovr_Dir      : AnyStr;
   Ierr         : INTEGER;
   I            : INTEGER;
   Cur_Dir      : AnyStr;

(* STRUCTURED *) CONST
   LetSet : SET OF CHAR = ['A'..'Z','a'..'z','\'];

BEGIN (* InitOvly *)
                                   (* Get current drive and directory *)
   GetDir( 0 , Cur_Dir );

   Ierr := IOResult;

   Home_Drive    := Cur_Dir[1];
   Home_Dir_Path := COPY( Cur_Dir, 3, LENGTH( Cur_Dir ) - 2 );

                                   (* Search DOS environment for     *)
                                   (* PIBTERM= definition.           *)

   Ovr_Dir := GetEnvStr('PIBTERM');

                                   (* See if environment string      *)
                                   (* makes sense.                   *)

   IF ( LENGTH( Ovr_Dir ) > 0 ) THEN
      IF ( NOT ( Ovr_Dir[1] IN LetSet ) ) THEN
         Ovr_Dir := '';

   IF ( LENGTH( Ovr_Dir ) > 0 ) THEN
      BEGIN
                                   (* PIBTERM= found in environment --- *)
                                   (* set home drive and directory      *)

         IF ( Ovr_Dir[2] = ':' ) THEN
            BEGIN
               Home_Drive := UpCase( Ovr_Dir[1] );
               IF LENGTH( Ovr_Dir ) > 2 THEN
                  Home_Dir_Path := COPY( Ovr_Dir, 3, LENGTH( Ovr_Dir ) - 2 )
               ELSE
                  Home_Dir_Path := '';
            END
         ELSE
            Home_Dir_Path := Ovr_Dir;

      END;
                                   (* Make PibTerm files findable    *)

   IF ( LENGTH( Home_Dir_Path ) <> 0 )  THEN
      Home_Dir := Home_Drive + ':\' + Home_Dir_Path + '\'
   ELSE
      Home_Dir := Home_Drive + ':\';

   I := POS( '\\' , Home_Dir );

   WHILE( I > 0 ) DO
      BEGIN
         DELETE( Home_Dir, I, 1 );
         I := POS( '\\' , Home_Dir );
      END;
{
   WRITELN('Home_Dir      = ',Home_Dir);
   WRITELN('Home_Drive    = ',Home_Drive);
   WRITELN('Home_Dir_Path = ',Home_Dir_Path);
   WRITELN('Ovr_Dir       = ',Ovr_Dir);
   Ch := ReadKey;
}
END    (* InitOvly *);
