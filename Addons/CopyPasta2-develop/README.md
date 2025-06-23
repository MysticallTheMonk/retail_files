# CopyPasta2
[Tukui Project Page](https://www.tukui.org/addons.php?id=186)

[Nuaik's YouTube Channel](https://www.youtube.com/channel/UCMvK4RUJtojPBaKND8DULFw)

CopyPasta is a small utility that enables multi-line/unlimited-length pasting of text or commands into WoW. This is a fork of CopyPasta which itself is a fork of Paste by the authors; idlenexusgaming & oscarucb who are both missing in action. Many people have attempted to reach out to the original authors but there has been no response from either. Due to the usefulness and popularity of his addon, it was necessary to fork his project and make it compatible with 9.x.  CopyPasta2 is essentially identical to paste but with its libraries updated for use with Shadowlands.  This addon will be discontinued should oscarucb or idlenexusgaming return from their hiatus to update paste/copypasta.

## Important Usage Note
This addon is a drop-in replacement for paste & copypasta, which is to say it works exactly like it, with all of its commands and help text.  You must disable paste for this one to function properly.

## Bug reporting and chat addon compatibility
Because no compatibility issues have been reported with other chat addons for paste or copypasta, it is assumed to also be true in copypasta2.  Please report bugs using the issues section of this project.  Bugs reported in comments will likely go unnoticed.  No feature requests will be implemented in copypasta.  All crippling bugs determined to be originating from the core addon will be resolved to the best of my ability. Bugs originating from the ace libraries will be resolved in subsequent versions of those libraries as soon as the Ace team hears of the bugs and fixes them.

## Description from the original author's addon page
If you've ever tried to paste a paragraph of text or a list of slash commands into WoW you've probably noticed that newlines are stripped and anything over 255 characters is silently truncated. The Paste addon solves this problem.

## Usage

Open the Paste window via minimap icon, keybind, LDB or /paste show
Paste your clipboard text into the box with control-v / command-v
Press the "Paste" button and the entire contents will be sent to your selected channel, one message per line, with long lines automatically split.
The "Default" channel can be used to execute a list of slash commands (eg TomTom /way commands)
Options are available via "/paste config"
Fully compatible with WoW 9.x and all chat addons.
