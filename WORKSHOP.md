This repo is a workshop for delivering and maintaining our own fork of `fx` for local use. We want to do wild experiments while keeping up with upstream `fx`. This repo is also our home base for contributing PRs to the project as desired, but it also helps us maintain features that we aren't trying to deliver upstream.

Installing fx via the install script in this repo gets you our patched fx on your system path.

Running "/maintain" will do the work of reading this document and maintaining the project:
- Keeps a scratch document SCRATCHPAD.md to keep track of history and other info needed to maintain the project over time, every time the skill is run it will add, update, or remove from the pad.
- Looks at all of the commits since last maintenance looking for opportunities to update or retire our patches.
- Rebases our fork on upstream main, handling merge conflicts, etc as much as possible
- Walks the features section below ensuring that each item is in place and implemented in some way
- Checks PRs for progress or attention needed
- Sends notifications for interesting new features/capabilities found in codebase
- When big changes happen upstream assess if human input is needed, if not do the work to ensure we are caught up, rebased, etc

## Features

### System prompt features

- Support --append-system-prompt-file and --system-prompt-file for replacing and appending the system prompt

### Effort related features

- Support FX_EFFORT and --effort parity with FX_MODEL and --model features.
- Support effort list as part of the model catalog. It should be rendered in relavent places like `fx model --json` so that e.g. an ADE can present a list of possible models and efforts per provider.

### External editor support

- Support the common Ctrl+G keybind to open fx in $EDITOR. We will need to override and rehome the fx default Ctrl+G functionality to antoher keybind.

### General

- All features need to support only the codex provider today. If a feature can easily work for all providers it should but we should focus on a perfect codex experience for now.
- As needed we can create PR specific branches and local feature branches so that e.g. we can make a feature easier to integrate locally in one branch and then a nearly identical branch for the equivilent upstream branch that can be rebased and altered based on feedback separately from the local one, etc. The `integration` branch is where all work must be merged that will be installed locally. We should record rerere resolutions where needed to make rebasing the same work easier over time.
