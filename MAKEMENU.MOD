(*----------------------------------------------------------------------*)
(*                Make_A_Menu --- Set up a menu                         *)
(*----------------------------------------------------------------------*)

PROCEDURE Make_A_Menu( VAR Menu     : Menu_Type;
                           Size     : INTEGER;
                           Row      : INTEGER;
                           Column   : INTEGER;
                           Width    : INTEGER;
                           Height   : INTEGER;
                           Default  : INTEGER;
                           Title    : AnyStr;
                           Texts    : AnyStr;
                           GenLet   : BOOLEAN     );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       Procedure:   Make_A_Menu                                       *)
(*                                                                      *)
(*       Purpose:     Set up a menu                                     *)
(*                                                                      *)
(*       Calling Sequence:                                              *)
(*                                                                      *)
(*          Make_A_Menu( VAR Menu     : Menu_Type;                      *)
(*                           Size     : INTEGER;                        *)
(*                           Row      : INTEGER;                        *)
(*                           Column   : INTEGER;                        *)
(*                           Width    : INTEGER;                        *)
(*                           Height   : INTEGER;                        *)
(*                           Default  : INTEGER;                        *)
(*                           Title    : AnyStr;                         *)
(*                           Texts    : AnyStr;                         *)
(*                           GenLet   : BOOLEAN     );                  *)
(*                                                                      *)
(*             Menu    --- Menu to be initialized                       *)
(*             Size    --- Number of entries in menu                    *)
(*             Row     --- Row position of upper left hand corner       *)
(*             Column  --- Column position of upper left hand corner    *)
(*             Width   --- Width of menu                                *)
(*             Height  --- Height of menu                               *)
(*             Default --- Default entry for menu                       *)
(*             Title   --- Title for menu                               *)
(*             Texts   --- Texts of menu item entries, each ended by a  *)
(*                         semicolon.                                   *)
(*             GenLet  --- Add x) to front of each menu item.           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I         : INTEGER;
   Text_Pos  : INTEGER;
   Prev_Pos  : INTEGER;
   Null_Texts: BOOLEAN;

CONST
   Letters  : ARRAY[1..26] OF CHAR =
              ('a','b','c','d','e','f','g','h','i','j',
               'k','l','m','n','o','p','r','s','t','u',
               'v','w','x','y','z','q');

BEGIN (* Make_A_Menu *)
                                   (* Set menu attributes *)
   WITH Menu DO
      BEGIN

         Menu_Size    := Size;
         Menu_Row     := Row;
         Menu_Column  := Column;
         Menu_Tcolor  := Menu_Text_Color;
         Menu_Hcolor  := Menu_Title_Color;
         Menu_Bcolor  := BLACK;
         Menu_Fcolor  := Menu_Frame_Color;
         Menu_Width   := Width;
         Menu_Height  := Height;
         Menu_Default := Default;

      END (* WITH Menu *);

   Text_Pos   := 1;
   Null_Texts := ( LENGTH( Texts ) = 0 );
   GenLet     := GenLet AND ( NOT Null_Texts );

                                   (* Get menu item text *)
   FOR I := 1 TO Size DO
      WITH Menu.Menu_Entries[I] DO
      BEGIN

         Menu_Item_Row    := I;
         Menu_Item_Column := 2;
         Prev_Pos         := Text_Pos;

         IF ( NOT Null_Texts ) THEN
            BEGIN
               WHILE( Texts[Text_Pos] <> ';' ) DO
                  INC( Text_Pos );
               Menu_Item_Text   := COPY( Texts, Prev_Pos, Text_Pos - Prev_Pos );
               INC( Text_Pos );
            END
         ELSE
            Menu_Item_Text := '';

         IF GenLet THEN
            IF ( Menu_Item_Text <> 'Quit' ) THEN
               Menu_Item_Text := Letters[I] + ') ' + Menu_Item_Text
            ELSE
               Menu_Item_Text := 'q) Quit';

      END;

   Menu.Menu_Title := Title;

END   (* Make_A_Menu *);