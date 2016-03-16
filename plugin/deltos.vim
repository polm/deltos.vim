" Navigate links
function! FollowDeltosLink()
    let oldx = getreg('x')
    normal "xyi)
    let link = getreg('x')
    call setreg('x', oldx)
    if !empty(link) && link =~ '//'
        let uuid = split(link, '//')[-1]
        let fname = $DELTOS_HOME . '/by-id/' . uuid
    else
        " try just using the word under the cursor - good for parents etc.
        " save and restore iskeyword since we need dashes here
        let oldisk = &iskeyword
        setlocal iskeyword+=-
        let fname = $DELTOS_HOME . '/by-id/' . expand("<cword>")
        let &iskeyword = oldisk
    endif
    if filereadable(fname)
        execute ':e' fnameescape(fname)
    end
endfunction

" Make new note and edit it
let g:deltos_command = 'deltos'
function! DeltosOpenNewNote()
    let fname = system(g:deltos_command . ' new')[:-2]
    execute ':e' fnameescape(fname)
endfunction

function! DeltosNewLink()
    let fname = system(g:deltos_command . ' new')[:-2]
    let uuid = split(fname, '/')[-1]
    execute "normal! ciw.(NewTitleHere//" . uuid . ")" 
endfunction

" Make visual selection into a link to a new note
" This expands the visual selection to completely include any touched words
" XXX currently if you highlight the last letter of a multi-letter word at the
" start of the visual selection it is *not* included; fixing this probably
" requires checking the length of the word there (using setpos and cword is
" one way)
function! DeltosNewLinkFromVisualSelection()
    normal `<eb
    let start = getpos('.')[2] - 1
    normal `>beh
    let finish = getpos('.')[2]
    let title = getline('.')[start : finish]
    let fname = system(g:deltos_command . ' new ' . title)[:-2]
    let uuid = split(fname, '/')[-1]
    let link = ".(" . title . '//' . uuid . ")"

    let prefix = ''
    if start > 0
      let prefix = getline('.')[: start - 1]
    endif
    call setline('.', prefix . link . getline('.')[finish+1 : ])
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
let s:unite_source_deltos_open = {  'name': 'deltos_open' }

function! s:unite_source_deltos_open.gather_candidates(args, context)
    " Goal: get buffers, display titles
    " This just gives us numbers
    let buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    return map(buffers, '{
                \ "word": DeltosGetTitle(bufname(v:val)),
                \ "source": "deltos_open",
                \ "kind": "buffer",
                \ "action__buffer_nr": v:val,
                \ }')
endfunction
call unite#define_source(s:unite_source_deltos_open)
unlet s:unite_source_deltos_open " we no longer need the function

" Now for all deltos files
let s:unite_source_deltos_all = { 'name': 'deltos_all' }

function! s:unite_source_deltos_all.gather_candidates(args, context)
    " display all files in deltos
    " fields are id, title, tags
    let alltsv = split(system(g:deltos_command . ' tsv'), "\n")
    return map(alltsv, '{
                \ "word": join(split(v:val,"\t")[0:1], " :: "),
                \ "source": "deltos_all",
                \ "kind": "file",
                \ "action__path": ($DELTOS_HOME . "/by-id/" . split(v:val,"\t")[2]),
                \ }')
endfunction
call unite#define_source(s:unite_source_deltos_all)
unlet s:unite_source_deltos_all " we no longer need the function

let s:unite_source_deltos_link = { 'name': 'deltos_link' }
function! s:unite_source_deltos_link.gather_candidates(args, context)
    let alltsv = split(system(g:deltos_command . ' tsv'), "\n")
    return map(alltsv, '{
                \ "word": join(split(v:val,"\t")[0:1], " :: "),
                \ "source": "deltos_link",
                \ "kind": "word",
                \ "action__text": ".(" . split(v:val,"\t")[0] . "//" . split(v:val,"\t")[2] . ")",
                \ }')
endfunction
call unite#define_source(s:unite_source_deltos_link)
unlet s:unite_source_deltos_link " we no longer need the function

augroup deltos
    autocmd!
    au BufRead,BufNewFile $DELTOS_HOME/* nnoremap <silent><buffer> <CR> :call FollowDeltosLink()<CR>
    au BufRead,BufNewFile $DELTOS_HOME/* nnoremap <leader>nd :call DeltosOpenNewNote()<CR>
    au BufRead,BufNewFile $DELTOS_HOME/* nnoremap <leader>id :call DeltosYankId()<CR>
    au BufRead,BufNewFile $DELTOS_HOME/* nnoremap <leader>nl :call DeltosNewLink()<CR>
    au BufRead,BufNewFile $DELTOS_HOME/* vnoremap <leader>nl :call DeltosNewLinkFromVisualSelection()<CR>
    au BufRead,BufNewFile $DELTOS_HOME/* set conceallevel=2 concealcursor=i " Uses conceal settings
augroup END

nnoremap <leader>do :<C-u>Unite -buffer-name=deltos_open -start-insert deltos_open<cr>
nnoremap <leader>da :<C-u>Unite -buffer-name=deltos_all -start-insert deltos_all<cr>
nnoremap <leader>li :<C-u>Unite -buffer-name=deltos_link -start-insert deltos_link<cr>
