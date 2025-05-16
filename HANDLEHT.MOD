(*----------------------------------------------------------------------*)
(*            Handle_Tab --- Process horizontal tab sequence            *)
(*----------------------------------------------------------------------*)

PROCEDURE Handle_Tab( VAR Tabs : Tab_Stop_Vector; NTabs : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Handle_Tab                                           *)
(*                                                                      *)
(*     Purpose:    Handle horizontal tab character for VT52, VT100.     *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Handle_Tab( VAR Tabs : Tab_Stop_Vector; NTabs : INTEGER );    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Curcol : INTEGER;
   ITab   : INTEGER;
   TabCol : INTEGER;

BEGIN (* Handle_Tab *)

   Curcol := WhereX;

   IF ( Curcol > Wrap_Screen_Col ) THEN
      Curcol := Wrap_Screen_Col;

   IF ( NTabs > 0 ) THEN
      BEGIN

         ITab   := 1;

         WHILE ( ( ITab <= NTabs ) AND
                 ( Curcol >= Tabs[ITab] ) ) DO
            INC( ITab );

         IF ( ITab <= NTabs ) THEN
            TabCol := Tabs[ITab]
         ELSE
            TabCol := Wrap_Screen_Col;

      END
   ELSE
      TabCol := Curcol;

   IF Double_Width_Mode THEN
      BEGIN
         TabCol := PRED( TabCol * 2 );
         IF ( TabCol > Wrap_Screen_Col ) THEN
            CASE ODD( Wrap_Screen_Col ) OF
               TRUE : TabCol := Wrap_Screen_Col;
               FALSE: TabCol := PRED( Wrap_Screen_Col );
            END (* CASE *);
      END;

   MoveToXY( TabCol , WhereY );

   IF Review_On THEN
      FOR ITab := CurCol TO ( TabCol - 1 ) DO
         IF ( LENGTH( Review_Line ) < Max_Review_Line_Length ) THEN
            Review_Line := Review_Line + ' ';

   IF ( Capture_On AND Exact_Capture ) THEN
      Capture_Char( CHR( HT ) );

   IF Printer_On THEN
      FOR ITab := CurCol TO ( TabCol - 1 ) DO
         Write_Prt( ' ' );

END   (* Handle_Tab *);
