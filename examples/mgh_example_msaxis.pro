;+
; NAME:
;   MGH_EXAMPLE_MSAXIS
;
; PURPOSE:
;   This example demonstrates master-slave relationships between
;   axes, atoms & symbols.
;
;   The central concept behind the MGHgrGraph class is that the axes
;   in a graph define coordinate conversions, which are then adopted
;   by atoms and symbols as they are added to the graph.  This concept
;   has now been taken a step further in that axes keep referencesto
;   the objects (slaves) that have been fitted to them and update
;   their slaves if any of the axis's relevant properties is changed.
;
;###########################################################################
; Copyright (c) 2016 NIWA:
;   http://www.niwa.co.nz/
; Licensed under the MIT open source license:
;   http://www.opensource.org/licenses/mit-license.php
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2000-06:
;     Written.
;   Mark Hadfield, 2004-07:
;     Modified to accommodate the recent overhaul of graph & axis classes.
;-
pro mgh_example_msaxis

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   name = 'Master-slave axis example'

   ograph = obj_new('MGHgrGraph', NAME=name)

   ograph->NewFont, SIZE=11

   ograph->NewText, name, LOCATIONS=[0,0.9], ALIGNMENT=0.5

   ;; Add x & y axes

   ograph->NewAxis, 0, RANGE=[-100,100], $
        LOCATION=[-0.75,-0.75], RESULT=xaxis0
   ograph->NewAxis, 0, RANGE=[-100,100], $
        LOCATION=[-0.75,0.75], RESULT=xaxis1

   xaxis0->AddSlave, xaxis1, /AXIS

   ograph->NewAxis, 1, RANGE=[-10,10], $
        NORM_RANGE=[-0.5,0.5], LOCATION=[-0.75,-0.75], RESULT=yaxis0

   ;; Add atoms & symbols, which by default pick up their scaling, and are
   ;; slaves to, the X & Y axes.

   ograph->NewSymbol, CLASS='MGHgrSymbol', 0, /FILL, COLOR=mgh_color('blue'), $
        RESULT=osym0
   ograph->NewSymbol, CLASS='MGHgrSymbol', 2, /FILL, COLOR=mgh_color('red'), $
        RESULT=osym1

   ograph->NewAtom, 'IDLgrPlot', [-105,105], [-10,10], SYMBOL=osym0, $
        RESULT=oatom0
   ograph->NewAtom, 'IDLgrPlot', [105,-105], [ -5, 5], SYMBOL=osym1, $
        RESULT=oatom1

   ;; Display

   mgh_new, 'MGH_Window', GRAPHICS_TREE=ograph, RESULT=owindow

   owindow->Update

   ;; After a short wait, rescale the master axes

   wait, 3

   xaxis0->SetProperty, RANGE=[-150,150], /EXACT, /EXTEND

   yaxis0->SetProperty, RANGE=[-12,12], TICKINTERVAL=6

   owindow->Update

end
