(*----------------------------------------------------------------------*)
(*           View_Prompt --- prompt for end-of-screen                   *)
(*----------------------------------------------------------------------*)

PROCEDURE View_Prompt( VAR View_Done  : BOOLEAN;
                       VAR View_Count : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  View_Prompt                                          *)
(*                                                                      *)
(*     Purpose:    Issues end-of-screen prompt for view routines        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        View_Prompt( VAR View_Done  : BOOLEAN;                        *)
(*                     VAR View_Count : INTEGER );                      *)
(*                                                                      *)
(*           View_Done  --- TRUE if Stop option selected here           *)
(*           View_Count --- Count of lines per panel.  May be changed   *)
(*                          here if C option selected.                  *)
(*                                                                      *)
(*     Calls:   RvsVideoOn                                              *)
(*              RvsVideoOff                                             *)
(*                                                                      *)
(*     Called by:                                                       *)
(*                                                                      *)
(*        View_A_File                                                   *)
(*        View_A_Directory                                              *)
(*        Get_Area_Code                                                 *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* View_Prompt *)

   View_Count := 1;
   View_Y     := WhereY;

   REPEAT

      GoToXY( 1 , View_Y );
      ClrEol;

      RvsVideoOn( Menu_Text_Color , BLACK );

      WRITE('Hit ENTER to continue, ESC to stop, ',
            'C to continue non-stop: ');
      ClrEol;

      RvsVideoOff( Menu_Text_Color , BLACK );

      Read_Kbd( View_Char[1] );

      IF ( View_Char[1] = CHR(ESC) ) THEN
         BEGIN
            IF PibTerm_KeyPressed THEN
               BEGIN
                  Read_Kbd( View_Char[1] );
                  View_Char[1] := ' ';
               END;
         END
      ELSE IF ( View_Char[1] IN ['S','s','C','c'] ) THEN
         View_Char[1] := UpCase( View_Char[1] )
      ELSE
         View_Char[1] := ' '

   UNTIL( View_Char[1] IN [ 'S', 'C', ' ', ^[ ] );

   CASE View_Char[1] Of
      'C':  View_Count := -MaxInt;
      'S',
      ^[ :  View_Done  := TRUE;
      ELSE
            ;
   END (* CASE *);

   GoToXY( 1 , View_Y );
   ClrEol;
   GoToXY( 1 , View_Y );

END  (* View_Prompt *);
