import os
import subprocess
import sys

def change_install_name(path):
    # Use otool to get the current install name
    result = subprocess.run(['otool', '-D', path], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error reading {path}: {result.stderr}")
        return

    current_install_name = result.stdout.split('\n')[1].strip()
    if current_install_name.startswith('/Users') or '/' not in current_install_name:
        # Construct the new install name
        lib_name = os.path.basename(current_install_name)
        new_install_name = f"@rpath/{lib_name}"

        # Use install_name_tool to change the install name
        result = subprocess.run(['install_name_tool', '-id', new_install_name, path], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"Updated {path} from {current_install_name} to {new_install_name}")
        else:
            print(f"Failed to update {path}: {result.stderr}")

def walk_and_update(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dylib'):
                full_path = os.path.join(root, file)
                change_install_name(full_path)

if __name__ == "__main__":
    directory_to_search = sys.argv[1]  # Set the path to the directory where the search should start
    walk_and_update(directory_to_search)
