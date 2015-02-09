; svn $Id$
;+
; CLASS:
;   MGH_Conductor
;
; PURPOSE:
;   A user interface for synchronised playback of one or more
;   MGH_Player objects.
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
;   Mark Hadfield, 1999-05.
;     Written.
;   Mark Hadfield, 1999-10.
;     Implemented the dialog by which animations can be added to the
;     conductor's list of "players" with the function
;     MGH_DIALOG_PICKOBJ. This was previously done with a class called
;     MGH_ConductorAddDialog, included in this source file. I have
;     saved this class elsewhere, to serve as a model if I ever want
;     to manage the player list with a non-modal dialog.
;   Mark Hadfield, 1999-11:
;     Now implemented as a sub-class of MGH_Atomator.
;   Mark Hadfield, 2001-06:
;     Updated for recent changes in MGH_GUI_Base event-handling conventions.
;   Mark Hadfield, 2001-09:
;     Updated for IDL 5.5.
;   Mark Hadfield, 2002-10:
;     - Updated for IDL 5.6.
;     - Toolbar menu items now used check buttons.
;   Mark Hadfield, 2004-05:
;     When players are released during object destruction, they have their
;     Update methods called (but their SLAVE property is not reset to 0,
;     in case they are being controlled by another conductor).
;-

; MGH_Conductor::Init
;
; Purpose:
;   Initialise an MGH_Conductor object.
;
function MGH_Conductor::Init, $
     player, PLAYBACK=playback, VISIBLE=visible, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(visible) eq 0 then visible = 1

   ;; Initialise the widget base

   ok = self->MGH_GUI_Base::Init(/COLUMN, /BASE_ALIGN_CENTER, /MBAR, $
                                 TITLE='IDL Conductor', TLB_SIZE_EVENTS=0, $
                                 TLB_FRAME_ATTR=1 , VISIBLE=0, $
                                 _STRICT_EXTRA=extra)

   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_GUI_Base'

   ;; Create a container for the list of "players" and add the
   ;; players, if any.

   self.players = obj_new('MGH_Container', DESTROY=0)

   self->AddPlayer, Player

   ;; Add an invisible base to enforce a minimum width for the widget.

   self->NewChild, 'widget_base', XSIZE=300, YPAD=0, YSIZE=0

   ;; Add the animator

   self.animator = self->NewChild(/OBJECT, 'MGH_Animator', CLIENT=self, $
                                  PLAYBACK=playback)

   ;; Set up the UI

   self->BuildMenuBar

   ;; Finalisation is done in a slightly different sequence than
   ;; normal here, because the base must be realized in order for it
   ;; to be aligned successfully. It was created invisible and is made
   ;; visible after alignment for cosmetic reasons.

   self->Finalize

   if self->IsTLB() then self->Align, [0.50,0.75]

   self->SetProperty, VISIBLE=visible

   ;; Finished!

   return, 1

end


; MGH_Conductor::Cleanup
;
pro MGH_Conductor::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   players = self.players->Get(/ALL, COUNT=count)

   for i=0,count-1 do begin
      if obj_valid(players[i]) then begin
         players[i]->Update
      endif
   endfor

   obj_destroy, self.players

   obj_destroy, self.animator

   self->MGH_GUI_Base::Cleanup

end


; MGH_Conductor::GetProperty
;
pro MGH_Conductor::GetProperty, $
     N_FRAMES=n_frames, N_PLAYERS=n_players, PLAYBACK=playback, $
     POSITION=position, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if arg_present(n_frames) then $
        n_frames = self->CountFrames()

   n_players = self.players->Count()

   if obj_valid(self.animator) then $
        self.animator->GetProperty, PLAYBACK=playback, POSITION=position

   self->MGH_GUI_Base::GetProperty, _STRICT_EXTRA=extra

end

; MGH_Player::SetProperty
;
pro MGH_Conductor::SetProperty, $
     PLAYBACK=playback, POSITION=position, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if obj_valid(self.animator) then $
        self.animator->SetProperty, PLAYBACK=playback, SLAVE=slave

   self->MGH_GUI_Base::SetProperty, _STRICT_EXTRA=extra

end

; MGH_Conductor::About
;
pro MGH_Conductor::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_GUI_Base::About, lun

   self->GetProperty, N_FRAMES=n_frames, N_PLAYERS=n_players

   printf, lun, self, ': I control ', strtrim(n_frames,2), ' frames in ', $
           strtrim(n_players,2), ' animators'

   players = self.players->Get(/ALL, COUNT=count)
   for i=0,count-1 do begin
      if obj_valid(players[i]) then begin
         players[i]->GetProperty, N_FRAMES=nf
         printf, lun, ': Animator ', mgh_obj_string(players[i], /SHOW_TITLE), $
                 ' has ', strtrim(nf,2), ' frames'
      endif
   endfor

end

; MGH_Conductor::AddPlayer

; Purpose:
;   Add one or more player objects to the container
;
pro MGH_Conductor::AddPlayer, Player

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   for i=0,n_elements(player)-1 do begin
      self.players->Add, player[i]
      player[i]->SetProperty, SLAVE=1
   endfor

end

; MGH_Conductor::CountFrames
;
;   Evaluated the number of frames controlled by the conductor by
;   scanning through all the players, counting frames in each, and
;   taking the minimum.
;
function MGH_Conductor::CountFrames

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = 0

   players = self.players->Get(/ALL, COUNT=n_players)

   for i=0,n_players-1 do begin
      if obj_valid(players[i]) then begin
         players[i]->GetProperty, N_FRAMES=n
         n_frames = n_elements(n_frames) gt 0 ? (n_frames < n) : n
      endif
   endfor

   if n_elements(n_frames) gt 0 then result = n_frames

   return, result

end

; MGH_Conductor::Display
;
pro MGH_Conductor::Display, position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(position) eq 0 then position = 0

   players = self.players->Get(/ALL, COUNT=count)

   for i=0,count-1 do begin
      if obj_valid(players[i]) then $
        players[i]->Display, position
   endfor

end

; MGH_Conductor::EventMenuBar
;
function MGH_Conductor::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'FILE.ADD PLAYER': begin
         ;; Since the MGH_GUI_PickObj object is modal, it returns from
         ;; its Init method only when its widget tree has been
         ;; destroyed. it is designed so that the (now widget-less)
         ;; object persists and can be queried about its properties.
         mgh_new, 'MGH_GUI_PickObj', self->GetCandidate(), /MODAL, $
                  /MULTIPLE, GROUP_LEADER=event.top, /SHOW_TITLE, RESULT=odlg
         odlg->GetProperty, STATUS=status
         if status then begin
            selected_objects = odlg->Selected(COUNT=n_selected)
            if n_selected gt 0 then self->AddPlayer, selected_objects
         endif
         obj_destroy, odlg
         self->Update
         return, 0
      end

      'FILE.ADD ALL': begin
         candidates = self->GetCandidate(COUNT=n_candidates)
         if n_candidates gt 0 then self->AddPlayer, candidates
         self->Update
         return, 0
      end

      'FILE.CLOSE': begin
         self->Kill
         return, 0
      end

      'WINDOW.UPDATE': begin
         self->Update
         return, 0
      end

      'WINDOW.SHOW ALL PLAYERS': begin
         self->ShowPlayer, /ALL
         return, 0
      end

      'WINDOW.TOOLBARS.PLAY BAR': begin
         self.animator->BuildPlayBar
         self.animator->UpdatePlayBar
         self.animator->UpdatePlayContext
         self->UpdateMenuBar
         return, 0
      end

      'WINDOW.TOOLBARS.DELAY BAR': begin
         self.animator->BuildDelayBar
         self.animator->UpdateDelayBar
         self.animator->UpdateDelayContext
         self->UpdateMenuBar
         return, 0
      end

      'WINDOW.TOOLBARS.RANGE BAR': begin
         self.animator->BuildRangeBar
         self.animator->UpdateRangeBar
         self.animator->UpdateRangeContext
         self->UpdateMenuBar
         return, 0
      end

      'HELP.ABOUT': begin
         self->About
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Conductor::GetCandidate
;
function MGH_Conductor::GetCandidate, COUNT=count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Get a list of all objects known to IDL. There must be at least
   ;; one (self).

   obj = obj_valid()

   ;; Perhaps there is a better way of specifying which are "playable"
   ;; objects?

   good = where((obj_isa(obj,'MGH_Player') or $
                 obj_isa(obj,'MGH_DGplayer')) and $
                (1-self.players->IsContained(obj)), count)

   return, count gt 0 ? obj[good] : -1

end

; MGH_Conductor::RemovePlayer
;
; Purpose:
;   Removes one or more objects from the players container
;
pro MGH_Conductor::RemovePlayer, Player, ALL=all

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if keyword_set(all) then player = self.players->Get(/ALL)

   for i=0,n_elements(player)-1 do begin
      if obj_valid(player[i]) then $
           if self.players->IsContained(player[i]) then begin
         self.players->Remove, player[i]
         player[i]->SetProperty, SLAVE=0
         player[i]->Update
      endif
   endfor

   self->CountFrames

end

; MGH_Conductor::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_Conductor::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ widget_info(self.menu_bar, /VALID_ID) then return

   if widget_info(self.menu_bar, /CHILD) gt 0 then $
        message, 'The menu bar already has children'

   ombar = obj_new('MGH_GUI_PDmenu', $
                   ['File','Window','Help'], BASE=self.menu_bar, /MBAR)

   ;; Add menu entries

   ;; ...File menu

   ombar->NewItem, PARENT='File', SEPARATOR=[0,0,1], $
        ['Add Player...','Add All','Close']

   ;; ...Window menu

   ombar->NewItem, PARENT='Window', MENU=[0,0,1], $
        ['Update','Show All Players','Toolbars']

   ombar->NewItem, PARENT='Window.Toolbars', /CHECKED_MENU, $
        ['Play Bar','Delay Bar','Range Bar']

   ;; ...Help menu

   ombar->NewItem, PARENT='Help', ['About']

end

; MGH_Conductor::ShowPlayer
;
;   Show or hide one or more players
;
PRO MGH_Conductor::ShowPlayer, Player, ALL=all, FLAG=flag

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(flag) eq 0 then flag = 1

   if keyword_set(all) then player = self.players->Get(/ALL)

   for i=0,n_elements(player)-1 do begin
      if obj_valid(player[i]) then begin
         player[i]->Update
         player[i]->Show, flag
      endif
   endfor

end

; MGH_Conductor::Update
;
pro MGH_Conductor::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->UpdateMenuBar

   if obj_valid(self.animator) then $
        self.animator->Update

end

; MGH_Conductor::UpdateMenuBar
;
pro MGH_Conductor::UpdateMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin

      self->GetProperty, N_PLAYERS=n_players

      self.animator->GetProperty, $
           EXPAND_DELAY_BAR=expand_delay_bar, $
           EXPAND_PLAY_BAR=expand_play_bar, $
           EXPAND_RANGE_BAR=expand_range_bar

      obar->SetItem, 'Window.Show All Players', SENSITIVE=(n_players gt 0)

      obar->SetItem, 'Window.Toolbars.Play Bar', SET_BUTTON=(expand_play_bar)
      obar->SetItem, 'Window.Toolbars.Delay Bar', SET_BUTTON=(expand_delay_bar)
      obar->SetItem, 'Window.Toolbars.Range Bar', SET_BUTTON=(expand_range_bar)

   endif

end

; MGH_Conductor__Define
;
pro MGH_Conductor__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Conductor, inherits MGH_GUI_Base, $
                 players: obj_new(), animator: obj_new()}

end


