(*----------------------------------------------------------------------*)
(*            Define_Key --- Define a function/keypad key               *)
(*----------------------------------------------------------------------*)

PROCEDURE Define_Key( Key_Name : AnyStr;
                      Key_Text : AnyStr  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Define_Key                                           *)
(*                                                                      *)
(*     Purpose:    Defines a function/keypad key string                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Define_Key( Key_Name : AnyStr;                                *)
(*                    Key_Text : AnyStr  );                             *)
(*                                                                      *)
(*           Key_Name --- Name of key to define                         *)
(*           Key_Text --- Text of key to be defined                     *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Key_Number : INTEGER;
   LKey_Text  : INTEGER;
   LDef       : INTEGER;

BEGIN (* Define_Key *)
                                   (* Get index of key *)

   Key_Number := Get_Key_Index( Key_Name );

                                   (* Insert key text *)

   IF ( Key_Number >= 0 ) THEN
      WITH Key_Definitions[Key_Number] DO
         BEGIN

            Key_Text  := Read_Ctrls( Key_Text );
            LKey_Text := LENGTH( Key_Text );

            IF ( Def = NIL ) THEN
               GETMEM( Def , SUCC( LKey_Text ) );

            IF ( Def <> NIL ) THEN
               BEGIN
                  LDef := LENGTH( Def^ );
                  IF ( LKey_Text > LDef ) THEN
                     IF ( ( Key_Number <> BS_Key ) AND
                          ( Key_Number <> Ctrl_BS_Key ) ) THEN
                        BEGIN
                           MyFreeMem( Def , SUCC( LDef ) );
                           GETMEM   ( Def , SUCC( LKey_Text ) );
                        END;
                  IF ( Def <> NIL ) THEN
                     Def^ := Key_Text;
               END;

         END;

END   (* Define_Key *);