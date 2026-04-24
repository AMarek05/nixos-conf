# TODO: Extract script blocks into Bash/ subdirectory

## Goal
- Extract inline  from each .nix tool file (except write.nix and _template.nix)
- Put each script body into 
- Replace the inline script with 

## Files to process
- [x] delete-file.nix
- [x] forge-tool.nix
- [x] gh.nix
- [x] git-agent.nix
- [x] list-dir.nix
- [x] patch-file.nix
- [x] read-file.nix
- [x] search-files.nix
- [x] sed-inplace.nix

## Steps
1. Create Bash/ directory
2. Write each script body as Bash/<name>.sh
3. Update each .nix to use builtins.readFile
4. Verify with git diff
