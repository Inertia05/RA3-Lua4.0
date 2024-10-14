import os
import xml.etree.ElementTree as ET
from tkinter import Tk
from tkinter import filedialog

def select_folder():
    """Open a dialog to select a folder and return the selected folder path."""
    # Hide the root Tk window
    root = Tk()
    root.withdraw()

    # Open the folder selection dialog
    folder_selected = filedialog.askdirectory()

    # Return the selected folder path
    return folder_selected

def extract_ids_and_lifetimes_from_xml_in_folder(directory_path):
    """Extract ids and system lifetimes from all FXParticleSystemTemplate elements in XML files within the specified folder."""
    data_list = []
    correct_namespace_count = 0
    wrong_namespace_files = []
    no_system_lifetime_count = 0

    for filename in os.listdir(directory_path):
        if filename.endswith('.xml'):
            file_path = os.path.join(directory_path, filename)
            found_data_in_file = []

            try:
                # Parse the XML file
                tree = ET.parse(file_path)
                root = tree.getroot()

                # Check the namespace of the root element
                namespace = root.tag.split('}')[0].strip('{')
                if namespace != 'uri:ea.com:eala:asset':
                    print(f"Warning: '{filename}' has a different namespace: {namespace}")
                    wrong_namespace_files.append(filename)
                    continue
                else:
                    correct_namespace_count += 1

                # Define the namespace (assuming 'uri:ea.com:eala:asset')
                ns = {'ns': 'uri:ea.com:eala:asset'}

                # Find all FXParticleSystemTemplate elements and get their id and SystemLifetime attribute
                for fx_template in root.findall('.//ns:FXParticleSystemTemplate', ns):
                    fx_id = fx_template.get('id')
                    system_lifetime = fx_template.get('SystemLifetime')

                    # If system_lifetime is missing, count it as missing and set lifetime to None
                    if not system_lifetime:
                        no_system_lifetime_count += 1
                        system_lifetime = "nil"  # Using "nil" for Lua

                    if fx_id:
                        found_data_in_file.append((fx_id, system_lifetime))

                # If no ids were found in this file, print a message
                if not found_data_in_file:
                    print(f"No 'id' found in file: {filename}")
                else:
                    data_list.extend(found_data_in_file)

            except ET.ParseError:
                print(f"Error parsing {filename}")

    return data_list, correct_namespace_count, wrong_namespace_files, no_system_lifetime_count

def save_data_to_lua_file(data_list, directory_path, total_files_processed, correct_namespace_count, no_system_lifetime_count, wrong_namespace_files):
    """Save the extracted ids and system lifetimes to a Lua file with a summary."""
    output_file_path = os.path.join(directory_path, 'extracted_fx_data.lua')

    with open(output_file_path, 'w') as file:
        # Add the summary to the Lua file
        file.write("-- Summary\n")
        file.write(f"-- Total files processed: {total_files_processed}\n")
        file.write(f"-- Total files with correct namespace: {correct_namespace_count}\n")
        file.write(f"-- Total 'id's found: {len(data_list)}\n")
        file.write(f"-- Files with missing 'SystemLifetime': {no_system_lifetime_count}\n")
        if wrong_namespace_files:
            file.write(f"-- Files with wrong namespace: {len(wrong_namespace_files)}\n")
            for wrong_file in wrong_namespace_files:
                file.write(f"--  - {wrong_file}\n")
        else:
            file.write("-- All files have the correct namespace.\n")

        file.write("\n-- Extracted FX Particle System Data\n")
        file.write("local FXParticleSystemData = {\n")
        
        # Align the Lua table output (padding outside the string values)
        max_id_length = max([len(fx_id) for fx_id, _ in data_list])
        for fx_id, system_lifetime in data_list:
            padding = ' ' * (max_id_length - len(fx_id))
            file.write(f'    {{ id = "{fx_id}",{padding} SystemLifetime = {system_lifetime} }},\n')

        file.write("}\n\n")
        file.write("return FXParticleSystemData\n")

    print(f"IDs and SystemLifetime values saved to {output_file_path}")

# Main flow
if __name__ == "__main__":
    # Select folder using the function
    folder_path = select_folder()

    if folder_path:
        # Extract IDs and SystemLifetime from XML files in the selected folder
        found_data, correct_namespace_count, wrong_namespace_files, no_system_lifetime_count = extract_ids_and_lifetimes_from_xml_in_folder(folder_path)

        # Output the collected data
        if found_data:
            total_files_processed = len([f for f in os.listdir(folder_path) if f.endswith('.xml')])
            save_data_to_lua_file(found_data, folder_path, total_files_processed, correct_namespace_count, no_system_lifetime_count, wrong_namespace_files)
        else:
            print("No IDs found in any file.")

        # Print summary
        print("\nSummary:")
        total_files_processed = len([f for f in os.listdir(folder_path) if f.endswith('.xml')])
        print(f"Total files processed: {total_files_processed}")
        print(f"Total files with correct namespace: {correct_namespace_count}")
        print(f"Total 'id's found: {len(found_data)}")
        print(f"Files with missing 'SystemLifetime': {no_system_lifetime_count}")
        if wrong_namespace_files:
            print(f"Files with wrong namespace: {len(wrong_namespace_files)}")
            for file in wrong_namespace_files:
                print(f" - {file}")
        else:
            print("All files have the correct namespace.")
    else:
        print("No folder selected.")
