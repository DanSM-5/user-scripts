[N]VIM Tricks
=============

# Select non-matched lines

```vimscript
" In command mode you can reverse a search with \@!
" E.g match all lines that do not start with 'https:'
:%s/^\(\(https:\)\@!\).*/
```

# Remove carriage return characters

```vimscript
" To remove characters that look like ^M which is a carriage return,
" you can use a regex with \r to catch it
:%s/\r$//g
```
