syntax include @Markdown syntax/markdown.vim
syntax region Markdown keepend start="^$" end="\%$" containedin=ALL contains=@Markdown,deltosLink,deltosCommand,deltosCodeOutput

" treat YAML as a comment
syntax region Special start="\%^" end="---$" 

"Here's the deltos-specific stuff
syn match deltosLink "\.([^)]*)" contains=deltosLinkOpener,deltosLinkCloser
syn match deltosLinkOpener "\.(" contained conceal cchar=°
syn match deltosLinkCloser "//[^)]*)" contained conceal

syn match deltosCommand "^!.*$" contains=deltosCommandKeyword,deltosCommandArgs
syn match deltosCommandKeyword "^![A-z][A-z-]*" contained
syn match deltosCommandArgs " .*$"  contained

syn match deltosCodeOutput "^無無無無.*$" contains=deltosOutputStart,deltosLink
syn match deltosOutputStart "^無無無無" conceal

hi link deltosCodeOutput Comment
hi link deltosLink Identifier
hi link deltosLinkCloser Type
hi link deltosCommandKeyword PreProc
hi link deltosCommandArgs Special

