(*----------------------------------------------------------------------*)
(*        PIBDIR.PAS --- MSDOS Directory Routines for Turbo Pascal      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Author:  Philip R. Burns                                            *)
(*  Version: 1.0  (January,1985)                                        *)
(*           2.0  (June,1985)                                           *)
(*           3.0  (October,1985)                                        *)
(*           4.0  (May,1986)                                            *)
(*  Systems: For MS-DOS on IBM PCs and close compatibles only.          *)
(*           Note:  I have checked these on Zenith 151s under           *)
(*                  MSDOS 2.1 and IBM PCs under PCDOS 2.0.              *)
(*                                                                      *)
(*  Needs:   Global types from PIBTERM.GLO.                             *)
(*                                                                      *)
(*  History: Original with me.                                          *)
(*                                                                      *)
(*           Suggestions for improvements or corrections are welcome.   *)
(*           Please leave messages on Gene Plantz's BBS (312) 882 4145  *)
(*           or Ron Fox's BBS (312) 940 6496.                           *)
(*                                                                      *)
(*           IF you use this code in your own programs, please be nice  *)
(*           and give proper credit.                                    *)
(*                                                                      *)
(*----------------------------------------------------------------------*)
(*                                                                      *)
(*  Routines:                                                           *)
(*                                                                      *)
(*      Convert_AsciiZ_To_String                                        *)
(*      Convert_String_To_AsciiZ                                        *)
(*      Dir_Get_Default_Drive                                           *)
(*      Dir_Set_Default_Drive                                           *)
(*      Dir_Get_Current_Path                                            *)
(*      Dir_Set_Current_Path                                            *)
(*      Dir_Set_Disk_Transfer_Address                                   *)
(*      Dir_Delete_File                                                 *)
(*      Dir_Count_Drives                                                *)
(*      Dir_Convert_Time                                                *)
(*      Dir_Convert_Date                                                *)
(*      Dir_Find_First_File                                             *)
(*      Dir_Find_Next_File                                              *)
(*      Dir_Get_Free_Space                                              *)
(*      Dir_Set_File_Date_And_Time                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

PROCEDURE Convert_AsciiZ_To_String( VAR S: AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Convert_AsciiZ_To_String                             *)
(*                                                                      *)
(*     Purpose:    Convert Ascii Z string to Turbo String               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Convert_AsciiZ_To_String( VAR S: AnyStr );                    *)
(*                                                                      *)
(*           S --- Ascii Z string to be turned into Turbo string        *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        None                                                          *)
(*                                                                      *)
(*     Remarks:                                                         *)
(*                                                                      *)
(*        The string S is assumed to have already received the Ascii Z  *)
(*        string in its [1]st thru [l]th locations.                     *)
(*        This routine searches for the 0-character marking the end of  *)
(*        the string and changes the Turbo string length (in S[0]) to   *)
(*        reflect the actual string length.                             *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   I: INTEGER;

BEGIN (* Convert_AsciiZ_To_String *)

   I := 1;

   WHILE( S[I] <> CHR(0) ) DO
      I := SUCC( I );

   S[0] := CHR( PRED( I ) );

END   (* Convert_AsciiZ_To_String *);

(*----------------------------------------------------------------------*)
(*   Convert_String_To_AsciiZ -- Convert Turbo string to Ascii Z String *)
(*----------------------------------------------------------------------*)

PROCEDURE Convert_String_To_AsciiZ( VAR S: AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Convert_String_To_AsciiZ                             *)
(*                                                                      *)
(*     Purpose:    Convert Turbo string to ascii Z string               *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Convert_String_To_AsciiZ( VAR S: AnyStr );                    *)
(*                                                                      *)
(*           S --- Turbo string to be turned into Ascii Z string        *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        None                                                          *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

BEGIN (* Convert_String_To_AsciiZ *)

   S := S + CHR( 0 );

END   (* Convert_String_To_AsciiZ *);

(*----------------------------------------------------------------------*)
(*     Dir_Get_Current_Path -- Get current directory path name          *)
(*----------------------------------------------------------------------*)

FUNCTION Dir_Get_Current_Path( Drive         : CHAR;
                               VAR Path_Name : AnyStr ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Dir_Get_Current_Path                                 *)
(*                                                                      *)
(*     Purpose:    Gets text of current directory path name             *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Iok := Dir_Get_Current_Path( Drive : CHAR;                    *)
(*                                     VAR Path_Name : AnyStr ) :       *)
(*                                     INTEGER;                         *)
(*                                                                      *)
(*           Drive      --- Drive to look on                            *)
(*           Path_Name  --- returned current path name                  *)
(*                                                                      *)
(*           Iok        --- 0 if all went well, else DOS return code    *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        MsDos                                                         *)
(*        Convert_String_To_AsciiZ                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dir_Reg: Registers;

BEGIN (* Dir_Get_Current_Path *)

    Dir_Reg.Ah := $47;
    Dir_Reg.Ds := SEG( Path_Name[1] );
    Dir_Reg.Si := OFS( Path_Name[1] );
    Dir_Reg.Dl := ORD( UpCase( Drive ) ) - ORD( '@' );

    MsDos( Dir_Reg );

    IF ( Carry_Flag AND Dir_Reg.Flags ) = 0 THEN
       BEGIN
          Dir_Get_Current_Path := 0;
          Convert_AsciiZ_To_String( Path_Name );
       END
    ELSE
       Dir_Get_Current_Path := Dir_Reg.Ax;

END   (* Dir_Get_Current_Path *);

(*----------------------------------------------------------------------*)
(*     Dir_Set_Current_Path -- Set current directory path name          *)
(*----------------------------------------------------------------------*)

FUNCTION Dir_Set_Current_Path( Path_Name : AnyStr ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Dir_Set_Current_Path                                 *)
(*                                                                      *)
(*     Purpose:    Sets new current directory path name                 *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Iok := Dir_Set_Current_Path( Path_Name : AnyStr ) :           *)
(*                                     INTEGER;                         *)
(*                                                                      *)
(*           Path_Name  --- New current path name                       *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        MsDos                                                         *)
(*        Convert_AsciiZ_To_String                                      *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dir_Reg: Registers;
   I      : INTEGER;

BEGIN (* Dir_Set_Current_Path *)

   Convert_String_To_AsciiZ( Path_Name );

   Dir_Reg.Ah := $3B;
   Dir_Reg.Ds := SEG( Path_Name[1] );
   Dir_Reg.Dx := OFS( Path_Name[1] );

   MsDos( Dir_Reg );

   IF ( Carry_Flag AND Dir_Reg.Flags ) = 0 THEN
      Dir_Set_Current_Path := 0
   ELSE
      Dir_Set_Current_Path := Dir_Reg.Ax;

END   (* Dir_Set_Current_Path *);


(*----------------------------------------------------------------------*)
(*     Dir_Set_Disk_Transfer_Address --- Set DMA address for disk I/O   *)
(*----------------------------------------------------------------------*)

PROCEDURE Dir_Set_Disk_Transfer_Address( VAR DMA_Buffer );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Dir_Set_Disk_Transfer_Address                        *)
(*                                                                      *)
(*     Purpose:    Sets DMA address for disk transfers                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Dir_Set_Disk_Transfer_Address( VAR DMA_Buffer );              *)
(*                                                                      *)
(*           DMA_Buffer --- direct memory access buffer                 *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        MsDos                                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dir_Reg: Registers;

BEGIN (* Dir_Set_Disk_Transfer_Address *)

   Dir_Reg.Ax := $1A00;
   Dir_Reg.Ds := SEG( DMA_Buffer );
   Dir_Reg.Dx := OFS( DMA_Buffer );

   MsDos( Dir_Reg );

END   (* Dir_Set_Disk_Transfer_Address *);

(*----------------------------------------------------------------------*)
(*            Dir_Set_Default_Drive --- Set Default Drive               *)
(*----------------------------------------------------------------------*)

PROCEDURE Dir_Set_Default_Drive( Drive: CHAR );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure:  Dir_Set_Default_Drive                                *)
(*                                                                      *)
(*     Purpose:    Sets default drive for disk I/O                      *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Dir_Set_Default_Drive( Drive : CHAR );                        *)
(*                                                                      *)
(*           Drive --- letter of default drive                          *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        MsDos                                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dir_Reg: Registers;

BEGIN  (* Dir_Set_Default_Drive *)

   Dir_Reg.Ah := $0E;
   Dir_Reg.Dl := ORD( UpCase( Drive ) ) - ORD( 'A' );

   MsDos( Dir_Reg );

END   (* Dir_Set_Default_Drive *);

(*----------------------------------------------------------------------*)
(*            Dir_Get_Default_Drive --- Get Default Drive               *)
(*----------------------------------------------------------------------*)

FUNCTION Dir_Get_Default_Drive: CHAR;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:  Dir_Get_Default_Drive                                 *)
(*                                                                      *)
(*     Purpose:   Gets default drive for disk I/O                       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Def_Drive := Dir_Get_Default_Drive : CHAR;                    *)
(*                                                                      *)
(*           Def_Drive --- Letter of default drive                      *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        MsDos                                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dir_Reg: Registers;

BEGIN  (* Dir_Get_Default_Drive *)

   Dir_Reg.Ah := $19;

   MsDos( Dir_Reg );

   Dir_Get_Default_Drive := CHR( Dir_Reg.Al + ORD( 'A' ) );

END   (* Dir_Get_Default_Drive *);

(*----------------------------------------------------------------------*)
(*            Dir_Count_Drives --- Count number of drives in system     *)
(*----------------------------------------------------------------------*)

FUNCTION Dir_Count_Drives : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:  Dir_Count_Drives                                      *)
(*                                                                      *)
(*     Purpose:   Finds number of installed DOS drives                  *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        ndrives := Dir_Count_Drives : INTEGER;                        *)
(*                                                                      *)
(*           ndrives --- number of drives in system                     *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        MsDos                                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dir_Reg: Registers;

BEGIN  (* Dir_Count_Drives *)

   Dir_Reg.Ah := $19;

   MsDos( Dir_Reg );

   Dir_Reg.Ah := $0E;
   Dir_Reg.Dl := Dir_Reg.Al;

   MsDos( Dir_Reg );

   Dir_Count_Drives := Dir_Reg.Al;

END   (* Dir_Count_Drives *);

(*----------------------------------------------------------------------*)
(*            Dir_Convert_Time --- Convert directory creation time      *)
(*----------------------------------------------------------------------*)

PROCEDURE Dir_Convert_Time ( Time : WORD; VAR S_Time : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Dir_Convert_Time                                      *)
(*                                                                      *)
(*     Purpose:   Convert creation time from directory to characters.   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Dir_Convert_Time( Time       : WORD;                          *)
(*                          VAR S_Time : AnyStr ) : INTEGER;            *)
(*                                                                      *)
(*           Time   --- time as read from directory                     *)
(*           S_Time --- converted time in hh:mm am/pm                   *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        STR                                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   HH   : String[2];
   MM   : String[2];
   SS   : String[2];
   AmPm : String[2];
   Hour : INTEGER;

BEGIN (* Dir_Convert_Time *)

   IF ( Time = 0 ) THEN

      S_Time := '        '

   ELSE
      CASE Time_Format OF

         Military_Time : BEGIN

                            STR( ( Time SHR 11 ):2 , HH );
                            IF HH[1] = ' ' THEN HH[1] := '0';

                            STR( ( ( Time AND $07E0 ) SHR 5 ):2 , MM );
                            IF MM[1] = ' ' THEN MM[1] := '0';

                            STR( ( ( Time AND $001F ) * 2 ):2 , SS );
                            IF SS[1] = ' ' THEN SS[1] := '0';

                            S_Time := HH + ':' + MM + ':' + SS;

                         END;

         AMPM_Time     : BEGIN

                            Hour := ( Time SHR 11 );

                            Adjust_Hour( Hour , AmPm );

                            STR( Hour:2 , HH );

                            STR( ( ( Time AND $07E0 ) SHR 5 ):2 , MM );
                            IF MM[1] = ' ' THEN MM[1] := '0';

                            S_Time := HH + ':' + MM + ' ' + AmPm;

                         END;

      END (* CASE *);

END  (* Dir_Convert_Time *);

(*----------------------------------------------------------------------*)
(*            Dir_Convert_Date --- Convert directory creation date      *)
(*----------------------------------------------------------------------*)

PROCEDURE Dir_Convert_Date ( Date : WORD; VAR S_Date : AnyStr );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Procedure: Dir_Convert_Date                                      *)
(*                                                                      *)
(*     Purpose:   Convert creation date from directory to characters.   *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Dir_Convert_Date( Date       : WORD;                          *)
(*                          VAR S_Date : AnyStr ) : INTEGER;            *)
(*                                                                      *)
(*           Date   --- date as read from directory                     *)
(*           S_Date --- converted date in yy/mm/dd                      *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        STR                                                           *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   YY : String[2];
   MM : String[2];
   DD : String[2];

BEGIN (* Dir_Convert_Date *)

   STR( ( 80 + ( Date SHR 9 ) ) : 2 , YY );

   STR( ( ( Date AND $01E0 ) SHR 5 ):2 , MM );
   IF MM[1] = ' ' THEN MM[1] := '0';

   STR( ( Date AND $001F ):2 , DD );
   IF DD[1] = ' ' THEN DD[1] := '0';

   CASE Date_Format OF
      MDY_Style: S_Date := MM + '/' + DD + '/' + YY;
      YMD_Style: S_Date := YY + '/' + MM + '/' + DD;
      DMY_Style: S_Date := DD + '/' + MM + '/' + YY;
      ELSE
         S_Date := MM + '/' + DD + '/' + YY;
   END (* CASE *);

END  (* Dir_Convert_Date *);

(*----------------------------------------------------------------------*)
(*     Dir_Set_File_Date_And_Time -- Set file date and time stamp       *)
(*----------------------------------------------------------------------*)

FUNCTION Dir_Set_File_Date_And_Time( File_Handle: INTEGER;
                                     File_Date  : INTEGER;
                                     File_Time  : INTEGER  ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Dir_Set_File_Date_And_Time                           *)
(*                                                                      *)
(*     Purpose:    Sets file time and date stamp                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Error := Dir_Set_File_Date_And_Time( File_Handle: INTEGER;    *)
(*                                             File_Date  : INTEGER;    *)
(*                                             File_Time  : INTEGER ):  *)
(*                                             INTEGER;                 *)
(*                                                                      *)
(*           File_Handle --- File handle of file to set time/date on    *)
(*           File_Date   --- File date in packed DOS form               *)
(*           File_Time   --- File time in packed DOS form               *)
(*           Error       --- DOS error return code                      *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        MsDos                                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dir_Reg  : Registers;

BEGIN (* Dir_Set_File_Date_And_Time *)

                                   (* Set up parameters to DOS call *)
   WITH Dir_Reg DO
      BEGIN
         Cx := File_Time;
         Dx := File_Date;
         Bx := File_Handle;
         Ah := $57;
         Al := 1;
      END;
                                   (* Set date and time *)
   MsDos( Dir_Reg );
                                   (* Check for bad return  *)

   IF ( Carry_Flag AND Dir_Reg.Flags ) = 0 THEN
      Dir_Set_File_Date_And_Time := 0
   ELSE
      Dir_Set_File_Date_And_Time := Dir_Reg.Ax;

END   (* Dir_Set_File_Date_And_Time *);

(*----------------------------------------------------------------------*)
(*     Dir_Get_File_Date_And_Time -- Get file date and time stamp       *)
(*----------------------------------------------------------------------*)

FUNCTION Dir_Get_File_Date_And_Time(     File_Handle: INTEGER;
                                     VAR File_Date  : INTEGER;
                                     VAR File_Time  : INTEGER  ) : INTEGER;

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Dir_Get_File_Date_And_Time                           *)
(*                                                                      *)
(*     Purpose:    Gets file time and date stamp                        *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Error := Dir_Get_File_Date_And_Time(     File_Handle: INTEGER;*)
(*                                             VAR File_Date  : INTEGER;*)
(*                                                 File_Time  : INTEGER *)
(*                                           ): INTEGER;                *)
(*                                                                      *)
(*           File_Handle --- File handle of file to set time/date on    *)
(*           File_Date   --- File date in packed DOS form               *)
(*           File_Time   --- File time in packed DOS form               *)
(*           Error       --- DOS error return code                      *)
(*                                                                      *)
(*     Calls:                                                           *)
(*                                                                      *)
(*        MsDos                                                         *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   Dir_Reg  : Registers;

BEGIN (* Dir_Get_File_Date_And_Time *)

                                   (* Set up parameters to DOS call *)
   WITH Dir_Reg DO
      BEGIN
         Bx := File_Handle;
         Ah := $57;
         Al := 0;
      END;
                                   (* Get date and time *)
   MsDos( Dir_Reg );
                                   (* Check for bad return  *)

   IF ( Carry_Flag AND Dir_Reg.Flags ) = 0 THEN
      BEGIN
         Dir_Get_File_Date_And_Time := 0;
         File_Time                  := Dir_Reg.Cx;
         File_Date                  := Dir_Reg.Dx;
      END
   ELSE
      BEGIN
         Dir_Get_File_Date_And_Time := Dir_Reg.Ax;
         File_Time                  := 0;
         File_Date                  := 0;
      END;

END   (* Dir_Get_File_Date_And_Time *);

(*----------------------------------------------------------------------*)
(*     Dir_Convert_File_Date_And_Time -- Get file date and time stamp   *)
(*----------------------------------------------------------------------*)

PROCEDURE Dir_Convert_File_Date_And_Time(      Date_Time  : LONGINT;
                                           VAR SFile_Date : AnyStr;
                                           VAR SDate_Time : AnyStr  );

(*----------------------------------------------------------------------*)
(*                                                                      *)
(*     Function:   Dir_Convert_File_Date_And_Time                       *)
(*                                                                      *)
(*     Purpose:    Gets file time and date stamp in string format       *)
(*                                                                      *)
(*     Calling Sequence:                                                *)
(*                                                                      *)
(*        Dir_Convert_File_Date_And_Time(     Date_Time  : LONGINT;     *)
(*                                        VAR SFile_Date : AnyStr;      *)
(*                                        VAR SDate_Time : AnyStr );    *)
(*                                                                      *)
(*           Date_Time   --- File time/date in packed DOS form          *)
(*           SFile_Date  --- File date in string form                   *)
(*           SDate_Time  --- File time in string form                   *)
(*                                                                      *)
(*----------------------------------------------------------------------*)

VAR
   DT : ARRAY[1..2] OF WORD ABSOLUTE Date_Time;

BEGIN (* Dir_Convert_File_Date_And_Time *)

   Dir_Convert_Time ( DT[1] , SDate_Time );
   Dir_Convert_Date ( DT[2] , SFile_Date );

END   (* Dir_Convert_File_Date_And_Time *);


