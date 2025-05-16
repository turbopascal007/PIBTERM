PROCEDURE Signal_End_Of_Transfer( Transfer_Protocol : Transfer_Type );

VAR
   I: INTEGER;

BEGIN (* Signal_End_Of_Transfer *)

   IF ( ( Transfer_Protocol <> None    ) AND
        ( Transfer_Protocol <> Kermit  )     ) THEN
      FOR I := 1 TO Transfer_Bells DO
         Menu_Beep;

END   (* Signal_End_Of_Transfer *);