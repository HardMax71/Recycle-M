import os

# Get the current script's filename
current_script = os.path.basename(__file__)

# Initialize a list to store the contents of each file
all_contents = []

# Get the current directory
current_dir = os.path.dirname(os.path.abspath(__file__))

# Loop through all files in the current directory
for filename in os.listdir(current_dir):
    # Skip directories and the current script
    if filename == current_script or os.path.isdir(os.path.join(current_dir, filename)):
        continue

    # Read and store the contents of each file
    with open(os.path.join(current_dir, filename), 'r', encoding='utf-8') as file:
        all_contents.append(file.read())

# Join the contents with double newline separator
combined_contents = '\n\n'.join(all_contents)

# Write the combined contents to a new text file
with open(os.path.join(current_dir, '_combined.txt'), 'w', encoding='utf-8') as output_file:
    output_file.write(combined_contents)

print(f"Contents of all files (except {current_script}) have been combined into 'combined.txt'")
