; svn $Id$
;+
; CLASS NAME:
;   MGH_Stack
;
; PURPOSE:
;   This class implements a last-in-first-out (LIFO) stack as a singly
;   linked list.
;
; CATEGORY:
;   Miscellaneous.
;
; IMPLEMENTATION:
;   The implementation is very straightforard. Items are added (always
;   to the end of the stack) via the Add method and retrieved (always
;   from the same end) via the Get method. Retrieving a value removes
;   it from the stack. The number of values is returned by the COUNT
;   property or the Count method.
;
; PERFORMANCE:
;   The time taken to create a stack, add 100,000 real numbers,
;   retrieve them all then destroy the stack is 9.4 s on my PC (Compaq
;   Deskpro with Pentium II 400 MHz).
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
;   Mark Hadfield, 1999-10:
;       Written.
;-

pro MGH_Stack::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   current = self.top

   while ptr_valid(current) do begin
      old = current
      current = (*current).next
      ptr_free, (*old).value  &  ptr_free, old
   endwhile

end

pro MGH_Stack::GetProperty, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   count = self.count

end

pro MGH_Stack::Add, Value

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   item = {MGH_StackItem}
   item.value = ptr_new(Value)

   if ptr_valid(self.top) then begin
      current = self.top
      item.next = current
   endif
   self.top = ptr_new(item)
   self.count += 1

end

function MGH_Stack::Count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.count

end

function MGH_Stack::Get

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.count le 0 then message, 'The stack is empty'

   item = *self.top

   ptr_free, self.top

   self.top = item.next

   value = *item.value

   ptr_free, item.value

   self.count -= 1

   return, value

end

pro MGH_StackItem__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct = {MGH_StackItem, value: ptr_new(), next: ptr_new()}

end

pro MGH_Stack__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Stack, top: ptr_new(), count: 0}

end

