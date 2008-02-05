//
// Easy gui construction with named components to be used in window handlers.
//
// Example of usage
// ==========================================
// guiwindow name, width, height	// will create name_elements and %name_width and %name_height
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
// data for the data of an element, for Textboxes its normally a textid as example.
//
// Notice: The negative keys are relative to the opposite side of the window, example:
// guiele background,cWinElemSpriteBox,cColorSchemeDarkGreen,x,0,-x2,0,y,0,-y2,0,data,0
// would create an element background that fills the complete window
//
// Names (if you use elename)
// ==========================================
// name_elements.elename		is an label into the name_elements data
// name_elements.elename_id		the id of the element (can be used in window handler as example)
// Additional defined are:
// .elename_x, .elename_x2, .elename_y, .elename_y2,
// .elename_width,  .elename_height
//
// When you use the macro guicaption:
// name_elements.caption_close_id and name_elements.caption_id are automatical defined
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
		%pop
		db cWinElemLast
		endvar
	%else 
		%error "expected guiwindow" 
	%endif
%endmacro

%macro guiele 2-14.nolist
	%ifctx guiwindow
		%ifnidn {},{%1}
		.%1:
		%xdefine %%name %$gui_window_cur_elements %+ .%1
		assign_workaround %%name %+ _id, ($-%$gui_window_cur_elements)/12
		%endif
%ifnidn {},{%2}		
	db %2, %3
	%assign %%paramcnt (%0-3)/2
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
			%assign %%x2 %%x1+%2
		%elifidn {%1},{h}
			%assign %%y2 %%y1+%2
		%elifidn {%1},{data}
			%assign %%data %2
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
		assign_workaround %$gui_window_cur_elements %+ .caption_close_id,0
		assign_workaround %$gui_window_cur_elements %+ .caption_id,1
	%else
		%error "expected guiwindow" 
	%endif
%endmacro
