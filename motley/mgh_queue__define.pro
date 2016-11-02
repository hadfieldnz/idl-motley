;+
; CLASS NAME:
;   MGH_Queue
;
; PURPOSE:
;   A first-in-first-out (FIFO) queue, currently implemented as a
;   singly linked list.
;
; CATEGORY:
;   Miscellaneous.
;
; IMPLEMENTATION:
;   The implementation is very straightforard. Items are added to the
;   tail of the queue via the Add method and retrieved from the head
;   of the queue via the Get method. Retrieving a value removes it
;   from the stack. The number of values is returned by the COUNT
;   property or the Count method.
;
; PERFORMANCE:
;   Adequate: see routine MGH_TIME_EXTEND.

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
;   Mark Hadfield, 2011-07:
;       Updated.
;-
pro MGH_Queue::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   head = self.head

   for i=0,self.count-1 do begin
      item = head
      head = (*head).next
      ptr_free, (*item).value  &  ptr_free, item
   endfor

end

pro MGH_Queue::GetProperty, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   count = self.count

end

pro MGH_Queue::Add, value

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   item = ptr_new({MGH_QueueItem})
   (*item).value = ptr_new(value)

   if self.count eq 0 then self.head = item else (*self.tail).next = item
   self.tail = item
   self.count = self.count + 1


end

function MGH_Queue::Count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.count

end

function MGH_Queue::Get

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.count le 0 then message, 'The queue is empty'

   item = *self.head

   ptr_free, self.head

   self.head = item.next

   value = *item.value

   ptr_free, item.value

   self.count = self.count - 1

   return, value

end

pro MGH_QueueItem__define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_QueueItem, inherits IDL_Object, $
                 value: ptr_new(), next: ptr_new()}

end

pro MGH_Queue__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Queue, inherits IDL_Object, $
                 head: ptr_new(), tail: ptr_new(), count: 0L}

end

