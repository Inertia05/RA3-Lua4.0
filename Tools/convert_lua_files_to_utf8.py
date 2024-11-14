import os
import chardet  # Library for detecting file encoding
import tkinter as tk
from tkinter import filedialog



def detect_encoding(file_path):
    """
    Detects the encoding of a given file using chardet.
    
    Parameters:
    - file_path: The path to the file to be analyzed.
    
    Returns:
    - The detected encoding (if any), or 'unknown' if the encoding cannot be determined.
    """
    with open(file_path, 'rb') as file:
        raw_data = file.read()
        result = chardet.detect(raw_data)
        encoding = result['encoding']
        return encoding if encoding else 'unknown'

def convert_folder_to_utf8(folder_path, new_folder_name="converted_utf8"):
    """
    Converts all Lua files in a folder and its subfolders with detected encoding to UTF-8 
    and saves them to a new folder, preserving the folder structure.
    
    Prints the encoding when it is encountered for the first time, and reports files with unknown encoding.
    At the end, displays the total number of files processed and a count of files for each encoding.
    
    Parameters:
    - folder_path: The path to the folder containing the files.
    - new_folder_name: The name of the new folder where UTF-8 files will be saved.
    """
    # Dictionary to track encodings encountered
    encoding_counts = {}
    total_files_processed = 0
    
    # Create a new folder to store the converted files
    new_folder_path = os.path.join(folder_path, new_folder_name)
    os.makedirs(new_folder_path, exist_ok=True)
    
    # Walk through the folder and subfolders, skipping the new_folder_path
    for dirpath, dirnames, filenames in os.walk(folder_path):
        # Skip the 'converted_utf8' folder
        if new_folder_name in dirpath:
            continue
        
        # Create a corresponding subfolder in the new folder
        relative_path = os.path.relpath(dirpath, folder_path)
        new_subfolder_path = os.path.join(new_folder_path, relative_path)
        os.makedirs(new_subfolder_path, exist_ok=True)
        
        for filename in filenames:
            if filename.endswith(".lua"):  # Only process Lua files
                input_file_path = os.path.join(dirpath, filename)
                try:
                    # Detect encoding of the file
                    detected_encoding = detect_encoding(input_file_path)
                    
                    # Count the number of files processed with this encoding
                    if detected_encoding not in encoding_counts:
                        encoding_counts[detected_encoding] = 0
                        # Print the encoding when it's encountered for the first time
                        print(f"Detected encoding for the first time: {detected_encoding}")
                    encoding_counts[detected_encoding] += 1
                    total_files_processed += 1
                    
                    # Print a message if encoding could not be determined
                    if detected_encoding == 'unknown':
                        print(f"Encoding could not be determined for file: {filename}")
                        continue

                    # Read the file with the detected encoding
                    with open(input_file_path, 'r', encoding=detected_encoding) as file:
                        content = file.read()

                    # Write the content to the corresponding new subfolder in UTF-8
                    output_file_path = os.path.join(new_subfolder_path, filename)
                    with open(output_file_path, 'w', encoding='utf-8') as utf8_file:
                        utf8_file.write(content)
                
                except UnicodeDecodeError as e:
                    print(f"Error decoding {filename} with {detected_encoding}: {e}")
                except Exception as e:
                    print(f"An error occurred with {filename}: {e}")

    # Print summary
    print(f"\nTotal files processed: {total_files_processed}")
    print("Number of files by encoding:")
    for encoding, count in encoding_counts.items():
        print(f"  {encoding}: {count} files")

import os
import tkinter as tk
from tkinter import filedialog, messagebox

def ask_for_output_location(default_output_path):
    """
    Asks the user where to save the output. Offers the choice between:
    - Saving in a folder parallel to the input folder (default).
    - Choosing a custom folder.
    - Saving as a subfolder within the input folder.
    
    Returns the chosen output folder path.
    """
    root = tk.Tk()
    root.withdraw()

    # Message box with options
    answer = messagebox.askyesnocancel("Save Options", 
                                       "Save output folder in the same directory as input?\n"
                                       "Yes: Parallel to input folder\n"
                                       "No: Select a custom location\n"
                                       "Cancel: Save inside the input folder")

    if answer is True:  # Yes -> Save parallel to input
        return default_output_path
    elif answer is False:  # No -> Choose a custom location
        output_folder = filedialog.askdirectory(title="Select Folder to Save Converted Files")
        return output_folder if output_folder else default_output_path
    else:  # Cancel -> Save inside input folder
        return os.path.join(default_output_path, "converted_utf8")

def select_folder_and_convert():
    """
    Opens a dialog to select a folder and then converts all Lua files in that folder and its subfolders to UTF-8.
    """
    # Create a root window and hide it
    root = tk.Tk()
    root.withdraw()

    # Open a dialog to select the folder
    folder_path = filedialog.askdirectory(title="Select Folder to Convert Lua Files")

    if folder_path:
        # Default output location: Parallel to the selected folder
        parent_folder = os.path.dirname(folder_path)
        folder_name = os.path.basename(folder_path)
        default_output_path = os.path.join(parent_folder, folder_name + "_converted_utf8")

        # Ask the user where to save the output
        output_folder = ask_for_output_location(default_output_path)
        
        if output_folder:
            # Call the conversion function (to be implemented)
            convert_folder_to_utf8(folder_path, output_folder)
            print(f"All Lua files in {folder_path} and its subfolders have been converted to UTF-8.")
        else:
            print("No folder selected for output.")
    else:
        print("No folder selected.")

# Example usage: Run this function to select the folder and convert files
if __name__ == "__main__":
    select_folder_and_convert()
