;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
;;; DO NOT EDIT DIRECTLY. This file is tangled from config.org.

(setq user-full-name "Will Hutchinson"
      user-mail-address "will@thehutchery.com")

(after! mu4e
  (setq mu4e-maildir "~/Mail/proton"
        mu4e-get-mail-command "mbsync proton"
        mu4e-update-interval 300
        mu4e-change-filenames-when-moving t
        mu4e-sent-folder "/Sent"
        mu4e-drafts-folder "/Drafts"
        mu4e-trash-folder "/Trash"
        mu4e-refile-folder "/Archive"
        message-send-mail-function #'message-send-mail-with-sendmail
        sendmail-program (executable-find "msmtp")
        message-sendmail-extra-arguments '("--read-envelope-from")
        message-sendmail-f-is-evil t))

(setq doom-font (font-spec :family "GeistMono Nerd Font" :size 15)
      doom-variable-pitch-font (font-spec :family "Alegreya" :size 18)
      doom-big-font (font-spec :family "GeistMono Nerd Font" :size 22))

(setq doom-theme 'doom-nord)

(after! vterm
  (custom-set-faces!
    '(term-color-black :foreground "#282828" :background "#282828")
    '(term-color-red :foreground "#cc241d" :background "#cc241d")
    '(term-color-green :foreground "#98971a" :background "#98971a")
    '(term-color-yellow :foreground "#d79921" :background "#d79921")
    '(term-color-blue :foreground "#458588" :background "#458588")
    '(term-color-magenta :foreground "#b16286" :background "#b16286")
    '(term-color-cyan :foreground "#689d6a" :background "#689d6a")
    '(term-color-white :foreground "#a89984" :background "#a89984")
    '(vterm-color-black :foreground "#282828" :background "#282828")
    '(vterm-color-red :foreground "#cc241d" :background "#cc241d")
    '(vterm-color-green :foreground "#98971a" :background "#98971a")
    '(vterm-color-yellow :foreground "#d79921" :background "#d79921")
    '(vterm-color-blue :foreground "#458588" :background "#458588")
    '(vterm-color-magenta :foreground "#b16286" :background "#b16286")
    '(vterm-color-cyan :foreground "#689d6a" :background "#689d6a")
    '(vterm-color-white :foreground "#a89984" :background "#a89984")
    '(vterm-color-bright-black :foreground "#928374" :background "#928374")
    '(vterm-color-bright-red :foreground "#fb4934" :background "#fb4934")
    '(vterm-color-bright-green :foreground "#b8bb26" :background "#b8bb26")
    '(vterm-color-bright-yellow :foreground "#fabd2f" :background "#fabd2f")
    '(vterm-color-bright-blue :foreground "#83a598" :background "#83a598")
    '(vterm-color-bright-magenta :foreground "#d3869b" :background "#d3869b")
    '(vterm-color-bright-cyan :foreground "#8ec07c" :background "#8ec07c")
    '(vterm-color-bright-white :foreground "#ebdbb2" :background "#ebdbb2")))

(setq display-line-numbers-type t)

(setq org-directory "~/org/"
      org-roam-directory (concat org-directory "roam/"))

(defvar +org-done-file (expand-file-name "done.org" org-directory)
  "Org file that collects completed task subtrees.")

(after! org
  (setq org-agenda-files
        (list (concat org-directory "tasks.org")
              (concat org-directory "inbox.org"))
        org-default-notes-file (concat org-directory "inbox.org")
        org-archive-location (concat +org-done-file "::* Done"))

  (defun +org/ensure-done-file ()
    "Create `+org-done-file' with a top-level Done heading when needed."
    (let ((done-file (expand-file-name +org-done-file)))
      (make-directory (file-name-directory done-file) t)
      (unless (file-exists-p done-file)
        (with-temp-file done-file
          (insert "#+title: Done\n#+startup: overview\n\n* Done\n")))))

  (defun +org/done-file-p ()
    "Return non-nil when the current buffer is `+org-done-file'."
    (and buffer-file-name
         (string= (file-truename buffer-file-name)
                  (file-truename +org-done-file))))

  (defun +org/org-directory-file-p ()
    "Return non-nil when the current buffer lives under `org-directory'."
    (and buffer-file-name
         (file-in-directory-p (file-truename buffer-file-name)
                              (file-truename org-directory))))

  (defun +org/archive-done-todo-at-marker (marker)
    "Move the done TODO at MARKER to `+org-done-file'."
    (when-let ((buffer (marker-buffer marker)))
      (with-current-buffer buffer
        (save-excursion
          (goto-char marker)
          (when (and (+org/org-directory-file-p)
                     (member (org-get-todo-state) org-done-keywords)
                     (not (+org/done-file-p)))
            (+org/ensure-done-file)
            (let ((org-archive-location (concat +org-done-file "::* Done")))
              (org-archive-subtree)
              (save-buffer)
              (when-let ((done-buffer (find-buffer-visiting +org-done-file)))
                (with-current-buffer done-buffer
                  (save-buffer))))))))
    (set-marker marker nil)
    (when-let ((agenda-buffer (and (boundp 'org-agenda-buffer-name)
                                   (get-buffer org-agenda-buffer-name))))
      (with-current-buffer agenda-buffer
        (when (derived-mode-p 'org-agenda-mode)
          (org-agenda-redo t)))))

  (defun +org/archive-done-todo ()
    "Move TODO entries to `+org-done-file' after they become done.

Archiving directly inside `org-after-todo-state-change-hook' can corrupt the
agenda refresh path: `org-agenda-todo' still expects the source heading to be in
place while it updates the agenda line.  Defer the archive until the todo command
has finished, then refresh the agenda buffer."
    (when (and (+org/org-directory-file-p)
               (member org-state org-done-keywords)
               (not (+org/done-file-p)))
      (run-at-time 0.1 nil #'+org/archive-done-todo-at-marker (point-marker))))

  (+org/ensure-done-file)
  (add-hook 'org-after-todo-state-change-hook #'+org/archive-done-todo)

  (setq org-capture-templates
        `(
          ;; Task capture
          ("t" "task" entry
           (file+headline ,(concat org-directory "tasks.org") "Tasks")
           "* TODO %?\nSCHEDULED: %t\n:PROPERTIES:\n:Created: %U\n:END:\n\n%a\n")

          ;; Work task capture
          ("w" "work task" entry
           (file+headline ,(concat org-directory "tasks.org") "Tasks")
           "* TODO %? :WORK:\nSCHEDULED: %t\n:PROPERTIES:\n:Created: %U\n:END:\n\n%a\n")

          ;; Inbox / zettel draft capture
          ("i" "inbox" entry
           (file+headline ,(concat org-directory "inbox.org") "Inbox")
           "* %? %^g\n:PROPERTIES:\n:Created: %U\n:Type: Zettel\n:Aliases:\n:References:\n:END:\n\n"))))

(after! org-roam
  (make-directory (expand-file-name "work" org-roam-directory) t)
  (make-directory (expand-file-name "zettels" org-roam-directory) t)
  (setq org-roam-capture-templates
        '(("z" "zettel" plain "%?"
           :if-new (file+head "zettels/${slug}.org" "#+title: ${title}\n#+created: %U\n#+filetags: :ZETTEL:\n\n")
           :unnarrowed t)
          ("w" "work spec" plain "** Context\n\n%?\n\n** Goals\n\n** Requirements\n\n** Open Questions\n\n** Links\n"
           :if-new (file+head "work/${slug}.org" "#+title: ${title}\n#+created: %U\n#+filetags: :WORK:\n#+type: WorkSpec\n\n")
           :unnarrowed t)))
  (org-roam-db-autosync-mode))

(after! projectile
  (setq projectile-project-search-path '("~/d/" "~/nixos-config")
        projectile-auto-discover t
        projectile-track-known-projects-automatically nil))

(defun +monorepo/find-cargo-workspace (dir)
  "Return the nearest Cargo workspace root above DIR as a project, or nil."
  (when-let* ((root (locate-dominating-file dir "Cargo.lock")))
    (cons 'transient (expand-file-name root))))

(after! project
  (add-hook 'project-find-functions #'+monorepo/find-cargo-workspace -100))

(map! :leader
      :desc "Vertical split" "s l" #'+evil/window-vsplit-and-follow)
