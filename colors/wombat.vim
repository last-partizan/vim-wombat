" vim:set ts=4 sw=4 noet fdm=marker:

set background=dark

if version > 580
	hi clear
	if exists("syntax_on")
		syntax reset
	endif
endif

let g:colors_name = "wombat"

if !has("gui_running") && &t_Co != 88 && &t_Co != 256
	finish
endif

" functions {{{
" returns an approximate grey index for the given grey level
fun s:grey_number(x)
	if &t_Co == 88
		if a:x < 23
			return 0
		elseif a:x < 69
			return 1
		elseif a:x < 103
			return 2
		elseif a:x < 127
			return 3
		elseif a:x < 150
			return 4
		elseif a:x < 173
			return 5
		elseif a:x < 196
			return 6
		elseif a:x < 219
			return 7
		elseif a:x < 243
			return 8
		else
			return 9
		endif
	else
		if a:x < 14
			return 0
		else
			let l:n = (a:x - 8) / 10
			let l:m = (a:x - 8) % 10
			if l:m < 5
				return l:n
			else
				return l:n + 1
			endif
		endif
	endif
endfun

" returns the actual grey level represented by the grey index
fun s:grey_level(n)
	if &t_Co == 88
		if a:n == 0
			return 0
		elseif a:n == 1
			return 46
		elseif a:n == 2
			return 92
		elseif a:n == 3
			return 115
		elseif a:n == 4
			return 139
		elseif a:n == 5
			return 162
		elseif a:n == 6
			return 185
		elseif a:n == 7
			return 208
		elseif a:n == 8
			return 231
		else
			return 255
		endif
	else
		if a:n == 0
			return 0
		else
			return 8 + (a:n * 10)
		endif
	endif
endfun

" returns the palette index for the given grey index
fun s:grey_color(n)
	if &t_Co == 88
		if a:n == 0
			return 16
		elseif a:n == 9
			return 79
		else
			return 79 + a:n
		endif
	else
		if a:n == 0
			return 16
		elseif a:n == 25
			return 231
		else
			return 231 + a:n
		endif
	endif
endfun

" returns an approximate color index for the given color level
fun s:rgb_number(x)
	if &t_Co == 88
		if a:x < 69
			return 0
		elseif a:x < 172
			return 1
		elseif a:x < 230
			return 2
		else
			return 3
		endif
	else
		if a:x < 75
			return 0
		else
			let l:n = (a:x - 55) / 40
			let l:m = (a:x - 55) % 40
			if l:m < 20
				return l:n
			else
				return l:n + 1
			endif
		endif
	endif
endfun

" returns the actual color level for the given color index
fun s:rgb_level(n)
	if &t_Co == 88
		if a:n == 0
			return 0
		elseif a:n == 1
			return 139
		elseif a:n == 2
			return 205
		else
			return 255
		endif
	else
		if a:n == 0
			return 0
		else
			return 55 + (a:n * 40)
		endif
	endif
endfun

" returns the palette index for the given R/G/B color indices
fun s:rgb_color(x, y, z)
	if &t_Co == 88
		return 16 + (a:x * 16) + (a:y * 4) + a:z
	else
		return 16 + (a:x * 36) + (a:y * 6) + a:z
	endif
endfun

" returns the palette index to approximate the given R/G/B color levels
fun s:color(r, g, b)
	" get the closest grey
	let l:gx = s:grey_number(a:r)
	let l:gy = s:grey_number(a:g)
	let l:gz = s:grey_number(a:b)

	" get the closest color
	let l:x = s:rgb_number(a:r)
	let l:y = s:rgb_number(a:g)
	let l:z = s:rgb_number(a:b)

	if l:gx == l:gy && l:gy == l:gz
		" there are two possibilities
		let l:dgr = s:grey_level(l:gx) - a:r
		let l:dgg = s:grey_level(l:gy) - a:g
		let l:dgb = s:grey_level(l:gz) - a:b
		let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
		let l:dr = s:rgb_level(l:gx) - a:r
		let l:dg = s:rgb_level(l:gy) - a:g
		let l:db = s:rgb_level(l:gz) - a:b
		let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
		if l:dgrey < l:drgb
			" use the grey
			return s:grey_color(l:gx)
		else
			" use the color
			return s:rgb_color(l:x, l:y, l:z)
		endif
	else
		" only one possibility
		return s:rgb_color(l:x, l:y, l:z)
	endif
endfun

" returns the palette index to approximate the 'rrggbb' hex string
fun s:rgb(rgb)
	let l:r = ("0x" . strpart(a:rgb, 0, 2)) + 0
	let l:g = ("0x" . strpart(a:rgb, 2, 2)) + 0
	let l:b = ("0x" . strpart(a:rgb, 4, 2)) + 0
	return s:color(l:r, l:g, l:b)
endfun

" sets the highlighting for the given group
fun s:HlGroup(group, fg, bg, attr)
	if a:fg != ""
		exec "hi ".a:group." guifg=".a:fg." ctermfg=".s:rgb(a:fg)
	endif
	if a:bg != ""
		exec "hi ".a:group." guibg=".a:bg." ctermbg=".s:rgb(a:bg)
	endif
	if a:attr != ""
		if a:attr == 'italic'
			exec "hi ".a:group." gui=".a:attr." cterm=none"
		else
			exec "hi ".a:group." gui=".a:attr." cterm=".a:attr
		endif
	endif
endfun

" same as above, but makes it for the spell-like things
fun s:HlSpell(group, bg)
	if ! has('gui_running')
		if a:bg != ""
			exec "hi ".a:group." ctermbg=".s:rgb(a:bg)
		endif
	else
		if a:bg != ""
			exec "hi ".a:group." guisp=".a:bg." gui=undercurl"
		endif
	endif
endfun
" }}}

" italic only in gui and only where font is not fixed-misc!

if has("gui_running") && &guifont !~ "Fixed"
	let s:italic = "italic"
else
	let s:italic = "none"
endif


" non-syntax items, interface, etc
call s:HlGroup("Normal",		"#dddddd",	"#242424",	"none")
call s:HlGroup("NonText",		"#4c4c36",	"",			"none")
call s:HlGroup("Cursor",		"#222222",	"#ecee90",	"none")

if version > 700
	call s:HlGroup("CursorLine",	"",	"#32322e",	"none")
	hi link CursorColumn CursorLine
	if version > 703
		call s:HlGroup("ColorColumn", "", "#2d2d2d", "")
	endif
endif

call s:HlGroup("Search",		"#d787ff",	"#636066",	"")
call s:HlGroup("MatchParen",	"#ecee90",	"#857b6f",	"bold")
call s:HlGroup("SpecialKey",	"#6c6c6c",	"#2d2d2d",	"none")
call s:HlGroup("Visual",		"#c3c6ca",  "#554d4b",	"none")
call s:HlGroup("LineNr",		"#857b6f",	"#121212",	"none")
call s:HlGroup("SignColumn",    "#a0a8b0",	"#2d2d2d",	"none")
call s:HlGroup("Folded",		"#a0a8b0",	"#404048",	"none")
call s:HlGroup("Title",			"#f6f3e8",	"",			"bold")
call s:HlGroup("VertSplit",		"#444444",	"#444444",	"none")
call s:HlGroup("StatusLine",	"#f6f3e8",	"#444444",	s:italic)
call s:HlGroup("StatusLineNC",	"#857b6f",	"#444444",	"none")
call s:HlGroup("Pmenu",			"#f6f3e8",	"#444444",	"")
call s:HlGroup("PmenuSel",		"#121212",	"#caeb82",	"")
call s:HlGroup("WarningMsg",	"#ff0000",	"",			"")

hi! link VisualNOS	Visual
hi! link FoldColumn	Folded
hi! link TabLineSel StatusLine
hi! link TabLineFill StatusLineNC
hi! link TabLine StatusLineNC
call s:HlGroup("TabLineSel", 	"#f6f3e8", "", 			"none")

" syntax highlighting
call s:HlGroup("Comment",		"#99968b",	"",			s:italic)

call s:HlGroup("Constant",		"#e5786d",	"",			"none")
call s:HlGroup("String",		"#95e454",	"",			s:italic)
"Character
"Number
"Boolean
"Float

call s:HlGroup("Identifier",	"#caeb82",	"",			"none")
call s:HlGroup("Function",		"#caeb82",	"",			"none")

call s:HlGroup("Statement", 	"#87afff",	"",			"none")
"Conditional
"Repeat
"Label
"Operator
call s:HlGroup("Keyword",		"#87afff",	"",			"none")
"Exception

call s:HlGroup("PreProc",		"#e5786d",	"",			"none")
"Include
"Define
"Macro
"PreCondit

call s:HlGroup("Type",			"#caeb82",	"",			"none")
"StorageClass
"Structure
"Typedef

call s:HlGroup("Special",		"#ffdead",	"",			"none")
"SpecialChar
"Tag
"Delimiter
"SpecialComment
"Debug

"Underlined

"Ignore

call s:HlGroup("Error", "#bbbbbb", "#aa0000", s:italic)

call s:HlGroup("Todo", "#666666", "#aaaa00", s:italic)

" Diff
call s:HlGroup("DiffAdd",    "", 		"#505450", "bold")
call s:HlGroup("DiffText",   "", 		"#673400", "bold")
call s:HlGroup("DiffDelete", "#343434", "#101010", "bold")
call s:HlGroup("DiffChange", "", 		"#53402d", "bold")

" Spellchek
if  version > 700
	" spell, make it underline, and less bright colors. only for terminal
	call s:HlSpell("SpellBad", "#881000")
	call s:HlSpell("SpellCap", "#003288")
	call s:HlSpell("SpellRare", "#73009F")
	call s:HlSpell("SpellLocal", "#a0cc00")
endif

" Plugins:
" ShowMarks
call s:HlGroup("ShowMarksHLl", "#ab8042", "#121212", "bold")
call s:HlGroup("ShowMarksHLu", "#aaab42", "#121212", "bold")
call s:HlGroup("ShowMarksHLo", "#42ab47", "#121212", "bold")
call s:HlGroup("ShowMarksHLm", "#aaab42", "#121212", "bold")

" Syntastic
call s:HlSpell("SyntasticError ", "#880000")
call s:HlSpell("SyntasticWarning", "#886600")
call s:HlSpell("SyntasticStyleError", "#ff6600")
call s:HlGroup("SyntasticErrorSign", "", "#880000", "")
call s:HlGroup("SyntasticWarningSign", "", "#886600", "")
call s:HlGroup("SyntasticStyleErrorSign", "", "#ff6600", "")
call s:HlGroup("SyntasticStyleWarningSign", "", "#ffaa00", "")

" Signify
call s:HlGroup("SignifySignAdd",    "#a0cc00", "#2d2d2d", "")
call s:HlGroup("SignifySignDelete", "#673400", "#2d2d2d", "")
call s:HlGroup("SignifySignChange", "#87afff", "#2d2d2d", "")
