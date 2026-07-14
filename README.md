# stay-awake

Keep a machine awake and marked "active" so presence-based apps (for example
Microsoft Teams) do not flip to Away or Offline for as long as it runs.

It does two things while active:

- prevents the system from going to idle sleep
- periodically registers input activity so the OS idle timer never crosses the
  threshold that presence apps read to decide you are away

Status: work in progress.
