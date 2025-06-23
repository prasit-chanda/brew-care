 🛠️  macOS Cleanup Script
 
    Script    : clean-mac.zsh
    Purpose   : Safely cleans unused system/user cache, logs, temp files, empties 
                trash, clears Homebrew leftovers, and reports space freed
    Author    : Prasit Chanda
    Platform  : macOS

 📄 Overview:
 
    The clean-mac.zsh script is a comprehensive macOS maintenance tool designed to safely clean up system 
    and user cache, logs, temporary files, old downloads, and trash. It also performs Homebrew cleanup, checks 
    system dependencies, and reports the amount of disk space freed. The script helps improve system performance, 
    free up storage, and maintain a clutter-free Mac environment, while providing detailed logs and system 
    information for transparency and troubleshooting.

 ✅ Key Features:
 
    The key features of clean-mac.zsh include comprehensive system maintenance and cleanup for macOS. 
    It displays detailed system information such as OS version, hardware specs, and network details. 
    The script safely cleans user and system caches, removes old logs, empties Trash, deletes temporary 
    files, and clears out old downloads to free up disk space. It also performs Homebrew cleanup, checks 
    for required dependencies, and can attempt to purge inactive memory. Throughout its execution, 
    the script provides clear, color-coded, and formatted output for each step, tracks execution time, 
    and logs all actions and results to a timestamped log file for easy review and transparency.
        
 📁 Output
 
    The output of the clean-mac.zsh script provides a clear, step-by-step summary of all maintenance 
    actions performed on your Mac. It begins by displaying detailed system information, including hardware 
    specs, OS version, network details, and uptime. As the script runs, it shows formatted and color-coded 
    messages for each cleanup stage—such as clearing caches, logs, temporary files, downloads, and 
    Trash—indicating what was cleaned, skipped, or already tidy. It also reports on Homebrew cleanup and 
    memory purging if available. At the end, the script summarizes the total disk space freed and provides 
    the path to a timestamped log file containing all actions and results, ensuring transparency and easy 
    review of the maintenance session.

 💡 Instructions

    1. Save it to workspace, e.g., clean-mac.zsh
    2. Make it executable by chmod +x clean-mac.zsh
    3. Run it by ./clean-mac.zsh
    4. Logs are generated within execution folder
