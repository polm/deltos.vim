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

function! DeltosOpenReply()
    " get the id of the current note
    let idline = system("grep -m1 '^id:' " . expand('%'))
    let id = split(idline, ' ')[-1]
    " create the reply
    let fname = system(g:deltos_command . ' reply ' . id)[:-2]
    if v:shell_error
      echo "Failed with error: " . fname
    else
      execute ':e' fnameescape(fname)
    endif
endfunction

function! DeltosGetThread()
    let oldcur = getcurpos()
    call cursor(0, 1)
    let tline = search('^thread:', 'c')
    call setpos('.', oldcur)
    if tline > 0
      return split(getline(tline), ' ')[-1]
    endif
endfunction

function! DeltosGetId()
    let oldcur = getcurpos()
    call cursor(0, 1)
    let tline = search('^id:', 'c')
    call setpos('.', oldcur)
    if tline > 0
      return split(getline(tline), ' ')[-1]
    endif
endfunction

function! DeltosOpenThreadNext()
    let id = DeltosGetId()

    let posts = split(system(g:deltos_command . ' get-thread ' . id), '\n')
    if v:shell_error
      echo "Failed with error!"
    else
      let nidx = index(posts, id) - 1
      if nidx < 0
        echo "Already at newest post"
      else
        execute ':e' fnameescape($DELTOS_HOME . '/by-id/' . posts[nidx])
      endif
    endif
endfunction

function! DeltosOpenThreadPrev()
    let id = DeltosGetId()

    let posts = split(system(g:deltos_command . ' get-thread ' . id), '\n')
    if v:shell_error
      echo "Failed with error!"
    else
      let nidx = index(posts, id) + 1
      if nidx >= len(posts)
        " if there is a reply-to, go there
        let reply_to = DeltosGetField('%','reply-to')
        if !v:shell_error
          execute ':e' fnameescape($DELTOS_HOME . '/by-id/' . reply_to)
        else 
          echo "Already at oldest post"
        endif
      else
        execute ':e' fnameescape($DELTOS_HOME . '/by-id/' . posts[nidx])
      endif
    endif
endfunction

function! DeltosOpenThreadFirst()
    let id = DeltosGetId()

    let posts = split(system(g:deltos_command . ' get-thread ' . id), '\n')
    if v:shell_error
      echo "Failed with error!"
    else
        execute ':e' fnameescape($DELTOS_HOME . '/by-id/' . posts[-1])
    endif
endfunction

function! DeltosOpenThreadLatest(tid)
    if a:tid == v:false
      let id = DeltosGetId()
    else
      let id = a:tid
    endif

    let posts = split(system(g:deltos_command . ' get-thread ' . id), '\n')
    if v:shell_error
      echo "Failed with error!"
    else
      execute ':e' fnameescape($DELTOS_HOME . '/by-id/' . posts[0])
    endif
endfunction

function! DeltosOpenFromFzf(line)
    let deltosid = split(a:line, '\t')[-1]
    execute ':e' fnameescape($DELTOS_HOME . '/by-id/' . deltosid)
endfunction

function! DeltosOpenFromFts(line)
    " TODO unify the format here with the other search - this shouldn't be
    " completely different...
    let parts = split(a:line, '\t')
    execute ':e +' . parts[1] . ' ' . parts[0]
endfunction

function! DeltosInsertLinkFromFzf(line)
    let deltosid = split(a:line, '\t')[-1]
    let fname = fnameescape($DELTOS_HOME . '/by-id/' . deltosid)
    let title = split(a:line, '\t')[0]
    let alias = DeltosGetField(fname, 'alias')
    if len(alias) > 0
      let title = alias
    endif
    let link = '.(' . title . '//' . deltosid . ')'
    execute "normal! i" . link . "\<ESC>"
endfunction

function! DeltosSetProjectFromFzf(line)
    let deltosid = split(a:line, '\t')[-1]

    let oldcur = getcurpos()
    call cursor(0, 1)
    
    " find and delete any existing parent
    let tline = search('^projects:', 'c')
    " get the contents of the line
    let projs = []
    if tline > 0 
      let projs = split(trim(getline(tline)[9:], " []"), "/, */")
      exec tline 'delete _'
    endif

    " now find the --- line and set the parent
    let tline = search('^---$', 'c') - 1
    " TODO uniq doesn't seem to be working, why not?
    let pline = join(uniq([deltosid] + projs), ", ")
    call append(tline, 'projects: [' .. pline .. ']')

    "reset cursor
    call setpos('.', oldcur)
endfunction

function! DeltosGoToProject()
  "TODO this is functional, but it only uses the first project.
  "Ideally it should open fzf to choose if there is more than one.
    let tline = search('^projects:', 'c')
    let projs = split(trim(getline(tline)[9:], " []"), "/, */")
    if len(projs) > 0
      call DeltosEdit(projs[0])
    endif 
endfunction

function! DeltosSetParentFromFzf(line)
    let deltosid = split(a:line, '\t')[-1]

    let oldcur = getcurpos()
    call cursor(0, 1)
    
    " find and delete any existing parent
    let tline = search('^parent:', 'c')
    if tline > 0 
      exec tline 'delete _'
    endif

    " now find the --- line and set the parent
    let tline = search('^---$', 'c') - 1
    call append(tline, 'parent: ' . deltosid)

    "reset cursor
    call setpos('.', oldcur)
endfunction

function! DeltosNewLink()
    let fname = system(g:deltos_command . ' new')[:-2]
    let uuid = split(fname, '/')[-2]
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
    let uuid = split(fname, '/')[-2]
    let link = ".(" . title . '//' . uuid . ")"

    let prefix = ''
    if start > 0
      let prefix = getline('.')[: start - 1]
    endif
    call setline('.', prefix . link . getline('.')[finish+1 : ])
endfunction

function! DeltosLineToNewEntry()
  let line = getline('.')
  let prefix = ''
  if '- ' == line[0:1]
    let line = line[2:]
    let prefix = '- '
  endif

  let fname = system(g:deltos_command . ' new ' . shellescape(line) )[:-2]
  let uuid = split(fname, '/')[-1]
  let link = ".(" . line . '//' . uuid . ")"
  call setline('.', prefix . link)
endfunction

" Put the current file ID in the paste buffer, good for making links
function! DeltosYankId()
    let @" = DeltosGetId()
endfunction

function! DeltosGetBuffers()
    return map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), 
          \ 'DeltosGetBufferLine(v:val)')
endfunction

function! DeltosGetBufferLine(bufnum)
    let ff  = fnameescape(expand('#' . a:bufnum))
    if isdirectory(ff)
      let ff = ff . '/deltos'
    endif
    let date = DeltosGetField(ff, 'date')
    let title = DeltosGetField(ff, 'title')
    let id = DeltosGetField(ff, 'id')
    return title . '	' . date . '	' . id
endfunction

function! DeltosGetField(fname, field)
    " this is honestly pretty awful!
    let ff = fnameescape(expand(a:fname))
    if isdirectory(ff)
      let ff = ff . '/deltos'
    endif
    let line = system("grep -m1 '^" . a:field . "' " . ff)
    let res = join(split(line, ' ')[1:-1], ' ')[0:-2] " -2 chomps the newline
    if res[0] == '"' && res[-1:] == '"'
      " remove quotes
      return res[1:-2]
    endif
    return res
endfunction

function! DeltosEdit(id)
  execute ':e' fnameescape($DELTOS_HOME . '/by-id/' . a:id)
endfunction

function! DeltosOpen()
  let base = expand('%')
  if isdirectory(base)
    " get the number of the buffer with the directory
    let cb = expand('<abuf>') 
    " open the deltos file
    execute ':e ' (base . '/deltos')
    " clear the directory buffer
    execute cb . 'bwipeout!'
  end

  call DeltosNavigationSummary()

  set statusline=%{DeltosGetField('%','title')}%=%{b:navsum}
  set filetype=deltos
endfunction

function! DeltosNavigationSummary()
  let navsum = system(g:deltos_command .. ' navigate-summary ' .. DeltosGetId())
  let b:navsum = navsum[0:-2]
endfunction

function! DeltosShowBacklinks()
  cgetexpr system('deltos links-to ' . expand('%:p:h:t'))
  copen
  wincmd p
endfunction

function! DeltosThreadSearch()
  let query = input("String to search: ")
  if len(query) == 0
    return
  endif
  let posts = split(system(g:deltos_command . ' get-thread ' . DeltosGetId()), '\n')
  let targets = ''
  " build the list in reverse order, since newer posts come first
  for post in posts
    "let targets = targets . ' ' . fnameescape($DELTOS_HOME . '/by-id/' . post . '/deltos')
    let targets = ' ' . fnameescape($DELTOS_HOME . '/by-id/' . post . '/deltos') . ' ' . targets
  endfor
  silent execute "grep! " . shellescape(query) . " " . targets
  let title = DeltosGetField('%', 'title')
  call setqflist([], 'a', {'title': 'grep ' . query . ' {' . title . '}' })
endfunction

function! DeltosQuickfixFormat(info)
  " just show the id
  " TODO: show date?
	let items = getqflist({'id' : a:info.id, 'items' : 1}).items
	let l = []
	for idx in range(a:info.start_idx - 1, a:info.end_idx - 1)
	    " use the simplified file name
    let ff  = fnameescape(expand('#' . items[idx].bufnr))
    let date = DeltosGetField(ff, 'date')[0:9]
    let title = DeltosGetField(ff, 'title')

	  call add(l, fnamemodify(bufname(items[idx].bufnr), ':p:h:t') . '|' . date . '|' . title . '|' . items[idx].text)
	endfor
	return l
endfunction
set qftf=DeltosQuickfixFormat

function! DeltosFzfNavigate()
  let id = DeltosGetId()
  call fzf#run(fzf#wrap({'source': 'deltos navigate ' .. id, 'options': g:deltos_search_opts, 'sink': function('DeltosOpenFromFzf')}))
endfunction

function! CopyTodo()
  " copy unfinished todos from the top of an entry to the bottom
  let oldpos = getpos(".")

  " move after the header
  call cursor(1, 1)
  call search('^---')
  normal! j

  let todos = ''
  while v:true
    let line = getline(".")
    if len(line) > 0 && line[0] != '-'
      " stop once we get a non-todo
      break
    elseif line =~ '\v- ([x)@!' || len(line) == 0
      " copy unfinished todos and empty divider lines
      let todos = todos . "\n" . line
    endif
    normal! j
  endwhile 

  cal setpos(".", oldpos)
  execute "normal! i" . todos . "\<Esc>"
endfunction

function! DeltosBranch()
  " reply to a note but then start a new thread
  call DeltosOpenReply()

  " no need to save cursor since this is a new note

  " now replace the thread id with the current id
  let tline = search('^thread:', 'c')
  let id = DeltosGetId()
  call setline(tline, 'thread: ' . id)
endfunction

augroup deltos
    autocmd!
    " Handle dir
    au VimEnter $DELTOS_HOME/by-id/*/deltos sil! au! FileExplorer *
    au BufEnter,BufRead $DELTOS_HOME/by-id/* :call DeltosOpen()
    au BufEnter,BufRead $DELTOS_HOME/by-id/* cd %:p:h
    "au BufRead $DELTOS_HOME/by-id/* :call DeltosShowBacklinks()
    " normal mode
    au FileType deltos nnoremap <buffer> <CR> :call FollowDeltosLink()<CR>
    " keep default behavior in quickfix
    au BufReadPost quickfix nnoremap <buffer> <CR> <CR>
    au FileType deltos nnoremap <leader>nd :call DeltosOpenNewNote()<CR>
    au FileType deltos nnoremap <leader>dr :call DeltosOpenReply()<CR>
    au FileType deltos nnoremap <leader>br :call DeltosBranch()<CR>
    au FileType deltos nnoremap <leader>id :call DeltosYankId()<CR>
    au FileType deltos nnoremap <leader>nl :call DeltosNewLink()<CR>
    au FileType deltos nnoremap <leader>ni :call DeltosLineToNewEntry()<CR>
    " threadgrep
    au FileType deltos nnoremap <leader>tg :call DeltosThreadSearch()<CR>
    " thread navigation
    au FileType deltos nnoremap <leader>l :call DeltosOpenThreadNext()<CR>
    au FileType deltos nnoremap <leader>h :call DeltosOpenThreadPrev()<CR>
    au FileType deltos nnoremap <leader>H :call DeltosOpenThreadFirst()<CR>
    au FileType deltos nnoremap <leader>L :call DeltosOpenThreadLatest(v:false)<CR>
    au FileType deltos nnoremap <leader>k :call DeltosGoToProject()<CR>
    " todos
    au FileType deltos nnoremap <leader>ct :call CopyTodo()<CR>
    " backlinks
    au FileType deltos silent nnoremap <leader>bl :call DeltosShowBacklinks()<CR>

    " visual
    au FileType deltos vnoremap <leader>nl :call DeltosNewLinkFromVisualSelection()<CR>
    " not interactive
    "au FileType deltos set conceallevel=2 concealcursor=i " Uses conceal settings

    " on saving
    au BufWritePost deltos silent exec '!deltos db-update ' . DeltosGetId()
    au BufWritePost deltos silent call DeltosNavigationSummary()
augroup END



let g:deltos_search_opts = '--bind ctrl-s:toggle-sort --preview "bat -fp -m deltos:Markdown --style plain $DELTOS_HOME/by-id/{4}/deltos" --preview-window down,border-horizontal --delimiter "\t"'
nnoremap <silent> <leader>ds :call fzf#run(fzf#wrap({'source': 'deltos tsv', 'options': g:deltos_search_opts, 'sink': function('DeltosOpenFromFzf')}))<cr>
let g:deltos_fts_opts = '+s -e --with-nth 3 --preview "bat -fp -m deltos:Markdown --style plain {1} --highlight-line {2}" --preview-window +{2}-5,down,border-horizontal --delimiter "\t"'
nnoremap <silent> <leader>fs :call fzf#run(fzf#wrap({'source': 'deltos deft', 'options': g:deltos_fts_opts, 'sink': function('DeltosOpenFromFts')}))<cr>
nnoremap <silent> <leader>nn :call DeltosFzfNavigate()<cr>
nnoremap <silent> <leader>il :call fzf#run(fzf#wrap({'source': 'deltos tsv', 'options': g:deltos_search_opts, 'sink': function('DeltosInsertLinkFromFzf')}))<cr>
nnoremap <silent> <leader>sP :call fzf#run(fzf#wrap({'source': 'deltos tsv', 'options': g:deltos_search_opts, 'sink': function('DeltosSetParentFromFzf')}))<cr>
nnoremap <silent> <leader>sp :call fzf#run(fzf#wrap({'source': 'deltos tsv', 'options': g:deltos_search_opts, 'sink': function('DeltosSetProjectFromFzf')}))<cr>
nnoremap <silent> <leader>do :call fzf#run(fzf#wrap({'source': DeltosGetBuffers(), 'sink': function('DeltosOpenFromFzf')}))<cr>

" custom text object
" do not make this dl - it makes dd slow
" ll is also not ok because it interferes with movement
" il - "interior of link"
vnoremap il :<C-U>silent! normal! T(vt/<CR>
omap il :normal vil<CR>
