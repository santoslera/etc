function! EnsureDirectory(path)
    let Path = expand(a:path)
    if !isdirectory(Path)
        return mkdir(Path, 'p')
    endif
endfunction
command! -nargs=+ -complete=file EnsureDirectory call EnsureDirectory(<args>)

function! IsDirectory(path)
    return isdirectory(expand(a:path))
endfunction

function! DirName(path)
    return fnamemodify(expand(a:path), ':h')
endfunction

function! BaseName(path)
    return fnamemodify(expand(a:path), ':t')
endfunction

function! FilePath(...)
    return join(a:000, '/')
endfunction

function! MarkFileSourced(path)
    let VariableName = LoadedName(a:path)
    execute 'let ' . VariableName . ' = 1'
endfunction

function! LoadedName(path)
    return 'g:loaded_' . substitute(expand(a:path), '[^a-zA-Z0-9_]', '_', 'g')
endfunction

function! IsFileAlreadySourced(path)
    return exists(LoadedName(a:path))
endfunction

" Source a file if it exists. Avoids reloading an already-loaded file.
function! Source(path)

    if IsFileAlreadySourced(a:path)
        return
    endif

    if filereadable(expand(a:path))
        call MarkFileSourced(a:path)
        execute join(['source', fnameescape(expand(a:path))], ' ')
    endif

endfunction
command! -nargs=+ -complete=file Source call Source(<args>)

" Lazily source a file.
function! LazySource(path)
    execute "Defer :call Source('" . a:path . "')"
endfunction
command! -nargs=+ -complete=file LazySource call LazySource(<args>)

" Utility function to allow the definition of a 'Define' command. The command
" is passed in as-is, and is expected in the form:
"
"     <name> = <value>
"
" If no variable of the name <name> exists, then the command is executed. This
" can be used to define variables that have not yet been defined, e.g.
"
"     Define g:foo = 1  " defines `g:foo` as 1
"     let g:bar = 2     " `g:bar` is 2
"     Define g:bar = 3  " no change as `g:bar` is already defined
"
function! Define(command)
    let l:index = stridx(a:command, ' ')
    let l:name = strpart(a:command, 0, l:index)
    if !exists(l:name)
        execute join(['let', a:command], ' ')
    endif
endfunction
command! -nargs=+ -complete=var Define call Define(<q-args>)

" Select a colorscheme. The first discovered colorscheme is used. Useful
" for when I forget to install Tomorrow Night Bright but want a nice fallback.
function! ColorScheme(...)
    for item in a:000
        if !empty(globpath(&runtimepath, FilePath('colors', item . '.vim')))
            execute join(['colorscheme', item], ' ')
            break
        endif
    endfor
endfunction
command! -nargs=+ ColorScheme call ColorScheme(<f-args>)

" Execute a command in a directory.
function! InDir(directory, command)
    let l:directory = $PWD
    execute 'cd ' . a:directory
    execute a:command
    execute 'cd ' . l:directory
endfunction

function! BackQuoted(string)
    return '`' . a:string . '`'
endfunction

function! SingleQuoted(string)
    return "'" . a:string . "'"
endfunction

function! DoubleQuoted(string)
    return '"' . a:string . '"'
endfunction

function! DoubleQuotedEscaped(string)
    return '"' . substitute(a:string, '"', '\"', 'g') . '"'
endfunction

" Enter normal mode. This is a stupid hack because I couldn't find an
" ex-command to enter normal mode. This may be because I am stupid.
function! EnterNormalMode()
    if mode() !=# 'n'
        call feedkeys("\<Esc>")
    endif
endfunction

" Put the contents of a variable at the cursor position.
function! Put(expr)
    silent execute ":normal! i\<C-R>=" . a:expr . "\<CR>\<Esc>"
endfunction
command! -nargs=+ -complete=var Put call Put(<q-args>)

" Get the (possibly multibyte) character at the cursor
" position.
function! GetCharacterAtCursor()
    let result = matchstr(getline('.'), '\%' . col('.') . 'c.')
    return result
endfunction

function! StrRep(string, times)

    let result = ''

    for i in range(a:times)
        let result .= a:string	
    endfor

    return result

endfunction

function! InsertNewline()
    execute ":normal! i\<CR>"
endfunction

function! GetIndent(string)
    return matchstr(a:string, '^\s*')
endfunction

function! GetCurrentLineIndent()
    return matchstr(getline('.'), '^\s*')
endfunction

command! -nargs=* Echo redraw | echomsg <args>

" Hide this function definition just so that if we try to
" reload this file we don't bump into errors due to an
" attempt to redefine while calling it.
if !exists('g:ReloadDefined')
    let g:ReloadDefined = 1
    function! Reload()
        source %
    endfunction
endif

function! IsWindows()
    for Field in ['win16', 'win32', 'win64']
        if has(Field)
            return 1
        endif
    endfor
    return 0
endfunction

function! IsMacintosh()
    return has('mac') || has('macunix')
endfunction

function! IsUnix()
    return has('unix')
endfunction

function! NVMap(expr)
    execute 'nmap ' . a:expr
    execute 'vmap ' . a:expr
endfunction
command! -nargs=* NVMap call NVMap(<q-args>)

function! NVNoRemap(expr)
    execute 'nnoremap ' . a:expr
    execute 'vnoremap ' . a:expr
endfunction
command! -nargs=* NVNoRemap call NVNoRemap(<q-args>)

function! Download(URL, Destination)

    call EnsureDirectory(DirName(expand(a:Destination)))
    let URL         = DoubleQuotedEscaped(expand(a:URL))
    let Destination = DoubleQuotedEscaped(expand(a:Destination))

    if IsWindows()
        let Command =
        \ [
        \   '!bitsadmin',
        \   '/transfer vimdownload',
        \   URL,
        \   Destination,
        \ ]
        execute join(Command, ' ')
    elseif executable('curl')
        execute join(['!curl -L -f -C -', URL, '-o', Destination], ' ')
    elseif executable('wget')
        execute join(['!wget -c', URL, '-O', Destination], ' ')
    endif

endfunction

" Don't indent namespace and template
function! CppNoNamespaceAndTemplateIndent()
    let l:cline_num = line('.')
    let l:cline = getline(l:cline_num)
    let l:pline_num = prevnonblank(l:cline_num - 1)
    let l:pline = getline(l:pline_num)
    while l:pline =~# '\(^\s*{\s*\|^\s*//\|^\s*/\*\|\*/\s*$\)'
        let l:pline_num = prevnonblank(l:pline_num - 1)
        let l:pline = getline(l:pline_num)
    endwhile
    let l:retv = cindent('.')
    let l:pindent = indent(l:pline_num)
    if l:pline =~# '^\s*template\s*\s*$'
        let l:retv = l:pindent
    elseif l:pline =~# '\s*typename\s*.*,\s*$'
        let l:retv = l:pindent
    elseif l:cline =~# '^\s*>\s*$'
        let l:retv = l:pindent - &shiftwidth
    elseif l:pline =~# '\s*typename\s*.*>\s*$'
        let l:retv = l:pindent - &shiftwidth
    elseif l:pline =~# '^\s*namespace.*'
        let l:retv = 0
    endif
    return l:retv
endfunction

" Make tab expand snippets in HTML.
function! HtmlTab()
    if exists('g:loaded_emmet_vim') && emmet#isExpandable()
        return "\<Plug>(emmet-expand-abbr)"
    endif
    return "\<Tab>"
endfunction

" Restore cursor position
function! RestoreCursorPosition()
    if line("'\"") <= line('$')
        silent! normal! g`"
        return 1
    endif
endfunction

" Update the file type if it's changed
function! MaybeSetFileType(Filetype)
    if a:Filetype !=# &filetype
        execute 'set filetype=' . a:Filetype
    endif
endfunction

" Set the file type based on the shebang (if any)
function! UpdateFileType()

    let Line = getline(1)
    if Line !~? '^#!' || len(Line) > 100
        return 0
    endif

    let EditorDictionary =
    \ {
    \   'sh'    : ['bash', 'sh', 'zsh', 'fish'],
    \   'r'     : ['r', 'rscript'],
    \   'python': ['python'],
    \ }

    let Prefixes =
    \ [
    \   '\v#!/usr/bin/env ',
    \   '\v#!/usr/bin/',
    \   '\v#!/bin/',
    \ ]

    for Key in keys(EditorDictionary)
        let Val = '(' . join(EditorDictionary[Key], '|') . ')'
        for Prefix in Prefixes
            if Line =~? Prefix . Val
                call MaybeSetFileType(Key)
                return 1
            endif
        endfor
    endfor

    return 0

endfunction

function! UseTabIndent()

endfunction
command! -range=% -nargs=0 UseSpaceIndent execute '<line1>,<line2>s#^\t\+#\=repeat(" ", len(submatch(0))*' . &ts . ')'
command! -range=% -nargs=0 UseTabIndent execute '<line1>,<line2>s#^\( \{' . &ts . '\}\)\+#\=repeat("\t", len(submatch(0))/' . &ts . ')'

function! LoadIf(condition, ...)
    let dots = get(a:000, 0, {})
    return a:condition
    \ ? dots
    \ : extend(dots, {'on': [], 'for': []})
endfunction

function! ProjectRoot()
    let Directory = expand(getcwd())
    let Anchors = ['.git', '.projectile', '.editorconfig']

    while Directory !=# '/'
        for Anchor in Anchors
            if !empty(glob(FilePath(Directory, Anchor)))
                return Directory
            endif
        endfor
        let Directory = DirName(Directory)
    endwhile

    return getcwd()
endfunction
command! ProjectFiles execute 'Files' ProjectRoot()

function! SyntaxItem()
    return synIDattr(synID(line('.'), col('.'), 1), 'name')
endfunction

function! GenerateCompileDatabase(force)

    let Root = ProjectRoot()
    let OWD = getcwd()

    " Bail if compile_commands.json already exists
    let CompileCommandsJSON = join([Root, 'compile_commands.json'], '/')
    if !a:force && filereadable(CompileCommandsJSON)
        return
    endif

    let CMakeLists = join([Root, 'CMakeLists.txt'], '/')
    if filereadable(CMakeLists)
        call GenerateCompileDatabaseCMake()
    endif

    execute join(['cd', fnameescape(OWD)], ' ')

endfunction

function! GenerateCompileDatabaseCMake()

    let Root = ProjectRoot()
    let OWD = getcwd()

    " Move to temporary directory
    let TempDir = tempname()
    call mkdir(TempDir, 'p')
    execute join(['cd', fnameescape(TempDir)], ' ')

    " Invoke CMake to generate compile commands
    call system(join(['cmake', '-DCMAKE_EXPORT_COMPILE_COMMANDS=Yes', shellescape(Root)], ' '))

    " Replace the current path with the project path
    let SedCommand = join(['s', getcwd(), Root, 'g'], '|')
    let Source = fnamemodify('compile_commands.json', ':p')
    let Target = FilePath(Root, 'compile_commands.json')
    call system(join(['sed', "'" . SedCommand . "'", shellescape(Source), '>', shellescape(Target)]))

    " Go home
    execute join(['cd', fnameescape(OWD)], ' ')

endfunction

function! UpdateChangeLog()

    " list holding lines to be inserted
    let Lines = []

    " construct header
    let Date = strftime('%Y-%m-%d')
    let Name = systemlist('git config user.name')[0]
    let Email = systemlist('git config user.email')[0]
    let Header = join([Date, Name, '<' . Email . '>'], '  ')
    call add(Lines, Header)

    " add blank line
    call add(Lines, '')

    " add changes
    let Entries = systemlist('git status --porcelain')
    for idx in range(0, len(Entries) - 1)
        call add(Lines, "\t* " . Entries[idx][3:] . ': ')
    endfor

    " add trailing line
    if len(Entries) > 0
        call add(Lines, '')
    endif

    " open changelog
    let Root = ProjectRoot()
    let ChangeLogPath = FilePath(Root, 'ChangeLog')
    execute join(['edit', fnameescape(ChangeLogPath)], ' ')

    " write to the buffer
    call append(0, Lines)

    " move cursor to first line requiring edit
    call setpos('.', [0, 3, len(Lines[2]) + 1, 0])

    " enter insert mode
    startinsert

endfunction
command! -nargs=? UpdateChangeLog call UpdateChangeLog(<args>)

function! ProfileStart(...)

    let Path = get(a:, 1, 'profile.log')
    execute join(['profile', 'start', expand(Path)], ' ')

    profile func *
    profile file *

    echomsg 'Writing profile to "' . Path . '".'

endfunction
command! -nargs=? ProfileStart call ProfileStart()

function! ProfileStop()

    profile stop

endfunction
command! -nargs=? ProfileStop call ProfileStop()

