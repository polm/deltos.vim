" Copy some basic Markdown syntax
syn region markdownH1 matchgroup=markdownHeadingDelimiter start="^##\@!"      end="#*\s*$" keepend oneline concealends
syn region markdownH2 matchgroup=markdownHeadingDelimiter start="^###\@!"     end="#*\s*$" keepend oneline concealends
syn region markdownH3 matchgroup=markdownHeadingDelimiter start="^####\@!"    end="#*\s*$" keepend oneline concealends
hi h1 cterm=BOLD ctermfg=White ctermbg=DarkRed
hi h2 cterm=BOLD ctermfg=White ctermbg=DarkBlue
hi h3 cterm=BOLD ctermfg=White ctermbg=DarkGreen
hi def link markdownH1 h1
hi def link markdownH2 h2
hi def link markdownH3 h3
syn region markdownBold matchgroup=markdownBoldGroup start="\S\@<=\*\*\|\*\*\S\@=" end="\S\@<=\*\*\|\*\*\S\@=" keepend concealends
syn region markdownCode matchgroup=markdownCodeDelimiter start="`" end="`" keepend concealends
hi def link markdownBold                  Underlined
hi def link markdownCode                  Identifier
 
"Here's the deltos-specific stuff
syn match deltosLink "\.([^)]*)" contains=deltosLinkOpener,deltosLinkCloser
syn match deltosLinkOpener "\.(" contained conceal cchar=°
syn match deltosLinkCloser "//[^)]*)" contained conceal
 
hi link deltosLink String
