# @OO 更加稳妥的方式还是读取全部被 Include 的 xml

# 对于原版源码，从 static.xml 读起

# 对于 mod，从 mod.xml 读起

import os
import xml.etree.ElementTree as ET
import tkinter as tk
from tkinter import filedialog
from collections import Counter, defaultdict
import pandas as pd
from collections import defaultdict

# Define the namespace mappings
NAMESPACE = {'ns': 'uri:ea.com:eala:asset'}

def parse_combat_info(xml_file):
    try:
        # Parse the XML file
        tree = ET.parse(xml_file)
        root = tree.getroot()
        
        # Extract relevant information
        combat_info = {
            "Filename": os.path.basename(xml_file),
            "UnitID": None,
            "Side": None,
            "BuildTime": None,
            "HealthBoxHeightOffset": None,
            "CommandSet": None,
            "KindOf": None,
            "WeaponCategory": None,
            "ThreatLevel": None,
            "MaxHealth": None,
            "ArmorSet": None,
            "Speed": None,
            "Weapons": [],  # List to hold all weapons
            "PassengerCapacity": None,
            "SpecialPower": None
        }
        
        # Extract information from GameObject attributes
        game_object = root.find(".//ns:GameObject", namespaces=NAMESPACE)
        if game_object is not None:
            combat_info["UnitID"] = game_object.get("id")
            combat_info["Side"] = game_object.get("Side")
            combat_info["BuildTime"] = game_object.get("BuildTime")
            combat_info["HealthBoxHeightOffset"] = game_object.get("HealthBoxHeightOffset")
            combat_info["CommandSet"] = game_object.get("CommandSet")
            combat_info["KindOf"] = game_object.get("KindOf")
            combat_info["WeaponCategory"] = game_object.get("WeaponCategory")
            combat_info["ThreatLevel"] = game_object.get("ThreatLevel")

        # Health
        health_element = root.find(".//ns:ActiveBody", namespaces=NAMESPACE)
        if health_element is not None:
            combat_info["MaxHealth"] = health_element.get("MaxHealth")
        
        # Armor
        armor_set = root.find(".//ns:ArmorSet", namespaces=NAMESPACE)
        if armor_set is not None:
            combat_info["ArmorSet"] = armor_set.get("Armor")
        
        # Speed
        for locomotor in root.findall(".//ns:LocomotorSet", namespaces=NAMESPACE):
            if locomotor.get("Condition") == "NORMAL":
                combat_info["Speed"] = locomotor.get("Speed")
        
        # Weapons - iterate through each <Weapon> tag within <WeaponSetUpdate>
        weapon_set = root.find(".//ns:WeaponSetUpdate/ns:WeaponSlotHardpoint", namespaces=NAMESPACE)
        if weapon_set is not None:
            for weapon in weapon_set.findall(".//ns:Weapon", namespaces=NAMESPACE):
                weapon_info = {
                    "Ordering": weapon.get("Ordering"),
                    "Template": weapon.get("Template"),
                    "ObjectStatus": weapon.get("ObjectStatus"),
                    "ForbiddenObjectStatus": weapon.get("ForbiddenObjectStatus"),
                }
                combat_info["Weapons"].append(weapon_info)

        # Transport capacity
        transport = root.find(".//ns:TransportContain", namespaces=NAMESPACE)
        if transport is not None:
            combat_info["PassengerCapacity"] = transport.get("ContainMax")
        
        # Special power
        special_power = root.find(".//ns:SpecialPower", namespaces=NAMESPACE)
        if special_power is not None:
            combat_info["SpecialPower"] = special_power.get("SpecialPowerTemplate")
        
        return combat_info

    except ET.ParseError as e:
        print(f"Error parsing XML file: {xml_file} - {e}")
        return None
    except Exception as e:
        print(f"Unexpected error in file {xml_file}: {e}")
        return None



def summarize_combat_info(all_combat_info):
    # Flatten data to handle each weapon in its own row (except the first weapon)
    flattened_data = []
    
    for info in all_combat_info:
        # Extract unit-level details
        base_data = {
            "Filename": info["Filename"],
            "UnitID": info["UnitID"],
            "Side": info["Side"],
            "BuildTime": info["BuildTime"],
            "HealthBoxHeightOffset": info["HealthBoxHeightOffset"],
            "CommandSet": info["CommandSet"],
            "KindOf": info["KindOf"],
            "WeaponCategory": info["WeaponCategory"],
            "ThreatLevel": info["ThreatLevel"],
            "MaxHealth": info["MaxHealth"],
            "ArmorSet": info["ArmorSet"],
            "Speed": info["Speed"],
            "PassengerCapacity": info["PassengerCapacity"],
            "SpecialPower": info["SpecialPower"]
        }
        
        # Handle weapons
        if info["Weapons"]:
            # Add the first weapon on the same row as unit
            first_weapon = info["Weapons"][0]
            row = base_data.copy()
            row.update({
                "Weapon_Ordering": first_weapon["Ordering"],
                "Weapon_Template": first_weapon["Template"],
                "Weapon_ObjectStatus": first_weapon["ObjectStatus"],
                "Weapon_ForbiddenObjectStatus": first_weapon["ForbiddenObjectStatus"],
            })
            flattened_data.append(row)
            
            # Add each subsequent weapon on a new row with unit details empty
            for weapon in info["Weapons"][1:]:
                row = {key: None for key in base_data}  # Empty unit-level details
                row.update({
                    "Filename": info["Filename"],
                    "Weapon_Ordering": weapon["Ordering"],
                    "Weapon_Template": weapon["Template"],
                    "Weapon_ObjectStatus": weapon["ObjectStatus"],
                    "Weapon_ForbiddenObjectStatus": weapon["ForbiddenObjectStatus"],
                })
                flattened_data.append(row)
        else:
            # No weapons, add unit data without weapon info
            flattened_data.append(base_data)

    # Convert flattened data into DataFrame and save as CSV
    df = pd.DataFrame(flattened_data)
    
    # Open a file dialog to choose save location and filename
    root = tk.Tk()
    root.withdraw()  # Hide the main Tk window
    output_path = filedialog.asksaveasfilename(
        title="Save Combat Info Summary",
        defaultextension=".csv",
        filetypes=[("CSV files", "*.csv")]
    )
    
    if output_path:  # Check if a path was selected
        df.to_csv(output_path, index=False)
        print(f"Summary saved to {output_path}")
    else:
        print("Save operation was canceled.")



def main():
    # Open a dialog to select a folder
    root = tk.Tk()
    root.withdraw()  # Hide the root window
    folder_path = filedialog.askdirectory(title="Select Folder with XML Files")
    
    if not folder_path:
        print("No folder selected.")
        return

    # Collect all XML files in the selected folder
    xml_files = [os.path.join(folder_path, f) for f in os.listdir(folder_path) if f.endswith('.xml')]

    # Parse each XML file
    all_combat_info = []
    for xml_file in xml_files:
        combat_info = parse_combat_info(xml_file)
        if combat_info:
            all_combat_info.append(combat_info)

    # Generate and print the summary
    summarize_combat_info(all_combat_info)

if __name__ == "__main__":
    main()
