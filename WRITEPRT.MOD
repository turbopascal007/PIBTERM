(*----------------------------------------------------------------------*)
(*         Write_Prt  --- Write a character to the printer              *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_Prt( Ch : CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Write_Prt                                            *)
(*                                                                      *)
(*     Purpose:    Writes one character to printer                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Write_Prt( Ch : CHAR );                                       *)
(*                                                                      *)
(*           Ch  --- Character to write out to printer                  *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ierr        : INTEGER;
   KCh         : CHAR;
   Local_Save  : Saved_Screen_Ptr;

BEGIN (* Write_Prt *)
                                   (* Don't write if printer not open! *)
   Ierr := 0;
   
   IF Lst_OK THEN
      BEGIN
         WRITE( Lst , Ch );
         Ierr := Int24Result;
      END;
                                   (* Indicate printing error occurred *)

   IF ( Lst_OK AND ( Ierr <> 0 ) ) THEN
      BEGIN

         Draw_Titled_Box( Local_Save, 10, 10, 60, 17, 'Printer Error' );

                                   (* Have to drain keyboard in case  *)
                                   (* error occurred with stuff still *)
                                   (* in keyboard buffer -- needed to *)
                                   (* prevent premature exit at the   *)
                                   (* "press any" prompt.             *)

         WHILE PibTerm_KeyPressed DO
            Read_Kbd( KCh );

         WRITELN;
         WRITELN(' Printer is not ready, please check to see');
         WRITELN(' that it is powered on and has enough paper.');
         WRITELN(' ');
         WRITE  (' ');

         Press_Any;

         Restore_Screen_And_Colors( Local_Save );

         WRITE( Lst , Ch );

         Lst_OK := ( Int24Result = 0 );

      END;

END   (* Write_Prt *);

(*----------------------------------------------------------------------*)
(*         Write_Prt_Str     --- Write string to the printer            *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_Prt_Str( S : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Write_Prt_Str                                        *)
(*                                                                      *)
(*     Purpose:    Writes a string to the printer                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Write_Prt_Str( S : AnyStr );                                  *)
(*                                                                      *)
(*           S --- String to write to printer                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   IS : INTEGER;

BEGIN (* Write_Prt_Str *)

   IF Lst_OK THEN
      FOR IS := 1 TO LENGTH( S ) DO
         Write_Prt( S[IS] );

END   (* Write_Prt_Str *);