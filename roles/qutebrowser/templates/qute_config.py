config.load_autoconfig()

# STREAMING/DOWNLOADING VIDEO.
# Max 480p.
config.bind("<z>", "spawn --userscript spawn_mpv.sh --ytdl-format=best[height<=?480]")

# Max 480p (ASCII).
config.bind(
    "<Shift-Ctrl-z>",
    "spawn --userscript spawn_mpv.sh --ytdl-format=best[height<=?480] -vo caca",
)

# Max 720p.
config.bind(
    "<Shift-z>", "spawn --userscript spawn_mpv.sh --ytdl-format=best[height<=?720]"
)

# Max 1080p.
config.bind(
    "<Shift-x>",
    "spawn --userscript spawn_mpv.sh --ytdl-format=bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best",
)

# Download Max 1080p.
config.bind(
    "<Shift-Ctrl-x>",
    "spawn --userscript download_video.sh",
)

# Max available.
# config.bind('<c>', 'spawn mpv {url}')

# REAL CONFIG
# Disable autoplay of video tags (mpv is used instead).
c.content.autoplay = False

# Set up download options.
c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = False

# Restore tabs only when clicked.
c.session.lazy_restore = True

# Behaviour when last tab is closed (leave last alive).
c.tabs.last_close = "ignore"

# Starting tab / Default page
# TODO: write a nice start page with links to popular services.
# c.url.default_page =
# c.url.start_pages =

# Set up search engines.
duckstr = "https://duckduckgo.com/?q={}"
googlestr = "https://google.com/search?hl=en&q={}"
# Translates english to polish by default, change to your like.
translate_english_polish = "https://translate.google.com/#en/pl/{}"
translate_german_polish = "https://translate.google.com/#de/pl/{}"
dictcc_german_english = "https://dict.cc/?s={}"
c.url.searchengines = {
    "DEFAULT": googlestr,
    "ddg": duckstr,
    "google": googlestr,
    "english": translate_english_polish,
    "german": translate_german_polish,
    "dictcc": dictcc_german_english,
}

# Fonts
basic_size = "8"
c.fonts.completion.entry = "{} monospace".format(basic_size)
c.fonts.completion.category = "bold {} monospace".format(basic_size)
c.fonts.debug_console = "{} monospace".format(basic_size)
c.fonts.downloads = "{} monospace".format(basic_size)
c.fonts.hints = "bold 13px monospace"
c.fonts.keyhint = "{} monospace".format(basic_size)
c.fonts.messages.error = "{} monospace".format(basic_size)
c.fonts.messages.info = "{} monospace".format(basic_size)
c.fonts.messages.warning = "{} monospace".format(basic_size)
c.fonts.prompts = "{} monospace".format(basic_size)
c.fonts.statusbar = "{} monospace".format(basic_size)
# c.fonts.tabs = "{} monospace".format(basic_size)

# File picker
c.fileselect.handler = "external"
c.fileselect.single_file.command = ["foot", "-e", "ranger", "--choosefile={}"]
c.fileselect.multiple_files.command = ["foot", "-e", "ranger", "--choosefiles={}"]
c.fileselect.folder.command = ["foot", "-e", "ranger", "--choosedir={}"]

# Dark mode
c.colors.webpage.preferred_color_scheme = "dark"
# c.colors.webpage.darkmode.enabled = True

# Password manager
config.bind(",p", "spawn --userscript qute-rbw")
config.bind(",P", "spawn --userscript qute-rbw --password-only")
# TODO: implement TOTP support in qute-rbw
# config.bind(",,P", "spawn --userscript qute-rbw --totp-only")
