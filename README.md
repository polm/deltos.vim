# deltos.vim

This is a vim plugin for use with [deltos](http://github.com/polm/deltos). It
comes with syntax highlighting and keybindings. For full enjoyment be sure to
install [Unite](http://github.com/Shougo/Unite.vim).

Local keybindings when in `$DELTOS_HOME/by-id`: 

| key | action |
| --- | --- |
| &lt;leader&gt;nd | new note (**N**ew **D**eltos) |
| &lt;leader&gt;id | yank the current note's ID |
| &lt;leader&gt;nl | make a link to a new note (wiki style) |
| (visual) &lt;leader&gt;nl | make the words in the visual selection into a link |
| Enter | follow link `.(link here//&lt;id&gt;)` |

Global keybindings:

| key | action |
| --- | --- |
| &lt;leader&gt;da | Open all deltos notes in Unite |
| &lt;leader&gt;do | Show all open deltos notes in Unite |

NeoBundle or similar is strongly recommended.

WTFPL / Kopyleft All Rites Reversed / do as you please.

-POLM
