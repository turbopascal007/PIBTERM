(*----------------------------------------------------------------------*)
(*             Toggle_Option -- Toggle an option on or off              *)
(*----------------------------------------------------------------------*)

PROCEDURE Toggle_Option( Option_Name : AnyStr; VAR Option_Flag : BOOLEAN );

(* STRUCTURED *) CONST
   OnOffChars : ARRAY[0..1] OF STRING[3] = ('OFF','ON');

BEGIN (* Toggle_Option *)

   Option_Flag := NOT Option_Flag;

   Draw_Titled_Box( Saved_Screen, 10, 10, 55, 15, '' );

   WRITE('*** ',Option_Name, ' now ', OnOffChars[ ORD( Option_Flag ) ] );

   Window_Delay;

   Restore_Screen_And_Colors( Saved_Screen );

END   (* Toggle_Option *);
