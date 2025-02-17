;;; init.el --- GNU Emacs initialization  -*- lexical-binding: t; -*-

;;; Code:

(defun my-emacs-version< (version) (version< emacs-version version))
(defun my-emacs-version>= (version) (not (my-emacs-version< version)))

(let ((minver "26"))
  (if (my-emacs-version< minver)
      (error "GNU Emacs v%s or later required for this init.el" minver)))

;; Disable garbage collection during initialization for faster startup.
(setq my-normal-gc-cons-threshold gc-cons-threshold)
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold my-normal-gc-cons-threshold)))

(defun my-emacs-d-path (file)
  "Return a path to FILE within the GNU Emacs directory."
  (expand-file-name file user-emacs-directory))

(defun my-add-to-multiple-hooks (function hooks)
  "Add the given function to a list of hooks."
  (mapc (lambda (hook) (add-hook hook function)) hooks))

(defun my-executables-found (exec-list)
  "Check whether a list of executables are in PATH."
  (if (null exec-list)
    t
    (if (executable-find (car exec-list))
      (my-executables-found (cdr exec-list))
      nil)))


;;;; Package Manager:

;; Bootstrap straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (my-emacs-d-path "straight/repos/straight.el/bootstrap.el"))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Use `use-package' to install packages.
(setq straight-use-package-by-default t)
(straight-use-package 'use-package)


;;;; Operating Systems:

(defconst *is-bsd* (eq system-type 'berkeley-unix))
(defconst *is-linux* (eq system-type 'gnu/linux))
(defconst *is-macos* (eq system-type 'darwin))
(defconst *is-windows* (eq system-type 'windows-nt))
(defconst *is-msdos* (eq system-type 'ms-dos))
(defconst *is-unix* (not (or *is-windows* *is-msdos*)))

(when (or *is-linux* *is-bsd*)
  ;; I typically use X window managers where focus follows the mouse.
  (setq focus-follows-mouse t))

(when *is-macos*
  ;; Fix problem where `exec-path' doesn't include the Homebrew path.
  (use-package exec-path-from-shell)
  (exec-path-from-shell-initialize))


;;;; General Settings:

(setq ring-bell-function 'ignore)

(setq custom-file null-device) ; Custom, not even once.

;; Run Emacs as a server so that emacsclient will work.
(require 'server)
(defconst *is-first-instance* (not (server-running-p)))
(when *is-first-instance* (server-start))

(save-place-mode 1) ; Remember position in files.
(recentf-mode 1) ; Remember recently edited files.
(setq recentf-max-menu-items 32) ; Default is 10.

;; Run `clean-buffer-list' at midnight.
(require 'midnight)
(midnight-delay-set 'midnight-delay 0)
(midnight-mode 1)

(global-set-key (kbd "C-c R") 'recentf-open-files)

;; Reduce buffer list clutter from dired.
(if (my-emacs-version>= "28")
    (setq dired-kill-when-opening-new-dired-buffer t))

;; Always kill the current buffer instead of prompting.
(global-set-key (kbd "C-x k") 'kill-current-buffer)

(delete-selection-mode 1) ; Typing replaces selection.

(global-auto-revert-mode 1) ; Revert externally edited files.

(put 'narrow-to-region 'disabled nil) ; Disable `narrow-to-region' warning.

(setq create-lockfiles nil) ; Live dangerously.

;; With Git, file system snapshots, and a proper backup strategy -- backup
;; files are just clutter.
(setq make-backup-files nil)

(setq large-file-warning-threshold nil) ; Open big files without prompting.

(when (my-emacs-version>= "28")
  (setq tramp-allow-unsafe-temporary-files t)) ; Open as root without prompting.

;; Disable garbage collection when minibuffer is active.
;; https://bling.github.io/blog/2016/01/18/why-are-you-changing-gc-cons-threshold/
(defun my-gc-minibuffer-setup-hook ()
  (setq gc-cons-threshold most-positive-fixnum))
(defun my-gc-minibuffer-exit-hook ()
  (setq gc-cons-threshold my-normal-gc-cons-threshold))
(add-hook 'minibuffer-setup-hook #'my-gc-minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'my-gc-minibuffer-exit-hook)

(use-package restart-emacs)

;; Force EasyPG to prompt for password within Emacs.
(setq epg-pinentry-mode 'loopback)

(defun my-add-to-path (newpath)
  "Add NEWPATH as a search path for executables, if it exists."
  (when (file-directory-p newpath)
    (let ((PATH (getenv "PATH")))
      (unless (string-match newpath PATH)
        (setenv "PATH" (concat PATH ":" newpath))))
    (add-to-list 'exec-path newpath)))

(my-add-to-path (concat (getenv "HOME") "/bin"))
(my-add-to-path (concat (getenv "HOME") "/.local/bin"))
(my-add-to-path (concat (getenv "HOME") "/go/bin"))
(my-add-to-path (concat (getenv "HOME") "/.cargo/bin"))

;; native-compilation causes warnings with some packages: by default, this opens
;; the *Warnings* window, which is annoying, so suppress it.
(if (my-emacs-version>= "28")
    (setq native-comp-async-report-warnings-errors nil))

;; In a Linux or BSD terminal...
(when (and (not (display-graphic-p)) (or *is-bsd* *is-linux*))
  ;; Start with the mouse enabled.
  (xterm-mouse-mode 1)
  ;; Make M-w send region to OS clipboard.
  (use-package clipetty
    :bind ("M-w" . clipetty-kill-ring-save)))

;; Open a URL in a web browser
(global-set-key (kbd "C-c u") #'browse-url)

;; Prefer vertical window splitting.
(setq split-height-threshold nil)

;; *scratch* starts out empty.
(setq initial-scratch-message nil)
;; *scratch* major mode defaults to lisp-interaction-mode, change it to
;; fundamental-mode.
(setq initial-major-mode 'fundamental-mode)
;; Persist *scratch* buffer across sessions.  The major mode is also persisted.
;; Skip doing this if another instance of Emacs is already open: don't want
;; multiple instances writing their scratch buffers to the same file.
(when *is-first-instance*
  (use-package persistent-scratch
    :config
    (persistent-scratch-setup-default)
    (setq persistent-scratch-autosave-interval 60)
    (persistent-scratch-autosave-mode 1)))
;; Don't allow *scratch* to be killed.  Instead, to delete everything in the
;; buffer, use C-x h C-d.
;; https://emacs.stackexchange.com/a/19256
(defun my-dont-kill-named-buffer (name)
  (if (not (equal (buffer-name) name))
      t
    (message "Not allowed to kill %s, burying instead" (buffer-name))
    (bury-buffer)
    nil))
(defun my-dont-kill-scratch () (my-dont-kill-named-buffer "*scratch*"))
(add-hook 'kill-buffer-query-functions #'my-dont-kill-scratch)


;;;; Appearance:

(setq custom-safe-themes t)

(straight-use-package
 '(almost-mono-themes :type git :host github :repo "ixtenu/almost-mono-themes"))
;;(load-theme 'almost-mono-white t)
;;(load-theme 'almost-mono-gray t)
(load-theme 'almost-mono-black t)

;; Make sure the mouse pointer can be seen when drawn atop the nearly black
;; background color.
(when (display-graphic-p)
  (set-mouse-color "white"))

;; Font customization (GUI only).
(when (display-graphic-p)
  (defun my-set-font (font)
    "Call `set-frame-font' and return t on success and nil on failure."
    (condition-case nil
        (progn (set-frame-font font t t nil) t)
      (error nil)))

  (defun my-set-fonts (font-list)
    "Call `my-set-font' on a list of fonts, in order, until success."
    (while (let ((font (pop font-list)))
             (and font (not (my-set-font font))))))

  (my-set-fonts
   (append
    '("Cascadia Code 12" "GoMono Nerd Font 12" "Go Mono 12")
    (cond
     ((or *is-linux* *is-bsd*)
      '("Hack 12" "DejaVu Sans Mono 11" "Inconsolata 12"))
     (*is-macos* '("Menlo 13"))
     (*is-windows* '("Consolas 12"))))))

;; TODO: doom-modeline seem to be causing problems in Emacs 27.1.  Errors are
;; being thrown when opening Python files in a Git project.
(when (my-emacs-version>= "28")
  ;; nerd-icons is required by doom-modeline.
  ;; Must run M-x nerd-icons-install-fonts after installation.
  (use-package nerd-icons)

  ;; Modeline eye candy.
  (use-package doom-modeline
    :init (doom-modeline-mode 1)
    ;; Fix issue with "../../.." (etc.) shown in modeline for paths visited via
    ;; symlink.  See the doom-modeline README for details.
    :config (setq doom-modeline-project-detection 'project)))

(tool-bar-mode -1) ; Disable the tool bar (it's large and not that useful).

(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1)) ; Disable scroll bars.

;; Disable the menu bar by default but make it easy to enable.
(menu-bar-mode -1)
(defun my-menu-bar-toggle ()
  "Toggle the menu bar on or off."
  (interactive)
  (if menu-bar-mode
      (menu-bar-mode -1)
    (menu-bar-mode 1)))
(global-set-key (kbd "C-c m") 'my-menu-bar-toggle)

;; Add clock to modeline (GUI only).
(setq display-time-format "%H:%M")
(setq display-time-default-load-average nil)
(when (display-graphic-p) (display-time-mode 1))

;; all-the-icons used for sidebar and dired (GUI only).
(when (display-graphic-p) (use-package all-the-icons))

(use-package dired-sidebar
  :commands (dired-sidebar-toggle-sidebar)
  :init
  (add-hook 'dired-sidebar-mode-hook
    (lambda ()
      (unless (file-remote-p default-directory)
        (auto-revert-mode))))
  :config
  (if (display-graphic-p)
    (setq dired-sidebar-theme 'icons)
    (setq dired-sidebar-theme 'ascii))
  (setq dired-sidebar-pop-to-sidebar-on-toggle-open nil)
  (setq dired-sidebar-use-term-integration t)
  (setq dired-sidebar-should-follow-file t)
  (setq dired-sidebar-follow-file-idle-delay 0.01)
  (setq dired-sidebar-no-delete-other-windows t))

(use-package ibuffer-sidebar
  :commands (ibuffer-sidebar-toggle-sidebar)
  :config
  (setq ibuffer-sidebar-pop-to-sidebar-on-toggle-open nil))

(defun my-sidebar-toggle ()
  "Toggle both `dired-sidebar' and `ibuffer-sidebar'."
  (interactive)
  ;; The showing-sidebar-p functions are internal.
  (require 'dired-sidebar)
  (require 'ibuffer-sidebar)
  (if (eq
        (not (dired-sidebar-showing-sidebar-p))
        (not (ibuffer-sidebar-showing-sidebar-p)))
    ;; Both sidebars hidden or shown.  Toggle both.
    (progn
      (dired-sidebar-toggle-sidebar)
      (ibuffer-sidebar-toggle-sidebar))
    ;; Sidebars are out-of-sync.  Hide whichever is showing.
    (if (ibuffer-sidebar-showing-sidebar-p)
      (ibuffer-sidebar-hide-sidebar)
      (dired-sidebar-hide-sidebar))))
(global-set-key (kbd "C-x C-n") 'my-sidebar-toggle)

(global-set-key (kbd "C-c S") 'speedbar)
;; Don't sort the speedbar: items should be in order of appearance.
(setq speedbar-tag-hierarchy-method '(speedbar-trim-words-tag-hierarchy))

(when (my-emacs-version>= "28")
  (context-menu-mode 1)) ; Make right-click more useful.

(setq inhibit-startup-screen t)

(setq frame-resize-pixelwise t) ; No gaps around "maximized" window.

(show-paren-mode 1)
(setq show-paren-delay 0)

(column-number-mode t)

(when (display-graphic-p)
  ;; Dired eye candy.
  (use-package all-the-icons-dired)
  (add-hook 'dired-mode-hook 'all-the-icons-dired-mode))

(blink-cursor-mode 1)
(setq-default cursor-type 'bar)
;; Switch to an underbar cursor while in overwrite mode.
(add-hook 'overwrite-mode-hook
          (lambda ()
            (setq cursor-type (if overwrite-mode 'hbar 'bar))))

;; Distraction-free writing mode.
(use-package writeroom-mode
  :bind
  (("S-<f11>" . #'writeroom-mode)
   ("C-M-<" . #'writeroom-decrease-width)
   ("C-M->" . #'writeroom-increase-width))
  :config
  (setq writeroom-local-effects
        '((lambda (writeroom-enabled)
            (if (> writeroom-enabled 0)
                ;; Disable line numbers when writeroom-mode is enabled
                (display-line-numbers-mode -1)
              ;; Restore line number defaults when writeroom-mode is disabled
              (when (and (display-graphic-p) (derived-mode-p 'prog-mode))
                (display-line-numbers-mode 1)))))))

(use-package goto-line-preview
  :config
  (global-set-key [remap goto-line] 'goto-line-preview))


;;;; Project Management:

;; For projectile-ag and projectile-ripgrep
(when (executable-find "ag")
  (use-package ag))
(when (executable-find "rg")
  (use-package rg
    :init (rg-enable-default-bindings)))

(use-package projectile
  :init
  (projectile-mode 1)
  :bind (:map projectile-mode-map ("C-c p" . projectile-command-map)))


;;;; Input:

(global-set-key "\C-x\C-m" 'execute-extended-command)
(defalias 'yes-or-no-p 'y-or-n-p)

;; Display possible completions for partial keychords.
(use-package which-key
  :config (which-key-mode 1))

;; Change the behavior of C-x 1: after using C-x 1 to hide the other windows,
;; use C-x 1 again to unhide them.
(use-package zygospore
  :bind (("C-x 1" . zygospore-toggle-delete-other-windows)))

;; Easier window navigation
(use-package ace-window
  :bind (("M-o" . ace-window)))
(global-set-key (kbd "C-c <left>") 'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>") 'windmove-up)
(global-set-key (kbd "C-c <down>") 'windmove-down)

(use-package multiple-cursors
  :init
  (global-set-key (kbd "C->") 'mc/mark-next-like-this)
  (global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)
  (global-set-key (kbd "C-S-<mouse-1>") 'mc/add-cursor-on-click))


;;;; Completion:

(when (my-emacs-version>= "27") ;; This breaks M-x with Emacs 26
  (use-package vertico
    :init
    (vertico-mode))

  ;; Persist history over Emacs restarts.  Vertico sorts by history position.
  (use-package savehist
    :init
    (savehist-mode))

  ;; A few more useful configurations for Vertico...
  (use-package emacs
    :init
    ;; Add prompt indicator to `completing-read-multiple'.
    (defun crm-indicator (args)
      (cons (concat "[CRM] " (car args)) (cdr args)))
    (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

    ;; Do not allow the cursor in the minibuffer prompt
    (setq minibuffer-prompt-properties
          '(read-only t cursor-intangible t face minibuffer-prompt))
    (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

    ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
    ;; Vertico commands are hidden in normal buffers.
    (if (my-emacs-version>= "28")
        (setq read-extended-command-predicate
              #'command-completion-default-include-p))

    ;; Enable recursive minibuffers
    (setq enable-recursive-minibuffers t))

  (use-package orderless
    :init
    (setq completion-styles '(orderless basic)
          completion-category-defaults nil
          completion-category-overrides '((file (styles partial-completion))))))


;;;; User Utilities:

(use-package crux
  :bind
  (("C-x 4 t" . #'crux-transpose-windows) ; Swap buffers in current/other window
   ("C-c o" . #'crux-open-with)     ; Open visited file with default application
   ("C-c D" . #'crux-delete-file-and-buffer) ; Delete visited file and its buffer
   ("C-c r" . #'crux-rename-file-and-buffer) ; Rename visited file and its buffer
   ("C-c c" . #'crux-copy-file-preserve-attributes) ; cp -a
   ("C-c !" . #'crux-sudo-edit)            ; Edit visited file with sudo
   ("C-c I" . #'crux-find-user-init-file)  ; Open init.el
   ("C-c P" . #'crux-kill-buffer-truename) ; Copy path to visited file
   ("C-c k" . #'crux-kill-other-buffers)   ; Kill all buffers except current
   ("C-c t" . #'crux-visit-term-buffer)    ; Open ansi-term
   ("C-c d" . #'crux-duplicate-current-line-or-region)))

(defun my-close-all-buffers ()
  "Close all buffers."
  (interactive)
  (mapc 'kill-buffer (buffer-list)))
(global-set-key (kbd "C-c W") #'my-close-all-buffers)


;;;; Git:

(use-package magit
  :bind
  ("C-c g" . 'magit-file-dispatch))

(add-hook 'git-commit-mode-hook (lambda ()
                                  (setq fill-column 72)
                                  (turn-on-auto-fill)))

(use-package git-modes)

(use-package git-timemachine)


;;;; Text Editing:

(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8-unix)
(prefer-coding-system 'utf-8)

(setq-default require-final-newline t)
(setq-default fill-column 80)
(use-package adaptive-wrap) ; Virtual indentation/prefixes for wrapped lines
(add-hook 'text-mode-hook (lambda ()
                            (auto-fill-mode 1)
                            (visual-line-mode 1)
                            (adaptive-wrap-prefix-mode 1)))

(global-set-key (kbd "C-c q") 'auto-fill-mode)
(global-set-key (kbd "C-c Q") 'refill-mode)

;; refill-mode doesn't play nicely with org-mode, so use an alternative.
(use-package aggressive-fill-paragraph
  :config
  (add-hook 'org-mode-hook
            (lambda () (local-set-key (kbd "C-c Q") #'aggressive-fill-paragraph-mode))))

;; https://stackoverflow.com/a/207067
(defun my-generalized-shell-command (command arg)
  "Unifies `shell-command' and `shell-command-on-region'.  If no region is
selected, run a shell command just like M-x shell-command (M-!).  If no region
is selected and an argument is a passed, run a shell command and place its
output after the mark as in C-u M-x `shell-command' (C-u M-!).  If a region is
selected pass the text of that region to the shell and replace the text in that
region with the output of the shell command as in C-u M-x
`shell-command-on-region' (C-u M-|).  If a region is selected AND an argument is
passed (via C-u) send output to another buffer instead of replacing the text in
region."
  (interactive (list (read-from-minibuffer "Shell command: " nil nil nil 'shell-command-history)
                     current-prefix-arg))
  (let ((p (if mark-active (region-beginning) 0))
        (m (if mark-active (region-end) 0)))
    (if (= p m)
        ;; No active region
        (if (eq arg nil)
            (shell-command command)
          (shell-command command t))
      ;; Active region
      (if (eq arg nil)
          (shell-command-on-region p m command t t)
        (shell-command-on-region p m command)))))

(global-set-key (kbd "C-c \\") #'my-generalized-shell-command)

(setq kill-whole-line t)
(setq backward-delete-char-untabify-method 'hungry)

;; Invoke `whitespace-cleanup' on save if whitespace was initially clean when
;; the file was opened.
(use-package whitespace-cleanup-mode
  :config
  (global-whitespace-cleanup-mode 1))

;; Cleanup whitespace only on edited lines.
(use-package ws-butler
  :config
  ;; Don't keep whitespace on the current line.
  (setq ws-butler-keep-whitespace-before-point nil)
  ;; Fix indentation to be consistent with `indent-tabs-mode'.
  (setq ws-butler-convert-leading-tabs-or-spaces t))
(my-add-to-multiple-hooks #'ws-butler-mode '(prog-mode-hook text-mode-hook))

(global-set-key (kbd "C-c w") 'whitespace-mode)

(let ((aspell (executable-find "aspell")))
  (when aspell
    (setq ispell-program-name aspell)))
(defun my-flyspell-toggle ()
  "Toggle flyspell-mode and run flyspell-buffer when enabling it."
  (interactive)
  (if flyspell-mode
      (flyspell-mode 0)
    (if (derived-mode-p 'prog-mode)
        (flyspell-prog-mode)
      (flyspell-mode 1))
    (flyspell-buffer)))
(global-set-key (kbd "<f6>") #'my-flyspell-toggle)

;; Most files indent with either a) four spaces; or b) hard tabs with tab stops
;; every 8 columns.
(defun my-tt ()
  "Toggle between 4-space soft tabs and 8-space hard tabs."
  (interactive)
  (if indent-tabs-mode
      (progn
        (setq indent-tabs-mode nil)
        (setq tab-width 4))
    (setq indent-tabs-mode t)
    (setq tab-width 8))
  (if (string-equal major-mode "sh-mode")
      (setq sh-basic-offset tab-width)))

;; my-open-line functions from: https://stackoverflow.com/a/2173393

;; like vi's "O" command
(defun my-open-line-above ()
  "Insert a newline above the current line and put point at beginning."
  (interactive)
  (unless (bolp)
    (beginning-of-line))
  (newline)
  (forward-line -1)
  (indent-according-to-mode))

;; like vi's "o" command
(defun my-open-line-below ()
  "Insert a newline below the current line and put point at beginning."
  (interactive)
  (unless (eolp)
    (end-of-line))
  (newline-and-indent))

(defun my-open-line (&optional abovep)
  "Insert a newline below the current line and put point at beginning.
With a prefix argument, insert a newline above the current line."
  (interactive "P")
  (if abovep
    (my-open-line-above)
    (my-open-line-below)))

(global-set-key (kbd "C-<return>") #'my-open-line)
(global-set-key (kbd "S-<return>") #'my-open-line-above)


;;;; HTML:

(add-hook 'html-mode-hook
  (lambda ()
    ;; Disable HTML indentation by default.
    (set (make-local-variable 'sgml-basic-offset) 0)))


;;;; Markdown:

(use-package markdown-mode
  :mode "\\.md\\'")

;; markdown-mode sets tab-width to 4 (the "natural Markdown tab width"); revert
;; that change, restore the default.
(add-hook 'markdown-mode-hook (lambda () (setq tab-width 8)))


;;;; Org:

(require 'org)

(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

(setq org-startup-indented t)
(setq org-special-ctrl-a/e t)
(setq org-startup-folded 'showeverything)
(setq org-use-sub-superscripts '{})
(setq org-pretty-entities t)
(setq org-log-done t)

(setq org-agenda-files (list "~/Sync/todo/todo.org"))

(setq org-todo-keywords
      '((sequence "TODO" "WAIT" "|" "DONE" "AXED")))

;; Sufficient unto the day is the evil thereof.
(setq org-deadline-warning-days 0)

;; https://emacs.stackexchange.com/a/60555
(defun my-org-link-copy (&optional arg)
  "Extract URL from org-mode link and add it to kill ring."
  (interactive "P")
  (let* ((link (org-element-lineage (org-element-context) '(link) t))
         (type (org-element-property :type link))
         (url (org-element-property :path link))
         (url (concat type ":" url)))
    (kill-new url)
    (message (concat "Copied URL: " url))))
(define-key org-mode-map (kbd "C-c e") #'my-org-link-copy)

(use-package org-cliplink
  :config
  (define-key org-mode-map (kbd "C-c L") #'org-cliplink))

(setq org-html-doctype "html5") ; Export as HTML5 (default is XHTML)
(setq org-html-postamble nil) ; No postamble

;; As a side effect, this eliminates the two-space indentation in source code
;; blocks.
(setq org-src-preserve-indentation t)


;;;; Programming:

(setq gdb-many-windows t)
(setq gdb-show-main t)

(add-hook 'prog-mode-hook (lambda () (setq show-trailing-whitespace 1)))

;; Turn on line numbers by default only in GUI mode.  In the terminal, there are
;; typically fewer columns, so don't waste them.
(if (display-graphic-p)
  (add-hook 'prog-mode-hook #'display-line-numbers-mode))

(use-package auto-highlight-symbol
  :config
  (add-hook 'prog-mode-hook (lambda () (auto-highlight-symbol-mode 1))))

(use-package highlight-numbers
  :config
  (add-hook 'prog-mode-hook 'highlight-numbers-mode))

(use-package company) ; completion

(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook ((lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)
(use-package lsp-ui :commands lsp-ui-mode)

;; Suppress "Keep current list of tags tables also?" prompts
(setq tags-add-tables nil)

(use-package editorconfig
  :config
  (setq editorconfig-trim-whitespaces-mode 'ws-butler-mode)
  (editorconfig-mode 1))

(when (my-emacs-version>= "29")
  (use-package treesit-auto
    :custom
    ;; On NixOS, it's better to install the grammars from nixpkgs.
    (when (not (executable-find "nixos-version"))
      (treesit-auto-install 'prompt))
    (treesit-auto-add-to-auto-mode-alist 'all)
    :config
    ;; Without the below line, rust-format-on-save doesn't work.  rust-mode has
    ;; its own setting to use tree-sitter anyway.
    (delete 'rust treesit-auto-langs)
    ;; My custom C styles don't work with c-ts-mode.
    ;; TODO: implement custom styles using c-ts-mode-indent-style.
    (delete 'c treesit-auto-langs)
    (global-treesit-auto-mode)))


;;;; Lisp:

(use-package paredit)


;;;; Emacs Lisp:

(add-hook #'emacs-lisp-mode-hook
          (lambda ()
            (setq indent-tabs-mode nil)
            (paredit-mode 1)))


;;;; Common Lisp:

;; Add extensions
(add-to-list #'auto-mode-alist '("\\.sbclrc\\'" . lisp-mode)) ; SBLC config file
(add-to-list #'auto-mode-alist '("\\.cl\\'" . lisp-mode)) ; *.cl files

(when (executable-find "sbcl")
  (use-package slime)
  (add-hook #'lisp-mode-hook
            (lambda ()
              (setq indent-tabs-mode nil)
              (paredit-mode 1)
              (unless (featurep 'slime)
                (require 'slime)
                (normal-mode))))
  (setq inferior-lisp-program "sbcl"))


;;;; C-family Programming Languages:

;; Derived from both:
;; https://stackoverflow.com/a/1450454
;; https://www.emacswiki.org/emacs/BackspaceWhitespaceToTabStop
(defun my-backspace-whitespace-to-tab-stop ()
  "Delete whitespace backwards to the next tab-stop, otherwise delete one character."
  (interactive)
  (if indent-tabs-mode
      (call-interactively 'backward-delete-char)
    (let ((movement (% (current-column) tab-width))
          (p (point)))
      (when (= movement 0) (setq movement tab-width))
      ;; Account for edge case near beginning of buffer
      (setq movement (min (- p 1) movement))
      (save-match-data
        (if (string-match "[^\t ]*\\([\t ]+\\)$" (buffer-substring-no-properties (- p movement) p))
            (backward-delete-char (- (match-end 1) (match-beginning 1)))
          (call-interactively 'backward-delete-char))))))

(defun my-c-mode-common-hook ()
  (setq-local c-auto-align-backslashes nil)
  (local-set-key (kbd "DEL") 'my-backspace-whitespace-to-tab-stop)
  (define-key c-mode-base-map "\C-m" 'c-context-line-break))

(add-hook #'c-mode-common-hook #'my-c-mode-common-hook)

;; https://www.doof.me.uk/2021/01/03/changing-emacs-c-c-align-function-to-only-apply-once-per-line/
(defun my-c-no-align-equals-in-vardecl ()
  "Eliminate alignment of equals signs in C variable declarations."
  (defvar align-rules-list) ; defined in align.el
  (let ((var-decl-regexp (alist-get 'regexp
                                    (alist-get 'c-variable-declaration
                                               align-rules-list))))
    (push `(valid . ,(lambda ()
                       (not (save-excursion
                              (end-of-line)
                              (looking-back var-decl-regexp nil)))))
          (alist-get 'c-assignment align-rules-list))))

(add-hook #'align-load-hook #'my-c-no-align-equals-in-vardecl)


;;;; C:

(setq-default c-tab-always-indent nil)

;; If supported, use Doxygen style for C/C++ rather than the GtkDoc.
(if (my-emacs-version>= "28")
    (setq-default c-doc-comment-style
                  '((java-mode . javadoc)
                    (pike-mode . autodoc)
                    (c-mode    . doxygen)
                    (c++-mode  . doxygen))))

;; My preferred indentation style for C.
(defconst my-preferred-c-style
  '("linux"
    (c-offsets-alist . ((arglist-intro . +)
                        (arglist-cont . 0)
                        (arglist-cont-nonempty . +)
                        (arglist-close . 0)
                        (inextern-lang . 0)))))

(c-add-style "preferred" my-preferred-c-style nil)
(setq c-default-style "preferred")

;; C styles based on path patterns.  The value can either by a string (e.g.,
;; "linux") or a function.  The path patterns are tested from first to last, and
;; the first match wins.
;;
;; local-init.el can add entries for the local machine.
(setq my-c-dir-styles
      '(("linux" . "linux")
        ("freebsd" . "bsd")
        ("openbsd" . "bsd")
        ("gnu" . "gnu")
        (nil . c-default-style)))

(when *is-linux*
  (add-to-list 'my-c-dir-styles '("/usr/src" . "linux")))
(when *is-bsd*
  (add-to-list 'my-c-dir-styles '("/usr/src" . "bsd")))

(defun my-c-style-from-path ()
  "Set C style based on its path pattern."
  (let ((style (assoc-default buffer-file-name my-c-dir-styles
                              (lambda (pattern path)
                                (or (not pattern)
                                    (and (stringp path)
                                         (string-match pattern path)))))))
    (cond
     ((stringp style) (c-set-style style))
     ((functionp style) (funcall style)))))

(add-hook 'c-mode-hook #'my-c-style-from-path)


;;;; Makefile:

(add-to-list 'auto-mode-alist '("\\.mak\\'" . makefile-gmake-mode))


;;;; Shell:

(setq sh-styles-alist
      '(("my-sh"
         (sh-basic-offset . 8)
         (sh-first-lines-indent . 0)
         (sh-indent-after-case . +)
         (sh-indent-after-do . +)
         (sh-indent-after-done . 0)
         (sh-indent-after-else . +)
         (sh-indent-after-if . +)
         (sh-indent-after-loop-construct . +)
         (sh-indent-after-open . +)
         (sh-indent-comment . t)
         (sh-indent-for-case-alt . +)
         (sh-indent-for-case-label . 0)
         (sh-indent-for-continuation . +)
         (sh-indent-for-do . 0)
         (sh-indent-for-done . 0)
         (sh-indent-for-else . 0)
         (sh-indent-for-fi . 0)
         (sh-indent-for-then . 0))))
(add-hook 'sh-set-shell-hook (lambda () (sh-load-style "my-sh")))


;;;; Python:

(when (executable-find "black")
  (use-package python-black
    :after python
    :hook (python-mode . python-black-on-save-mode-enable-dwim)))


;;;; Go:

(when (executable-find "go")
  ;; Ensure that $GOPATH/bin is in the path.  If $GOPATH is undefined, $HOME/go
  ;; is the default.
  (let* ((GOPATH (getenv "GOPATH"))
         (gopath (if GOPATH GOPATH
                   (concat (getenv "HOME") "/go")))
         (gobin (concat gopath "/bin")))
    (my-add-to-path gobin))

  (use-package go-mode
    :mode "\\.go\\'")

  ;; Go LSP integration
  ;; go install golang.org/x/tools/gopls@latest
  (when (executable-find "gopls")
    (add-hook 'go-mode-hook #'lsp-deferred)
    (defun lsp-go-install-save-hooks ()
      (add-hook 'before-save-hook #'lsp-format-buffer t t)
      (add-hook 'before-save-hook #'lsp-organize-imports t t))
    (add-hook 'go-mode-hook #'lsp-go-install-save-hooks)))

;;;; Rust:

;; TODO: Consider a more sophisticated setup, e.g.,
;; https://robert.kra.hn/posts/rust-emacs-setup/

(when (my-executables-found '("rustc" "cargo"))
  (use-package rust-mode
    :init
    (when (executable-find "rustfmt")
      (setq rust-format-on-save t))
    (when (my-emacs-version>= "29")
      (setq rust-mode-treesitter-derive t)))
  (add-hook 'rust-mode-hook
    (lambda () (setq indent-tabs-mode nil))))


;;;; Nix:

(when (executable-find "nix")
  (use-package nix-mode
    :mode "\\.nix\\'"))


;;;; Local Changes:

(let ((local-init (my-emacs-d-path "local-init.el")))
  (when (file-exists-p local-init)
    (load-file local-init)))


;;;; (Hopefully) Temporary Workarounds:

;; GnuPG 2.4.1 broke EasyPG:
;; https://dev.gnupg.org/T6481
;; https://old.reddit.com/r/emacs/comments/137r7j7/gnupg_241_encryption_issues_with_emacs_orgmode/
;; Fixed in GnuPG 2.4.4 (note some Linux distros backported the fix to earlier versions).
;; Leaving this workaround here for a while, until GnuPG 2.4.4 can be assumed.
(fset #'epg-wait-for-status 'ignore)


;;; init.el ends here
