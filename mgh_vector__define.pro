;+
; CLASS NAME:
;   MGH_Vector
;
; PURPOSE:
;   This class implements a random-access container for heterogeneous
;   data. It is implemented using an array of pointers.
;
; PROPERTIES:
;   COUNT (Get):
;     The number of items currently stored in the vector.
;
;   SIZE (Init, Get, Set):
;     The capacity of the vector, i.e. the size of the pointer array
;     used to keep track of the items. The size can be changed via the
;     SetProperty method. If it is increased then the array is padded
;     with blank pointers; if it is reduced then any items beyond the
;     new size are deleted and their pointers freed.
;
; METHODS:
;   In addition to the usual suspects (Init, Cleanup, GetProperty,
;   SetProperty):
;
;     Add (Procedure):
;       This method adds a single item at the end of the vector and
;       increments the COUNT property. If this would exceed the
;       capacity of the vector, then the SIZE is increased; the
;       increase is always done in reasonably large chunks to avoid
;       performance degradation.
;
;     Count (Function):
;       This method takes no arguments and returns the COUNT property.
;
;     Get (Function):
;       This method retrieves a single item from a position specified
;       by the POSITION keyword. The default is POSITION=0. The item
;       is not removed from the vector. (There is no way of removing
;       items other than by reducing the SIZE).
;
;     Put (Procedure):
;       This method puts a new value into a position specified by the
;       POSITION keyword (default is POSITION=0). There must already
;       be a value stored at this location.
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
;     Written.
;   Mark Hadfield, 2000-11:
;     Added the Array method, which returns an array holding the
;     data.
;   Mark Hadfield, 2009-09:
;     The Add method now supports the NO_COPY keyword.
;   Mark Hadfield, 2011-07:
;     - The Add method now supports the EXTRACT keyword, specifying
;       that the contents of arrays should be extracted and added one
;       by one (cf. the List object introduced in IDL version 8). A
;       hidden method called AddItem. Has been added to support
;       it. Note that leaving arrays entire is generally much more
;       efficient.
;     - The Array method has been renamed ToArray (cf. the List object
;       introduced in IDL version 8) and now returns values, not
;       pointers, by default. It now handles stored arrays in the same
;       way as the List object, with an additional FLATTEN keyword that
;       causes it to produce a 1D array.
;   Mark Hadfield, 2011-07-25:
;     - Added a NO_COPY keyword to the ToArray method.
;     - The old Values method has been deleted, as it can now be
;       replaced by ToArray(/POINTER, /NO_COPY).
;   Mark Hadfield, 2011-07-28:
;     - The Add method now does nothing when supplied with undefined
;       values: in this it differs from the List object, which stores
;       a !NULL in their place.
;   Mark Hadfield, 2011-08:
;     - The result array is now created with the REPLICATE function
;       rather than the MAKE_ARRAY function. This is necessary for
;       structure types, as you can't create an array of generic structures.
;-
function MGH_Vector::Init, SIZE=size

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.values = ptr_new([])

   self.size = 0

   self.count = 0

   return, 1

end

pro MGH_Vector::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ptr_valid(self.values) then begin
      for i=0,n_elements(*self.values)-1 do $
            ptr_free, (*self.values)[i]
   endif

   ptr_free, self.values


end

pro MGH_Vector::GetProperty, COUNT=count, SIZE=size

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   count = self.count

   size = self.size

end

pro MGH_Vector::SetProperty, SIZE=size

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(size) gt 0 then begin

      delta = size - self.size

      case fix(delta gt 0) - fix(delta lt 0) of

         -1: begin
            values = *self.values
            ptr_free, self.values
            ptr_free, values[size:self.size-1]
            self.values = ptr_new(values[0:size-1])
            self.size = size
            self.count = self.count < self.size
         end

         0:

         1: begin
            values = *self.values
            ptr_free, self.values
            self.values = ptr_new([values, ptrarr(delta)])
            self.size = size
         end

      endcase

   endif

end

pro MGH_Vector::Add, value, $
     EXTRACT=extract, NO_COPY=no_copy

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(extract) then begin
      foreach val, value do self->AddItem, val
      if keyword_set(no_copy) then mgh_undefine, value
   endif else begin
      self->AddItem, value, NO_COPY=no_copy
   endelse

end

pro MGH_Vector::AddItem, value, NO_COPY=no_copy

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   compile_opt HIDDEN

   if n_elements(value) eq 0 then return

   if self.count ge self.size then $
        self->SetProperty, SIZE=(round(1.5*self.size) > (self.size+1000))

   (*self.values)[self.count] = ptr_new(value, NO_COPY=no_copy)

   self.count ++

end

function MGH_Vector::Count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.count

end

function MGH_Vector::Get, POSITION=position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.count le 0 then $
        message, 'The vector is empty'

   if n_elements(position) eq 0 then position = 0

   if position gt self.count-1 then $
        message, 'Position exceeds number of items'

   return, *(*self.values)[position]

end

pro MGH_Vector::Put, value, POSITION=position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.count le 0 then $
        message, 'The vector is empty'

   if n_elements(position) eq 0 then position = 0

   if position gt self.count-1 then $
        message, 'Position exceeds number of items'

   ptr_free, (*self.values)[position]

   (*self.values)[position] = ptr_new(value)

end

; MGH_Vector::ToArray
;
;   Return an array holding a copy of the data.
;
;   KEYWORD ARGUMENTS
;     FLATTEN (input, switch)
;       If set, return a copy of the data in a 1D array, with all
;       arrays in the container flattened and their elements
;       concatenated.
;
;     NO_COPY (input, switch)
;       If set, data are moved to the output array, leaving an null
;       pointer in the source object.
;
;     POINTERS (input, switch)
;       If set, return an array of pointers to a copy of the
;       data. This keyword may not be used with any of the others.
;
;     TRANSPOSE (input, switch)
;       If set, the dimension represented by position in the container
;       becomes the last dimension in the output array. The default is
;       for it to become the first. This keyword may not be set
;       together with the FLATTEN keyword.
;
;     TYPE (input, integer scalar)
;       Specify the type of the output array, using the same
;       conventions as the TYPE keyword to MAKE_ARRAY. The default is
;       the type of the first item in the container.
;
function MGH_Vector::ToArray, $
     FLATTEN=flatten, NO_COPY=no_copy, POINTERS=pointers, $
     TRANSPOSE=transpose, TYPE=type

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.count eq 0 then $
        message, 'The vector is empty'

   ;; The code below requires one or two passes through the array of
   ;; pointers to the stored data. I *think* it is more efficient to
   ;; make a copy of that array at the outset.  (It certainly makes
   ;; the code more readable.)

   val = *self.values

   if keyword_set(pointers) then begin

      if keyword_set(flatten) then $
           message, 'The FLATTEN and POINTER keywords may not be used together'
      if keyword_set(transpose) then $
           message, 'The TRANSPOSE and POINTER keywords may not be used together'
      if n_elements(type) gt 0 then $
           message, 'The TYPE and POINTER keywords may not be used together'

      if keyword_set(no_copy) then begin
         result = (*self.values)[0:self.count-1]
      endif else begin
         result = ptrarr(self.count)
         for i=0,self.count-1 do result[i] = ptr_new(*val[i])
      endelse

   endif else begin

      ;; The following scalar will be replicated to form the result array
      item = n_elements(type) gt 0 ? (make_array(1, TYPE=type))[0] : (*val[0])[0]

      if keyword_set(flatten) then begin

         if keyword_set(transpose) then $
              message, 'The FLATTEN and TRANSPOSE keywords may not be used together'

         ;; Two scans through the data are required: the first to
         ;; count the elements & set up the result array and the
         ;; second to copy the data to the right locations in the
         ;; result array.
         n = 0
         for i=0,self.count-1 do $
               n += n_elements(*val[i])
         if n eq 0 then return, !null
         result = replicate(item, n)
         m = 0
         for i=0,self.count-1 do begin
            n = n_elements(*val[i])
            if n gt 0 then begin
               result[m:m+n-1] = *val[i]
               m += n
            endif
         endfor

      endif else begin

         n_dim = size(*val[0], /N_DIMENSIONS)
         if n_dim gt 0 then begin
            dim = size(*val[0], /DIMENSIONS)
            dim = keyword_set(transpose) ? [dim,self.count] : [self.count,dim]
         endif else begin
            dim = [self.count]
         endelse
         result = replicate(item, dim)
         if keyword_set(transpose) then begin
            case n_dim of
               0: for i=0,self.count-1 do result[i] = *val[i]
               1: for i=0,self.count-1 do result[*,i] = *val[i]
               2: for i=0,self.count-1 do result[*,*,i] = *val[i]
               3: for i=0,self.count-1 do result[*,*,*,i] = *val[i]
               4: for i=0,self.count-1 do result[*,*,*,*,i] = *val[i]
               5: for i=0,self.count-1 do result[*,*,*,*,*,i] = *val[i]
               6: for i=0,self.count-1 do result[*,*,*,*,*,*,i] = *val[i]
               7: for i=0,self.count-1 do result[*,*,*,*,*,*,*,i] = *val[i]
            endcase
         endif else begin
            case n_dim of
               0: for i=0,self.count-1 do result[i] = *val[i]
               1: for i=0,self.count-1 do result[i,*] = *val[i]
               2: for i=0,self.count-1 do result[i,*,*] = *val[i]
               3: for i=0,self.count-1 do result[i,*,*,*] = *val[i]
               4: for i=0,self.count-1 do result[i,*,*,*,*] = *val[i]
               5: for i=0,self.count-1 do result[i,*,*,*,*,*] = *val[i]
               6: for i=0,self.count-1 do result[i,*,*,*,*,*,*] = *val[i]
               7: for i=0,self.count-1 do result[i,*,*,*,*,*,*,*] = *val[i]
            endcase
         endelse

      endelse

      if keyword_set(no_copy) then begin
         for i=0,self.count-1 do ptr_free, val[i]
      endif

   endelse

   if keyword_set(no_copy) then begin
      ptr_free, self.values
      self.values = ptr_new([])
      self.size = 0
      self.count = 0
   endif

   return, result

end

pro MGH_Vector__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Vector, inherits IDL_Object, $
                 values: ptr_new(), count: 0L, size: 0L}

end

