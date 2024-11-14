import os
import re
import chardet

def detect_encoding(file_path, bytes_to_read=100000):
    """
    Detect the file encoding by reading the first `bytes_to_read` bytes.
    Increase `bytes_to_read` for more accurate detection.
    """
    with open(file_path, 'rb') as f:
        raw_data = f.read(bytes_to_read)
        result = chardet.detect(raw_data)
        return result['encoding']

def write_file_with_line_numbers(input_file_path, output_file_path, encoding):
    """
    Write a file with line numbers to the output.
    Skip if the output file already exists.
    """
    if os.path.exists(output_file_path):
        print(f"File {output_file_path} already exists. Skipping generation.")
        return

    try:
        with open(input_file_path, 'r', encoding=encoding) as infile, open(output_file_path, 'w', encoding='utf-8') as outfile:
            for line_number, line in enumerate(infile, 1):
                outfile.write(f"{line_number}: {line}")
        print(f"Generated file with line numbers: {output_file_path}")
    except UnicodeDecodeError as e:
        print(f"UnicodeDecodeError while writing line numbers: {e}. Please check the detected encoding manually.")

def extract_desync_context_from_line_numbered_file(line_numbered_file, desync_index, context_lines=10):
    """
    Extract the desync context from the line-numbered file.
    """
    with open(line_numbered_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Extract context around the desync index
    start_context = max(0, desync_index - context_lines - 1)  # Subtract 1 for 0-based indexing
    end_context = min(len(lines), desync_index + context_lines)

    return lines[start_context:end_context]

def diff_logs_with_shift_and_context(file1_path, file2_path, file1_numbered_path, file2_numbered_path, output_diff_path, max_shift=5, context_lines=10, encoding1=None, encoding2=None):
    if not encoding1:
        encoding1 = detect_encoding(file1_path)
    if not encoding2:
        encoding2 = detect_encoding(file2_path)
    
    if encoding1 != encoding2:
        print(f"Error: Encodings do not match for {file1_path} and {file2_path}. Skipping comparison.")
        return
    
    print(f"Using encoding for {file1_path}: {encoding1}")
    print(f"Using encoding for {file2_path}: {encoding2}")

    try:
        with open(file1_path, 'r', encoding=encoding1) as file1, open(file2_path, 'r', encoding=encoding2) as file2, open(output_diff_path, 'w', encoding='utf-8') as diff_file:
            file1_lines = file1.readlines()
            file2_lines = file2.readlines()

            i = 0
            j = 0
            desyncs_detected = 0
            desync_contexts = []  # Store desync contexts here

            while i < len(file1_lines) and j < len(file2_lines):
                if file1_lines[i] != file2_lines[j]:
                    # Desync detected, extract context from line-numbered files
                    file1_context = extract_desync_context_from_line_numbered_file(file1_numbered_path, i + 1, context_lines)
                    file2_context = extract_desync_context_from_line_numbered_file(file2_numbered_path, j + 1, context_lines)

                    desync_contexts.append({
                        "file1_context": file1_context,
                        "file2_context": file2_context,
                        "desync_index": (i + 1, j + 1)  # 1-based line numbers
                    })

                    desyncs_detected += 1

                    # Try shifting to find a match and realign
                    matched = False
                    for shift in range(1, max_shift + 1):
                        if (i + shift < len(file1_lines) and file1_lines[i + shift] == file2_lines[j]):
                            i += shift
                            matched = True
                            break
                        elif (j + shift < len(file2_lines) and file1_lines[i] == file2_lines[j + shift]):
                            j += shift
                            matched = True
                            break

                    if not matched:
                        i += 1
                        j += 1
                else:
                    i += 1
                    j += 1

            # Output the desync contexts
            for context in desync_contexts:
                file1_context = context['file1_context']
                file2_context = context['file2_context']
                desync_index = context['desync_index']

                diff_file.write(f"Desync at line {desync_index[0]} in file 1 and line {desync_index[1]} in file 2:\n")
                diff_file.write("\nFile 1 context:\n")
                diff_file.writelines(file1_context)
                diff_file.write("\nFile 2 context:\n")
                diff_file.writelines(file2_context)
                diff_file.write("\n" + "="*40 + "\n")  # Separator for better readability

            print(f"Differences with context written for {file1_path} vs {file2_path} in {output_diff_path}")

    except UnicodeDecodeError as e:
        print(f"UnicodeDecodeError: {e}. Please check the detected encoding manually.")

def get_frame_number(filename):
    match = re.search(r'Frame(\d+)', filename)
    return match.group(1) if match else None

def compare_folder_logs_with_context_and_line_numbers(folder_path, encoding=None):
    files = os.listdir(folder_path)
    
    # Group files by frame number
    frame_groups = {}
    for file in files:
        frame_num = get_frame_number(file)
        if frame_num:
            if frame_num not in frame_groups:
                frame_groups[frame_num] = []
            frame_groups[frame_num].append(os.path.join(folder_path, file))

    # Compare files in each frame group
    for frame, files in frame_groups.items():
        if len(files) == 2:
            file1, file2 = files
            output_diff = os.path.join(folder_path, f"diff_Frame{frame}.txt")

            # Create files with line numbers, skipping if they already exist
            file1_with_line_numbers = os.path.join(folder_path, f"file1_Frame{frame}_with_line_numbers.txt")
            file2_with_line_numbers = os.path.join(folder_path, f"file2_Frame{frame}_with_line_numbers.txt")
            write_file_with_line_numbers(file1, file1_with_line_numbers, encoding)
            write_file_with_line_numbers(file2, file2_with_line_numbers, encoding)

            # Perform diff and context check, grabbing context from line-numbered files
            diff_logs_with_shift_and_context(file1, file2, file1_with_line_numbers, file2_with_line_numbers, output_diff, encoding1=encoding, encoding2=encoding)
        else:
            print(f"Frame {frame} does not have exactly 2 files, skipping...")

def select_folder_and_compare_with_context_and_line_numbers():
    from tkinter import Tk, filedialog
    root = Tk()
    root.withdraw()  # Hide the main tkinter window
    
    folder_selected = filedialog.askdirectory(title="Select the folder containing log files")
    
    if folder_selected:
        print(f"Folder selected: {folder_selected}")

        # Provide encoding options to the user
        print("Select an encoding option:")
        print("1. gbk")
        print("2. mac_roman")
        print("3. utf-8")
        print("4. Auto-detect encoding")

        user_choice = input("Enter the number of your choice (1-4): ").strip()

        if user_choice == '1':
            manual_encoding = 'gbk'
        elif user_choice == '2':
            manual_encoding = 'mac_roman'
        elif user_choice == '3':
            manual_encoding = 'utf-8'
        elif user_choice == '4':
            manual_encoding = None  # Trigger auto-detection
        else:
            print("Invalid choice. Defaulting to auto-detection.")
            manual_encoding = None

        if manual_encoding:
            print(f"Manual encoding selected: {manual_encoding}")
            compare_folder_logs_with_context_and_line_numbers(folder_selected, encoding=manual_encoding)
        else:
            print("Auto-detecting encoding...")
            compare_folder_logs_with_context_and_line_numbers(folder_selected)
    else:
        print("No folder selected, exiting.")

# Run the folder selection and comparison
if __name__ == "__main__":
    select_folder_and_compare_with_context_and_line_numbers()
