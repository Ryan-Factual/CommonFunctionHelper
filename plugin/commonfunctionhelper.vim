if !has('python')
  finish
endif

let g:sch_scarecrow_rules_path =
  \ get( g:, 'sch_scarecrow_rules_path', '~/code/scarecrow-rules' )

let s:script_folder_path = escape( expand( '<sfile>:p:h' ), '\' )
let s:python_folder_path = s:script_folder_path . '/../python/'
let g:list_folder_path = s:script_folder_path . '/../list/functions'

set dictionary+=~/.vim/functions
set complete-=k complete+=k
function! Search(...)
  if a:0 == 0
    call SearchCurrentFunction()
  else
    call call("SearchTokens", a:000)
  endif
endfunction

function! SearchCurrentFunction()
  let full_path = escape( expand( '%:p' ), '\' )
  if !IsScarecrowRulesPath(full_path)
    return
  endif

  let name = expand("<cword>")
  execute "!" . s:python_folder_path . "shell" . " -k " name
endfunction

function! SearchTokens(...)
  let full_path = escape( expand( '%:p' ), '\' )
  if !IsScarecrowRulesPath(full_path)
    return
  endif
  
  execute "!" . s:python_folder_path . "shell" . " -s " join(a:000, ' ')
endfunction

function! Test(...)
  let full_path = escape( expand( '%:p:h' ), '\' )
  if !IsScarecrowRulesPath(full_path)
    return
  endif
  
  let file = split(expand('%:r'), '/')[-1]
  let file_path = join([split(full_path, '/')[-1], file], '.')
  let working_dir = getcwd()
  execute 'cd' g:sch_scarecrow_rules_path
  if a:0 == 0
    execute "!" . "scarecrow test " . file_path
  else
    execute "!" . "scarecrow test " . file_path . '\#' . a:1
  endif
  execute 'cd' l:working_dir

endfunction

function! IsScarecrowRulesPath(path)
  return a:path =~ "/scarecrow-rules/"
endfunction

function! MyCompleteFunction( findstart, base )
  if a:findstart
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '[A-Za-z_]'
        let start -= 1
    endwhile
    return start
  else
    silent call DictGrep( a:base, '~/.vim/functions' )
    let matches = []
    for thismatch in getqflist()
        call add(matches, thismatch.text)
    endfor
    return map(matches, 's:makeSnipmateItem(v:val)')
  endif
endfunction

function! DictGrep( leader, file )
    try
        exe "vimgrep /^" . a:leader . ".*/j " . a:file
    catch /.*/
        echo "no matches"
    endtry
endfunction

function! s:makeSnipmateItem(value)
  let pair = split(a:value, "\t")
  return {
        \ 'word': pair[0],
        \ 'menu': pair[1],
        \ }
endfunction
setlocal completefunc=MyCompleteFunction
command! -nargs=* Search :call Search(<f-args>)
command! -nargs=? Test :call Test(<f-args>)
