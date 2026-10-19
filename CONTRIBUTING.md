# Contributing

Thanks for helping improve Nulea Mouse Mapper. This project accepts changes through pull requests; GitHub Issues, Discussions, and the Wiki are intentionally disabled.

## Before opening a pull request

1. Fork the repository and create a focused branch.
2. Keep driver installation opt-in. No workflow, setup command, or application launch may install a driver automatically.
3. Preserve device scoping. A mapping must never default to every keyboard or mouse.
4. Keep personal device handles, generated mapping plans, downloaded binaries, and runtime files out of Git.
5. Run the local checks:

   ```powershell
   .\scripts\setup.ps1
   npm run check
   ```

6. Validate both mapper scripts without running them:

   ```powershell
   $exe = Resolve-Path '.\.runtime\AutoHotkey64.exe'
   Start-Process $exe -ArgumentList '/ErrorStdOut=UTF-8','/Validate','.runtime\DiscoverNulea.ahk' -Wait
   Start-Process $exe -ArgumentList '/ErrorStdOut=UTF-8','/Validate','.runtime\NuleaMapper.ahk' -Wait
   ```

## Pull-request scope

- Use one pull request per logical change.
- Explain user-visible behavior and input-safety implications.
- Include manual test notes for Windows-specific changes.
- Do not add downloaded executables, archives, personal device identifiers, telemetry, or network services.
- Never weaken the emergency-exit path or enable startup integration by default.

Maintainers may close changes that broaden device access, introduce silent installation, or reduce recovery options.
