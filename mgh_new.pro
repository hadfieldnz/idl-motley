; svn $Id$
;+
; NAME:
;   MGH_NEW
;
; PURPOSE:
;   A procedure that calls function OBJ_NEW and optionally returns the
;   object reference.
;
; CALLING SEQUENCE:
;   MGH_NEW, Name, P1, P2, ...
;
; INPUTS:
;   Name
;     Class name for the new object
;
;   Pn
;     The arguments to be passed to the method given by Name. These
;     arguments are the positional arguments documented for the called
;     method, and are passed to the called method exactly as if it had
;     been called directly. The number of positional arguments in this
;     list must not exceed 10.
;
; KEYWORD PARAMETERS:
;   Keywords are passed to the called function, with the exception of
;   the following:
;
;   RESULT
;     Set this keyword to a named variable to return the object reference.
;
;###########################################################################
;
; This software is provided subject to the following conditions:
;
; 1.  NIWA makes no representations or warranties regarding the
;     accuracy of the software, the use to which the software may
;     be put or the results to be obtained from the use of the
;     software.  Accordingly NIWA accepts no liability for any loss
;     or damage (whether direct of indirect) incurred by any person
;     through the use of or reliance on the software.
;
; 2.  NIWA is to be acknowledged as the original author of the
;     software where the software is used or presented in any form.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-06:
;     Written.
;   Mark Hadfield, 2001-07:
;     Modified for IDL 5.5: _EXTRA changed to _REF_EXTRA and
;     _STRICT_EXTRA.
;   Mark Hadfield, 2002-06:
;     Reduced maximum number of parameters, Pn from 15 to 10. Even the
;     latter value is ridiculously conservative.
;-
pro MGH_NEW, name, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, $
             RESULT=result, _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(name, /TYPE) ne 7 then $
        message, 'The first parameter must be a class name.'

   case size(_extra, /TYPE) of

      0: begin
         case n_params() of
            1:  result = obj_new(Name)
            2:  result = obj_new(Name, P1)
            3:  result = obj_new(Name, P1, P2)
            4:  result = obj_new(Name, P1, P2, P3)
            5:  result = obj_new(Name, P1, P2, P3, P4)
            6:  result = obj_new(Name, P1, P2, P3, P4, P5)
            7:  result = obj_new(Name, P1, P2, P3, P4, P5, P6)
            8:  result = obj_new(Name, P1, P2, P3, P4, P5, P6, P7)
            9:  result = obj_new(Name, P1, P2, P3, P4, P5, P6, P7, P8)
            10:  result = obj_new(Name, P1, P2, P3, P4, P5, P6, P7, P8, P9)
            11:  result = obj_new(Name, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10)
            else:  message,  BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumparm', n_params()
         endcase
      end

      else: begin
         case n_params() of
            1:  result = obj_new(Name, $
                                 _STRICT_EXTRA=_extra)
            2:  result = obj_new(Name, P1, $
                                 _STRICT_EXTRA=_extra)
            3:  result = obj_new(Name, P1, P2, $
                                 _STRICT_EXTRA=_extra)
            4:  result = obj_new(Name, P1, P2, P3, $
                                 _STRICT_EXTRA=_extra)
            5:  result = obj_new(Name, P1, P2, P3, P4, $
                                 _STRICT_EXTRA=_extra)
            6:  result = obj_new(Name, P1, P2, P3, P4, P5, $
                                 _STRICT_EXTRA=_extra)
            7:  result = obj_new(Name, P1, P2, P3, P4, P5, P6, $
                                 _STRICT_EXTRA=_extra)
            8:  result = obj_new(Name, P1, P2, P3, P4, P5, P6, P7, $
                                 _STRICT_EXTRA=_extra)
            9:  result = obj_new(Name, P1, P2, P3, P4, P5, P6, P7, P8, $
                                 _STRICT_EXTRA=_extra)
            10:  result = obj_new(Name, P1, P2, P3, P4, P5, P6, P7, P8, P9, $
                                  _STRICT_EXTRA=_extra)
            11:  result = obj_new(Name, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10, $
                                  _STRICT_EXTRA=_extra)
            else:  message,  BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumparm', n_params()
         endcase
      end

   endcase

end

