fun! Clear_javafilename(file_key, file_path) abort "{{{
  return substitute(substitute(
        \ substitute(a:file_path, '\v^.+(main|test)\/java\/', '', ''),
        \ '\/', '.', 'g'), '\v\.java$', '', '')
endfunction "}}}

fun! Load_known_imports() abort "{{{
  return readfile(expand('~/.vim/known_imports'))
endfunction "}}}

fun! Rg_list_imports() abort "{{{
  let rg_command = "rg --no-heading --no-line-number --no-filename -o '^import[[:space:]][^;]+' | sort -u"

  let rg_java_files = systemlist('rg --files -t java | awk ' . "'" . '!/properties/' . "'")
  let local_tree_imports = map(rg_java_files, function('Clear_javafilename'))

  let local_imports = systemlist(rg_command) + local_tree_imports + Load_known_imports() 
  return uniq(sort(map(local_imports, "Clean_import(v:val)")))
endfunction "}}}

fun! Clean_import(import) "{{{
  return substitute(a:import, '\v^import[[:space:]]+|;.*$', '', 'g')
endfunction "}}}

fun! Insert_imports(...) "{{{
  for x in a:000
    call imports#insert_import(x)
  endfor
endfunction "}}}

function! s:insert_imports(...)
  return fzf#run({
        \ 'source': Rg_list_imports(),
        \ 'sink': function('Insert_imports'),
        \ 'options': '--multi --reverse'})
endfunction

nnoremap  :call <SID>insert_imports()<CR>

