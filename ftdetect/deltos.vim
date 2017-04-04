" Pick up any files in the deltos dir
au BufRead,BufNewFile $DELTOS_HOME/by-id/*/deltos set filetype=deltos
" Set statusline to post title
au BufWinEnter,BufWritePost $DELTOS_HOME/by-id/*/deltos set statusline=%{DeltosGetTitle('%')}
