" Vim syntax file
" Language: FSA files for black-box testing
" Maintainer: Kareem Khazem
" Latest Revision: 24 March 2015

if exists("b:current_syntax")
  finish
endif

syn match fsaComment "\v^#.+$"
hi link   fsaComment Comment

syn match fsaAction "\v(keys|verb|line)"
hi link   fsaAction   Type

syn match fsaKeyword "\v(all-except|all|stay|pre|post|initial|final)"
hi link   fsaKeyword   Identifier

syn region fsaActionBlock start="--" end="-->" contains=fsaAction,fsaString,fsaList
hi link fsaActionBlock Keyword

syn region fsaString start='"' end='"' contained
syn region fsaList   start='\[' end='\]' contained
hi link    fsaString String
hi link    fsaList String


syntax include @Bash syntax/sh.vim
syntax region bashSnip matchgroup=Snip start="{" end="}" contains=@Bash
hi link Snip SpecialComment
