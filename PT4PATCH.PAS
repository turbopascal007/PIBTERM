{$R-,S-,I-}
UNIT PT4PATCH;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, PibTimer;

   FUNCTION GetEnvStr( Search_String : AnyStr ) : AnyStr;

IMPLEMENTATION
                                   (* Get command line parameters       *)
{$I GETCOMAN.MOD }
                                   (* Get environment string            *)
{$I GETENVST.MOD }
                                   (* Initialize directories            *)
{$I INITOVLY.MOD }

(*----------------------------------------------------------------------*)

TYPE
   BigBuffer = ARRAY[0..65519] OF BYTE;
   BufferPtr = ^BigBuffer;

   PatchRec = RECORD (* Must match patch area of OVERMGR exactly *)
                 ID        : STRING[18];
                 Path      : STRING[64];
                 StackSize : WORD;
                 CheckEms  : BOOLEAN;
              END;

CONST
   PatchID = 'OVERLAY PATCH AREA';

VAR
   DataSegment  : BufferPtr;
   Offset       : WORD;
   Limit        : WORD;
   Ch           : CHAR;
   T1           : LONGINT;
   PatchPtr     : ^PatchRec;

(*----------------------------------------------------------------------*)

FUNCTION Search( VAR B : BufferPtr ; Limit : WORD; Match : STRING ) : WORD;

VAR
   O : Word;
   P : ^STRING;

BEGIN (* Search *)

   O := Limit;

   REPEAT
      DEC( O );
      P := @B^[O];
   UNTIL( O = 0 ) OR ( P^ = Match );

   Search := O;

END   (* Search *);

(*----------------------------------------------------------------------*)

BEGIN (* PT4PATCH *)
                                   (* Get command line parameters     *)
   Get_Command_Line_Parameters;
                                   (* Get config file directory  *)
   InitOvly;
                                   (* Assume text mode from    *)
                                   (* current system setting.  *)
   Start_Video_Mode := LastMode;
   Text_Mode        := LastMode;

                                   (* Fix up patchable overlay parameters *)
   DataSegment := PTR( DSeg , 0 );
   Limit       := ( SSeg - DSeg ) * 16;

   Offset := Search( DataSegment, Limit, PatchID );

   IF ( Offset > 0 ) THEN
      BEGIN
         PatchPtr := PTR( DSeg , Offset );
         WITH PatchPtr^ DO
            BEGIN
               Path     := Home_Dir + 'PIBT.OVR';
               CheckEMS := Use_EMM_For_Overlays;
            END;
      END;
                                   (* Check memory *)
   IF ( MemAvail < 65000 ) THEN
      BEGIN
          WRITELN;
          WRITELN('*** WARNING *** There are only ', MemAvail SHR 10,
                  'K bytes of work space available,');
          WRITELN('                PibTerm may not be able to run.');
          WRITELN('                Hit Enter key to continue.');
          T1 := TimeOfDay;
          WHILE ( ( NOT KeyPressed ) AND ( TimeDiff( T1 , TimeOfDay ) < 10 ) ) DO;
          IF KeyPressed THEN
             WHILE (       KeyPressed ) DO
                READ( Ch )
          ELSE
             WRITELN('Enter key not struck, PibTerm will try to continue anyway.');
      END;

END   (* PT4PATCH *).
