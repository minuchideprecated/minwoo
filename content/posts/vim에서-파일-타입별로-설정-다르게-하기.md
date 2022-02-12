---
author: minwoo.kim
categories:
  - vim
date: 2021-12-26T23:38:40Z
tags:
  - editor
  - vim
  - nvim
  - neovim
title: 'vim에서 파일 타입별로 설정 다르게 하기 (neovim 포함)'
cover:
  image: '/assets/img/coding.jpg'
  alt: 'Coding'
  relative: false
---

사내 코드 규칙 등 회사 또는 개인 프로젝트 할 시에 탭 사이즈를 다르게 하는 경우가 많습니다.  
요즘에는 웹은 스페이스 2칸, 서버는 스페이스 4칸으로 하는 경우가 많은 것으로 보입니다.  
이에 따라 vim에서도 filetype에 따라 설정하는 법을 공유합니다.

## autocmd

autocmd를 사용하여 하는 경우에는 vim 설정 파일을 열고 아래와 같이 추가합니다.

### `~/.vimrc`

neovim의 경우 `~/.config/nvim/init.vim`

```vimscript
if has("autocmd")
  filetype on
  autocmd FileType python setlocal ts=4 sts=4 sw=4 et
  autocmd FileType javascriptreact setlocal ts=2 sts=2 sw=2 et nu
  autocmd FileType typescriptreact setlocal ts=2 sts=2 sw=2 et nu
endif
```

## ftplugin

ftplugin은 여러 언어를 다루고, 설정 파일이 복잡한 경우에 유리합니다.

### `~/.vim/after/ftplugin/typescriptreact.vim`

neovim의 경우 `~/.config/nvim/ftplugin/typescriptreact.vim`

```vimscript
setlocal ts=2 sts=2 sw=2 et nu
```
