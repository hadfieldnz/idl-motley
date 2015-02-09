; svn $Id$
;+
; NAME:
;   MGH_GET_CT
;
; PURPOSE:
;   This function reads a colour table file and returns a single
;   colour table in the form of a structure.
;
; CALLING SEQUENCE:
;   Result = MGH_GET_CT(table_id)
;
; POSITIONAL PARAMETERS
;   table_id (input, scalar integer or string)
;     The table to be read. If numeric, this argument must be an
;     integer, 0 <= table_id <= n_tables. If a string, this argument
;     must match one of the tables in the file case-insensitively.
;
; KEYWORDS:
;   FILE (input, scalar string)
;     The name of the colour table file. The default is supplied by
;     invoking the function MGH_CT_FILE with the SYSTEM keyword.
;
;   NAMES (input, switch)
;     Set this keyword to have the function return a list of
;     colour-table names from the file.
;
;   SYSTEM (input, switch)
;     This keyword has an effect only if the FILE keyword is not
;     specified explicitly--see above.
;
; RETURN VALUE:
;   The function returns an anonymous structure with tags name
;   (string), red (256-element byte array), green (ditto) and blue
;   (ditto).
;
; PROCEDURE:
;   Straightforward, adapted from LOADCT.
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
;   Mark Hadfield, 1998-08:
;     Written.
;   Mark Hadfield, 2001-01:
;     - Upgraded for IDL 5.5.
;     - Added NAMES keyword.
;   Mark Hadfield, 2002-12:
;     - Upgraded for IDL 5.6.
;     - Default colour-table file name now calculated by MGH_CT_FILE.
;-

function MGH_GET_CT, table_id, FILE=file, NAMES=names, SYSTEM=system

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(table_id) eq 0 then table_id = 0

   if n_elements(file) eq 0 then file = mgh_ct_file(SYSTEM=system)

   openr, lun, file, /BLOCK, /GET_LUN

   n_tables = 0b
   readu, lun, n_tables

   table_names = bytarr(32, n_tables)
   point_lun, lun, n_tables * 768L + 1
   readu, lun, table_names
   table_names = strtrim(table_names, 2)

   if keyword_set(names) then return, table_names

   id_type = size(table_id, /TYPE)

   case 1 of

      id_type eq 7: begin
         table_index = where(strmatch(table_names, table_id, /FOLD_CASE), n_match)
         if n_match eq 0 then $
              message, 'Table '+table_id+' was not found in file '+file
         table_index = table_index[0]
      end

      id_type ge 1 and id_type le 3: begin
         table_index = table_id[0]
      end

   endcase

   if table_index lt 0 or table_index gt n_tables-1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_badindex', table_index

   aa=assoc(lun, bytarr(256), 1)
   r = aa[table_index*3]
   g = aa[table_index*3+1]
   b = aa[table_index*3+2]

   free_lun, lun

   return, {name: table_names[table_index], n_colors:256S, red: r, green: g, blue: b}

end

