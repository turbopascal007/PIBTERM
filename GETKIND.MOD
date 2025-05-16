(*----------------------------------------------------------------------*)
(*      Get_Key_Index --- Get index of function key from short name     *)
(*----------------------------------------------------------------------*)

FUNCTION Get_Key_Index( Short_Name : AnyStr ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Get_Key_Index                                        *)
(*                                                                      *)
(*     Purpose:    Get index of function key from short name.           *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Key_Index( Short_Name : AnyStr ) : INTEGER;               *)
(*                                                                      *)
(*           Short_Name --- Short version of function key name          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I : INTEGER;

BEGIN (* Get_Key_Index *)
                                      (* Evict blanks from key name *)
   I := POS( ' ' , Short_Name );

   WHILE ( I > 0 ) DO
      BEGIN
         DELETE( Short_Name, I, 1 );
         I := POS( ' ' , Short_Name );
      END;

   Short_Name   := UpperCase( Short_Name );

                                   (* Assume key name not found *)
   Get_Key_Index := 0;
                                   (* Search for key name *)
   FOR I := 0 TO Max_Key_Def DO
      WITH Key_Definitions[I] DO
         IF ( Name <> '' ) THEN
            IF ( Name = Short_Name ) THEN
               BEGIN
                  Get_Key_Index := I;
                  EXIT;
               END;

END   (* Get_Key_Index *);
