" Vundle
set nocompatible              " required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'
" Folding
Plugin 'tmhedberg/SimpylFold'
" db interface
Plugin 'dbext.vim'
" Indents for python
Plugin 'vim-scripts/indentpython.vim'
" Vim LaTeX support
Plugin 'lervag/vimtex'
" Vim Go support
Plugin 'fatih/vim-go'
" Colors
Plugin 'jnurmine/Zenburn'
Plugin 'altercation/vim-colors-solarized'
" Sessions
Plugin 'tpope/vim-obsession'
" Planutml previews on save
" TODO: modify that plugin so it can support class-like declarations.
" Plugin 'scrooloose/vim-slumlord'
Plugin 'tyru/open-browser.vim'
Plugin 'weirongxu/plantuml-previewer.vim'
" Planuml syntax
Plugin 'aklt/plantuml-syntax'
" Asynchrounous checkers.
Plugin 'w0rp/ale'
" Pretty status bar 
Plugin 'vim-airline/vim-airline'
" Autocompleting
Plugin 'Valloric/YouCompleteMe'
" Git commit support
Plugin 'jreybert/vimagit'
" Beautify on :Au.
Plugin 'Chiel92/vim-autoformat'
" File tree.
Plugin 'scrooloose/nerdtree'
" Git stuff for file tree.
Plugin 'Xuyuanp/nerdtree-git-plugin'
" Julia support.
Plugin 'JuliaEditorSupport/julia-vim'
" Markdown
Plugin 'godlygeek/tabular'
Plugin 'plasticboy/vim-markdown'
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required

" " End of Vundle
