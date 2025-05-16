(*----------------------------------------------------------------------*)
(*           Read_Config_File --- Read configuration file               *)
(*----------------------------------------------------------------------*)

FUNCTION Read_Config_File : BOOLEAN;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Read_Config_File                                     *)
(*                                                                      *)
(*     Purpose:    Reads parameters from primary PibTerm config. file   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Read_Ok := Read_Config_File : BOOLEAN;                        *)
(*                                                                      *)
(*           Read_Ok --- TRUE if config file found, else FALSE.         *)
(*                                                                      *)
(*     Calls:   Get_Config_File_Line                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Ival       : INTEGER;
   OK_To_Read : BOOLEAN;
   I          : INTEGER;
   J          : INTEGER;
   Param_Num  : INTEGER;
   Param_Str  : AnyStr;
   Param_Ival : INTEGER;
   Param_Rval : LONGINT;
   Full_Name  : AnyStr;
   Config_File: Text_File;

BEGIN (* Read_Config_File *)
                                   (* Assign configuration file *)

  Add_Path( Config_File_Name, Home_Dir, Full_Name );

  ASSIGN( Config_File , Full_Name );
       (*!I-*)
  RESET( Config_File );
       (*!I+*)

  OK_To_Read := ( Int24Result = 0 );

  IF NOT OK_To_Read THEN           (* If config file missing, prompt *)
                                   (* user for input                 *)

     BEGIN (* No configuration file *)

        WRITELN;
        WRITELN('Can''t find configuration file ',Full_Name);

     END   (* No configuration file *)

  ELSE                            (* PIBTERM.CNF exists -- read it *)
     BEGIN  (* Config file exists *)

        WRITELN('Reading configuration file ',Full_Name);

        WHILE( Get_Config_File_Line( Config_File, Param_Num, Param_Str,
                                     Param_Ival, Param_Rval ) ) DO
           IF ( Param_Num > 0 ) THEN
              Set_Parameter( Param_Num, Param_Ival, Param_Rval, Param_Str );

        CLOSE( Config_File );

     END    (* Config file exists *);

   Read_Config_File := OK_To_Read;

END   (* Read_Config_File *);
