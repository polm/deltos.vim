syntax include @Markdown syntax/markdown.vim
syntax region Markdown keepend start="^$" end="\%$" containedin=ALL contains=@Markdown,deltosLink,deltosCommand

" treat YAML as a comment
syntax region Special start="\%^" end="---$" 

"Here's the deltos-specific stuff
syn match deltosLink "\.([^)]*)" contains=deltosLinkOpener,deltosLinkCloser
syn match deltosLinkOpener "\.(" contained conceal cchar=°
syn match deltosLinkCloser "//[^)]*)" contained conceal

syn match deltosCommand "^!.*$" contains=deltosCommandKeyword,deltosCommandArgs
syn match deltosCommandKeyword "^![A-z][A-z]*" contained
syn match deltosCommandArgs " .*$"  contained
 
hi link deltosLink Identifier
hi link deltosLinkCloser Type
hi link deltosCommandKeyword PreProc
hi link deltosCommandArgs Special

