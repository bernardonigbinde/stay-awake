# stay-awake

> [!NOTE]
> A small, for-fun project for learning cross-platform systems programming in
> Swift: one codebase, three operating systems, and how each one exposes native
> APIs to a command-line tool.

Keep a machine awake and marked "active" so presence-based apps (for example
Microsoft Teams) do not flip to Away or Offline for as long as it runs.

It does two things while active:

- prevents the system from going to idle sleep
- periodically registers input activity so the OS idle timer never crosses the
  threshold that presence apps read to decide you are away

## usage

```
stay-awake 2h      # stay active for 2 hours
stay-awake 45m     # stay active for 45 minutes
stay-awake         # default 1h
stay-awake -v      # print version
stay-awake -h      # print help
```

Duration is `<n>h` or `<n>m`. Press ctrl-c to stop early; it releases
everything cleanly on the way out.

## how it works

The idle timer, not just sleep state, is what presence apps read. Preventing
sleep alone is not enough, so on each tick it also registers a tiny input event
that resets the idle timer without moving the pointer anywhere it was not.

- macOS: an `IOPMAssertion` blocks idle sleep; the nudge posts a `CGEvent`
  mouse move (+1px then back) through the HID event tap. Posting synthetic
  events needs Accessibility permission, so grant your terminal
  Accessibility under System Settings > Privacy & Security the first time.
- Windows: `SetThreadExecutionState` blocks sleep; the nudge is a zero-delta
  `SendInput` mouse move, which bumps `GetLastInputInfo`.
- Linux: `systemd-inhibit` holds an idle:sleep lock; the nudge is an X11
  `XTestFakeRelativeMotionEvent`. X11 only. On Wayland there is no portable
  way to inject input, so the nudge is skipped (sleep is still blocked) and it
  warns you at startup.

## platform support

| platform | sleep | idle nudge | status |
| --- | --- | --- | --- |
| macOS | IOPMAssertion | CGEvent | tested |
| Windows | SetThreadExecutionState | SendInput | written to the docs, not yet verified |
| Linux (X11) | systemd-inhibit | XTest | written to the docs, not yet verified |
| Linux (Wayland) | systemd-inhibit | none | nudge unsupported |

Only the macOS path has been run by the author so far. The Windows and Linux
backends are written to their documented APIs but not yet tested on real
hardware; fixes welcome.

## build

```
swift build -c release
.build/release/stay-awake 2h
```

Linux needs `libx11-dev` and `libxtst-dev` for the idle nudge to link.
