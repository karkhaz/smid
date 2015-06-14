" Vim syntax file
" Language: smid files for black-box testing
" Maintainer: Kareem Khazem
" Latest Revision: 24 March 2015

if exists("b:current_syntax")
  finish
endif

syn match fsaComment "\v#.+$" contained
syn match fsaTopComment "\v#.+$"
hi link   fsaComment Comment
hi link   fsaTopComment Comment

syn match fsaAction "\v(keys|text|line|click|clik|scroll|scrl|move|move-rel|movr|prob)"
hi link   fsaAction   Type

syn match fsaKeyword "\v(all-except|all|stay|pre|post|initial|final|region|\=)"
hi link   fsaKeyword   Identifier

syn region fsaActionBlock start="--" end="-->" contains=fsaAction,fsaString,fsaList,fsaCoords,fsaComment,fsaProb
hi link fsaActionBlock Keyword

syn region fsaString start='"' end='"' contained
syn region fsaList   start='\[' end='\]' contained
syn region fsaCoords start='(' end=')' contained
syn match  fsaProb   "\v(high|med|low)" contained
hi link    fsaString String
hi link    fsaList   String
hi link    fsaCoords String
hi link    fsaProb   String


syntax include @Bash syntax/sh.vim
syntax region bashSnip matchgroup=Snip start="{" end="}" contains=@Bash
hi link Snip SpecialComment
