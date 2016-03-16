# deltos.vim

This is a vim plugin for use with [deltos](http://github.com/polm/deltos). It
comes with syntax highlighting and keybindings. For full enjoyment be sure to
install [Unite](http://github.com/Shougo/Unite.vim).

Local keybindings when in `$DELTOS_HOME/by-id`: 

| key | action |
| --- | --- |
| <leader>nd | new note (**N**ew **D**eltos) |
| <leader>id | yank the current note's ID |
| <leader>nl | make a link to a new note (wiki style) |
| (visual) <leader>nl | make the words in the visual selection into a link |
| Enter | follow link `.(link here//<id>)` |

Global keybindings:

| key | action |
| --- | --- |
| <leader>da | Open all deltos notes in Unite |
| <leader>do | Show all open deltos notes in Unite |

NeoBundle or similar is strongly recommended.

WTFPL / Kopyleft All Rites Reversed / do as you please.

-POLM
