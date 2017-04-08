" Navigate links
function! FollowDeltosLink()
    let oldx = getreg('x')
    normal "xyi)
    let link = getreg('x')
    call setreg('x', oldx)
    if !empty(link) && link =~ '//'
        let uuid = split(link, '//')[-1]
        let fname = $DELTOS_HOME . '/by-id/' . uuid . '/deltos'
    else
        " try just using the word under the cursor - good for parents etc.
        " save and restore iskeyword since we need dashes here
        let oldisk = &iskeyword
        setlocal iskeyword+=-
        let fname = $DELTOS_HOME . '/by-id/' . expand("<cword>") . '/deltos'
        let &iskeyword = oldisk
    endif
    echom 'fname: ' . fname
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
    let ff  = fnameescape(expand(a:fname))
    let titleline = system("grep -m1 '^title' " . ff)
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
                \ "action__path": ($DELTOS_HOME . "/by-id/" . split(v:val,"\t")[2] . "/deltos"),
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

function! DeltosDaily()
  " Setting the editor to echo means we just get the filename
  let fname = system("EDITOR=echo " . g:deltos_command . " daily")[:-2]
  if filereadable(fnameescape(fname))
    execute ':e' fnameescape(fname)
  end
endfunction

function! DeltosOpen()
  if isdirectory(expand('%'))
    let base = expand('%')
    execute ':e ' (base . '/deltos')
    set statusline=%{DeltosGetTitle('%')}
    set filetype=deltos
  end
endfunction

augroup deltos
    autocmd!
    " Handle dir
    au VimEnter $DELTOS_HOME/by-id/*/deltos sil! au! FileExplorer *
    au BufEnter,BufRead $DELTOS_HOME/by-id/* :call DeltosOpen()
    au BufEnter,BufRead $DELTOS_HOME/by-id/* cd %:p:h
    " normal mode
    au FileType deltos nnoremap <buffer> <CR> :call FollowDeltosLink()<CR>
    au FileType deltos nnoremap <leader>nd :call DeltosOpenNewNote()<CR>
    au FileType deltos nnoremap <leader>id :call DeltosYankId()<CR>
    au FileType deltos nnoremap <leader>nl :call DeltosNewLink()<CR>
    au FileType deltos nnoremap <leader>da :call DeltosDaily()<CR>
    " visual
    au FileType deltos vnoremap <leader>nl :call DeltosNewLinkFromVisualSelection()<CR>
    " not interactive
    au FileType deltos set conceallevel=2 concealcursor=i " Uses conceal settings
augroup END

nnoremap <leader>do :<C-u>Unite -buffer-name=deltos_open -start-insert deltos_open<cr>
nnoremap <leader>ds :<C-u>Unite -buffer-name=deltos_all -start-insert deltos_all<cr>
nnoremap <leader>li :<C-u>Unite -buffer-name=deltos_link -start-insert deltos_link<cr>
