(*----------------------------------------------------------------------*)
(*        Display_Transfer_Types --- Display transfer type menu         *)
(*----------------------------------------------------------------------*)

PROCEDURE Display_Transfer_Types(     Menu_Title    : AnyStr;
                                      Menu_Default  : Transfer_Type;
                                      Allow_None    : BOOLEAN;
                                      Row           : INTEGER;
                                      Column        : INTEGER;
                                      Width         : INTEGER;
                                      Height        : INTEGER;
                                      Menu_Depth    : INTEGER;
                                      Menu_Erase    : BOOLEAN;
                                  VAR Transfer_Kind : Transfer_Type );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Display_Transfer_Types                               *)
(*                                                                      *)
(*     Purpose:    Display transfer type menu.                          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Display_Transfer_Types(     Menu_Title    : AnyStr;           *)
(*                                    Menu_Default  : Transfer_Type );  *)
(*                                    Allow_None    : BOOLEAN;          *)
(*                                    Row           : INTEGER;          *)
(*                                    Column        : INTEGER;          *)
(*                                    Width         : INTEGER;          *)
(*                                    Height        : INTEGER;          *)
(*                                    Menu_Depth    : INTEGER;          *)
(*                                    Menu_Erase    : BOOLEAN;          *)
(*                                VAR Transfer_Kind : Transfer_Type );  *)
(*                                                                      *)
(*           Menu_Title    --- Title for menu                           *)
(*           Menu_Default  --- Default transfer protocol                *)
(*           Allow_None    --- Allow "None" as transfer type            *)
(*           Row           --- Starting row for menu                    *)
(*           Column        --- Starting column for menu                 *)
(*           Width         --- Width for menu                           *)
(*           Height        --- Height for menu                          *)
(*           Menu_Depth    --- Depth for last menu item                 *)
(*           Menu_Erase    --- TRUE to erase menu when done             *)
(*           Transfer_Kind --- Type of transfer protocol selected       *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Transfer_Menu      : Menu_Type;
   Transfer_Menu_Size : INTEGER;
   I                  : INTEGER;
   J                  : INTEGER;
   Default            : INTEGER;
   T                  : Transfer_Type;
   Transfer_Names     : AnyStr;
   Trans_Prots        : ARRAY[1..Max_Transfer_Types] OF Transfer_Type;

BEGIN (* Display_Transfer_Types *)

                                   (* Figure number of transfer types *)
                                   (* defined                         *)
   Transfer_Menu_Size  := 11;
   Transfer_Names      := 'Ascii;Xmodem (Checksum);Xmodem (CRC);Kermit;Telink;Modem7 (Checksum);' +
                          'Modem7 (CRC);Xmodem 1K;Xmodem 1K G;Ymodem Batch;' +
                          'Ymodem G Batch;';

                                   (* Copy in types of built-in protocols *)
   Default := -1;

   FOR I := 1 TO 11 DO
      BEGIN
         Trans_Prots[I] := Transfers[I];
         IF ( Menu_Default = Trans_Prots[I] ) THEN
            Default := I;
      END;
                                   (* Add names of user-defined protocols *)
                                   (* to list.                            *)
   FOR T := PUser1 TO PUser10 DO
      IF ( Trans_Type_Name[T] <> '  ' ) THEN
         BEGIN
            Transfer_Names                  := Transfer_Names +
                                               LTrim( Transfer_Name_List[SUCC(ORD(T))] ) + ';';
            INC( Transfer_Menu_Size );
            Trans_Prots[Transfer_Menu_Size] := T;
            IF ( Menu_Default = Trans_Prots[Transfer_Menu_Size] ) THEN
               Default := Transfer_Menu_Size;
         END;
                                   (* Insert 'NONE' as last protocol *)
   IF Allow_None THEN
      BEGIN
         INC( Transfer_Menu_Size );
         Trans_Prots[Transfer_Menu_Size] := None;
         Transfer_Names                  := Transfer_Names + 'None;';
      END;
                                   (* Assume Xmodem checksum if no protocol *)
                                   (* selected, or None if possible.        *)
   IF ( Default < 0 ) THEN
      IF Allow_None THEN
         Default := Transfer_Menu_Size
      ELSE
         Default := 2;
                                   (* Get transfer menu *)

   Make_A_Menu( Transfer_Menu, Transfer_Menu_Size, Row, Column,
                               Width, Height, Default,
                               Menu_Title, Transfer_Names, TRUE );

                                   (* Alter item positions if necessary *)

   IF ( Transfer_Menu_Size > Menu_Depth ) THEN
      FOR I := SUCC( Menu_Depth ) TO Transfer_Menu_Size DO
         WITH Transfer_Menu.Menu_Entries[I] DO
            BEGIN
               Menu_Item_Row    :=
                  Transfer_Menu.Menu_Entries[I - Menu_Depth].Menu_Item_Row;
               Menu_Item_Column :=
                  Transfer_Menu.Menu_Entries[I - Menu_Depth].Menu_Item_Column + 30;
            END;
                                   (* Get transfer type *)

   Menu_Display_Choices( Transfer_Menu );

   I := Menu_Get_Choice( Transfer_Menu , Menu_Erase );

                                   (* Get transfer protocol *)
   IF ( I > 0 ) THEN
      Transfer_Kind := Trans_Prots[ I ]
   ELSE
      Transfer_Kind := None;

END   (* Display_Transfer_Types *);
