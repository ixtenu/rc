;;; init.el --- GNU Emacs initialization -*- lexical-binding: t; -*-

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

;;
;; Package Manager
;;

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

;;
;; Operating Systems
;;

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

;;
;; General Settings
;;

(setq ring-bell-function 'ignore)

(setq custom-file null-device) ; Custom, not even once.

;; Run Emacs as a server so that emacsclient will work.
(require 'server)
(unless (server-running-p) (server-start))

(save-place-mode 1) ; Remember position in files.
(recentf-mode 1) ; Remember recently edited files.

;; Run `clean-buffer-list' at midnight.
(require 'midnight)
(midnight-delay-set 'midnight-delay 0)

;; Reduce buffer list clutter from dired.
(if (my-emacs-version>= "28")
    (setq dired-kill-when-opening-new-dired-buffer t))

(delete-selection-mode 1) ; Typing replaces selection.

(global-auto-revert-mode 1) ; Revert externally edited files.

(put 'narrow-to-region 'disabled nil) ; Disable `narrow-to-region' warning.

(setq create-lockfiles nil) ; Live dangerously.

;; With Git, file system snapshots, and a proper backup strategy -- backup
;; files are just clutter.
(setq make-backup-files nil)

;; Disable garbage collection when minibuffer is active.
;; https://bling.github.io/blog/2016/01/18/why-are-you-changing-gc-cons-threshold/
(defun my-gc-minibuffer-setup-hook ()
  (setq gc-cons-threshold most-positive-fixnum))
(defun my-gc-minibuffer-exit-hook ()
  (setq gc-cons-threshold my-normal-gc-cons-threshold))
(add-hook 'minibuffer-setup-hook #'my-gc-minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'my-gc-minibuffer-exit-hook)

(use-package restart-emacs)
(defun my-restart-emacs-reset-desktop ()
  "Restart GNU Emacs without `desktop-save-mode'."
  (interactive)
  (desktop-save-mode 0)
  (delete-file (desktop-full-file-name))
  (restart-emacs))

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

;;
;; Appearance
;;

(setq custom-safe-themes t)

(if (display-graphic-p)
    (use-package constant-theme
      :config
      (load-theme 'constant))
  (use-package grayscale-theme
    :config
    (load-theme 'grayscale)))

(when *is-bsd*
  (ignore-errors (set-frame-font "DejaVu Sans Mono 11" nil t)))
(when *is-linux*
  (ignore-errors (set-frame-font "Inconsolata 12" nil t))
  (ignore-errors (set-frame-font "Hack 11" nil t)))
(when *is-macos*
  (ignore-errors (set-frame-font "Menlo 13" nil t)))
(when *is-windows*
  (ignore-errors (set-frame-font "Consolas 12" nil t)))

;; all-the-icons is required by doom-modeline.
;; Must run M-x all-the-icons-install-fonts after installation.
(use-package all-the-icons)

;; Modeline eye candy.
(use-package doom-modeline
  :init (doom-modeline-mode 1))

(tool-bar-mode -1)

(setq inhibit-startup-screen t)
(setq initial-scratch-message "")

(show-paren-mode 1)
(setq show-paren-delay 0)

(column-number-mode t)

;; https://www.emacswiki.org/emacs/LineNumbers#h5o-1
(require 'display-line-numbers)
(defcustom display-line-numbers-exempt-modes
  '(vterm-mode eshell-mode shell-mode term-mode ansi-term-mode)
  "Major modes on which to disable line numbers."
  :group 'display-line-numbers
  :type 'list
  :version "green")
(defun display-line-numbers--turn-on ()
  "Turn on line numbers except for certain major modes.
Exempt major modes are defined in `display-line-numbers-exempt-modes'."
  (unless (or (minibufferp)
              (member major-mode display-line-numbers-exempt-modes))
    (display-line-numbers-mode)))
(global-display-line-numbers-mode)

;; Cusor is a vertical bar, or an underbar in overwrite mode.
(blink-cursor-mode 1)
(setq-default cursor-type 'bar)
(add-hook 'overwrite-mode-hook
          (lambda ()
            (setq cursor-type (if overwrite-mode 'hbar 'bar))))

;;
;; Project Management
;;

(use-package projectile
  :init
  (projectile-mode 1)
  :bind (:map projectile-mode-map ("C-c p" . projectile-command-map)))

;;
;; Input
;;

(global-set-key "\C-x\C-m" 'execute-extended-command)
(defalias 'yes-or-no-p 'y-or-n-p)

;; Display possible completions for partial keychords.
(use-package which-key
  :config (which-key-mode 1))

;; Change the behavior of C-x 1: after using C-x 1 to hide the other windows,
;; use C-x 1 again to unhide them.
(use-package zygospore
  :bind (("C-x 1" . zygospore-toggle-delete-other-windows)))

;;
;; Completion
;;

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

;;
;; User Utilities
;;

(use-package crux
  :bind
  (("C-x 4 t" . #'crux-transpose-windows) ; Swap buffers in current/other window
   ("C-c o" . #'crux-open-with) ; Open visited file with default application
   ("C-c D" . #'crux-delete-file-and-buffer) ; Delete visited file and its buffer
   ("C-c r" . #'crux-rename-file-and-buffer) ; Rename visited file and its buffer
   ("C-c c" . #'crux-copy-file-preserve-attributes) ; cp -a
   ("C-c !" . #'crux-sudo-edit) ; Edit visited file with sudo
   ("C-c I" . #'crux-find-user-init-file) ; Open init.el
   ("C-c P" . #'crux-kill-buffer-truename) ; Copy path to visited file
   ("C-c k" . #'crux-kill-other-buffers) ; Kill all buffers except current
   ("C-c t" . #'crux-visit-term-buffer) ; Open ansi-term
   ("C-c d" . #'crux-duplicate-current-line-or-region)))

;;
;; Git
;;

(use-package magit
  :bind
  ("C-c g" . 'magit-file-dispatch))

(add-hook 'git-commit-mode-hook (lambda ()
                                  (setq fill-column 72)
                                  (turn-on-auto-fill)))

(use-package diff-hl
  :config
  (global-diff-hl-mode)
  ;; diff-hl README says these are needed with Magit 2.4 or newer.
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh))

(use-package git-modes)

;;
;; Text Editing
;;

(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8-unix)
(prefer-coding-system 'utf-8)

(setq-default require-final-newline t)
(setq-default fill-column 80)
(add-hook 'text-mode-hook 'auto-fill-mode)

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
    (setq tab-width 8)))

;;
;; Markdown
;;

(use-package markdown-mode
  :mode "\\.md\\'")

;; markdown-mode sets tab-width to 4 (the "natural Markdown tab width"); revert
;; that change, restore the default.
(add-hook 'markdown-mode-hook (lambda () (setq tab-width 8)))

;;
;; Org
;;

(require 'org)

(global-set-key (kbd "C-c l") 'org-store-link)
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

(setq org-startup-indented t)
(setq org-special-ctrl-a/e t)
(setq org-startup-folded 'showeverything)
(setq org-use-sub-superscripts '{})
(setq org-pretty-entities t)

(setq org-todo-keywords
      '((sequence "TODO" "WAITING" "|" "DONE" "CANCELED")))

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

;;
;; Programming
;;

(setq gdb-many-windows t)
(setq gdb-show-main t)

(add-hook 'prog-mode-hook (lambda () (setq show-trailing-whitespace 1)))

;; Disabled: causing "Match data clobbered by buffer modification hooks" errors
;; with M-x replace-string and similar commands
(when nil
  (use-package auto-highlight-symbol
    :config
    (add-hook 'prog-mode-hook (lambda () (auto-highlight-symbol-mode 1)))))

(use-package highlight-numbers
  :config
  (add-hook 'prog-mode-hook 'highlight-numbers-mode))

(use-package rainbow-delimiters
  :config (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))

(use-package company) ; completion

(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook ((lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)
(use-package lsp-ui :commands lsp-ui-mode)

;;
;; Emacs Lisp
;;

(add-hook #'emacs-lisp-mode-hook (lambda () (setq indent-tabs-mode nil)))

;;
;; C-family Programming Languages
;;

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

;;
;; C
;;

(setq-default c-tab-always-indent nil)

;; If supported, use Doxygen style for C/C++ rather than the GtkDoc.
(if (my-emacs-version>= "28")
    (setq-default c-doc-comment-style
                  '((java-mode . javadoc)
                    (pike-mode . autodoc)
                    (c-mode    . doxygen)
                    (c++-mode  . doxygen))))

(setq c-default-style "linux")

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

;;
;; Makefile
;;

(add-to-list 'auto-mode-alist '("\\.mak\\'" . makefile-gmake-mode))

;;
;; Shell
;;

(setq sh-basic-offset 8)

;;
;; Go
;;

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

;;
;; Local Changes
;;

(let ((local-init (my-emacs-d-path "local-init.el")))
  (when (file-exists-p local-init)
    (load-file local-init)))
