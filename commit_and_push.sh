#!/bin/zsh

# Enable nullglob to prevent "no matches found" errors
setopt nullglob

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
WORKSPACE="/Users/amisharawat/workspace"
GITHUB_USERNAME="AmishaRawat1810"
MAX_DEPTH=3  # Maximum depth to search for git repos

# Arrays to store results
declare -a NO_GIT_REPOS=()
declare -a UP_TO_DATE=()
declare -a COMMITTED_AND_PUSHED=()
declare -a BRANCH_SWITCHED=()
declare -a FAILED_OPERATIONS=()
declare -a SUBDIRS_WITH_GIT=()

# Function to ask for confirmation
ask_confirmation() {
    local prompt=$1
    local response
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    while true; do
        echo -e "${YELLOW}$prompt${NC}"
        read -r response
        case "$response" in
            [Yy][Ee][Ss]|[Yy])
                return 0
                ;;
            [Nn][Oo]|[Nn])
                return 1
                ;;
            *)
                echo -e "${RED}Please answer 'yes' or 'no' (y/n)${NC}"
                ;;
        esac
    done
}

# Function to get file size in human readable format
format_file_size() {
    local size=$1
    if (( size < 1024 )); then
        echo "${size}B"
    elif (( size < 1048576 )); then
        echo "$((size / 1024))KB"
    else
        echo "$((size / 1048576))MB"
    fi
}

# Function to show changed files summary
show_changed_files_summary() {
    local repo_dir=$1
    
    echo -e "\n${MAGENTA}📋 CHANGED FILES SUMMARY:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local changed_files=$(cd "$repo_dir" && git status -s 2>/dev/null)
    
    if [[ -z "$changed_files" ]]; then
        echo -e "${YELLOW}No changes detected${NC}"
        return 1
    fi
    
    local file_count=$(echo "$changed_files" | wc -l)
    echo -e "${GREEN}Total changed files: ${file_count}${NC}\n"
    
    # Count by status
    local modified=$(echo "$changed_files" | grep "^ M" | wc -l)
    local added=$(echo "$changed_files" | grep "^A " | wc -l)
    local deleted=$(echo "$changed_files" | grep "^ D" | wc -l)
    local untracked=$(echo "$changed_files" | grep "^??" | wc -l)
    
    if (( modified > 0 )); then
        echo -e "  ${YELLOW}Modified:${NC}   $modified files"
    fi
    if (( added > 0 )); then
        echo -e "  ${GREEN}Added:${NC}       $added files"
    fi
    if (( deleted > 0 )); then
        echo -e "  ${RED}Deleted:${NC}      $deleted files"
    fi
    if (( untracked > 0 )); then
        echo -e "  ${BLUE}Untracked:${NC}    $untracked files"
    fi
    
    echo -e "\n${CYAN}File List (First 20):${NC}\n"
    # Show file list with status (limit to 20)
    echo "$changed_files" | head -20 | while read -r line; do
        local change_status="${line:0:2}"
        local filename="${line:3}"
        
        # Skip node_modules
        if [[ "$filename" == *"node_modules"* ]]; then
            continue
        fi
        
        case "$change_status" in
            "M ")  echo -e "  ${YELLOW}[MOD]${NC} $filename" ;;
            "A ")  echo -e "  ${GREEN}[ADD]${NC} $filename" ;;
            "D ")  echo -e "  ${RED}[DEL]${NC} $filename" ;;
            "??")  echo -e "  ${BLUE}[NEW]${NC} $filename" ;;
            *)     echo -e "  $change_status         $filename" ;;
        esac
    done
    
    if (( file_count > 20 )); then
        echo -e "\n${YELLOW}... and $(( file_count - 20 )) more files${NC}"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check if directory has subdirectories with git repos
has_subdirectory_git_repos() {
    local dir=$1
    local depth=$2
    
    if (( depth > MAX_DEPTH )); then
        return 1
    fi
    
    # Check if directory exists
    if [[ ! -d "$dir" ]]; then
        return 1
    fi
    
    local found=0
    
    # Use find command instead of glob to avoid errors
    while IFS= read -r subdir; do
        if [[ -d "$subdir/.git" ]] && [[ "$subdir" != "$dir/.git" ]]; then
            found=1
            break
        fi
    done < <(find "$dir" -maxdepth 1 -type d -not -name "." 2>/dev/null)
    
    return $(( 1 - found ))
}

# Function to process a git repository
process_git_repo() {
    local repo_dir=$1
    local repo_name=$(basename "$repo_dir")
    
    echo -e "\n${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║ Repository: $repo_name${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    
    cd "$repo_dir" || return 1
    
    # Get current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    
    echo -e "${BLUE}Path:${NC}      $repo_dir"
    echo -e "${BLUE}Branch:${NC}    $current_branch"
    
    # Check for uncommitted changes
    local changes=$(git status -s 2>/dev/null | grep -v "^??" | grep -v "node_modules")
    
    if [[ -z "$changes" ]]; then
        echo -e "${GREEN}Status:${NC}    ✓ Up to date (no uncommitted changes)${NC}"
        UP_TO_DATE+=("$repo_name")
        
        # Check if on master branch
        if [[ "$current_branch" == "master" ]]; then
            echo -e "${YELLOW}Branch:${NC}    On master branch${NC}"
            if ask_confirmation "Do you want to switch to main branch and push? (yes/no): "; then
                if git checkout -b main 2>/dev/null || git checkout main 2>/dev/null; then
                    if git push -u origin main 2>/dev/null; then
                        echo -e "${GREEN}✓ Switched to main and pushed${NC}"
                        BRANCH_SWITCHED+=("$repo_name (master→main)")
                    else
                        echo -e "${RED}✗ Failed to push to main${NC}"
                        FAILED_OPERATIONS+=("$repo_name (push to main failed)")
                    fi
                fi
            fi
        fi
        return 0
    fi
    
    echo -e "${YELLOW}Status:${NC}    ⚠ Has uncommitted changes${NC}"
    
    # Show changed files
    show_changed_files_summary "$repo_dir"
    
    # Ask for commit confirmation
    echo -e "\n${MAGENTA}═══════════════════════════════════════${NC}"
    echo -e "${MAGENTA}⚠️  COMMIT CONFIRMATION REQUIRED${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}Repository:${NC}    $repo_name"
    echo -e "${BLUE}Current Branch:${NC} $current_branch"
    
    local commit_message="chore: commit changes - $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BLUE}Commit Message:${NC}"
    echo -e "  $commit_message"
    echo -e "${MAGENTA}═══════════════════════════════════════${NC}"
    
    if ! ask_confirmation "📨 Do you want to commit these changes? (yes/no): "; then
        echo -e "${YELLOW}⊘ Commit skipped for $repo_name${NC}"
        return 0
    fi
    
    # Stage all changes (excluding node_modules)
    echo -e "${BLUE}Staging changes (excluding node_modules)...${NC}"
    git add -A
    git reset HEAD "node_modules" 2>/dev/null
    git reset HEAD "**/node_modules" 2>/dev/null
    
    # Commit
    echo -e "${BLUE}Committing...${NC}"
    if git commit -m "$commit_message"; then
        echo -e "${GREEN}✓ Changes committed${NC}"
    else
        echo -e "${RED}✗ Commit failed${NC}"
        FAILED_OPERATIONS+=("$repo_name (commit failed)")
        return 1
    fi
    
    # Check if need to switch branch
    if [[ "$current_branch" == "master" ]]; then
        echo -e "\n${YELLOW}⚠️  Repository is on 'master' branch${NC}"
        if ask_confirmation "Do you want to switch to 'main' branch? (yes/no): "; then
            if git checkout -b main 2>/dev/null || git checkout main 2>/dev/null; then
                current_branch="main"
                echo -e "${GREEN}✓ Switched to main${NC}"
                BRANCH_SWITCHED+=("$repo_name (master→main)")
            fi
        fi
    fi
    
    # Push to remote
    echo -e "\n${MAGENTA}🚀 PUSH TO GITHUB${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Branch:${NC}    $current_branch"
    
    if ! ask_confirmation "Do you want to push to GitHub? (yes/no): "; then
        echo -e "${YELLOW}⊘ Push skipped for $repo_name${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Pushing to origin/$current_branch...${NC}"
    if git push -u origin "$current_branch"; then
        echo -e "${GREEN}✓ Successfully pushed to GitHub${NC}"
        COMMITTED_AND_PUSHED+=("$repo_name")
    else
        echo -e "${RED}✗ Push failed${NC}"
        FAILED_OPERATIONS+=("$repo_name (push failed)")
        return 1
    fi
    
    return 0
}

# Function to create a new git repository
create_git_repo() {
    local repo_dir=$1
    local repo_name=$(basename "$repo_dir")
    
    echo -e "\n${MAGENTA}🔧 CREATE GIT REPOSITORY${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Directory:${NC}      $repo_name"
    echo -e "${BLUE}Path:${NC}           $repo_dir"
    
    # Count files
    local file_count=$(find "$repo_dir" -type f ! -path '*/\.*' ! -path '*/node_modules/*' 2>/dev/null | wc -l)
    echo -e "${BLUE}Files:${NC}          $file_count"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if ! ask_confirmation "Do you want to initialize git in this directory? (yes/no): "; then
        echo -e "${YELLOW}⊘ Git initialization skipped${NC}"
        return 1
    fi
    
    cd "$repo_dir" || return 1
    
    # Initialize git repo
    echo -e "${BLUE}Initializing git repository...${NC}"
    git init
    git config user.name "Amisha Rawat"
    git config user.email "amisharawat05@outlook.com"  # Update with your email
    
    # Create .gitignore if it doesn't exist
    if [[ ! -f .gitignore ]]; then
        echo -e "${BLUE}Creating .gitignore...${NC}"
        cat > .gitignore << 'EOF'
# Dependencies
node_modules/
package-lock.json
yarn.lock

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Build
dist/
build/
*.log
EOF
        git add .gitignore
    fi
    
    # Stage files
    echo -e "${BLUE}Staging files...${NC}"
    git add -A
    git reset HEAD "node_modules" 2>/dev/null
    git reset HEAD "**/node_modules" 2>/dev/null
    
    # Initial commit
    local commit_message="chore: initial commit - $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BLUE}Creating initial commit...${NC}"
    
    if git commit -m "$commit_message"; then
        echo -e "${GREEN}✓ Initial commit created${NC}"
    else
        echo -e "${RED}✗ Commit failed${NC}"
        FAILED_OPERATIONS+=("$repo_name (initial commit failed)")
        return 1
    fi
    
    # Rename branch to main if it's master
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$current_branch" == "master" ]]; then
        git branch -m main
        current_branch="main"
    fi
    
    # Ask about creating remote
    if ask_confirmation "Do you want to create a repository on GitHub? (yes/no): "; then
        if command -v gh &> /dev/null; then
            echo -e "${BLUE}Creating GitHub repository...${NC}"
            if gh repo create "$repo_name" --public --source=. --remote=origin --yes 2>/dev/null; then
                echo -e "${GREEN}✓ GitHub repository created${NC}"
                
                # Push to remote
                if ask_confirmation "Do you want to push to GitHub? (yes/no): "; then
                    echo -e "${BLUE}Pushing to origin/$current_branch...${NC}"
                    if git push -u origin "$current_branch"; then
                        echo -e "${GREEN}✓ Successfully pushed to GitHub${NC}"
                        COMMITTED_AND_PUSHED+=("$repo_name (new repo)")
                        return 0
                    else
                        echo -e "${RED}✗ Push failed${NC}"
                        FAILED_OPERATIONS+=("$repo_name (push failed)")
                        return 1
                    fi
                fi
            else
                echo -e "${RED}✗ Failed to create GitHub repository${NC}"
                FAILED_OPERATIONS+=("$repo_name (GitHub creation failed)")
                return 1
            fi
        else
            echo -e "${YELLOW}⚠️  GitHub CLI (gh) not installed${NC}"
            echo -e "${YELLOW}Install with: brew install gh${NC}"
            NO_GIT_REPOS+=("$repo_name (git initialized, needs GitHub setup)")
            return 0
        fi
    else
        echo -e "${YELLOW}⊘ GitHub repository creation skipped${NC}"
        NO_GIT_REPOS+=("$repo_name (git initialized, no remote)")
        return 0
    fi
}

# Function to scan directory for git repos
scan_workspace() {
    echo -e "\n${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║   Scanning Workspace for Git Repos     ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    
    local directories=(
        "advent-of-code"
        "array"
        "assignments"
        "bag-of-goodies"
        "cat-example"
        "classes"
        "codecrafters-shell-javascript"
        "db-exercisee"
        "fetchAndJson"
        "file-methods"
        "games"
        "generator"
        "git-demo"
        "java"
        "jayanth"
        "js-practice"
        "l-system"
        "lisp-not-lips"
        "load-testing-fun"
        "load-testing-fun-mine"
        "maths"
        "mvc-example"
        "networking"
        "objects"
        "others-projects"
        "p5-js"
        "pair_project"
        "promises"
        "react"
        "readable-writeable"
        "recursion"
        "risk-imperium"
        "shell-cmd"
        "spike-work"
        "svg"
        "til-AmishaRawat1810"
        "typescript"
        "vibe-wtih-ai"
        "vis-secret-plotter"
        "web-components"
        "web-sockets"
        "websites"
    )
    
    local total=${#directories[@]}
    local processed=0
    
    for dir in "${directories[@]}"; do
        local full_path="$WORKSPACE/$dir"
        
        if [[ ! -d "$full_path" ]]; then
            continue
        fi
        
        ((processed++))
        echo -e "\n${CYAN}[${processed}/${total}]${NC} Processing: $dir"
        
        # Check if directory has subdirectories with git repos (like assignments)
        if has_subdirectory_git_repos "$full_path" 0; then
            echo -e "${YELLOW}   ℹ️  This directory has sub-directories with git repos${NC}"
            SUBDIRS_WITH_GIT+=("$dir")
            
            # Ask if user wants to process subdirectories
            if ask_confirmation "   Process sub-directories? (yes/no): "; then
                while IFS= read -r subdir; do
                    # Skip the parent directory itself
                    if [[ "$subdir" != "$full_path" ]] && [[ -d "$subdir/.git" ]]; then
                        process_git_repo "$subdir"
                    fi
                done < <(find "$full_path" -maxdepth 1 -type d -not -name "." -not -name ".git" 2>/dev/null)
            fi
            # Skip further processing for this directory since it has subdirectories
            continue
        elif [[ -d "$full_path/.git" ]]; then
            # It's a git repository
            process_git_repo "$full_path"
        else
            # No git repo found
            echo -e "${YELLOW}   ⚠️  No git repository found${NC}"
            if ask_confirmation "   Do you want to initialize git? (yes/no): "; then
                create_git_repo "$full_path"
            else
                NO_GIT_REPOS+=("$dir")
            fi
        fi
    done
}

# Function to display summary report
display_summary() {
    echo -e "\n\n${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║          FINAL SUMMARY REPORT          ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    
    # Committed and Pushed
    if (( ${#COMMITTED_AND_PUSHED[@]} > 0 )); then
        echo -e "\n${GREEN}✓ COMMITTED AND PUSHED (${#COMMITTED_AND_PUSHED[@]}):${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for repo in "${COMMITTED_AND_PUSHED[@]}"; do
            echo -e "  ${GREEN}✓${NC} $repo"
        done
    fi
    
    # Up to Date
    if (( ${#UP_TO_DATE[@]} > 0 )); then
        echo -e "\n${BLUE}✓ UP TO DATE (${#UP_TO_DATE[@]}):${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for repo in "${UP_TO_DATE[@]}"; do
            echo -e "  ${BLUE}✓${NC} $repo"
        done
    fi
    
    # Branch Switched
    if (( ${#BRANCH_SWITCHED[@]} > 0 )); then
        echo -e "\n${MAGENTA}⇄ BRANCH SWITCHED (${#BRANCH_SWITCHED[@]}):${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for repo in "${BRANCH_SWITCHED[@]}"; do
            echo -e "  ${MAGENTA}⇄${NC} $repo"
        done
    fi
    
    # Subdirectories with Git
    if (( ${#SUBDIRS_WITH_GIT[@]} > 0 )); then
        echo -e "\n${YELLOW}📁 DIRECTORIES WITH SUB-GIT-REPOS (${#SUBDIRS_WITH_GIT[@]}):${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for repo in "${SUBDIRS_WITH_GIT[@]}"; do
            echo -e "  ${YELLOW}📁${NC} $repo"
        done
    fi
    
    # No Git Repos
    if (( ${#NO_GIT_REPOS[@]} > 0 )); then
        echo -e "\n${RED}✗ NO GIT REPOSITORY (${#NO_GIT_REPOS[@]}):${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for repo in "${NO_GIT_REPOS[@]}"; do
            echo -e "  ${RED}✗${NC} $repo"
        done
    fi
    
    # Failed Operations
    if (( ${#FAILED_OPERATIONS[@]} > 0 )); then
        echo -e "\n${RED}⚠️  FAILED OPERATIONS (${#FAILED_OPERATIONS[@]}):${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for operation in "${FAILED_OPERATIONS[@]}"; do
            echo -e "  ${RED}⚠️${NC}  $operation"
        done
    fi
    
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Process completed!${NC}\n"
}

# Main execution
main() {
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║   Workspace Git Manager                ║${NC}"
    echo -e "${MAGENTA}║   Interactive Mode Enabled             ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        echo -e "\n${YELLOW}⚠️  Warning: GitHub CLI (gh) not found.${NC}"
        echo -e "${YELLOW}   Install with: brew install gh${NC}"
        echo -e "${YELLOW}   Some features may be limited without it.${NC}"
    fi
    
    # Scan workspace
    scan_workspace
    
    # Display summary
    display_summary
}

# Run main function
main