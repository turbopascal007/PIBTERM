(*----------------------------------------------------------------------*)
(*          Update_Review_Pointers --- Update review buffer pointers    *)
(*----------------------------------------------------------------------*)

PROCEDURE Update_Review_Pointers;

VAR
   L: INTEGER;
   I: INTEGER;

BEGIN (* Update_Review_Pointers *)

                                   (* Append CR/LF as needed *)

   Review_Line := Review_Line + CHR( CR ) + CHR( LF );

   FOR I := 1 TO LENGTH( Review_Line ) DO
      BEGIN
                                   (* Increment capture pointer           *)

         IF ( Review_Head = Max_Review_Length ) THEN
            Review_Head := 1
         ELSE
            INC( Review_Head );
                                   (* If we wrapped into last char,       *)
                                   (* update last char pointer            *)

         IF ( Review_Head = Review_Tail ) THEN
            BEGIN
               IF ( Review_Tail = Max_Review_Length ) THEN
                  Review_Tail := 1
               ELSE
                  INC( Review_Tail );
            END;

         IF ( Review_Tail = 0 ) THEN
            Review_Tail := 1;

         Review_Buffer^[Review_Head] := Review_Line[I];

      END;

   Review_Line := '';

END   (* Update_Review_Pointers *);
