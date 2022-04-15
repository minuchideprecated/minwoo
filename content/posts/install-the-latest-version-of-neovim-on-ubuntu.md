---
author: minwoo.kim
categories:
  - vim
date: 2022-04-15T03:43:40Z
tags:
  - editor
  - vim
  - nvim
  - neovim
title: 'Ubuntu에서 Neovim (nvim) 최신 버전 설치하기'
cover:
  image: '/assets/img/coding.jpg'
  alt: 'Coding'
  relative: false
---

Ubuntu 20.04에서 Neovim 최신 버전 설치하는 방법은 아래와 같습니다.

```bash
# 만약 Neovim이 이미 설치되어 있다면 제거한다.
sudo apt-get remove neovim -y

sudo add-apt-repository ppa:neovim-ppa/stable 
sudo apt-get update -y
sudo apt-get install neovim -y
```

감사합니다.
