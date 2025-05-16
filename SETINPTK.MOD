(*----------------------------------------------------------------------*)
(*                Set_Input_Keys --- Set Input Key Values               *)
(*----------------------------------------------------------------------*)

PROCEDURE Set_Input_Keys( File_Name : AnyStr; Tell : BOOLEAN );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Set_Input_Keys                                       *)
(*                                                                      *)
(*     Purpose:    Set values of function keys and keypad keys          *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Set_Input_Keys( File_Name : AnyStr; Tell : BOOLEAN );         *)
(*                                                                      *)
(*           If not null is file name to read key definitions from.     *)
(*                                                                      *)
(*     Calls:                                                           *)
(*               Menu_Display_Choices                                   *)
(*               Menu_Get_Choices                                       *)
(*               Read_Key_Defs_From_File;                               *)
(*               Get_Key_Defs_From_Keyboard;                            *)
(*               Write_Key_Defs_To_File;                                *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        This whole section of code should be reworked to use          *)
(*        full-screen editing at some point.                            *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

CONST
   Quit_Item = 5;

VAR
   Input_Key_Menu      : Menu_Type;
   Done                : BOOLEAN;
   Key_Type            : INTEGER;

BEGIN (* Set_Input_Keys *)
                                   (* If file name specified, get keys *)
                                   (* from specified file.             *)

   IF LENGTH( File_Name ) > 0 THEN
      BEGIN
         Read_Key_Defs_From_File( File_Name , Tell );
         EXIT;
      END;

   Make_A_Menu( Input_Key_Menu, Quit_Item, 11, 15, 0, 0, Quit_Item,
                'Function key definition: ',
                'D)isplay current definitions;E)nter definitions from keyboard;' +
                'R)ead definitions from file;' +
                'W)rite definitions to file;Q)uit key definition;',
                FALSE );

                                   (* Loop until quit chosen *)
   Done := FALSE;

   REPEAT
                                   (* Display menu of choices *)

      Menu_Display_Choices( Input_Key_Menu );
      Key_Type := Menu_Get_Choice( Input_Key_Menu , Erase_Menu );

                                   (* Do requested operation *)
      CASE Key_Type OF

         1: Display_Current_Key_Defs;
         2: Get_Key_Defs_From_Keyboard;
         3: Read_Key_Defs_From_File( File_Name , TRUE );
         4: Write_Key_Defs_To_File;
         ELSE
            Done := TRUE;

      END (* CASE *);

      Input_Key_Menu.Menu_Default := Quit_Item;

   UNTIL Done;

END   (* Set_Input_Keys *);
