;+
; NAME:
;   MGH_TIME_EXTEND
;
; PURPOSE:
;   Determine the time taken to accumulate a set of elements of
;   similar data type, then save the results to an array.
;
; POSITIONAL PARAMATERS:
;   option (input, scalar integer, optional):
;     Specify the method:
;       0 - Array, extended at every step. (Default).
;       1 - MGH_Vector
;       2 - Array with lazy extension
;       3 - MGH_Queue
;       4 - List class/function, introduced in IDL 8.
;
; KEYWORD PARAMATERS:
;   ITEM (input, scalar of any type):
;     The value of the items to be accumulated (all the same).
;
;   NUM (input, scalar integer):
;     The number of items to be accumulated.
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
;     Written as MGH_TEST_EXTEND.
;   Mark Hadfield, 2010-11:
;     - Moved into the Motley library and renamed MGH_TIME_EXTEND.
;     - Added option 4: the IDL 8 List object.
;     - Fixed a bug in option 2: array type was hard-coded as string.
;   Mark Hadfield, 2011-07:
;     - Increased default number of items to 20000.
;-
pro mgh_time_extend, option, ITEM=item, NUM=num

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(num) eq 0 then num = 20000

   if n_elements(item) eq 0 then item = 0.E0

   if n_elements(option) eq 0 then option = 0

   t0 = systime(1)

   case option of

      0: begin
         array = []
         for i=0,num-1 do array = [array,item]
      end

      1: begin
         ovec = obj_new('MGH_Vector')
         for i=0,num-1 do ovec->Add, item
         array = ovec->ToArray()
         obj_destroy, ovec
      end

      2: begin
         size = 100
         array = replicate(item, size)
         for i=0,num-1 do begin
            if i gt size-1 then begin
               array = [temporary(array), replicate(item, round(0.5*size))]
               size = n_elements(array)
            endif
            array[i] = item
         endfor
         array = array[0:num-1]
      end

      3: begin
         ovec = obj_new('MGH_Queue')
         for i=0,num-1 do ovec->Add, item
         array = make_array(num, TYPE=size(item, /TYPE))
         for i=0,num-1 do array[i] = ovec->Get()
      end

      4: begin
         ovec = obj_new('List')
         for i=0,num-1 do ovec->Add, item
         array = ovec->ToArray()
         obj_destroy, ovec
      end

   endcase

   help, array

   message, /INFORM, mgh_format_float(systime(1)-t0)

end
