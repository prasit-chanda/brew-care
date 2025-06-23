 🛠️  Homebrew Maintenance Script
 
    Script    : brew-maintenance.zsh
    Purpose   : Safely automates Homebrew maintenance by checking, updating, 
                upgrading, diagnosing, fixing issues, cleaning up old files, and 
                reporting freed disk space on macOS.
    Author    : Prasit Chanda
    Platform  : macOS

 📄 Overview:
 
    The latest update to the brew-maintenance.zsh script introduces several improvements and new features. Output formatting and color coding have been enhanced for better readability, making it easier to follow each maintenance step. The script now performs more robust checks for essential dependencies like Homebrew and Xcode Command Line Tools, ensuring your environment is ready before proceeding. Steps have been added to fix permissions for Homebrew directories, detect and repair broken or unlinked formulae, and relink critical tools such as brew, curl, git, python3, ruby, and node. After cleaning up old versions to free disk space, the script measures and reports the amount of disk space freed. All actions and results are logged to a timestamped log file for transparency, and minor bug fixes and code cleanup have been applied throughout.

 ✅ Key Features:
 
    Key features of the brew-maintenance.zsh script include automatic checks for Homebrew and Xcode dependencies, fixing permissions, diagnosing issues, updating and upgrading all formulae and casks, repairing broken or unlinked packages, relinking critical tools, and cleaning up outdated files to free disk space. The script provides clear, color-coded output, measures and reports disk space freed, and logs all actions to a timestamped file for easy review.
        
 📁 Output
 
    The output of the brew-maintenance.zsh script provides a detailed, step-by-step summary of the Homebrew maintenance process on your Mac. It starts by displaying a decorative header and the current date, followed by system and Homebrew configuration details. For each maintenance stage—such as fixing permissions, diagnosing issues, updating and upgrading formulae and casks, fixing broken links, relinking critical tools, and cleaning up old versions—the script prints clear, color-coded messages indicating progress and results. After all tasks, it reports the amount of disk space freed (or notes if there was no change), confirms completion, and shows the path to a timestamped log file containing all actions and results. The output is both visually formatted for easy reading in the terminal and saved to a log file for future reference.

 💡 Instructions

    1. Save it to workspace, e.g., brew-maintenance.zsh
    2. Make it executable by chmod +x brew-maintenance.zsh
    3. Run it by ./brew-maintenance.zsh
    4. Logs are generated within execution folder