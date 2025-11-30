import os
import re

def update_screen_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Define replacements
    replacements = [
        # EdgeInsets
        (r'const EdgeInsets\.all\((\d+)\)', r'EdgeInsets.all(MediaQuery.of(context).size.width * \1 / 400)'),
        (r'EdgeInsets\.all\((\d+)\)', r'EdgeInsets.all(MediaQuery.of(context).size.width * \1 / 400)'),
        
        # SizedBox height
        (r'const SizedBox\(height: (\d+)\)', r'SizedBox(height: MediaQuery.of(context).size.height * \1 / 800)'),
        (r'SizedBox\(height: (\d+)\)', r'SizedBox(height: MediaQuery.of(context).size.height * \1 / 800)'),
        
        # SizedBox width
        (r'const SizedBox\(width: (\d+)\)', r'SizedBox(width: MediaQuery.of(context).size.width * \1 / 400)'),
        (r'SizedBox\(width: (\d+)\)', r'SizedBox(width: MediaQuery.of(context).size.width * \1 / 400)'),
        
        # Font sizes
        (r'fontSize: (\d+)', r'fontSize: MediaQuery.of(context).size.width * \1 / 400'),
        
        # Icon sizes
        (r'size: (\d+)', r'size: MediaQuery.of(context).size.width * \1 / 400'),
        
        # BorderRadius
        (r'BorderRadius\.circular\((\d+)\)', r'BorderRadius.circular(MediaQuery.of(context).size.width * \1 / 400)'),
        
        # Container dimensions
        (r'width: (\d+)', r'width: MediaQuery.of(context).size.width * \1 / 400'),
        (r'height: (\d+)', r'height: MediaQuery.of(context).size.height * \1 / 800'),
    ]
    
    # Apply replacements
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Updated: {os.path.basename(file_path)}")

# Update all dart files in screens directory
screens_dir = r'lib\screens'
for file in os.listdir(screens_dir):
    if file.endswith('.dart'):
        file_path = os.path.join(screens_dir, file)
        update_screen_file(file_path)

print("All screens updated!")