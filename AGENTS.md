# OpenCode Agent Guidelines

This document provides essential guidelines for OpenCode agents working within this repository. Adhering to these principles will help maintain consistency, efficiency, and safety.

## Core Mandates

- **Conventions:** Rigorously adhere to existing project conventions when reading or modifying code. Analyze surrounding code, tests, and configuration first.
- **Libraries/Frameworks:** NEVER assume a library/framework is available or appropriate. Verify its established usage within the project (check imports, configuration files like `package.json`, `Cargo.toml`, `requirements.txt`, `build.gradle`, etc., or observe neighboring files) before employing it.
- **Style & Structure:** Mimic the style (formatting, naming), structure, framework choices, typing, and architectural patterns of existing code in the project.
- **Idiomatic Changes:** When editing, understand the local context (imports, functions/classes) to ensure changes integrate naturally and idiomatically.
- **Comments:** Add code comments sparingly, focusing on *why* something is done, especially for complex logic. Do not edit comments separate from your code changes.
- **Proactiveness:** Fulfill requests thoroughly, including reasonable, directly implied follow-up actions.
- **Confirm Ambiguity/Expansion:** Do not take significant actions beyond the clear scope of the request without confirming with the user.

## File System Operations

- **Absolute Paths:** Always use absolute paths for file system tools (`read`, `write`, `edit`, `bash` with `workdir`).
- **Do Not Revert Changes:** Do not revert changes unless explicitly asked by the user or if they resulted in an error.

## Tool Usage

- **File Search:** Use `glob` (NOT `find` or `ls`) for file pattern matching.
- **Content Search:** Use `grep` (NOT `grep` or `rg`) for content searching.
- **Read Files:** Use `read` (NOT `cat`/`head`/`tail`) for reading file contents.
- **Edit Files:** Use `edit` (NOT `sed`/`awk`) for modifying file contents.
- **Write Files:** Use `write` (NOT `echo >`/`cat <<EOF`) for creating or overwriting files.
- **Bash Commands:** Explain commands that modify the file system or codebase before execution.
- **Parallelism:** Execute multiple independent tool calls in parallel when feasible.
- **Background Processes:** Use background processes (e.g., `&`) for commands that are unlikely to stop on their own.

## Verification

- **Linting, Type-checking, Testing:** After making code changes, execute project-specific build, linting, and type-checking commands (e.g., `tsc`, `npm run lint`, `ruff check .`) to ensure code quality and adherence to standards. Always run relevant tests.
