; svn $Id$
;+
; NAME:
;   MGH_EXAMPLE_STRUCT
;
; PURPOSE:
;   This example procedure compares two methods of building up an anonymous
;   structure with a large number of tags.
;
;   Option 0 calls the MGH_STRUCT_BUILD function, which has been designed for
;   efficiency and robustness when the number of tags and/or the volume of data
;   is large.
;
;   Option 1 uses repeated calls to CREATE_STRUCT, which repeatedly increments
;   the structure. For large problems this is inefficient (it has quadratic timing)
;   because the structure has is copied on every call.
;
;   A more realistic example of the application of MGH_STRUCT_BUILD can be seen in
;   the Retrieve method of the MGHncFile class.
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
;   Mark Hadfield, Nov 2000:
;       Written.
;-

pro mgh_example_struct, option, N_TAGS=n_tags, TAG_SIZE=tag_size

   compile_opt DEFINT32
   compile_opt STRICTARR

    if n_elements(option) eq 0 then option = 0

    if n_elements(n_tags) eq 0 then n_tags = 200

    if n_elements(tag_size) eq 0 then tag_size = 10000

    data = bytarr(tag_size)

    tags = 'v'+strtrim(string(lindgen(n_tags),FORMAT='(Z)'),2)

    message, /INFORM, 'Creating structure with '+strtrim(n_tags,2)+' tags each of '+strtrim(tag_size,2)+' bytes for total of '+strtrim(n_tags*tag_size,2)+' bytes'

    case option of

        0: begin

            message, /INFORM, 'Option is '+strtrim(option,2)+': store data in pointer array and call MGH_BUILD_STRUCT'

            mgh_tic

            values = ptrarr(n_tags)

            for i=0,n_tags-1 do values[i] = ptr_new(data)

            result = mgh_struct_build(tags, values)

            ptr_free, values

            mgh_toc

        end

        1: begin

            message, /INFORM, 'Option is '+strtrim(option,2)+': repeated calls to CREATE_STRUCT'

            mgh_tic

            for i=0,n_tags-1 do $
                case n_elements(result) of
                    0: result = create_struct(tags[i], data)
                 else: result = create_struct(result, tags[i], data)
                endcase

            mgh_toc

        end

    endcase

end
