# Nushell <https://www.nushell.sh/> initialization

# Suppress welcome banner
$env.config.show_banner = false

def iscmd [name] {
    (which $name | where type == "external" | length) > 0
}

# Add directory to PATH if it exists and isn't already in PATH.
def --env addtopath [dir] {
    let d = ($dir | path expand)
    if not ($d | path exists) {
        return
    }
    if ($env.path | any { |p| $p == $d }) {
        return
    }
    $env.path = ($env.path | append $d)
}

let kernel = (try { ^uname | str trim } catch { "" })
let is_openbsd = $kernel == "OpenBSD"
let is_linux = $kernel == "Linux"

addtopath $"($env.home)/bin"
addtopath $"($env.home)/.local/bin"
addtopath $"($env.home)/go/bin"
addtopath $"($env.home)/.cargo/bin"

if ("/usr/local/plan9" | path exists) {
    $env.PLAN9 = "/usr/local/plan9"
} else if ($"($env.home)/plan9" | path exists) {
    $env.PLAN9 = $"($env.home)/plan9"
}
if ($env.PLAN9? != null) {
    addtopath $"($env.PLAN9)/bin"
}

# vis text editor installs as vise in *BSD userlands because there's a vis(1)
# utility in the base system
let vis_exe = if ($kernel in ["Darwin", "FreeBSD", "OpenBSD"]) { "vise" } else { "vis" }
let vis_cmd = if ($kernel in ["Darwin", "FreeBSD", "OpenBSD"]) and (iscmd "vise") { "vise" } else { "vis" }
def vis [...args] {
    if not (iscmd $vis_cmd) {
        error make { msg: "vis: command not available" }
    }
    ^$vis_cmd ...$args
}
def visu [...args] {
    if not ($kernel in ["Darwin", "FreeBSD", "OpenBSD"]) or not ("/usr/bin/vis" | path exists) {
        error make { msg: "visu: /usr/bin/vis not available" }
    }
    ^/usr/bin/vis ...$args
}

for e in ["nano-wrapper", "nano", $vis_exe, "nvim", "vim", "vi", "mg", "jmacs", "godit"] {
    if (iscmd $e) {
        $env.EDITOR = $e
        $env.VISUAL = $e
        $env.config.buffer_editor = $e
        break
    }
}

def fzp [program, ...args] {
    if not (iscmd "fzf") {
        error make { msg: "fzp: fzf must be installed" }
    }
    let selection = (fzf -m | lines)
    ^$program ...$args ...$selection
}

def fze [...args] {
    if ($env.VISUAL? == null) {
        error make { msg: "fze: cannot open editor when VISUAL is unset" }
    }
    fzp $env.VISUAL ...$args
}

def --env mkcd [dir?] {
    if ($dir == null) {
        print -e "mkcd: missing operand"
        print -e "usage: mkcd directory"
        print -e "mkdir and chdir into the given directory."
        return
    }
    ^mkdir -p $dir
    cd $dir
}

def --env upcd [levels?] {
    let levels = ($levels | default 0)
    mut dir = ""
    for _ in 1..$levels {
        $dir = $"../($dir)"
    }
    if ($dir | is-empty) {
        $dir = $env.PWD
    }
    cd $dir
}

def --env lk [...args] {
    if not (iscmd "walk") {
        error make { msg: "lk: walk must be installed" }
    }
    let target = (^walk ...$args | str trim)
    cd $target
}

def grep [...args] {
    if $is_openbsd { ^grep ...$args } else { ^grep --color=auto ...$args }
}
def df [...args] { ^df -h ...$args }

def ls_base [] {
    if $kernel == "OpenBSD" { ["-hF"] } else { ["-hF", "--color=auto"] }
}

def lr [...args] { ^ls ...(ls_base) -R ...$args }
def ll [...args] { ^ls ...(ls_base) -l ...$args }
def la [...args] { ^ls ...(ls_base) -l -A ...$args }
def lx [...args] {
    if not $is_linux {
        error make { msg: "lx: only available on Linux" }
    }
    ^ls ...(ls_base) -l -BX ...$args
}
def lz [...args] { ^ls ...(ls_base) -l -rS ...$args }
def lt [...args] { ^ls ...(ls_base) -l -rt ...$args }

def chown [...args] {
    if $is_linux { ^chown --preserve-root ...$args } else { ^chown ...$args }
}
def chmod [...args] {
    if $is_linux { ^chmod --preserve-root ...$args } else { ^chmod ...$args }
}
def chgrp [...args] {
    if $is_linux { ^chgrp --preserve-root ...$args } else { ^chgrp ...$args }
}

let img_cmd = if (iscmd "nsxiv") { "nsxiv" } else if (iscmd "sxiv") { "sxiv" } else { null }
def img [...args] {
    if ($img_cmd == null) {
        error make { msg: "img: nsxiv or sxiv must be installed" }
    }
    ^$img_cmd ...$args
}

let maim_cmd = if (iscmd "maim") { "maim" } else { null }
let xclip_cmd = if (iscmd "xclip") { "xclip" } else { null }
def screencap_desktop [...args] {
    if ($maim_cmd == null) {
        error make { msg: "screencap_desktop: maim must be installed" }
    }
    ^$maim_cmd ...$args
}
def screencap_window [...args] {
    if ($maim_cmd == null) {
        error make { msg: "screencap_window: maim must be installed" }
    }
    ^$maim_cmd -st 9999999 ...$args
}
def screencap_select [...args] {
    if ($maim_cmd == null) {
        error make { msg: "screencap_select: maim must be installed" }
    }
    ^$maim_cmd -s ...$args
}
def clip_png [...args] {
    if ($xclip_cmd == null) or ($maim_cmd == null) {
        error make { msg: "clip_png: maim and xclip must be installed" }
    }
    ^$xclip_cmd -selection clipboard -t image/png ...$args
}

# GNU Emacs
let emacs_cmd = if (iscmd "emacs") { "emacs" } else { null }
def ge [...args] {
    if ($emacs_cmd == null) {
        error make { msg: "ge: emacs must be installed" }
    }
    ^$emacs_cmd -nw ...$args
}
def gec [...args] {
    if ($emacs_cmd == null) {
        error make { msg: "gec: emacs must be installed" }
    }
    if not (iscmd "emacsclient") {
        error make { msg: "gec: emacsclient must be installed" }
    }
    ^emacsclient -n ...$args
}

# Shorter name for JOE's Emacs emulation
def jm [...args] {
    if not (iscmd "jmacs") {
        error make { msg: "jm: jmacs must be installed" }
    }
    ^jmacs ...$args
}

# Alias for lightweight Emacs-like editor
let em_candidates = ["godit-wrapper", "godit", "mg", "jmacs", "jed", "zile", "qemacs"]
let em_cmd = (try { $em_candidates | where { |c| iscmd $c } | first } catch { null })
def em [...args] {
    if ($em_cmd == null) {
        error make { msg: "em: no suitable editor found" }
    }
    ^$em_cmd ...$args
}

# new vi (aka nvi aka Berkeley vi) is commonly installed as ex/vi.  Try to
# provide nex/nvi aliases for it.
let vi_cmd = if (iscmd "nvim") { "nvim" } else if (iscmd "^vim") { "vim" } else { null }
def vi [...args] {
    # Prefer /usr/bin/ex if it exists since on BSD that's nvi whereas
    # /usr/local/bin/ex would be vim (if installed).  On Linux, there isn't a
    # convenient and portable way of distinguishing nvi's ex from other
    # implementations (e.g., vim's or Ancient Vi's) so don't try.
    if ($vi_cmd == null) {
        error make { msg: "vi: nvim or vim must be installed" }
    }
    ^$vi_cmd ...$args
}
def vim [...args] {
    if (iscmd "nvim") { ^nvim ...$args } else { ^vim ...$args }
}

def nex [...args] {
    if (iscmd "^nex") {
        ^nex ...$args
    } else if ("/usr/bin/ex" | path exists) {
        ^/usr/bin/ex ...$args
    } else if (iscmd "ex") {
        ^ex ...$args
    } else {
        error make { msg: "nex: ex must be installed" }
    }
}
def nvi [...args] {
    if (iscmd "^nvi") {
        ^nvi ...$args
    } else if (iscmd "nex") or ("/usr/bin/ex" | path exists) or (iscmd "ex") {
        ^nex -v ...$args
    } else {
        error make { msg: "nvi: nex or ex must be installed" }
    }
}

def nano [...args] {
    if (iscmd "nano-wrapper") {
        # invoke nano via a wrapper script
        # <https://github.com/ixtenu/script/blob/master/nano-wrapper>
        ^nano-wrapper ...$args
    } else if (iscmd "^nano") {
        ^nano ...$args
    } else {
        error make { msg: "nano: must be installed" }
    }
}
# four letters is too many
def na [...args] {
    nano ...$args
}

def sam [...args] {
    if not (iscmd "^sam") {
        error make { msg: "sam: must be installed" }
    }
    # sam-wrapper isn't meant for plan9port sam.
    let use_wrapper = if (iscmd "sam-wrapper") {
        if ($env.PLAN9? == null) {
            true
        } else {
            let sam_path = (try { which sam | first | get path } catch { null })
            $sam_path != $"($env.PLAN9)/bin/sam"
        }
    } else {
        false
    }
    # invoke sam via a wrapper script
    # <https://github.com/ixtenu/script/blob/master/sam-wrapper>
    if $use_wrapper { ^sam-wrapper ...$args } else { ^sam ...$args }
}

# textadept is much too long
def ta [...args] {
    if (iscmd "^ta") {
        ^ta ...$args
    } else if (iscmd "textadept") {
        ^textadept ...$args
    } else {
        error make { msg: "ta: textadept must be installed" }
    }
}

# Debian/Ubuntu renamed fd to fdfind due to a naming conflict.
def fd [...args] {
    if (iscmd "^fd") {
        ^fd ...$args
    } else if (iscmd "fdfind") {
        ^fdfind ...$args
    } else {
        error make { msg: "fd: fd or fdfind must be installed" }
    }
}

# kitty's SSH wrapper.
def kssh [...args] {
    if not (iscmd "kitty") {
        error make { msg: "kssh: kitty must be installed" }
    }
    ^kitty +kitten ssh ...$args
}

# Consistent names for Sublime Text and Sublime Merge
def subl [...args] {
    if (iscmd "^subl") {
        ^subl ...$args
    } else if (iscmd "sublime_text") {
        ^sublime_text ...$args
    } else if (iscmd "subl-text") {
        ^subl-text ...$args
    } else if (iscmd "subl4") {
        ^subl4 ...$args
    } else {
        error make { msg: "subl: Sublime Text must be installed" }
    }
}
def subm [...args] {
    if (iscmd "^subm") {
        ^subm ...$args
    } else if (iscmd "sublime_merge") {
        ^sublime_merge ...$args
    } else if (iscmd "subl-merge") {
        ^subl-merge ...$args
    } else if (iscmd "smerge") {
        ^smerge ...$args
    } else {
        error make { msg: "subm: Sublime Merge must be installed" }
    }
}

# Alternate name for vscode
def code [...args] {
    if (iscmd "^code") {
        ^code ...$args
    } else if (iscmd "code-oss") {
        ^code-oss ...$args
    } else {
        error make { msg: "code: code-oss must be installed" }
    }
}

# Alias sudo to doas and vice versa if one is available and the other isn't.
def sudo [...args] {
    if (iscmd "^sudo") {
        ^sudo ...$args
        return
    }
    if (iscmd "^doas") {
        ^doas ...$args
        return
    }
    error make { msg: "sudo: sudo or doas must be installed" }
}
def doas [...args] {
    if (iscmd "^doas") {
        ^doas ...$args
        return
    }
    if (iscmd "^sudo") {
        ^sudo ...$args
        return
    }
    error make { msg: "doas: doas or sudo must be installed" }
}
