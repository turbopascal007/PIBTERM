(*----------------------------------------------------------------------*)
(*      Get_Long_Key_Name --- Get long version of function key name.    *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Long_Key_Name(     Short_Name : AnyStr;
                             VAR Long_Name  : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Long_Key_Name                                    *)
(*                                                                      *)
(*     Purpose:    Gets long version of function key name.              *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Long_Key_Name(     Short_Name : AnyStr;                   *)
(*                           VAR Long_Name  : AnyStr  );                *)
(*                                                                      *)
(*           Short_Name --- Short version of function key name          *)
(*           Long_Name  --- Long version of function key name           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I         : INTEGER;
   Last_Ch   : CHAR;
   Extended  : BOOLEAN;
   Pg_Found  : BOOLEAN;

LABEL 1;

BEGIN (* Get_Long_Key_Name *)

   Long_Name := '';
   Last_Ch   := ' ';
   Extended  := FALSE;
   Pg_Found  := FALSE;

   FOR I := 1 TO LENGTH( Short_Name ) Do
      BEGIN

         CASE Short_Name[I] OF
            ' '      : ;
            'X'      : BEGIN
                          Long_Name := Long_Name + 'Ext ';
                          Extended  := TRUE;
                       END;
            'A'      : Long_Name := Long_Name + 'Alt ';
            'C'      : Long_Name := Long_Name + 'Ctrl ';
            'S'      : Long_Name := Long_Name + 'Shift ';
            'K'      : Long_Name := Long_Name + 'Kpd ';
            'N'      : Long_Name := Long_Name + 'Alt ';
            'F'      : Long_Name := Long_Name + 'F';
            'P'      : IF ( NOT Extended ) THEN
                          BEGIN
                             Long_Name := Long_Name + 'PrtSc';
                             GOTO 1;
                          END
                       ELSE
                          BEGIN
                             Long_Name := Long_Name + 'Pg';
                             Pg_Found  := TRUE;
                          END;
            'E'      : IF ( NOT Extended ) THEN
                          BEGIN
                             Long_Name := Long_Name + 'Enter';
                             GOTO 1;
                          END
                       ELSE
                          IF ( Last_Ch = 'D' ) THEN
                             Long_Name := COPY( Long_Name, 1,
                                                LENGTH( Long_Name ) - 4 ) +
                                                'Del'
                          ELSE
                             Long_Name := Long_Name + 'End';
            'H'      : Long_Name := Long_Name + 'Home';
            'I'      : Long_Name := Long_Name + 'Ins';
            'U'      : Long_Name := Long_Name + 'Up';
            'D'      : IF ( NOT Pg_Found ) THEN
                          Long_Name := Long_Name + 'Down'
                       ELSE
                          Long_Name := Long_Name + 'Dn';
            'L'      : Long_Name := Long_Name + 'Left';
            'R'      : Long_Name := Long_Name + 'Right';
            'B'      : BEGIN
                          Long_Name := Long_Name + 'Backspace';
                          GOTO 1;
                       END;
            '0'..'9' : BEGIN
                          IF ( Last_Ch IN ['C','S','A'] ) THEN
                             Long_Name := Long_Name + 'F';
                          Long_Name := Long_Name + Short_Name[I];
                       END;
            ELSE  Long_Name := Long_Name + Short_Name[I];
         END (* CASE *);

         IF ( Short_Name[I] <> ' ' ) THEN
            Last_Ch := Short_Name[I] ;

      END;

1:
   Long_Name[1] := UpCase( Long_Name[1] );

END   (* Get_Long_Key_Name *);
