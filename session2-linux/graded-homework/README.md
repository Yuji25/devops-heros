# Lecture 2 Graded Homework

## Task 1: Soft Link vs. Hard Link

### My understanding : 
* **Inode:** Think of an **inode** as the actual memory ID/house where your data lives. The file name is just the nameplate on the door.
* **Hard Link:** A **second nameplate** pointing to the **exact same house (same inode)**. If you delete the original file, the data is still safe because the hard link still points to that house.
* **Soft Link (Symlink):** Just a **shortcut** (like a Windows shortcut) that points to the *original file name*. If you delete the original file, the shortcut breaks (dangling link).

### Commands I practiced : 
```bash
# 0. Directory for this task
mkdir task1 && cd task1

# 1. Create a dummy file
echo "Hello DevOps" > original.txt

# 2. Create a Hard Link (ln <source> <link_name>)
ln original.txt hardlink.txt

# 3. Create a Soft Link (ln -s <source> <link_name>)
ln -s original.txt softlink.txt

# 4. Check the inodes (notice original and hardlink share the exact same number!)
ls -li

# 5. Test deleting the original file
rm original.txt

# Check what happens:
cat hardlink.txt   # Still prints "Hello DevOps" (Data is safe!)
cat softlink.txt   # Error: No such file or directory (Shortcut broke!)
```

### Quick Comparison Table (For Interview)
| Feature | Hard Link | Soft Link (Symbolic) |
| :--- | :--- | :--- |
| **What it is** | Direct pointer to the inode (actual data). | Shortcut pointing to the file path. |
| **Command** | `ln file link` | `ln -s file link` |
| **If original is deleted** | Data stays intact. | Link breaks completely. |
| **Across different disks/partitions**| No | Yes |
| **Can link directories** | No | Yes |

## Task 2: `adduser` vs. `useradd`

### My understanding :
* **`useradd` (Low-level / Raw):** Built into all Linux systems. It creates the user and does nothing else. It won't create a home directory or ask for a password unless you pass lots of flags.
* **`adduser` (Friendly / Recommended on Ubuntu):** An interactive script. It guides you step-by-step: asks for a password, creates the home folder (`/home/username`), and sets up defaults automatically.

> **Ubuntu Preference:** Always prefer **`adduser`** for manual human use because it sets up everything cleanly without missing steps.

### Commands I practiced :
```bash
# 1. Create a test user interactively (Recommended way)
sudo adduser testdevops

# 2. Add this user to sudo (admin) group
sudo usermod -aG sudo testdevops

# 3. Verify user was created with home directory and ID
id testdevops
ls -ld /home/testdevops

# 4. Clean up / delete user and their home directory when done
sudo userdel -r testdevops
```


## Task 3: `journalctl` (System & Service Logs)

### My understanding :
`journalctl` is like the **black-box flight recorder** for Linux. It collects and displays logs from the operating system kernel and background services (like Docker, Nginx, or SSH).

### Commands I practiced :
```bash
# 1. View recent 20 logs for SSH service
sudo journalctl -u ssh -n 20 --no-pager

# 2. View live logs in real-time (press Ctrl+C to exit)
sudo journalctl -u ssh -f

# 3. View system errors only (priority = error)
sudo journalctl -p err -n 10 --no-pager

# 4. View logs from today's boot only
sudo journalctl -b
```
* `-u <service>`: Target a specific unit/service.
* `-n <number>`: Number of lines to show.
* `-f`: Follow logs live (just like `tail -f`).
* `--no-pager`: Prints directly to terminal without entering scroll mode.



## Task 4: Important Cheat Sheet Commands to Practice
```bash
# 1. Disk space check (Human-readable)
df -h

# 2. RAM / Memory check
free -h

# 3. Check active listening ports & sockets (ss is modern netstat)
ss -tuln

# 4. View your system IP address details
ip a
```
