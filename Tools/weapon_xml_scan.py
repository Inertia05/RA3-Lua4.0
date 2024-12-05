import xml.etree.ElementTree as ET
import pandas as pd
import os
import tkinter as tk
from tkinter import filedialog
from collections import defaultdict

def parse_weapon_file(xml_file, seen_weapons, duplicate_weapons):
    weapon_data = []
    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    for weapon in root.findall(".//{uri:ea.com:eala:asset}WeaponTemplate"):
        weapon_id = weapon.get("id")
        
        # Check for duplicate weapons and record the conflict
        if weapon_id in seen_weapons:
            # Add the current file to the list of duplicates for this weapon
            duplicate_weapons[weapon_id].append(xml_file)
            print(f"Duplicate weapon found: {weapon_id} (first seen in {seen_weapons[weapon_id]}, duplicate in {xml_file})")
        else:
            # Mark weapon as seen and associate it with the current file
            seen_weapons[weapon_id] = xml_file

            weapon_info = {
                "WeaponID": weapon_id,
                "AttackRange": weapon.get("AttackRange"),
                "AcceptableAimDelta": weapon.get("AcceptableAimDelta"),
                "ClipSize": weapon.get("ClipSize"),
                "FiringLoopSound": weapon.get("FiringLoopSound"),
                "AutoReloadsClip": weapon.get("AutoReloadsClip"),
                "PreAttackType": weapon.get("PreAttackType"),
                "CanFireWhileMoving": weapon.get("CanFireWhileMoving"),
                "RequiredAntiMask": weapon.get("RequiredAntiMask"),
                "ForbiddenAntiMask": weapon.get("ForbiddenAntiMask"),
                "RadiusDamageAffects": weapon.get("RadiusDamageAffects"),
                "Flags": weapon.get("Flags")
            }
            
            # Timings
            pre_attack_delay = weapon.find(".//{uri:ea.com:eala:asset}PreAttackDelay")
            if pre_attack_delay is not None:
                weapon_info["PreAttackMinSeconds"] = pre_attack_delay.get("MinSeconds")
                weapon_info["PreAttackMaxSeconds"] = pre_attack_delay.get("MaxSeconds")

            firing_duration = weapon.find(".//{uri:ea.com:eala:asset}FiringDuration")
            if firing_duration is not None:
                weapon_info["FiringMinSeconds"] = firing_duration.get("MinSeconds")
                weapon_info["FiringMaxSeconds"] = firing_duration.get("MaxSeconds")

            clip_reload_time = weapon.find(".//{uri:ea.com:eala:asset}ClipReloadTime")
            if clip_reload_time is not None:
                weapon_info["ClipReloadMinSeconds"] = clip_reload_time.get("MinSeconds")
                weapon_info["ClipReloadMaxSeconds"] = clip_reload_time.get("MaxSeconds")

            # Nuggets
            nuggets = weapon.find(".//{uri:ea.com:eala:asset}Nuggets")
            if nuggets is not None:
                for nugget in nuggets:
                    nugget_type = nugget.tag.split('}')[-1]
                    if nugget_type == "StripMaxHealthPercentNugget":
                        weapon_info.update({
                            "AmountToStrip": nugget.get("AmountToStrip"),
                            "DamageType": nugget.get("DamageType"),
                            "DamageFXType": nugget.get("DamageFXType"),
                            "DeathType": nugget.get("DeathType")
                        })
                    elif nugget_type == "ActivateLiftObjectNugget":
                        weapon_info["LiftLifetime"] = nugget.get("Lifetime")
            
            weapon_data.append(weapon_info)
    
    return weapon_data

def parse_included_files(definition_file):
    tree = ET.parse(definition_file)
    root = tree.getroot()
    included_files = []

    for include in root.findall(".//{uri:ea.com:eala:asset}Include"):
        source = include.get("source")
        if source:
            included_files.append(source)
    
    return included_files

def save_weapon_data_to_csv(weapon_data, output_path):
    df = pd.DataFrame(weapon_data)
    df.to_csv(output_path, index=False)
    print(f"Weapon data saved to {output_path}")

def main():
    root = tk.Tk()
    root.withdraw()
    source_folder = filedialog.askdirectory(title="Select folder containing Weapon.xml")

    if source_folder:
        weapon_definition_file = os.path.join(source_folder, "Weapon.xml")
        
        if os.path.isfile(weapon_definition_file):
            included_files = parse_included_files(weapon_definition_file)
            included_files.insert(0, "Weapon.xml")  # Include Weapon.xml itself

            weapon_data = []
            seen_files = set()
            seen_weapons = {}
            duplicate_files = 0
            duplicate_weapons = defaultdict(list)

            for file in included_files:
                file_path = os.path.join(source_folder, file)
                
                if file in seen_files:
                    duplicate_files += 1
                    print(f"Duplicate file skipped: {file}")
                    continue

                seen_files.add(file)

                if os.path.isfile(file_path):
                    file_weapon_data = parse_weapon_file(file_path, seen_weapons, duplicate_weapons)
                    weapon_data.extend(file_weapon_data)
                else:
                    print(f"File not found: {file_path}")

            # Ask where to save the final CSV file
            save_path = filedialog.asksaveasfilename(
                title="Save weapon data as CSV",
                defaultextension=".csv",
                filetypes=[("CSV files", "*.csv")]
            )
            
            if save_path:
                save_weapon_data_to_csv(weapon_data, save_path)
            else:
                print("No save location selected.")
            
            # Print summary
            print("\nScan Summary:")
            print(f"Total files processed: {len(seen_files)}")
            print(f"Duplicate files skipped: {duplicate_files}")
            print(f"Total unique weapons found: {len(seen_weapons)}")
            print(f"Total entries written to CSV: {len(weapon_data)}")

            # Print duplicate weapon details in a more readable format
            print("\nDuplicate Weapons Found:")
            for weapon_id, file_list in duplicate_weapons.items():
                first_file = os.path.basename(seen_weapons[weapon_id])  # Get only the filename
                duplicates = ", ".join(os.path.basename(f) for f in file_list)
                print(f"    - WeaponID: {weapon_id}")
                print(f"      First seen in: {first_file}")
                print(f"      Duplicates in: {duplicates}\n")

        else:
            print("Weapon.xml not found in the selected folder.")
    else:
        print("No folder selected.")

if __name__ == "__main__":
    main()
