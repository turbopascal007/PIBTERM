UNIT PT4KERM;

INTERFACE

USES
   Dos, Crt, GlobType, StringMan, GlobRout, PibTimer, PibAsync,
   PT4DISPC;

(* EXPORTS *)
   PROCEDURE Do_Kermit( Transfer_Direction : CHAR );

IMPLEMENTATION

CONST
   Kermit_Mess1_Line = 11;
   Kermit_Mess2_Line = 12;
   Kermit_Mess3_Line = 13;
   Kermit_Title_Line = 14;

CONST
   Send_Offset    = 1100;
   Receive_Offset = 1100;

(* STRUCTURED *) CONST
   Kermit_Screen_Write    : BOOLEAN = FALSE;
   Save_Display_Status    : BOOLEAN = TRUE;
   Kermit_Attributes      : BOOLEAN = FALSE;
   Kermit_Do_Long_Blocks  : BOOLEAN = FALSE;
   Kermit_Do_Sliding_Win  : BOOLEAN = FALSE;
   Kermit_Do_File_Size    : BOOLEAN = FALSE;
   Kermit_Do_File_Time    : BOOLEAN = FALSE;
   Kermit_Do_File_Date    : BOOLEAN = FALSE;
   His_Kermit_Window_Size : INTEGER = 0;
   His_Kermit_MaxLX1      : INTEGER = 0;
   His_Kermit_MaxLX2      : INTEGER = 0;
   Kermit_File_Size       : LONGINT = 0;
   Kermit_File_Time       : WORD = 0;
   Kermit_File_Date       : WORD = 0;
   Kermit_CFile_Size      : STRING[10] = '';
   Kermit_CFile_Time      : STRING[10] = '';
   Kermit_CFile_Date      : STRING[10] = '';
   Kermit_Window_Used     : INTEGER = 0;
   Kermit_Window_Errors   : INTEGER = 0;
   Kermit_Doing_Transfer  : BOOLEAN = FALSE;
   Window_Size_Used       : INTEGER = 0;
   Initial_SOH_Received   : BOOLEAN = FALSE;

(* STRUCTURED *) CONST
   Send_Titles    : ARRAY[1..5] OF STRING[22] =
                    ('Packets sent         :',
                     'Bytes sent           :',
                     'Retries              :',
                     'Bytes to send        :',
                     'Current block window :' );

   Receive_Titles : ARRAY[1..5] OF STRING[22] =
                    ('Packets received     :',
                     'Bytes received       :',
                     'Retries              :',
                     'Bytes to receive     :',
                     'Current block window :' );

   Line_Titles    : ARRAY[6..14] OF STRING[22] =
                    ('8th bit quoting      :',
                     'Block check type     :',
                     'Compression          :',
                     'Sliding windows      :',
                     'Long blocks          :',
                     'Last status message  :',
                     '',
                     '',
                     '' );

   Key_Title   : STRING[60]
                 = ' ^F=abort file   ^B=abort batch   ^K=abort Kermit   ^R=retry';

  {executable code local to this module follows}

{$I KDEBUG.MOD     }
{$I KINIT.MOD      }
{$I KERMCRC.MOD    }
{$I KDISPLAY.MOD   }
{$I KADJUSTF.MOD   }
{$I KFIXFNAM.MOD   }
{$I KOPEN.MOD      }
{$I KREC.MOD       }
{$I KSEND.MOD      }
{$I KFINSERV.MOD   }
{$I KREMCOMM.MOD   }
{$I KCHECKAC.MOD   }
{$I SENDKER1.MOD   }
{$I SENDKER2.MOD   }
{$I RECEIVK1.MOD   }
{$I RECEIVK2.MOD   }
{$I DOKERM.MOD     }

END   (* PT4KERM *).
