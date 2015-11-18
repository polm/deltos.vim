" Navigate links
function! FollowDeltosLink()
    let oldx = getreg('x')
    normal "xyi)
    let link = getreg('x')
    call setreg('x', oldx)
    let uuid = split(link, '//')[-1]
    let fname = $DELTOS_HOME . '/by-id/' . uuid
    " Don't create new files
    " If the uuid isn't a filename it's probably empty or a url etc.
    if filereadable(fname) 
        execute ':e' fnameescape(fname)
    endif
endfunction

" Make new note and edit it
let g:deltos_command = 'deltos'
function! DeltosOpenNewNote()
    let fname = system(g:deltos_command . ' new')[:-2]
    execute ':e' fnameescape(fname)
endfunction

" Make current line into a link to a new note
function! DeltosNewLinkFromCurrentLine()
    let line = getline('.')
    " note we can just pass the title to deltos new
    let fname = system(g:deltos_command . ' new ' . line)[:-2]
    let link = '.(' . line . '//' . fname . ')'
    call setline('.', link)
endfunction

" Put the current file ID in the paste buffer, good for making links
function! DeltosYankId()
    let idline = system("grep -m1 '^id:' " . expand('%'))
    let @" = split(idline, ' ')[-1]
endfunction

function! DeltosGetTitle(fname)
    let titleline = system("grep -m1 '^title' " . fnameescape(expand(a:fname)))
    return join(split(titleline, ' ')[1:-1], ' ')[0:-2] " -2 chomps the newline
endfunction

"Deltos unite stuff
let s:unite_source = {
   \   'name': 'deltos',
   \ }

function! s:unite_source.gather_candidates(args, context)
    " Goal: get buffers, display titles
    " This just gives us numbers
    let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    return map(buffers, '{
                \ "word": DeltosGetTitle(bufname(v:val)),
                \ "source": "deltos",
                \ "kind": "buffer",
                \ "action__buffer_nr": v:val,
                \ }')
endfunction
call unite#define_source(s:unite_source)
unlet s:unite_source " we no longer need the function

au BufRead,BufNewFile $DELTOS_HOME/* set filetype=deltos
au BufRead,BufNewFile $DELTOS_HOME/* nmap <silent><buffer> <CR> :call FollowDeltosLink()<CR>
au BufRead,BufNewFile $DELTOS_HOME/* nnoremap <leader>nd :call DeltosOpenNewNote()<CR>
au BufRead,BufNewFile $DELTOS_HOME/* nnoremap <leader>id :call DeltosYankId()<CR>
au BufRead,BufNewFile $DELTOS_HOME/* nnoremap <leader>nl :call DeltosNewLinkFromCurrentLine()<CR>
au BufRead,BufNewFile $DELTOS_HOME/* nnoremap <leader>a :<C-u>Unite -buffer-name=deltos deltos<cr>
au BufWritePost $DELTOS_HOME/* silent !deltos update

au BufRead,BufNewFile $DELTOS_HOME/* set conceallevel=2 concealcursor=i " Uses conceal settings
