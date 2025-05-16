(*----------------------------------------------------------------------*)
(*         Get_Parameter --- Get value of PibTerm parameter             *)
(*----------------------------------------------------------------------*)

PROCEDURE Get_Parameter(     Param_Num : INTEGER;
                         VAR Param_Str : AnyStr   );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  GetÿParameter                                        *)
(*                                                                      *)
(*     Purpose:    Get value of PibTerm parameter                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Get_Parameter(     Param_Num  : INTEGER;                      *)
(*                       VAR Param_Str  : AnyStr   );                   *)
(*                                                                      *)
(*           Param_Num  --- Parameter to get                            *)
(*           Param_Str  --- string parameter value                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   P_Ptr  : POINTER;
   P_IPtr : Param_IPtr_Type ABSOLUTE P_Ptr;
   P_XPtr : Param_XPtr_Type ABSOLUTE P_Ptr;
   P_SPtr : Param_SPtr_Type ABSOLUTE P_Ptr;
   P_CPtr : Param_CPtr_Type ABSOLUTE P_Ptr;
   P_LPtr : Param_LPtr_Type ABSOLUTE P_Ptr;
   P_BPtr : Param_BPtr_Type ABSOLUTE P_Ptr;
   P_TPtr : Param_TPtr_Type ABSOLUTE P_Ptr;
   P_FPtr : Param_FPtr_Type ABSOLUTE P_Ptr;
   P_DPtr : Param_DPtr_Type ABSOLUTE P_Ptr;
   P_OPtr : Param_OPtr_Type ABSOLUTE P_Ptr;
   P_WPtr : Param_WPtr_Type ABSOLUTE P_Ptr;

BEGIN (* Get_Parameter *)
                                   (* Get parameter address *)

   P_Ptr := Parameters[Param_Num].PAddr;

                                   (* Convert parameter value to string *)

   CASE Parameters[Param_Num].PType OF

      BColor_Param,
      Color_Param,
      Integer_Param,
      PosInt_Param  : STR( P_IPtr^ , Param_Str );

      FileN_Param,
      String_Param,
      Path_Param,
      Box_Param,
      ExtTrans_Param: Param_Str := Write_Ctrls( P_SPtr^ );

      VidMode_Param : CASE New_Text_Mode OF
                         BW80: Param_Str := 'B';
                         Mono: Param_Str := 'M';
                         ELSE  Param_Str := 'C';
                      END (* CASE *);

      KCheck_Param,
      Char_Param    : Param_Str := P_CPtr^;

      SpecChar_Param: Param_Str := Write_Ctrls( P_CPtr^ );

      LongInt_Param : STR( P_XPtr^ , Param_Str );

      Boolean_Param : Param_Str := CHR( ORD( P_LPtr^ ) + ORD( '0' ) );

      Byte_Param    : STR( P_BPtr^ , Param_Str );

      Transfer_Param: Param_Str := Trans_Type_Name[ P_FPtr^ ];

      Terminal_Param: STR( ORD( P_TPtr^ ) , Param_Str );

      Date_Param    : CASE Date_Format OF
                         YMD_Style: Param_Str := 'YMD';
                         MDY_Style: Param_Str := 'MDY';
                         DMY_Style: Param_Str := 'DMY';
                      END (* CASE *);

      Time_Param    : IF ( Time_Format = AMPM_Time ) THEN
                         Param_Str := 'AMPM'
                      ELSE IF ( Time_Format = Military_Time ) THEN
                         Param_Str := 'MILITARY';

      ScrOrder_Param: STR( ORD( P_OPtr^ ) , Param_Str );

      Hexi_Param    : Param_Str := Dec_To_Hex( P_WPtr^ );

      Word_Param    : STR( P_WPtr^ , Param_Str );

      Host_Param    : IF Host_Mode THEN
                         Param_Str := Privilege
                      ELSE
                         Param_Str := ' ';
      ELSE
                      Param_Str := '';

   END (* CASE *);

END   (* Get_Parameter *);

(*----------------------------------------------------------------------*)
(*    Write_Config_File --- Write updated PibTerm configuration file    *)
(*----------------------------------------------------------------------*)

PROCEDURE Write_Config_File( Config_File_Name : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Write_Config_File                                    *)
(*                                                                      *)
(*     Purpose:    Writes updated parameters to PibTerm config. file    *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Write_Config_File;                                            *)
(*                                                                      *)
(*      Calls:   Get_Parameter                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   S          : AnyStr;
   I          : INTEGER;
   Written    : ARRAY[1..Max_Param_Names] OF BOOLEAN;
   SName      : String12;
   RName      : String12;
   T          : Transfer_Type;
   SingleF    : CHAR;
   HostOK     : CHAR;
   Config_File: Text_File;

(*----------------------------------------------------------------------*)

PROCEDURE Write_One_Parameter( Name : Char_2; Index : INTEGER );

VAR
   S    : AnyStr;
   Ierr : INTEGER;

BEGIN (* Write_One_Parameter *)

   IF ( Index <= 0 ) THEN
      Index := Look_Up_Parameter( Name )
   ELSE
      Name  := Parameters[ Index ].PName;

   IF ( ( Index > 0 ) AND ( NOT ( Name[1] IN Digits ) ) ) THEN
      BEGIN
         Written[Index] := TRUE;
         Get_Parameter( Index , S );
         WRITELN( Config_File , Name, '=', S );
         Ierr := INT24Result;
      END;

END   (* Write_One_Parameter *);

(*----------------------------------------------------------------------*)

BEGIN (* Write_Config_File *)
                                   (* Fix up config file name *)

   IF ( LENGTH( Config_File_Name ) = 0 ) THEN
      Config_File_Name := 'PIBTERM.CNF';

   Add_Path( Config_File_Name, Home_Dir, Config_File_Name );

   ASSIGN( Config_File, Config_File_Name );
             (*!I-*)
   REWRITE( Config_File );
             (*!I+*)

   IF ( Int24Result <> 0 ) THEN
      BEGIN
         WRITELN;
         WRITELN('Can''t write to ',Config_File_Name);
      END
   ELSE
      BEGIN  (* Write configuration file *)

                                   (* No parameters written yet *)

         FOR I := 1 TO Max_Param_Names DO
            Written[I] := FALSE;

                                   (* Write function key guys first *)

         Write_One_Parameter( 'FC' , 0 );
         Write_One_Parameter( 'FD' , 0 );
         Write_One_Parameter( 'FW' , 0 );
         Write_One_Parameter( 'FM' , 0 );
         Write_One_Parameter( 'FS' , 0 );

                                   (* Don't write special guys *)

         Written[Look_Up_Parameter('FN')] := TRUE;
         Written[Look_Up_Parameter('HP')] := TRUE;

                                   (* Write other parameter definitions *)

         FOR I := 1 TO Max_Param_Names DO
            IF ( NOT Written[I] ) THEN
               Write_One_Parameter( '  ' , I );

      END   (* Write configuration file *);

      (*!I-*)
   CLOSE( Config_File );
      (*!I+*)

   I := Int24Result;

END   (* Write_Config_File *);

