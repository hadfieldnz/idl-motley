; svn $Id$
;+
; NAME:
;   MGH_EXAMPLE_CONTAINER
;
; PURPOSE:
;   Example code for container classes. Reports time for various operations.
;
; POSITIONAL PARAMETERS:
;   option (input, scalar integer)
;     This parameter controls the container type. Valid values are 0-3.
;
; KEYWORD PARAMETERS:
;   GET (input, switch)
;     Controls whether to retrieve items from the container after they
;     are added. Default is 1.
;
;   N_ITEMS (input, scalar integer)
;     Number of items to process. Default is 20,000.
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
;   Mark Hadfield, Oct 1999:
;     Written.
;   Mark Hadfield, Sep 2001:
;     Added an option to use a plain string array as a container,
;     with the same resizing code as is used in MGH_Vector.
;-

pro mgh_example_container, option, GET=get, ITEM=item, N_ITEMS=n_items

   compile_opt DEFINT32
   compile_opt STRICTARR

   if n_elements(option) eq 0 then option = 0

   if n_elements(item) eq 0 then item = 'aaaa'

   case option of
      0:  class = 'mgh_vector'
      1:  class = 'mgh_stack'
      2:  class = 'mgh_queue'
      3:  class = 'array'
   endcase

   if n_elements(get) eq 0 then get = 1

   if n_elements(n_items) eq 0 then n_items = 50000

   if option le 2 then begin

      ;; Create & destroy a container to ensure methods are in memory.

      obj_destroy, obj_new(class)

      ;; Set GET=0 to suppress the Get() operation.  For the the stack
      ;; and the queue, the Get() operation removes the element from
      ;; the container so setting GET to 0 means the container is
      ;; destroyed while full. A Get() on an MGH_Vector does not
      ;; remove the element so it is destroyed full in either case

      t0 = systime(1)

      ocontainer = obj_new(class)

      for i=0,n_items-1 do ocontainer->Add, item

      t1 = systime(1)

      if keyword_set(get) then $
           case strlowcase(class) of
         'mgh_vector': for i=0,n_items-1 do dummy = ocontainer->Get(POSITION=i)
         else        : for i=0,n_items-1 do dummy = ocontainer->Get()
      endcase

      t2 = systime(1)

      obj_destroy, ocontainer

      t3 = systime(1)

   endif else begin

      size = 1000

      item_type = size(item, /TYPE)

      t0 = systime(1)

      array = make_array(size, TYPE=item_type)

      for i=0,n_items-1 do begin

         if i gt size-1 then begin

            delta = round(0.5*size)

            array = [temporary(array), make_array(delta, TYPE=item_type)]

            size += delta

         endif

         array[i] = item

      endfor

      t1 = systime(1)

      if keyword_set(get) then $
           for i=0,n_items-1 do dummy = array[i]

      t2 = systime(1)

      mgh_undefine, array

      t3 = systime(1)

   endelse

   print, 'Container is an '+class
   print, 'Creating container & adding elements took '+string(t1-t0)
   if keyword_set(get) then $
        print, 'Getting elements took '+string(t2-t1)
   print, 'Destroying container took '+string(t3-t2)

end
