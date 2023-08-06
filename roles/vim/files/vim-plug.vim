source ~/.config/nvim/plug.vim
call plug#begin('~/.config/nvim/plugged')
" Folding
Plug 'tmhedberg/SimpylFold'
" db interface
" Plug 'dbext.vim'
" Indents for python
Plug 'vim-scripts/indentpython.vim'
" Vim LaTeX support
Plug 'lervag/vimtex'
" Colors
Plug 'jnurmine/Zenburn'
" Sessions
Plug 'tpope/vim-obsession'
" Planutml previews on save
" TODO: modify that plugin so it can support class-like declarations.
" Plug 'scrooloose/vim-slumlord'
Plug 'tyru/open-browser.vim'
Plug 'weirongxu/plantuml-previewer.vim'
" Planuml syntax
Plug 'aklt/plantuml-syntax'
" Asynchrounous checkers.
Plug 'w0rp/ale'
" Pretty status bar
Plug 'vim-airline/vim-airline'
" Beautify on :Au.
Plug 'Chiel92/vim-autoformat'
" File tree.
Plug 'scrooloose/nerdtree'
" Git stuff for file tree.
Plug 'Xuyuanp/nerdtree-git-plugin'
" Julia support.
" Plug 'JuliaEditorSupport/julia-vim'
" Markdown
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'
" Coloring/Indendation for many languages
Plug 'sheerun/vim-polyglot'
" All of your Plugs must be added before the following line
call plug#end()

" Lock versions
source ~/.config/nvim/snapshot.vim
