//
// Easy gui construction with named components to be used in window handlers.
//
// Example of usage
// ==========================================
// guiwindow name, width, height		// will create name_elements and %name_width and %name_height
// ...
// guiwinresize color[, <resizeoptionlist>]	// Make a resizable window. Automatically creates a sizer and collects the necessary data.
// ...
// guicaption color, textid			// creates a caption
// ...
// guiele [elename],guitype,color, Optionlist...
// ...
// endguiwindow
//
//
// Optionlist:
// ==========================================
// A gui element you need atleast 4 dimensions and a data value.
// for fast creating of guis, the guiele macro can do some internal calculations for you,
// like offsets from the right, bottom or useing height/width values instead of the second coordinate.
// All values are given in key value pairs, example: x1,55,x2,10, ...
//  
// Possible keys to describe an element coordinate are:
// x,-x			for the left coordinate of an element
// x2,-x2,w		for the right coordinate of an element, (w means width and is relative to x1/-x1)
// y,-y			for the top coordinate of an element
// y2,-y2,h		for the bottom coordinate of an element, (h means height and is relative to y1/-y1)
// data			for the data of an element, for Textboxes its normally a textid as example.
// sx, sy		When resizing the window, move this entire element. (default: do not move)
// sx2, sy2		When resizing the window, move the lower-right corner of this element. (default: move with upper-left corner)
//			Valid values for s? are 1/2 (move half window delta) and 1 (move window delta)
//			If sx and sx2 are both present, sx2 must come after sx, or the element will not be resized horizontally.
//			If sy and sy2 are both present, sx2 must come after sy, or the element will not be resized vertically.
//
// Notice: The negative keys are relative to the opposite side of the window, example:
// guiele background,cWinElemSpriteBox,cColorSchemeDarkGreen,x,0,-x2,0,y,0,-y2,0,data,0
// would create an element background that fills the complete window
//
//
// Resizable window Optionlist:
// ==========================================
// Values are again given as key/value, but some keys take two values:
// All keys come in pairs. One has a w and controls width; the other has an h and controls height.
// w,[min],[max]	Minimum and maximum width and height. If a value is omitted (eg. w,,2048), size from guiwindow is used.
// h,[min],[max]	If key is omitted, window cannot be resized in that direction.
//
// itemw,size,extra	Item width/height (size) and extra window width/height not associated with any items.
// itemh,size,extra	If key is omitted, window can be freely resized in that direction, if resizable.
//
// wele,element		Window element to get item count in .data (.data+1 for hele)
// hele,element		element may be either name or numeric id.
//			If key omitted, data is stored in the sizer.
//
//
// Names (if you use elename)
// ==========================================
// name_elements.elename		is a label in the name_elements data
// name_elements.elename_id		the id of the element (can be used in window handler as example)
// Additional defined are:
// .elename_x, .elename_x2, .elename_y, .elename_y2,
// .elename_width,  .elename_height
//
// When you use the macro guicaption:
// name_elements.caption_close_id and name_elements.caption_id are automatically defined
// guicaption also does some setup required for endguiwindow to properly generate
// sizer data, and is therefore required if guiwinresize is present.
//
// Hint: The ids are calculated for each element created by guiele 
// so it's possible to mix guiele with normal hand written element definitions!
//

%macro guiwindow 1-3.nolist
	varb %1_elements	
	%push guiwindow
	%if %2
		%assign %1_width %2
		%define %$_width %2
	%endif
	%if %3
		%assign %1_height %3
		%define %$_height %3
	%endif
	
	%define %$gui_window_cur_elements %1_elements
%endmacro

%macro endguiwindow 0.nolist
	%ifctx guiwindow
		%ifdef %$gui_window_doresize
			guiele sizer,cWinElemSizer,%$_sizer_color, -x,11, w,12, -y,11, h,12, data,0, sx,1, sy,1
			db cWinElemExtraData,cWinDataSizer
			dd ._sizer_elemlist,._sizer_constraints
			dw 0
			db cWinElemLast
		._sizer_elemlist:
			%$gui_window_doresize %$guiwindow_sizeelem,0
			%ifndef PREPROCESSONLY
				%if ($-._sizer_elemlist) <> (._sizer_elemlist - %$gui_window_cur_elements - 1)/12
					%error "guiwinresize does not support manual window elements"
				%endif
			%endif
		%else
			db cWinElemLast
		%endif
		%pop
		endvar
	%else 
		%error "expected guiwindow" 
	%endif
%endmacro

%macro guiwinresize 3-17
	%ifnctx guiwindow
		%error "expected guiwindow" 
	%endif

	%define %$gui_window_doresize db
	%define %$_sizer_color %1
	%rotate 1

	%define %%minwidth %$_width
	%define %%maxwidth %$_width
	%define %%widthstep 1
	%define %%widthele .sizer_id
	%define %%basewidth 0
	%define %%minheight %$_height
	%define %%maxheight %$_height
	%define %%heightstep 1
	%define %%heightele .sizer_id
	%define %%baseheight 0
	
	%assign %%resizeok 0

	%assign %%paramsleft %0-1
	%rep %0-1
		%ifidn {%1},{w}
			%ifnidn {%2},{}
				%define %%minwidth %2
				%assign %%resizeok 1
			%endif
			%ifnidn {%3},{}
				%define %%maxwidth %3
				%assign %%resizeok 1
			%endif
			%assign %%paramsleft %%paramsleft-1
			%rotate 1
		%elifidn {%1},{itemw}
			%define %%widthstep %2
			%define %%basewidth %3
			%assign %%paramsleft %%paramsleft-1
			%rotate 1
		%elifidn {%1},{wele}
			%ifnum %2
				%define %%widthele %2
			%else
				%define %%widthele .%2 %+ _id
			%endif
		%elifidn {%1},{h}
			%ifnidn {%2},{}
				%define %%minheight %2
				%assign %%resizeok 1
			%endif
			%ifnidn {%3},{}
				%define %%maxheight %3
				%assign %%resizeok 1
			%endif
			%assign %%paramsleft %%paramsleft - 1
			%rotate 1
		%elifidn {%1},{itemh}
			%define %%heightstep %2
			%define %%baseheight %3
			%assign %%paramsleft %%paramsleft-1
			%rotate 1
		%elifidn {%1},{hele}
			%ifnum %2
				%define %%heightele %2
			%else
				%define %%heightele .%2 %+ _id
			%endif
		%else
			%define unknown %1
			%error "Unknown key unknown"
		%endif
		%if %%paramsleft = 2
			%exitrep
		%elif %%paramsleft < 2
			%assign count 2-%%paramsleft
			%error "Expected count additional argument(s)"
			%exitrep
		%endif
		%assign %%paramsleft %%paramsleft-2
		%rotate 2
	%endrep
	noglobal vard ._sizer_constraints
		dw %%minwidth, %%maxwidth
		db %%widthstep, %%widthele
		dw %%basewidth
		dw %%minheight,%%maxheight
		db %%heightstep, %%heightele
		dw %%baseheight
	endvar
	[section .datab]
	%if %%resizeok = 0
		%error guiwinresize does not create a resizable window.
	%endif
%endmacro

%macro guiele 2-22.nolist
	%ifctx guiwindow
		%ifnidn {},{%1}
		.%1:
		%xdefine %%name %$gui_window_cur_elements %+ .%1
		.%1 %+ _id equ ($-%$gui_window_cur_elements)/12
		%endif
%ifnidn {},{%2}
	db %2, %3
	%assign %%paramcnt (%0-3)/2
	%assign %%sizer 0
	%rotate 1
	%rep %%paramcnt
		%rotate 2
		%ifidn {%1},{x}
			%assign %%x1 %2
		%elifidn {%1},{-x}
			%assign %%x1 %$_width-1-(%2)
		%elifidn {%1},{x2}
			%assign %%x2 %2
		%elifidn {%1},{-x2}
			%assign %%x2 %$_width-1-(%2)
		%elifidn {%1},{y}
			%assign %%y1 %2
		%elifidn {%1},{-y}
			%assign %%y1 %$_height-1-(%2)
		%elifidn {%1},{y2}
			%assign %%y2 %2
		%elifidn {%1},{-y2}
			%assign %%y2 %$_height-1-(%2)
		%elifidn {%1},{w}
			%assign %%x2 %%x1+%2-1
		%elifidn {%1},{h}
			%assign %%y2 %%y1+%2-1
		%elifidn {%1},{data}
			%assign %%data %2
		%elifidn {%1},{sx}
			%xdefine %%sizer (%%sizer) & 11001100b
			%ifidn {%2},{1}
				%xdefine %%sizer (%%sizer) | 11b
			%elifidn {%2},{1/2}
				%assign %%sizer (%%sizer) | 110000b
			%else
				%define unknown %2
				%error "Unknown sizer instruction unknown"
			%endif
		%elifidn {%1},{sy}
			%xdefine %%sizer (%%sizer) & 00110011b
			%ifidn {%2},{1}
				%xdefine %%sizer (%%sizer) | 1100b
			%elifidn {%2},{1/2}
				%xdefine %%sizer (%%sizer) | 11000000b
			%else
				%define unknown %2
				%error "Unknown sizer instruction unknown"
			%endif
		%elifidn {%1},{sx2}
			%xdefine %%sizer (%%sizer) & 11011101b
			%ifidn {%2},{1}
				%xdefine %%sizer (%%sizer) | 10b
			%elifidn {%2},{1/2}
				%xdefine %%sizer (%%sizer) | 100000b
			%else
				%define unknown %2
				%error "Unknown sizer instruction unknown"
			%endif
		%elifidn {%1},{sy2}
			%xdefine %%sizer (%%sizer) & 01110111b
			%ifidn {%2},{1}
				%xdefine %%sizer (%%sizer) | 1000b
			%elifidn {%2},{1/2}
				%xdefine %%sizer (%%sizer) | 10000000b
			%else
				%define unknown %2
				%error "Unknown sizer instruction unknown"
			%endif
		%else
			%define unknown %1
			%error "Unknown key unknown"
		%endif
	%endrep
	%ifnidn {},{%%name}
	assign_workaround %%name %+ _x, %%x1
	assign_workaround %%name %+ _x2, %%x2
	assign_workaround %%name %+ _width, %%x2-%%x1
	assign_workaround %%name %+ _y, %%y1
	assign_workaround %%name %+ _y2, %%y2
	assign_workaround %%name %+ _height, %%y2-%%y1
	%endif
	dw %%x1, %%x2, %%y1, %%y2, %%data
	%xdefine %$guiwindow_sizeelem %$guiwindow_sizeelem,%%sizer
%endif
	%else 
		%error "expected guiwindow" 
	%endif
%endmacro

%macro assign_workaround 2
	%assign %1 %2
%endmacro

%macro guicaption 2.nolist
	%ifctx guiwindow
		.caption_close:
		db cWinElemTextBox,%1
		dw 0, 10, 0, 13, 0x00C5
		.caption:
		db cWinElemTitleBar,%1
		dw 11,%$_width-1, 0, 13, %2
		.caption_close_id equ 0
		.caption_id equ 1
		%define %$guiwindow_sizeelem 0,2
	%else
		%error "expected guiwindow" 
	%endif
%endmacro
