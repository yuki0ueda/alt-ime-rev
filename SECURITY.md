# Security Policy

## Reporting a Vulnerability

If you believe you have found a security vulnerability in alt-ime-rev,
please report it privately so it can be triaged before public disclosure.

**Preferred channel: GitHub Private Vulnerability Reporting**

Open a private report from the repository's
[Security tab](https://github.com/yuki0ueda/alt-ime-rev/security/advisories/new).
This routes the report to the maintainer through GitHub's coordinated
disclosure flow. Please **do not** open a public issue for security
vulnerabilities.

When reporting, please include:

- A clear description of the issue and its potential impact
- Steps to reproduce (a minimal `.ahk` snippet or hotkey sequence is ideal)
- The version of alt-ime-rev (tag or commit SHA) and the Windows version
  on which you reproduced it
- Any relevant log output from `ime_debug.log`

You should expect an initial acknowledgement within a few days. Resolution
time varies with severity; the maintainer will keep you updated through the
private advisory thread.

## Scope

This project is a small, single-developer AutoHotkey v2 utility. The
realistic threat model is limited (no network I/O, no privileged
operations, no persistent state beyond `ime_debug.log` and the .exe
itself), but reports about any of the following are welcome:

- Code execution paths via crafted input or window titles
- DLL injection / hijacking risks introduced by the script
- Unintended privilege escalation through the compiled .exe
- Issues with the GitHub Actions release pipeline that could allow
  tampering with published artifacts

## Out of Scope

- Bugs in upstream AutoHotkey v2 itself (please report those to
  [AutoHotkey/AutoHotkey](https://github.com/AutoHotkey/AutoHotkey))
- Issues that depend on an attacker who already has full local access
  to the user's Windows session
