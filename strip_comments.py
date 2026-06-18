import os

def clean_dart_comments(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()

                    lines = content.split('\n')
                    new_lines = []
                    for line in lines:
                        stripped = line.strip()
                        # Remove basic // comments, keeping docstrings (///) and URLs/ignore rules
                        if stripped.startswith('//') and not stripped.startswith('///') and 'http://' not in stripped and 'https://' not in stripped and not stripped.startswith('// ignore') and not stripped.startswith('// TODO'):
                            continue 
                        new_lines.append(line)
                    
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write('\n'.join(new_lines))
                except Exception as e:
                    print(f"Failed on {filepath}: {e}")

if __name__ == '__main__':
    clean_dart_comments(r'c:\Users\Thokala Rakesh\OneDrive\Desktop\shaaka\shaaka\lib')
    print("Done stripping comments.")
