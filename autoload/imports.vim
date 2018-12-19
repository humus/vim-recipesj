
function! imports#import_data() abort "{{{
    let l:current_line = 1
    let l:imports = []
    while imports#scan_file_line(l:current_line)
        if getline(l:current_line) =~ '^import'
            let l:import = {'line': l:current_line}
            let l:import['class'] = matchstr(getline(l:current_line), '\v^import\s+\zs\S[^;]+\ze;')
            call add(l:imports, l:import)
        endif
        let l:current_line += 1
    endwhile

    echo l:imports[0]['class']

    return l:imports
endfunction "}}}

function! imports#scan_file_line(line) abort "{{{
    if getline(a:line) =~ '\v(^\@|public class)'
        return 0
    endif
    if getline(a:line) > line('$')
        return 0
    endif
    if a:line > 1000
        return 0
    endif
    return 1
endfunction "}}}

function! imports#find_import_desc(imports_list, next_import) abort "{{{
    let imports = map(copy(a:imports_list), 'extend(v:val, {"score": 0})')

    for import_index in range(len(a:imports_list))
        let current = imports[import_index]
        if current['class'] < a:next_import
            let current['score'] += import_index
            if import_index + 1 < len(imports) && imports[import_index+1]['class'] > a:next_import
                let current['score'] += len(imports)
            endif
        endif
    endfor

    call sort(imports, "imports#sort_by_score")
    let linebefore = imports[0]['line']
    let empty_line = imports#needs_empty_line(imports, linebefore, a:next_import)

    return {'linebefore': linebefore,
                \ 'appendemptyline': empty_line,
                \ 'classtoinsert': a:next_import}
endfunction "}}}

function! imports#sort_by_score(one, another) abort "{{{
    return a:another['score'] - a:one['score']
endfunction "}}}

function! imports#getblocks() abort "{{{
    let class_dec = searchpos('^public class', 'bwnc')[0]
    let pack_dec = searchpos('^package', 'bnc')[0]

    let blocks = []

    let linenum = pack_dec + 1
    let block_index = 0
    while linenum < class_dec
        while getline(linenum) !~ '\v^import' && linenum < class_dec
            let linenum += 1
        endwhile
        call add(blocks, '')
        while getline(linenum) =~ '\v^import' && linenum < class_dec
            let blocks[block_index] .= matchstr(getline(linenum), '\v^import [^;]+;') . '#'
            let linenum += 1
        endwhile
        let blocks[block_index]=blocks[block_index][0:-1]
        let block_index += 1
    endwhile

    return blocks

endfunction "}}}

function! imports#needs_empty_line(imports, linebefore, next_import) "{{{
    let import_desc = filter(copy(a:imports), "v:val['line'] == " . a:linebefore)[0]
    let components = split(a:next_import, '\.', 0)
    let components_2 = split(import_desc['class'], '\.', 0)
    
    if components[0] != components_2[0]
        return 1
    endif
    
    if components[1] != components_2[1]
        return 1
    endif

    return 0
endfunction "}}}

fun! imports#insert_import_context(import_context) abort "{{{
    let import_line = 'import ' . a:import_context['classtoinsert'] . ';'
    let offset = 0
    if a:import_context['appendemptyline']
        let offset = 1
        call append(a:import_context['linebefore'], '')
    endif
    call append(a:import_context['linebefore']+offset, import_line)
endfunction "}}}
