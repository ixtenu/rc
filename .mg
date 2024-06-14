audible-bell 0
set-fill-column 80
column-number-mode 1
auto-execute *.txt auto-fill-mode
auto-execute *.md auto-fill-mode
auto-execute *.c c-mode
auto-execute *.h c-mode
make-backup-files 0
# M-a (borrowed from nano) as alternative set-mark-command since its default
# C-SPC key binding is my tmux prefix key.
global-set-key "\^[a" set-mark-command
