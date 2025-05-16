(*----------------------------------------------------------------------*)
(*        Make_And_Display_Menu --- Set up a menu and display it        *)
(*----------------------------------------------------------------------*)

PROCEDURE Make_And_Display_Menu( VAR Menu     : Menu_Type;
                                     Size     : INTEGER;
                                     Row      : INTEGER;
                                     Column   : INTEGER;
                                     Width    : INTEGER;
                                     Height   : INTEGER;
                                     Default  : INTEGER;
                                     Title    : AnyStr;
                                     Texts    : AnyStr;
                                     GenLet   : BOOLEAN;
                                     Erase_It : BOOLEAN;
                                 VAR Choice   : INTEGER );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*       Procedure:   Make_And_Display_Menu                             *)
(*                                                                      *)
(*       Purpose:     Set up a menu and display it                      *)
(*                                                                      *)
(*       Calling Sequence:                                              *)
(*                                                                      *)
(*          Make_And_Display_Menu( VAR Menu     : Menu_Type;            *)
(*                                     Size     : INTEGER;              *)
(*                                     Row      : INTEGER;              *)
(*                                     Column   : INTEGER;              *)
(*                                     Width    : INTEGER;              *)
(*                                     Height   : INTEGER;              *)
(*                                     Default  : INTEGER;              *)
(*                                     Title    : AnyStr;               *)
(*                                     Texts    : AnyStr;               *)
(*                                     GenLet   : BOOLEAN;              *)
(*                                     Erase_It : BOOLEAN;              *)
(*                                 VAR Choice   : INTEGER );            *)
(*                                                                      *)
(*             Menu     --- Menu to be initialized                      *)
(*             Size     --- Number of entries in menu                   *)
(*             Row      --- Row position of upper left hand corner      *)
(*             Column   --- Column position of upper left hand corner   *)
(*             Width    --- Width of menu                               *)
(*             Height   --- Height of menu                              *)
(*             Default  --- Default entry for menu                      *)
(*             Title    --- Title for menu                              *)
(*             Texts    --- Texts of menu item entries, each ended by a *)
(*                          semicolon.                                  *)
(*             GenLet   --- Add x) to front of each menu item.          *)
(*             Erase_It --- TRUE to erase menu after displaying it      *)
(*             Choice   --- resultant choice                            *)
(*                                                                      *)
(*       Calls:                                                         *)
(*                                                                      *)
(*          Make_A_Menu                                                 *)
(*          Menu_Display_Choices                                        *)
(*          Menu_Get_Choice                                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Make_And_Display_Menu *)
                                   (* Set up menu *)

   Make_A_Menu( Menu, Size, Row, Column, Width, Height, Default,
                Title, Texts, GenLet );

                                   (* Display menu *)
   Menu_Display_Choices( Menu );
                                   (* Get choice *)

   Choice := Menu_Get_Choice( Menu , Erase_It );

END   (* Make_And_Display_Menu *);