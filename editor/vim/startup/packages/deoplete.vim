Plug 'Shougo/deoplete.nvim'    , LoadIf(g:CompletionEngine ==# 'deoplete')
Plug 'roxma/nvim-yarp'         , LoadIf(g:CompletionEngine ==# 'deoplete')
Plug 'roxma/vim-hug-neovim-rpc', LoadIf(g:CompletionEngine ==# 'deoplete')
 
if !g:CompletionEngine ==# 'deoplete'
    finish
endif

if has('python3')

py3 <<EOF

has_neovim = 0
try:
    import neovim
    has_neovim = 1
except:
    pass

import vim
vim.command("let g:HasNeovimModule = %i" % has_neovim)

EOF

endif

if !g:HasNeovimModule
    !pip3 install --upgrade neovim
endif

let g:deoplete#enable_at_startup = 1

function! DeopleteInit() abort
    
    call deoplete#custom#buffer_option({
    \ 'auto_complete_delay' : 300,
    \ 'auto_refresh_delay'  : 50,
    \ 'smart_case'          : v:true,
    \ })

    call deoplete#custom#option('ignore_sources', {
    \ '_': ['buffer', 'around'],
    \ })

endfunction

augroup DeopleteInit
    autocmd!
    autocmd BufEnter * call DeopleteInit()
augroup END
