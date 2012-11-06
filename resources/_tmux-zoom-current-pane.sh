#! /usr/bin/env sh

maximized_pane_id_delimiter=@
maximized_pane_prefix=_TMUX_MAXIMIZED_PANE_$maximized_pane_id_delimiter

current_pane_id=`tmux list-panes -F "#{pane_active} #{pane_id}" | sed -n -e '/^1 /s/^1 %\([0-9]*\)$/\1/gp'`
current_window_name_starts_with=$(tmux display -p "#${#maximized_pane_prefix}W")

current_window_is_a_maximized_pane=''
if [ $current_window_name_starts_with = $maximized_pane_prefix ]; then
  current_window_is_a_maximized_pane=true
fi

if [ $current_window_is_a_maximized_pane ]; then
  current_window_name=$(tmux display -p '#W')
  maximized_pane_id=`echo $current_window_name | rev | cut -f 1 -d "$maximized_pane_id_delimiter" | rev`
  tmux select-window -t "%$maximized_pane_id"
  tmux select-pane   -t "%$maximized_pane_id"
  tmux swap-pane     -s "%$current_pane_id"
  tmux kill-window   -t "%$maximized_pane_id"
else
  tmux new-window
  tmux clock-mode
  new_pane_id=`tmux list-panes -F '#{pane_active} #{pane_id}' | sed -n -e '/^1 /s/^1 %\([0-9]*\)$/\1/gp'`
  tmux rename-window "$maximized_pane_prefix$new_pane_id"
  tmux swap-pane -s "%$current_pane_id"
fi
