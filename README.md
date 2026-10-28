# Daily Hub for Omarchy

A calm productivity panel for the Omarchy Quattro bar. Daily Hub brings daily
priorities, tasks, focus sessions, reminders, and day progress into one place
while leaving specialist tools such as Screen Time and media controls separate.

Daily Hub is currently under active development. Version `0.1.0` includes:

- daily tasks and priority marking;
- automatic carry-over of unfinished tasks;
- a dedicated Big 3, Today list, and Later backlog;
- task descriptions, editing, reordering, search, and filtering;
- quick movement between Today and Later with visible carry counts;
- a focus and break timer with desktop notifications;
- native Omarchy reminder creation and status;
- day and task progress;
- a read-only summary from the Screen Time plugin when it is installed;
- keyboard-first controls.

## Install

Once the first public release is available:

```sh
omarchy plugin add https://github.com/DevBrightly/omarchy-daily-hub.git --enable
```

Daily Hub stores its local state in
`~/.local/share/br-daily-hub/state.json`. Removing or updating the plugin does
not delete that file.

## Usage

Click the Daily Hub bar item to open the panel. Middle-click it to start or
pause the timer. Inside the panel:

- `a` or `q` focuses the quick-add input;
- `/` focuses task search;
- `f` starts or pauses the timer;
- `r` resets the current timer;
- `c` clears completed tasks;
- `Escape` closes the panel.

## Configure

Use **Setup → Bar** to configure the day boundaries, timer lengths, screen-time
guide, and bar label. The widget can also be moved with:

```sh
omarchy bar move io.github.devbrightly.daily-hub --section center
```

## Remove

```sh
omarchy plugin remove io.github.devbrightly.daily-hub
```

The plugin runs inside `omarchy-shell` with your user permissions, like all
Omarchy shell plugins. It launches only Omarchy's reminder and notification
commands and reads/writes the local paths documented above. It does not make
network requests.

## Development

Validate the repository with:

```sh
npm test
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml Store.qml
```

The dependency-free test suite covers state migration, Big 3 enforcement,
Today/Later behavior, rollover, task editing and manifest integrity. GitHub
Actions runs the same suite automatically for pushes and pull requests.

See [ROADMAP.md](ROADMAP.md) for the planned task, focus, and project-management
features.

## License

MIT
