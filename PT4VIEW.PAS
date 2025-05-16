UNIT PT4VIEW;

INTERFACE

USES
   Dos, Crt, GlobType, GlobRout, StringMan, PibAsync, PibTimer;

(* EXPORTS *)
   PROCEDURE View_A_File( View_File_Name : AnyStr );

IMPLEMENTATION
                                   (* View a file, internal procedures *)
{$I VIEWSUB1.MOD }
{$I VIEWSUB2.MOD }
                                   (* View a file main *)
{$I PIBVIEW.MOD  }

END   (* PT4VIEW *).
