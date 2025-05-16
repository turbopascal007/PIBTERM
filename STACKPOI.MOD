(*----------------------------------------------------------------------*)
(*    StackPointer --- Return the stack pointer at point of the call    *)
(*----------------------------------------------------------------------*)

FUNCTION StackPointer : INTEGER;

BEGIN (* StackPointer *)

    INLINE(
            $89/$E0/                {MOV     AX,SP}
            $05/$08/$00/            {ADD     AX,0008}
            $89/$EC/                {MOV     SP,BP}
            $5D/                    {POP     BP}
            $C2/$02/$00             {RET     0002}
          );

END   (* StackPointer *);
