;;; init.el -*- lexical-binding: t; -*-

(doom! :feature
       eval
       (evil +everywhere)
       file-templates
       (lookup +devdocs +docsets)
       snippets
       spellcheck
       (syntax-checker +childframe)
       workspaces

       :completion
       (company +auto)
       (ivy +fuzzy +posframe)

       :ui
       doom
       doom-dashboard
       ;; doom-modeline
       (modeline +evil)
       doom-quit
       evil-goggles
       hl-todo
       nav-flash
       neotree
       (popup +all +defaults)
       ;; (pretty-code +fira)
       vc-gutter
       vi-tilde-fringe
       window-select

       :editor
       rotate-text

       :emacs
       dired
       ediff
       electric
       eshell
       imenu
       term
       vc

       :tools
       editorconfig
       macos
       make
       magit
       docker

       :lang
       data
       emacs-lisp
       javascript
       lua
       markdown
       (org +attach +babel +capture +export +present)
       plantuml
       python
       sh
       web

       :config
       (default +bindings +snippets +evil-commands))
