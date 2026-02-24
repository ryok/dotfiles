set encoding=utf-8
scriptencoding utf-8

set fileencoding=utf-8
set fileencodings=ucs-bom,utf-8,euc-jp,cp932
set fileformats=unix,dos,mac
set ambiwidth=double

" 表示
syntax enable
colorscheme desert
set number
set cursorline
set laststatus=2
set showcmd
set wildmenu

" 検索
set hlsearch
set incsearch
set ignorecase
set smartcase

" インデント
set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4

" 操作
set backspace=indent,eol,start
set clipboard=unnamed
set mouse=a

" バックアップを作らない
set nobackup
set noswapfile

filetype plugin indent on
