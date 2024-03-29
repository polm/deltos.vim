" Pick up any files in the deltos dir
"au BufRead,BufNewFile $DELTOS_HOME/by-id/* set filetype=deltos
au BufRead,BufNewFile $DELTOS_HOME/by-id/*/deltos set filetype=deltos
" Set statusline to post title
au BufWinEnter,BufWritePost $DELTOS_HOME/by-id/*/deltos call DeltosOpen()
" for backlinks
au BufRead,BufNewFile $DELTOS_HOME/by-id/*/deltos set errorformat=%m\	%f
