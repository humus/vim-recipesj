
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
