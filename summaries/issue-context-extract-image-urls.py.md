# issue-context/scripts/extract-image-urls.py

A Python utility that extracts image URLs from GitHub issue JSON fed on stdin.

Behavior:

- Reads issue body and comments from JSON input.
- Finds markdown image links `![...](https://...)` and GitHub upload URLs.
- Deduplicates URLs while preserving order.
- Prints one URL per line.

Used by the issue-context skill to identify visuals referenced in issue text so
they can be downloaded and reviewed.
