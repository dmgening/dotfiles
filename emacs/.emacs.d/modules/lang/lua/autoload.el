;;; lang/lua/autoload.el -*- lexical-binding: t; -*-

;;;###autoload
(defun +lua/repl ()
  "Open Lua REPL."
  (interactive)
  (lua-start-process "lua" "lua")
  (pop-to-buffer lua-process-buffer))

;;;###autoload
(defun +lua/run-love-game ()
  "Run the current project with Love2D."
  (interactive)
  (async-shell-command
   (format "%s %s"
           (or (executable-find "love")
               (if IS-MAC "open -a love.app"))
           (shell-quote-argument (doom-project-root)))))

