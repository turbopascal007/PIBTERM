(*----------------------------------------------------------------------*)
(*  Allocate_Dial_And_Review --- Get memory for dial dir and review buf *)
(*----------------------------------------------------------------------*)

PROCEDURE Allocate_Dial_And_Review;

BEGIN (* Allocate_Dial_And_Review *)

                                   (* Allocate dialing directory *)

   GetMem( Dialing_Directory , Dialing_Dir_Size_Max *
                               Dialing_Dir_Entry_Length );

                                   (* Check if we got the space *)

   IF ( Dialing_Directory = NIL ) THEN
      WRITELN('--- There is not enough memory to store the dialing directory.');

                                   (* Get review buffer *)

   IF ( Max_Review_Length > ( MaxAvail - 8000 ) ) THEN
      Max_Review_Length    := MAX( 0 , ( MaxAvail - 8000 ) );

   Review_On := ( Max_Review_Length > 0 );

   IF Review_On THEN
      GetMem( Review_Buffer , Max_Review_Length );

   Review_On := Review_On AND ( Review_Buffer <> NIL );

   Review_Head      := 0;
   Review_Tail      := 0;
   Review_Line[0]   := #0;

END    (* Allocate_Dial_And_Review *);