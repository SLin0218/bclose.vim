" Delete buffer while keeping window layout (don't close buffer's windows).
" Version 2008-11-18 from http://vim.wikia.com/wiki/VimTip165
" Licensed under CC-BY-SA
if v:version < 700 || exists('loaded_bclose') || &cp
  finish
endif
let loaded_bclose = 1
if !exists('bclose_multiple')
  let bclose_multiple = 1
endif

" Display an error message.
function! s:Warn(msg)
  echohl ErrorMsg
  echomsg a:msg
  echohl NONE
endfunction

let g:buffer_name_list = ['[coc-explorer]-1']

function! s:WinExcludeBufferNameList(win_nr_list, buffer_name_list) abort
  for buffer_name in a:buffer_name_list
    let l:bufnr = bufwinnr(bufnr(buffer_name))
    call filter(a:win_nr_list, 'v:val !~ ' . l:bufnr)
  endfor
endfunction

" Command ':Bclose' executes ':bd' to delete buffer in current window.
" The window will show the alternate buffer (Ctrl-^) if it exists,
" or the previous buffer (:bp), or a blank buffer if no previous.
" Command ':Bclose!' is the same, but executes ':bd!' (discard changes).
" An optional argument can specify which buffer to close (name or number).
function! s:Bclose(bang, buffer)
  if empty(a:buffer)
    let btarget = bufnr('%')
  elseif a:buffer =~ '^\d\+$'
    let btarget = bufnr(str2nr(a:buffer))
  else
    let btarget = bufnr(a:buffer)
  endif
  if btarget < 0
    call s:Warn('No matching buffer for '.a:buffer)
    return
  endif
  " 帮助文档直接关闭
  if &filetype == 'help'
    execute 'close'
    return
  endif

  if &filetype == 'startify'
    return
  endif

  " 判断是否修改，提示不允许关闭，如果使用 ! 修饰符则强制执行
  if empty(a:bang) && getbufvar(btarget, '&modified')
    call s:Warn('No write since last change for buffer '.btarget.' (use :Bclose!)')
    return
  endif
  " Numbers of windows that view target buffer which we will delete.
  let wnums = filter(range(1, winnr('$')), 'winbufnr(v:val) == btarget')
  if !g:bclose_multiple && len(wnums) > 1
    call s:Warn('Buffer is in multiple windows (use ":let bclose_multiple=1")')
    return
  endif

  let wcurrent = winnr()

  let win_nr_list = range(1, winnr('$'))
  call s:WinExcludeBufferNameList(win_nr_list, g:buffer_name_list)
  if len(win_nr_list) > 1
    execute 'q'
    return
  endif

  for w in wnums
    " 跳转到指定窗口
    execute w.'wincmd w'
    " 获取轮换区 上一个 buf
    let prevbuf = bufnr('#')
    if prevbuf > 0 && buflisted(prevbuf) && prevbuf != w
      " 跳转到下一个buf
      buffer #
    else
      " 跳转到上一个buf
      bprevious
    endif
    if btarget == bufnr('%')
      " 列出的不是要删除目标的缓冲区的数量。
      " Numbers of listed buffers which are not the target to be deleted.
      let blisted = filter(range(1, bufnr('$')), 'buflisted(v:val) && v:val != btarget')
      " 已列出，未定位，也未显示
      " Listed, not target, and not displayed.
      let bhidden = filter(copy(blisted), 'bufwinnr(v:val) < 0')
      " 如果有的话，请选择第一个缓冲区（可能会更聪明）。
      " Take the first buffer, if any (could be more intelligent).
      let bjump = (bhidden + blisted + [-1])[0]
      if bjump > 0
        " 跳转到其他缓冲区
        execute 'buffer '.bjump
      else
        " 新建一个缓冲区
        "execute 'enew'.a:bang
        execute 'Startify'
      endif
    endif
  endfor
  " 删除指定buffer
  execute 'bdelete'.a:bang.' '.btarget
  " 关闭窗口
  execute wcurrent.'wincmd w'
endfunction
command! -bang -complete=buffer -nargs=? Bclose call <SID>Bclose('<bang>', '<args>')

if exists ("g:bclose_no_plugin_maps") &&  g:bclose_no_plugin_maps
    "do nothing
elseif exists ("g:no_plugin_maps") &&  g:no_plugin_maps
    "do nothing
else
     nnoremap <silent> <Leader>bd :Bclose<CR>
endif
