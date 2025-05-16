FUNCTION CompareStr( VAR S1, S2 : AnyStr ) : Comparer;

BEGIN (* CompareStr *)

   IF ( S1 = S2 ) THEN
      CompareStr := Equal
   ELSE IF ( S1 < S2 ) THEN
      CompareStr := Less
   ELSE
      CompareStr := Greater;

END   (* CompareStr *);